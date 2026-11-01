package com.apserp.plat.meta;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.tenant.TenantContext;
import com.apserp.plat.meta.expr.ExprEvaluator;
import com.apserp.plat.meta.expr.ExprException;
import com.apserp.plat.perm.PermissionService;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/**
 * 动作与按钮引擎。
 *
 * <p>一个按钮 = 元数据（文案/图标/样式/可见与可用表达式/权限点）+ 一串动作（{@code plat.ButtonAction}）。
 * 前端只渲染后端下发的按钮，不在页面里写死任何按钮。</p>
 *
 * <p>可见性两层判定，缺一不可：</p>
 * <ol>
 *   <li><b>权限点</b>：{@code Button.FunctionId → ModuleFunction.Code → plat.ufn_Perm_Check}；无权限直接不下发。</li>
 *   <li><b>表达式</b>：{@code VisibleExpr}（不下发）与 {@code IsEnabledExpr}（下发但置灰），针对当前行数据求值。</li>
 * </ol>
 *
 * <p>动作类型（{@code ButtonAction.ActionType}）：</p>
 * <pre>
 *   1 = 内置（BuiltinCode：OPEN_FORM / DELETE / SUBMIT / EXPORT / REFRESH / CLOSE）
 *   2 = 导航（Target：前端路由或对象编码）
 *   3 = 命令（Command：后端注册的动作编码，如 PRINT / SYNC）
 *   4 = 脚本（Command：仅允许白名单命令，禁止任意代码执行）
 * </pre>
 */
@Service
public class ActionService {

    private final JdbcTemplate jdbc;
    private final PermissionService permissionService;

    public ActionService(JdbcTemplate jdbc, PermissionService permissionService) {
        this.jdbc = jdbc;
        this.permissionService = permissionService;
    }

    // ------------------------------------------------------------ DTO

    public record ActionDto(long id, int seq, int actionType, String actionTypeName, String builtinCode,
                            String target, String command, String paramJson, String confirmText,
                            String successMessage, boolean needWorkflow, boolean enabled) {
    }

    public record ButtonDto(long id, String code, String name, String text, String icon, int buttonType,
                            int sort, String style, String visibleExpr, String enabledExpr,
                            String functionCode, List<ActionDto> actions) {
    }

    /** 运行时下发的按钮：已按权限过滤、已按当前行数据求出可见/可用。 */
    public record ResolvedButton(String code, String text, String icon, int buttonType, String style,
                                 boolean visible, boolean enabled, String disableReason,
                                 List<ActionDto> actions) {
    }

    public record ButtonSaveRequest(Long id, String code, String name, String text, String icon, int buttonType,
                                    long functionId, int sort, boolean visible, String visibleExpr,
                                    String enabledExpr, String style, String remark,
                                    List<ActionSaveRequest> actions) {
    }

    public record ActionSaveRequest(int actionType, String builtinCode, String target, String command,
                                    String paramJson, String confirmText, String successMessage,
                                    boolean needWorkflow) {
    }

    private static final Map<Integer, String> ACTION_TYPES = Map.of(
            1, "内置", 2, "导航", 3, "命令", 4, "脚本");

    /** 允许的脚本白名单：只允许幂等的展示类命令，杜绝任意执行。 */
    private static final List<String> COMMAND_WHITELIST = List.of(
            "PRINT", "EXPORT", "REFRESH", "SYNC", "COPY", "NOTIFY");

    // ------------------------------------------------------------ 读取

    public List<ButtonDto> listButtons(String objectCode) {
        long tenantId = TenantContext.requireTenantId();
        String sql = """
                SELECT b.Id, b.Code, b.Name, b.Text, b.Icon, b.ButtonType, b.Sort, b.Style,
                       b.VisibleExpr, b.IsEnabledExpr, f.Code AS FunctionCode
                FROM plat.Button b
                LEFT JOIN plat.ModuleFunction f ON f.Id = b.FunctionId
                WHERE b.TenantId = ? AND b.IsDeleted = 0
                """;
        List<ButtonDto> heads;
        if (objectCode == null || objectCode.isBlank()) {
            heads = jdbc.query(sql + " ORDER BY b.Code",
                    (rs, i) -> mapButton(rs), tenantId);
        } else {
            heads = jdbc.query(sql + """
                            AND b.FunctionId IN (SELECT Id FROM plat.ModuleFunction WHERE TenantId = ? AND Code = ?)
                            ORDER BY b.Sort
                            """,
                    (rs, i) -> mapButton(rs), tenantId, tenantId, objectCode);
        }
        return heads.stream().map(b -> new ButtonDto(b.id(), b.code(), b.name(), b.text(), b.icon(),
                b.buttonType(), b.sort(), b.style(), b.visibleExpr(), b.enabledExpr(), b.functionCode(),
                actionsOf(b.id()))).toList();
    }

    private ButtonDto mapButton(java.sql.ResultSet rs) throws java.sql.SQLException {
        return new ButtonDto(rs.getLong("Id"), rs.getString("Code"), rs.getString("Name"),
                rs.getString("Text"), rs.getString("Icon"), rs.getInt("ButtonType"),
                rs.getInt("Sort"), rs.getString("Style"), rs.getString("VisibleExpr"),
                rs.getString("IsEnabledExpr"), rs.getString("FunctionCode"), List.of());
    }

    private List<ActionDto> actionsOf(long buttonId) {
        return jdbc.query("""
                        SELECT Id, Seq, ActionType, BuiltinCode, Target, Command, ParamJson,
                               ConfirmText, SuccessMessage, NeedWorkflow, IsEnabled
                        FROM plat.ButtonAction
                        WHERE ButtonId = ?
                        ORDER BY Seq, Id
                        """,
                (rs, i) -> new ActionDto(rs.getLong("Id"), rs.getInt("Seq"), rs.getInt("ActionType"),
                        ACTION_TYPES.getOrDefault(rs.getInt("ActionType"), "未知"),
                        rs.getString("BuiltinCode"), rs.getString("Target"), rs.getString("Command"),
                        rs.getString("ParamJson"), rs.getString("ConfirmText"),
                        rs.getString("SuccessMessage"), rs.getBoolean("NeedWorkflow"),
                        rs.getBoolean("IsEnabled")),
                buttonId);
    }

    // ------------------------------------------------------------ 运行时解析

    /**
     * 给前端某一行数据解析出按钮：过滤无权限、求值可见与可用。
     *
     * @param objectCode 数据对象编码（用于取该功能点下的按钮）
     * @param row        当前行数据（可为空：列表页无选中行时只返回工具栏按钮）
     */
    public List<ResolvedButton> resolve(String objectCode, Map<String, Object> row) {
        Map<String, Object> ctx = row == null ? Map.of() : row;
        List<ResolvedButton> out = new ArrayList<>();
        for (ButtonDto b : listButtons(objectCode)) {
            // 1) 权限点：有 FunctionCode 才校验（平台管理员在 PermissionService 内直通）
            if (b.functionCode() != null && !b.functionCode().isBlank()
                    && !permissionService.check(b.functionCode(), "read")) {
                continue;
            }
            // 2) 可见表达式
            boolean visible = true;
            if (b.visibleExpr() != null && !b.visibleExpr().isBlank()) {
                try {
                    visible = ExprEvaluator.test(b.visibleExpr(), ctx);
                } catch (ExprException e) {
                    // 表达式坏掉时“宁可不显示”，避免误操作
                    visible = false;
                }
            }
            if (!visible) {
                continue;
            }
            // 3) 可用表达式
            boolean enabled = true;
            String reason = null;
            if (b.enabledExpr() != null && !b.enabledExpr().isBlank()) {
                try {
                    enabled = ExprEvaluator.test(b.enabledExpr(), ctx);
                    if (!enabled) {
                        reason = "当前数据不满足按钮条件";
                    }
                } catch (ExprException e) {
                    enabled = false;
                    reason = "按钮启用条件配置有误：" + e.getMessage();
                }
            }
            out.add(new ResolvedButton(b.code(), b.text() == null ? b.name() : b.text(), b.icon(),
                    b.buttonType(), b.style(), true, enabled, reason, b.actions()));
        }
        return out;
    }

    // ------------------------------------------------------------ 写

    public long saveButton(Long id, ButtonSaveRequest req) {
        long tenantId = TenantContext.requireTenantId();
        if (req.code() == null || req.code().isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "按钮编码不能为空");
        }
        validateExpr(req.visibleExpr(), "可见表达式");
        validateExpr(req.enabledExpr(), "可用表达式");
        if (req.actions() != null) {
            for (ActionSaveRequest a : req.actions()) {
                if (a.actionType() == 4 && (a.command() == null
                        || COMMAND_WHITELIST.stream().noneMatch(c -> c.equalsIgnoreCase(a.command())))) {
                    throw new ApiException(ErrorCode.BAD_REQUEST,
                            "脚本动作只允许白名单命令：" + String.join("/", COMMAND_WHITELIST));
                }
            }
        }
        Long uid = TenantContext.userId();
        long buttonId;
        if (id == null) {
            Long dup = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM plat.Button WHERE TenantId = ? AND Code = ? AND IsDeleted = 0
                    """, Long.class, tenantId, req.code());
            if (dup != null && dup > 0) {
                throw new ApiException(ErrorCode.DUPLICATE_KEY, "按钮编码已存在：" + req.code());
            }
            jdbc.update("""
                    INSERT plat.Button (TenantId, Code, Name, Text, Icon, ButtonType, FunctionId, Sort,
                                        IsVisible, VisibleExpr, IsEnabledExpr, Style, Remark, IsDeleted,
                                        CreatedBy, CreatedAt)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, sysutcdatetime())
                    """, tenantId, req.code(), req.name(), req.text(), req.icon(),
                    req.buttonType() <= 0 ? 1 : req.buttonType(), req.functionId() <= 0 ? null : req.functionId(),
                    req.sort(), req.visible() ? 1 : 0, req.visibleExpr(), req.enabledExpr(),
                    req.style(), req.remark(), uid);
            buttonId = jdbc.queryForObject("""
                    SELECT Id FROM plat.Button WHERE TenantId = ? AND Code = ?
                    """, Long.class, tenantId, req.code());
        } else {
            int n = jdbc.update("""
                    UPDATE plat.Button
                    SET Name = ?, Text = ?, Icon = ?, ButtonType = ?, FunctionId = ?, Sort = ?,
                        IsVisible = ?, VisibleExpr = ?, IsEnabledExpr = ?, Style = ?, Remark = ?,
                        ModifiedBy = ?, ModifiedAt = sysutcdatetime()
                    WHERE Id = ? AND TenantId = ? AND IsDeleted = 0
                    """, req.name(), req.text(), req.icon(), req.buttonType() <= 0 ? 1 : req.buttonType(),
                    req.functionId() <= 0 ? null : req.functionId(), req.sort(), req.visible() ? 1 : 0,
                    req.visibleExpr(), req.enabledExpr(), req.style(), req.remark(), uid, id, tenantId);
            if (n == 0) {
                throw new ApiException(ErrorCode.NOT_FOUND, "按钮不存在：" + id);
            }
            buttonId = id;
            jdbc.update("DELETE FROM plat.ButtonAction WHERE ButtonId = ?", buttonId);
        }
        if (req.actions() != null) {
            int seq = 0;
            for (ActionSaveRequest a : req.actions()) {
                seq += 10;
                jdbc.update("""
                        INSERT plat.ButtonAction (ButtonId, Seq, ActionType, BuiltinCode, Target, Command,
                                                  ParamJson, ConfirmText, SuccessMessage, NeedWorkflow, IsEnabled)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
                        """, buttonId, seq, a.actionType() <= 0 ? 1 : a.actionType(), a.builtinCode(),
                        a.target(), a.command(), a.paramJson(), a.confirmText(), a.successMessage(),
                        a.needWorkflow() ? 1 : 0);
            }
        }
        return buttonId;
    }

    public void deleteButton(String code) {
        long tenantId = TenantContext.requireTenantId();
        Long id = jdbc.query("SELECT Id FROM plat.Button WHERE TenantId = ? AND Code = ? AND IsDeleted = 0",
                (rs, i) -> rs.getLong(1), tenantId, code).stream().findFirst().orElse(null);
        if (id == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, "按钮不存在：" + code);
        }
        jdbc.update("DELETE FROM plat.ButtonAction WHERE ButtonId = ?", id);
        jdbc.update("UPDATE plat.Button SET IsDeleted = 1, DeletedBy = ?, DeletedAt = sysutcdatetime() WHERE Id = ?",
                TenantContext.userId(), id);
    }

    /** 设计器用：某对象下可选的功能点（用于给按钮挂权限点）。 */
    public List<Map<String, Object>> functionsOf(String objectCode) {
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                        SELECT Id, Code, Name FROM plat.ModuleFunction
                        WHERE TenantId = ? AND (Code = ? OR Code LIKE ?)
                        ORDER BY Code
                        """,
                (rs, i) -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("id", rs.getLong("Id"));
                    m.put("code", rs.getString("Code"));
                    m.put("name", rs.getString("Name"));
                    return m;
                }, tenantId, objectCode, objectCode + ".%");
    }

    private void validateExpr(String expr, String label) {
        if (expr == null || expr.isBlank()) {
            return;
        }
        try {
            ExprEvaluator.compile(expr);
        } catch (ExprException e) {
            throw new ApiException(ErrorCode.BAD_REQUEST, label + "有误：" + e.getMessage());
        }
    }
}

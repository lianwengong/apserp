package com.aschain.plat.meta;

import com.aschain.common.ApiException;
import com.aschain.common.ErrorCode;
import com.aschain.common.tenant.TenantContext;
import com.aschain.plat.perm.PermissionService;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/**
 * 动作执行器：把「按钮上配置的动作链」真正执行掉。
 *
 * <p>之前前端只认 5 个内置动作，导航/命令/脚本动作点下去没反应。现在所有动作都在服务端
 * 按注册表分派，新增动作只需要在 {@link #COMMANDS} 里登记一个实现，不用改前端。</p>
 *
 * <p>权限两道：按钮的权限功能点（FunctionCode）+ 数据对象动作码（{@code DATA:{code}:delete} 等）。
 * 平台管理员在 {@link PermissionService} 内部直通。</p>
 */
@Service
public class ActionExecutor {

    private static final Logger log = LoggerFactory.getLogger(ActionExecutor.class);

    private final JdbcTemplate jdbc;
    private final ActionService actionService;
    private final MetaDefinitionService definitionService;
    private final MetaQueryService queryService;
    private final MetaSaveProc saveProc;
    private final ApprovalService approvalService;
    private final PermissionService permissionService;
    private final DocStatusService docStatus;

    /** 服务端命令注册表：命令名 → 实现。命令名同时是脚本动作的白名单键。 */
    private final Map<String, Command> commands = new LinkedHashMap<>();

    public ActionExecutor(JdbcTemplate jdbc, ActionService actionService,
                          MetaDefinitionService definitionService, MetaQueryService queryService,
                          MetaSaveProc saveProc, ApprovalService approvalService,
                          PermissionService permissionService, DocStatusService docStatus) {
        this.jdbc = jdbc;
        this.actionService = actionService;
        this.definitionService = definitionService;
        this.queryService = queryService;
        this.saveProc = saveProc;
        this.approvalService = approvalService;
        this.permissionService = permissionService;
        this.docStatus = docStatus;

        commands.put("export.csv", this::commandExportCsv);
        commands.put("copy.record", this::commandCopyRecord);
        commands.put("audit.log", this::commandAuditLog);
        commands.put("workflow.submit", this::commandSubmitWorkflow);
    }

    // ---------------------------------------------------------------- DTO

    /**
     * 执行结果：前端按 {@code kind} 决定做什么。
     * navigate=跳路由，download=下载，refresh=刷新列表，message=只提示，close=关表单。
     */
    public record ExecuteResult(String kind, String message, String route, String downloadUrl,
                                Map<String, Object> data, boolean refresh) {

        static ExecuteResult message(String text) {
            return new ExecuteResult("message", text, null, null, Map.of(), false);
        }

        static ExecuteResult navigate(String route) {
            return new ExecuteResult("navigate", null, route, null, Map.of(), true);
        }

        static ExecuteResult download(String url) {
            return new ExecuteResult("download", null, null, url, Map.of(), false);
        }

        static ExecuteResult refresh(String text) {
            return new ExecuteResult("refresh", text, null, null, Map.of(), true);
        }
    }

    public record ExecuteRequest(String objectCode, Long id, String buttonCode,
                                 Map<String, Object> params) {
    }

    private interface Command {
        ExecuteResult run(String objectCode, Long id, Map<String, Object> params);
    }

    // ---------------------------------------------------------------- 执行

    /**
     * 执行某个按钮的全部动作，遇到第一个「终止型」结果（导航/下载/关表单）就停。
     */
    public ExecuteResult execute(ExecuteRequest req) {
        if (req.objectCode() == null || req.objectCode().isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "缺少数据对象编码");
        }
        if (req.buttonCode() == null || req.buttonCode().isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "缺少按钮编码");
        }
        MetaQueryService.requireValidObjectCode(req.objectCode());

        ActionService.ButtonDto button = actionService.listButtons(req.objectCode()).stream()
                .filter(b -> b.code().equals(req.buttonCode()))
                .findFirst()
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND,
                        "该对象没有这个按钮：" + req.buttonCode()));
        if (button.functionCode() != null && !button.functionCode().isBlank()
                && !permissionService.check(button.functionCode(), "read")) {
            throw new ApiException(ErrorCode.FORBIDDEN, "没有该按钮的权限：" + button.functionCode());
        }

        List<ActionService.ActionDto> actions = button.actions().stream()
                .filter(ActionService.ActionDto::enabled)
                .toList();
        if (actions.isEmpty()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "按钮没有可执行的动作：" + button.code());
        }

        ExecuteResult last = ExecuteResult.message("已执行");
        for (ActionService.ActionDto action : actions) {
            ExecuteResult result = dispatch(req, action);
            log.info("action_execute object={} id={} button={} type={} code={} kind={}",
                    req.objectCode(), req.id(), button.code(), action.actionType(),
                    action.builtinCode() != null ? action.builtinCode() : action.command(),
                    result.kind());
            last = result;
            if (isTerminal(result)) {
                return result;
            }
        }
        return last;
    }

    private boolean isTerminal(ExecuteResult r) {
        return "navigate".equals(r.kind()) || "download".equals(r.kind())
                || "close".equals(r.kind());
    }

    private ExecuteResult dispatch(ExecuteRequest req, ActionService.ActionDto action) {
        return switch (action.actionType()) {
            case 1 -> builtin(req, action);
            case 2 -> navigation(req, action);
            case 3, 4 -> command(req, action);
            default -> throw new ApiException(ErrorCode.BAD_REQUEST,
                    "不支持的动作类型：" + action.actionType());
        };
    }

    // ---------------------------------------------------------------- 内置动作

    private ExecuteResult builtin(ExecuteRequest req, ActionService.ActionDto action) {
        String code = action.builtinCode() == null ? "" : action.builtinCode().trim().toUpperCase();
        return switch (code) {
            case "OPEN_FORM" -> ExecuteResult.navigate(
                    "/object/" + req.objectCode() + "?id=" + (req.id() == null ? "" : req.id()));
            case "DELETE" -> softDelete(req);
            case "SUBMIT" -> commandSubmitWorkflow(req.objectCode(), req.id(), req.params());
            case "EXPORT" -> commandExportCsv(req.objectCode(), req.id(), req.params());
            case "PRINT" -> printUrl(req);
            case "REFRESH" -> ExecuteResult.refresh(action.successMessage());
            case "CLOSE" -> new ExecuteResult("close", action.successMessage(), null, null,
                    Map.of(), true);
            default -> throw new ApiException(ErrorCode.BAD_REQUEST,
                    "未知的内置动作：" + action.builtinCode());
        };
    }

    /**
     * 打印：返回渲染地址，前端取回 HTML 后开新窗口打印。
     * 模板编码从动作的 target 里取（设计器可指定用哪个模板），留空用默认模板。
     */
    private ExecuteResult printUrl(ExecuteRequest req) {
        if (req.id() == null || req.id() <= 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "请先选择一条单据再打印");
        }
        String template = req.params() == null ? null : (String) req.params().get("templateCode");
        String url = "/api/runtime/print?objectCode=" + urlEncode(req.objectCode())
                + "&id=" + req.id()
                + (template == null || template.isBlank() ? "" : "&templateCode=" + urlEncode(template));
        return new ExecuteResult("print", null, null, url, Map.of(), false);
    }

    /** 软删除：按元数据把 IsDeleted 置 1，业务数据保留可追溯。 */
    private ExecuteResult softDelete(ExecuteRequest req) {
        if (req.id() == null || req.id() <= 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "缺少主键，无法删除");
        }
        if (!permissionService.check("DATA:" + req.objectCode(), "delete")) {
            throw new ApiException(ErrorCode.FORBIDDEN, "没有该对象的删除权限：" + req.objectCode());
        }
        // 状态机：终态/审批中的单据不允许删除
        docStatus.guardDelete(req.objectCode(), req.id());
        var object = definitionService.getObject(req.objectCode());
        String table = "[" + object.schemaName() + "].[" + object.objectName() + "]";
        int n;
        try {
            n = jdbc.update("UPDATE " + table
                    + " SET IsDeleted = 1, DeletedAt = sysutcdatetime() WHERE ["
                    + object.primaryKey() + "] = ? AND ISNULL(IsDeleted, 0) = 0", req.id());
        } catch (org.springframework.dao.DataAccessException ex) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "该对象不支持删除（缺少 IsDeleted 列）", ex);
        }
        if (n == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND, "记录不存在或已被删除");
        }
        return ExecuteResult.refresh("已删除");
    }

    // ---------------------------------------------------------------- 导航动作

    private ExecuteResult navigation(ExecuteRequest req, ActionService.ActionDto action) {
        String target = action.target();
        if (target == null || target.isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "导航动作没有配置目标地址");
        }
        // 允许用 {id} 占位，前端不用拼字符串
        String route = req.id() == null ? target : target.replace("{id}", String.valueOf(req.id()));
        return ExecuteResult.navigate(route);
    }

    // ---------------------------------------------------------------- 命令动作

    private ExecuteResult command(ExecuteRequest req, ActionService.ActionDto action) {
        String name = action.command() != null && !action.command().isBlank()
                ? action.command().trim()
                : action.builtinCode() == null ? "" : action.builtinCode().trim();
        if (name.isEmpty()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "命令动作没有配置命令名");
        }
        // ActionType=4（脚本）只允许白名单：与命令注册表同一份名单，前端改不了
        Command cmd = commands.get(name);
        if (cmd == null) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                    "命令未注册（脚本动作白名单）：" + name + "，可用：" + String.join(",", commands.keySet()));
        }
        return cmd.run(req.objectCode(), req.id(), req.params() == null ? Map.of() : req.params());
    }

    private ExecuteResult commandExportCsv(String objectCode, Long id, Map<String, Object> params) {
        String filters = params.get("filters") == null ? null : String.valueOf(params.get("filters"));
        if (id != null && id > 0) {
            filters = "[{\"f\":\"Id\",\"op\":\"eq\",\"v\":\"" + id + "\"}]";
        }
        String sort = params.get("sort") == null ? null : String.valueOf(params.get("sort"));
        String url = "/api/runtime/export?objectCode=" + urlEncode(objectCode)
                + (filters == null || filters.isBlank() ? "" : "&filters=" + urlEncode(filters))
                + (sort == null || sort.isBlank() ? "" : "&sort=" + urlEncode(sort));
        return ExecuteResult.download(url);
    }

    private ExecuteResult commandCopyRecord(String objectCode, Long id, Map<String, Object> params) {
        if (id == null || id <= 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "缺少主键，无法复制");
        }
        Map<String, Object> row = single(objectCode, id);
        if (row.isEmpty()) {
            throw new ApiException(ErrorCode.NOT_FOUND, "记录不存在");
        }
        var object = definitionService.getObject(objectCode);
        Map<String, Object> copy = new LinkedHashMap<>(row);
        copy.remove(object.primaryKey());
        copy.remove("RowVersion");
        copy.remove("CreatedAt");
        copy.remove("ModifiedAt");
        // 编码类字段加后缀，避免撞唯一键；编号类清空交给编号引擎
        for (String key : List.of("Code", "DocNo")) {
            if (copy.get(key) != null) {
                String value = String.valueOf(copy.get(key));
                copy.put(key, value.length() > 40 ? value.substring(0, 40) + "-COPY" : value + "-COPY");
            }
        }
        String json;
        try {
            json = new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(copy);
        } catch (Exception e) {
            throw new ApiException(ErrorCode.INTERNAL, "复制失败：无法序列化数据", e);
        }
        long tenantId = TenantContext.requireTenantId();
        Long userId = TenantContext.userId();
        long newId = jdbc.execute((org.springframework.jdbc.core.ConnectionCallback<Long>) con ->
                saveProc.call(con, tenantId, userId, objectCode, json));
        return new ExecuteResult("refresh", "已复制为 #" + newId, null, null,
                Map.of("newId", newId), true);
    }

    private ExecuteResult commandAuditLog(String objectCode, Long id, Map<String, Object> params) {
        if (id == null || id <= 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "缺少主键，无法查询操作日志");
        }
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT TOP 50 Id, UserName, ActionType, ObjectNo, [At]
                FROM plat.AuditLog
                WHERE TenantId = ? AND ObjectType = ? AND ObjectId = ?
                ORDER BY Id DESC
                """, TenantContext.requireTenantId(), objectCode, id);
        return new ExecuteResult("message", "共 " + rows.size() + " 条操作日志", null, null,
                Map.of("logs", rows), false);
    }

    private ExecuteResult commandSubmitWorkflow(String objectCode, Long id, Map<String, Object> params) {
        if (id == null || id <= 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "缺少主键，无法提交审批");
        }
        if (!permissionService.check("DATA:" + objectCode, "write")) {
            throw new ApiException(ErrorCode.FORBIDDEN, "没有该对象的写入权限：" + objectCode);
        }
        // 状态机：只有允许提交的状态才能发起审批
        docStatus.guardSubmit(objectCode, id);
        String businessNo = params.get("businessNo") == null ? null
                : String.valueOf(params.get("businessNo"));
        String title = params.get("title") == null ? null : String.valueOf(params.get("title"));
        long instanceId = approvalService.submit(objectCode, id, businessNo, title);
        return new ExecuteResult("refresh", "已提交审批", null, null,
                Map.of("instanceId", instanceId), true);
    }

    // ---------------------------------------------------------------- 导出

    /**
     * 按元数据导出 CSV（UTF-8 BOM，Excel 直接打开不乱码）。
     * 列取该对象默认列表视图；没有视图则取全部可见字段。
     * 表头用中文标题，取值仍按字段名——两者必须分开，否则列名一改就全空。
     */
    public String exportCsv(String objectCode, String filters, String sort, int maxRows) {
        MetaQueryService.requireValidObjectCode(objectCode);
        if (!permissionService.check("DATA:" + objectCode, "read")) {
            throw new ApiException(ErrorCode.FORBIDDEN, "没有该对象的读取权限：" + objectCode);
        }
        List<String[]> columns = exportColumns(objectCode);
        var page = queryService.query(objectCode, filters, sort, 1, Math.min(Math.max(maxRows, 1), 5000));

        StringBuilder sb = new StringBuilder(64 * 1024);
        sb.append('\uFEFF');
        sb.append(String.join(",", columns.stream().map(c -> csvCell(c[1])).toList())).append("\r\n");
        for (Map<String, Object> row : page.rows()) {
            List<String> cells = new ArrayList<>(columns.size());
            for (String[] column : columns) {
                Object v = row.get(column[0]);
                cells.add(csvCell(v == null ? "" : String.valueOf(v)));
            }
            sb.append(String.join(",", cells)).append("\r\n");
        }
        log.info("action_export object={} rows={} cols={}", objectCode, page.rows().size(), columns.size());
        return sb.toString();
    }

    /** @return 每项 {字段名, 表头} */
    private List<String[]> exportColumns(String objectCode) {
        List<MetaDefinitionService.ColumnDto> viewColumns = definitionService.listViews(objectCode).stream()
                .filter(MetaDefinitionService.ListViewDto::isDefault)
                .findFirst()
                .map(MetaDefinitionService.ListViewDto::columns)
                .orElse(List.of());
        List<String[]> columns = viewColumns.stream()
                .filter(MetaDefinitionService.ColumnDto::visible)
                .map(c -> new String[]{c.fieldName(),
                        c.title() == null || c.title().isBlank() ? c.fieldName() : c.title()})
                .toList();
        if (!columns.isEmpty()) {
            return columns;
        }
        return definitionService.listFields(objectCode).stream()
                .filter(f -> !f.primaryKey())
                .filter(f -> !"IsDeleted".equalsIgnoreCase(f.fieldName()))
                .filter(f -> !"TenantId".equalsIgnoreCase(f.fieldName()))
                .map(f -> new String[]{f.fieldName(),
                        f.displayName() == null || f.displayName().isBlank() ? f.fieldName() : f.displayName()})
                .toList();
    }

    private static String csvCell(String raw) {
        String v = raw;
        if (v.indexOf('"') >= 0) {
            v = v.replace("\"", "\"\"");
        }
        if (v.indexOf(',') >= 0 || v.indexOf('"') >= 0 || v.indexOf('\n') >= 0 || v.indexOf('\r') >= 0) {
            return "\"" + v + "\"";
        }
        return v;
    }

    private static String urlEncode(String raw) {
        return java.net.URLEncoder.encode(raw, StandardCharsets.UTF_8);
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> single(String objectCode, long id) {
        var page = queryService.query(objectCode,
                "[{\"f\":\"Id\",\"op\":\"eq\",\"v\":\"" + id + "\"}]", null, 1, 1);
        return page.rows().isEmpty() ? Map.of() : (Map<String, Object>) page.rows().get(0);
    }

    /** 前端脚本动作的可选命令（与后端注册表保持一份名单）。 */
    public List<String> availableCommands() {
        return List.copyOf(commands.keySet());
    }
}

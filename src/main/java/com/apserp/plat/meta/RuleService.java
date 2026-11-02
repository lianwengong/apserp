package com.apserp.plat.meta;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.tenant.TenantContext;
import com.apserp.plat.meta.expr.ExprEvaluator;
import com.apserp.plat.meta.expr.ExprException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/**
 * 规则引擎：把 {@code plat.BizRule} + {@code plat.RuleBinding} 变成可执行的校验。
 *
 * <p>三段式语义：</p>
 * <ol>
 *   <li><b>解析</b>：保存规则时就用 {@link ExprEvaluator} 编译，语法错误当场拒绝（设计器即时反馈）。</li>
 *   <li><b>绑定</b>：规则通过 {@code RuleBinding} 挂到「数据对象 + 触发时机 + 字段」，一个对象可挂多条，按 Sort 执行。</li>
 *   <li><b>执行</b>：保存前（BEFORE_SAVE=1）失败即抛 {@link ApiException}；仅警告（Severity=1）不阻断，收集进结果。</li>
 * </ol>
 *
 * <p>触发时机编码：</p>
 * <pre>
 *   1 = BEFORE_SAVE 保存前校验（阻断）
 *   2 = AFTER_SAVE  保存后动作（不阻断，失败只记录）
 *   3 = BEFORE_DELETE 删除前校验（阻断）
 *   4 = ON_QUERY    查询时附加条件（预留给数据范围）
 * </pre>
 */
@Service
public class RuleService {

    public static final int BEFORE_SAVE = 1;
    public static final int AFTER_SAVE = 2;
    public static final int BEFORE_DELETE = 3;

    /** Severity：1 警告（不阻断）、2 错误（阻断）。 */
    public static final int WARN = 1;
    public static final int ERROR = 2;

    private final JdbcTemplate jdbc;

    private final MetaOverlay overlay;

    public RuleService(JdbcTemplate jdbc, MetaOverlay overlay) {
        this.jdbc = jdbc;
        this.overlay = overlay;
    }

    // ------------------------------------------------------------ DTO

    public record RuleDto(long id, String code, String name, int ruleType, String expression,
                          String errorMessage, int severity, boolean enabled, String remark,
                          int bindingCount) {
    }

    public record RuleBindingDto(long id, long ruleId, String ruleCode, long dataObjectId,
                                 String objectCode, String fieldName, int triggerEvent, int sort,
                                 boolean enabled) {
    }

    public record RuleViolation(String ruleCode, String message, int severity) {
    }

    public record RuleCheckResult(boolean passed, List<RuleViolation> violations, int evaluated) {
        public static RuleCheckResult ok(int n) {
            return new RuleCheckResult(true, List.of(), n);
        }
    }

    public record RuleSaveRequest(String code, String name, int ruleType, String expression,
                                  String errorMessage, int severity, boolean enabled, String remark) {
    }

    public record BindingSaveRequest(long ruleId, String objectCode, String fieldName,
                                     int triggerEvent, int sort, boolean enabled) {
    }

    // ------------------------------------------------------------ 规则 CRUD

    public List<RuleDto> listRules() {
        List<RuleDto> gray = overlay.rules();
        if (gray != null) {
            return gray;
        }
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                        SELECT r.Id, r.Code, r.Name, r.RuleType, r.Expression, r.ErrorMessage,
                               r.Severity, r.IsEnabled, r.Remark,
                               (SELECT COUNT(*) FROM plat.RuleBinding b WHERE b.RuleId = r.Id AND b.IsEnabled = 1) AS BindingCount
                        FROM plat.BizRule r
                        WHERE r.TenantId = ? AND r.IsDeleted = 0
                        ORDER BY r.Code
                        """,
                (rs, i) -> new RuleDto(rs.getLong("Id"), rs.getString("Code"), rs.getString("Name"),
                        rs.getInt("RuleType"), rs.getString("Expression"), rs.getString("ErrorMessage"),
                        rs.getInt("Severity"), rs.getBoolean("IsEnabled"), rs.getString("Remark"),
                        rs.getInt("BindingCount")),
                tenantId);
    }

    public RuleDto getRule(String code) {
        return listRules().stream().filter(r -> r.code().equals(code)).findFirst()
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "规则不存在：" + code));
    }

    public long saveRule(Long id, RuleSaveRequest req) {
        long tenantId = TenantContext.requireTenantId();
        if (req.code() == null || req.code().isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "规则编码不能为空");
        }
        String expression = req.expression() == null ? "" : req.expression().trim();
        try {
            ExprEvaluator.compile(expression);
        } catch (ExprException e) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "规则表达式有误：" + e.getMessage());
        }
        if (req.severity() != WARN && req.severity() != ERROR) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "severity 只能是 1（警告）或 2（错误）");
        }
        Long uid = TenantContext.userId();
        if (id == null) {
            Long dup = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM plat.BizRule WHERE TenantId = ? AND Code = ? AND IsDeleted = 0
                    """, Long.class, tenantId, req.code());
            if (dup != null && dup > 0) {
                throw new ApiException(ErrorCode.DUPLICATE_KEY, "规则编码已存在：" + req.code());
            }
            jdbc.update("""
                    INSERT plat.BizRule (TenantId, Code, Name, RuleType, Expression, ErrorMessage,
                                         Severity, IsEnabled, Remark, IsDeleted, CreatedBy, CreatedAt)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, sysutcdatetime())
                    """, tenantId, req.code(), req.name(), req.ruleType() <= 0 ? 1 : req.ruleType(),
                    expression, req.errorMessage(), req.severity(), req.enabled() ? 1 : 0,
                    req.remark(), uid);
            return queryId("plat.BizRule", tenantId, req.code());
        }
        int n = jdbc.update("""
                UPDATE plat.BizRule
                SET Name = ?, RuleType = ?, Expression = ?, ErrorMessage = ?, Severity = ?,
                    IsEnabled = ?, Remark = ?, ModifiedBy = ?, ModifiedAt = sysutcdatetime()
                WHERE Id = ? AND TenantId = ? AND IsDeleted = 0
                """, req.name(), req.ruleType() <= 0 ? 1 : req.ruleType(), expression,
                req.errorMessage(), req.severity(), req.enabled() ? 1 : 0, req.remark(),
                uid, id, tenantId);
        if (n == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND, "规则不存在或已删除：" + id);
        }
        return id;
    }

    public void deleteRule(String code) {
        long tenantId = TenantContext.requireTenantId();
        Long id = jdbc.query("SELECT Id FROM plat.BizRule WHERE TenantId = ? AND Code = ? AND IsDeleted = 0",
                (rs, i) -> rs.getLong(1), tenantId, code).stream().findFirst().orElse(null);
        if (id == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, "规则不存在：" + code);
        }
        jdbc.update("DELETE FROM plat.RuleBinding WHERE RuleId = ?", id);
        jdbc.update("""
                UPDATE plat.BizRule SET IsDeleted = 1, DeletedBy = ?, DeletedAt = sysutcdatetime()
                WHERE Id = ?
                """, TenantContext.userId(), id);
    }

    // ------------------------------------------------------------ 绑定

    public List<RuleBindingDto> listBindings(String objectCode) {
        List<RuleBindingDto> gray = overlay.bindings(objectCode);
        if (gray != null) {
            return gray;
        }
        long tenantId = TenantContext.requireTenantId();
        String sql = """
                SELECT b.Id, b.RuleId, r.Code AS RuleCode, b.DataObjectId, o.Code AS ObjectCode,
                       b.FieldName, b.TriggerEvent, b.Sort, b.IsEnabled
                FROM plat.RuleBinding b
                JOIN plat.BizRule r ON r.Id = b.RuleId
                JOIN plat.DataObject o ON o.Id = b.DataObjectId
                WHERE o.TenantId = ? AND o.IsDeleted = 0
                """;
        List<RuleBindingDto> rows;
        if (objectCode == null || objectCode.isBlank()) {
            rows = jdbc.query(sql + " ORDER BY o.Code, b.Sort",
                    (rs, i) -> new RuleBindingDto(rs.getLong("Id"), rs.getLong("RuleId"),
                            rs.getString("RuleCode"), rs.getLong("DataObjectId"),
                            rs.getString("ObjectCode"), rs.getString("FieldName"),
                            rs.getInt("TriggerEvent"), rs.getInt("Sort"), rs.getBoolean("IsEnabled")),
                    tenantId);
        } else {
            rows = jdbc.query(sql + " AND o.Code = ? ORDER BY b.Sort",
                    (rs, i) -> new RuleBindingDto(rs.getLong("Id"), rs.getLong("RuleId"),
                            rs.getString("RuleCode"), rs.getLong("DataObjectId"),
                            rs.getString("ObjectCode"), rs.getString("FieldName"),
                            rs.getInt("TriggerEvent"), rs.getInt("Sort"), rs.getBoolean("IsEnabled")),
                    tenantId, objectCode);
        }
        return rows;
    }

    public long bind(BindingSaveRequest req) {
        long tenantId = TenantContext.requireTenantId();
        Long objectId = jdbc.query("SELECT Id FROM plat.DataObject WHERE TenantId = ? AND Code = ? AND IsDeleted = 0",
                (rs, i) -> rs.getLong(1), tenantId, req.objectCode()).stream().findFirst().orElse(null);
        if (objectId == null) {
            throw new ApiException(ErrorCode.META_OBJECT_NOT_FOUND, "数据对象不存在：" + req.objectCode());
        }
        Long ruleId = jdbc.query("SELECT Id FROM plat.BizRule WHERE TenantId = ? AND Id = ? AND IsDeleted = 0",
                (rs, i) -> rs.getLong(1), tenantId, req.ruleId()).stream().findFirst().orElse(null);
        if (ruleId == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, "规则不存在：" + req.ruleId());
        }
        jdbc.update("""
                INSERT plat.RuleBinding (RuleId, DataObjectId, FieldName, TriggerEvent, Sort, IsEnabled)
                VALUES (?, ?, ?, ?, ?, ?)
                """, ruleId, objectId, req.fieldName(), req.triggerEvent() <= 0 ? BEFORE_SAVE : req.triggerEvent(),
                req.sort(), req.enabled() ? 1 : 0);
        return jdbc.queryForObject("SELECT MAX(Id) FROM plat.RuleBinding", Long.class);
    }

    public void unbind(long bindingId) {
        long tenantId = TenantContext.requireTenantId();
        int n = jdbc.update("""
                DELETE b FROM plat.RuleBinding b
                JOIN plat.DataObject o ON o.Id = b.DataObjectId
                WHERE b.Id = ? AND o.TenantId = ?
                """, bindingId, tenantId);
        if (n == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND, "绑定不存在：" + bindingId);
        }
    }

    // ------------------------------------------------------------ 执行

    /** 取某对象在指定触发时机下的启用规则（按 Sort）。 */
    public List<BoundRule> rulesFor(String objectCode, int triggerEvent) {
        List<RuleDto> grayRules = overlay.rules();
        List<RuleBindingDto> grayBindings = overlay.bindings(objectCode);
        if (grayRules != null && grayBindings != null) {
            return boundFromOverlay(grayRules, grayBindings, triggerEvent);
        }
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                        SELECT r.Code, r.Name, r.Expression, r.ErrorMessage, r.Severity, b.FieldName
                        FROM plat.RuleBinding b
                        JOIN plat.BizRule r ON r.Id = b.RuleId
                        JOIN plat.DataObject o ON o.Id = b.DataObjectId
                        WHERE o.TenantId = ? AND o.Code = ? AND b.TriggerEvent = ?
                          AND b.IsEnabled = 1 AND r.IsEnabled = 1 AND r.IsDeleted = 0
                        ORDER BY b.Sort, r.Code
                        """,
                (rs, i) -> new BoundRule(rs.getString("Code"), rs.getString("Name"),
                        rs.getString("Expression"), rs.getString("ErrorMessage"),
                        rs.getInt("Severity"), rs.getString("FieldName")),
                tenantId, objectCode, triggerEvent);
    }

    public record BoundRule(String code, String name, String expression, String message,
                            int severity, String fieldName) {
    }

    /**
     * 执行保存前校验。任一条 Severity=2 的规则不通过即抛异常（阻断保存）；
     * Severity=1 只收集。返回通过时的告警列表。
     */
    public List<RuleViolation> checkBeforeSave(String objectCode, Map<String, Object> data) {
        List<RuleViolation> warnings = new ArrayList<>();
        List<BoundRule> rules = rulesFor(objectCode, BEFORE_SAVE);
        for (BoundRule r : rules) {
            boolean pass;
            try {
                pass = ExprEvaluator.test(r.expression(), data);
            } catch (ExprException e) {
                throw new ApiException(ErrorCode.BAD_REQUEST,
                        "规则 [" + r.code() + "] 执行失败：" + e.getMessage());
            }
            if (!pass) {
                RuleViolation v = new RuleViolation(r.code(), r.message(), r.severity());
                if (r.severity() >= ERROR) {
                    throw new ApiException(ErrorCode.BAD_REQUEST, r.message());
                }
                warnings.add(v);
            }
        }
        return warnings;
    }

    /** 删除前校验。 */
    /** 灰度快照里的绑定 → 运行时规则列表（与实时库同构，便于保存链路直接复用）。 */
    private List<BoundRule> boundFromOverlay(List<RuleDto> rules, List<RuleBindingDto> bindings,
                                             int triggerEvent) {
        Map<String, RuleDto> byCode = new java.util.LinkedHashMap<>();
        for (RuleDto r : rules) {
            byCode.put(r.code(), r);
        }
        List<BoundRule> out = new java.util.ArrayList<>();
        bindings.stream()
                .filter(b -> b.triggerEvent() == triggerEvent && b.enabled())
                .sorted(java.util.Comparator.comparingInt(RuleBindingDto::sort))
                .forEach(b -> {
                    RuleDto r = byCode.get(b.ruleCode());
                    if (r != null && r.enabled()) {
                        out.add(new BoundRule(r.code(), r.name(), r.expression(), r.errorMessage(),
                                r.severity(), b.fieldName()));
                    }
                });
        return out;
    }

    public void checkBeforeDelete(String objectCode, Map<String, Object> data) {
        for (BoundRule r : rulesFor(objectCode, BEFORE_DELETE)) {
            boolean pass;
            try {
                pass = ExprEvaluator.test(r.expression(), data);
            } catch (ExprException e) {
                throw new ApiException(ErrorCode.BAD_REQUEST,
                        "规则 [" + r.code() + "] 执行失败：" + e.getMessage());
            }
            if (!pass && r.severity() >= ERROR) {
                throw new ApiException(ErrorCode.BAD_REQUEST, r.message());
            }
        }
    }

    /**
     * 测试台：用一份示例数据试跑某对象在指定时机下的规则，返回每条规则的结果。
     * 设计器用它做“即时验证”，不落库、不影响业务。
     */
    public List<Map<String, Object>> test(String objectCode, int triggerEvent, Map<String, Object> data) {
        Map<String, Object> ctx = data == null ? new LinkedHashMap<>() : new LinkedHashMap<>(data);
        List<Map<String, Object>> out = new ArrayList<>();
        for (BoundRule r : rulesFor(objectCode, triggerEvent)) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("ruleCode", r.code());
            row.put("name", r.name());
            row.put("expression", r.expression());
            row.put("severity", r.severity());
            try {
                Object value = ExprEvaluator.eval(r.expression(), ctx);
                boolean pass = ExprEvaluator.truthy(value);
                row.put("result", value);
                row.put("passed", pass);
                row.put("message", pass ? "" : r.message());
                row.put("error", null);
            } catch (ExprException e) {
                row.put("result", null);
                row.put("passed", false);
                row.put("message", r.message());
                row.put("error", e.getMessage());
            }
            out.add(row);
        }
        return out;
    }

    /** 校验表达式语法（设计器边输边校验）。 */
    public Map<String, Object> validateExpression(String expression) {
        Map<String, Object> out = new LinkedHashMap<>();
        try {
            ExprEvaluator.Compiled c = ExprEvaluator.compile(expression);
            out.put("valid", true);
            out.put("error", null);
            out.put("sample", c.eval(Map.of("ctx", Map.of())));
        } catch (ExprException e) {
            out.put("valid", false);
            out.put("error", e.getMessage());
        }
        return out;
    }

    private long queryId(String table, long tenantId, String code) {
        Long id = jdbc.query("SELECT Id FROM " + table + " WHERE TenantId = ? AND Code = ?",
                (rs, i) -> rs.getLong(1), tenantId, code).stream().findFirst().orElse(null);
        return id == null ? 0L : id;
    }
}

package com.apserp.plat.meta;

import com.apserp.common.tenant.TenantContext;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/**
 * 灰度元数据覆盖层：让「灰度版本」真正对指定用户生效。
 *
 * <p>之前灰度只是标记，所有人读的还是实时表。现在：发布时若指定灰度名单（Status=2），
 * 名单里的用户读元数据（对象/字段/视图/表单/规则/按钮）时走<b>该版本快照</b>，
 * 其他用户继续读实时配置。快照解析结果按「租户+版本」缓存，发布/激活时失效。</p>
 *
 * <p>边界（必须说清楚，否则会误判）：灰度<b>只影响读</b>——列表/表单/规则校验/按钮下发。
 * 物理表结构、保存过程 {@code usp_Meta_Save} 用的是实时元数据；因此灰度期间不要加/删字段，
 * 只改展示与规则。平台管理员永远读实时配置（否则发布者自己看不到真实状态）。</p>
 */
@Service
public class MetaOverlay {

    private static final Logger log = LoggerFactory.getLogger(MetaOverlay.class);

    private final JdbcTemplate jdbc;
    private final MetaCache cache;
    private final ObjectMapper json = new ObjectMapper();

    public MetaOverlay(JdbcTemplate jdbc, MetaCache cache) {
        this.jdbc = jdbc;
        this.cache = cache;
    }

    /** 解析后的快照：只保留覆盖层用得到的几段。 */
    public record Snapshot(int version,
                           List<Map<String, Object>> objects,
                           List<Map<String, Object>> fields,
                           List<Map<String, Object>> views,
                           List<Map<String, Object>> columns,
                           List<Map<String, Object>> forms,
                           List<Map<String, Object>> formFields,
                           List<Map<String, Object>> buttons,
                           List<Map<String, Object>> actions,
                           List<Map<String, Object>> rules,
                           List<Map<String, Object>> bindings) {
    }

    /**
     * 当前用户命中的灰度快照；<b>没有返回 null</b>（调用方按实时库处理）。
     *
     * <p>平台管理员直通实时库：发布者要能看到「真实配置」，否则连自己都分不清哪份在生效。</p>
     */
    public Snapshot current() {
        if (TenantContext.isPlatformAdmin()) {
            return null;
        }
        Long tenantId = TenantContext.tenantId();
        Long userId = TenantContext.userId();
        if (tenantId == null || userId == null) {
            return null;
        }
        Integer version = grayVersionOf(tenantId, userId);
        if (version == null) {
            return null;
        }
        return snapshotOf(tenantId, version);
    }

    private Integer grayVersionOf(long tenantId, long userId) {
        return cache.get("grayver", "u" + userId, () -> jdbc.query("""
                        SELECT TOP 1 v.Version
                        FROM plat.MetaVersion v
                        JOIN plat.MetaVersionGray g ON g.MetaVersionId = v.Id
                        WHERE v.TenantId = ? AND v.Scope = 'meta' AND v.Status = 2 AND g.UserId = ?
                        ORDER BY v.Version DESC
                        """, rs -> rs.next() ? rs.getInt(1) : null, tenantId, userId));
    }

    @SuppressWarnings("unchecked")
    private Snapshot snapshotOf(long tenantId, int version) {
        return cache.get("graysnap", "v" + version, () -> {
            List<String> payloads = jdbc.queryForList("""
                    SELECT Payload FROM plat.MetaVersion
                    WHERE TenantId = ? AND Scope = 'meta' AND Version = ?
                    """, String.class, tenantId, version);
            if (payloads.isEmpty() || payloads.get(0) == null) {
                return null;
            }
            try {
                Map<String, Object> root = json.readValue(payloads.get(0), Map.class);
                Snapshot s = new Snapshot(version,
                        rows(root, "objects"), rows(root, "fields"), rows(root, "listViews"),
                        rows(root, "listViewColumns"), rows(root, "formLayouts"), rows(root, "formFields"),
                        rows(root, "buttons"), rows(root, "buttonActions"),
                        rows(root, "rules"), rows(root, "ruleBindings"));
                log.info("gray_snapshot_loaded tenant={} version={} objects={} fields={}",
                        tenantId, version, s.objects().size(), s.fields().size());
                return s;
            } catch (Exception e) {
                // 快照坏了不能拖垮整页：降级为实时库，并留下明确日志
                log.warn("gray_snapshot_broken tenant={} version={} err={}", tenantId, version, e.getMessage());
                return null;
            }
        });
    }

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> rows(Map<String, Object> root, String key) {
        Object value = root.get(key);
        if (!(value instanceof List<?> list)) {
            return List.of();
        }
        List<Map<String, Object>> out = new ArrayList<>(list.size());
        for (Object o : list) {
            if (o instanceof Map<?, ?> m) {
                out.add((Map<String, Object>) m);
            }
        }
        return out;
    }

    // ---------------------------------------------------------------- 覆盖查询
    // 约定：返回 null = 「不用覆盖」，调用方走实时库；返回空列表 = 该版本里确实没有。

    public List<MetaDefinitionService.DataObjectDto> objects() {
        Snapshot s = current();
        if (s == null) {
            return null;
        }
        List<MetaDefinitionService.DataObjectDto> out = new ArrayList<>(s.objects().size());
        for (Map<String, Object> o : s.objects()) {
            out.add(new MetaDefinitionService.DataObjectDto(
                    num(o.get("Id")), str(o.get("Code")), str(o.get("Name")), (int) num(o.get("ObjectType")),
                    str(o.get("SchemaName")), str(o.get("ObjectName")), str(o.get("PrimaryKey")),
                    str(o.get("DocNoField")), str(o.get("TenantField")), str(o.get("DefaultOrder")),
                    bool(o.get("IsReadOnly"))));
        }
        return out;
    }

    public List<MetaDefinitionService.FieldDto> fields(String objectCode) {
        Snapshot s = current();
        if (s == null) {
            return null;
        }
        List<MetaDefinitionService.FieldDto> out = new ArrayList<>();
        for (Map<String, Object> f : s.fields()) {
            if (!objectCode.equals(str(f.get("ObjectCode")))) {
                continue;
            }
            out.add(new MetaDefinitionService.FieldDto(str(f.get("FieldName")), str(f.get("DisplayName")),
                    str(f.get("DataType")), f.get("MaxLength") == null ? null : (int) num(f.get("MaxLength")),
                    bool(f.get("IsNullable")), bool(f.get("IsPrimaryKey")), bool(f.get("IsIdentity")),
                    bool(f.get("IsRequired")), (int) num(f.get("LookupType")), str(f.get("LookupSource")),
                    str(f.get("LookupDisplayField")), str(f.get("Format")), (int) num(f.get("Sort"))));
        }
        return out;
    }

    public List<MetaDefinitionService.ListViewDto> views(String objectCode) {
        Snapshot s = current();
        if (s == null) {
            return null;
        }
        List<MetaDefinitionService.ListViewDto> out = new ArrayList<>();
        for (Map<String, Object> v : s.views()) {
            if (!objectCode.equals(str(v.get("ObjectCode")))) {
                continue;
            }
            String viewCode = str(v.get("Code"));
            List<MetaDefinitionService.ColumnDto> columns = new ArrayList<>();
            for (Map<String, Object> c : s.columns()) {
                if (!viewCode.equals(str(c.get("ViewCode")))) {
                    continue;
                }
                columns.add(new MetaDefinitionService.ColumnDto(str(c.get("FieldName")), str(c.get("Title")),
                        c.get("Width") == null ? null : (int) num(c.get("Width")), alignOf(c.get("Align")),
                        bool(c.get("IsSum")), bool(c.get("IsVisible")), (int) num(c.get("Sort"))));
            }
            out.add(new MetaDefinitionService.ListViewDto(num(v.get("Id")), viewCode, str(v.get("Name")),
                    (int) num(v.get("PageSize")), str(v.get("DefaultSort")), bool(v.get("IsDefault")), columns));
        }
        return out;
    }

    /** 快照里的 Align 是 smallint，运行时 DTO 用字符串（left/center/right），这里统一换算。 */
    private static String alignOf(Object raw) {
        if (raw == null) {
            return null;
        }
        if (raw instanceof Number n) {
            return switch (n.intValue()) {
                case 2 -> "center";
                case 3 -> "right";
                default -> "left";
            };
        }
        return str(raw);
    }

    public List<MetaDefinitionService.FormLayoutDto> forms(String objectCode) {
        Snapshot s = current();
        if (s == null) {
            return null;
        }
        List<MetaDefinitionService.FormLayoutDto> out = new ArrayList<>();
        for (Map<String, Object> f : s.forms()) {
            if (!objectCode.equals(str(f.get("ObjectCode")))) {
                continue;
            }
            String layoutCode = str(f.get("Code"));
            List<MetaDefinitionService.FormFieldDto> fields = new ArrayList<>();
            for (Map<String, Object> ff : s.formFields()) {
                if (!layoutCode.equals(str(ff.get("LayoutCode")))) {
                    continue;
                }
                fields.add(new MetaDefinitionService.FormFieldDto(str(ff.get("FieldName")),
                        str(ff.get("Label")), String.valueOf(num(ff.get("ControlType"))),
                        (int) num(ff.get("Row")), (int) num(ff.get("Col")), (int) num(ff.get("Span")),
                        bool(ff.get("IsReadOnly")), bool(ff.get("IsRequired")), bool(ff.get("IsHidden")),
                        str(ff.get("GroupName")), (int) num(ff.get("Sort"))));
            }
            out.add(new MetaDefinitionService.FormLayoutDto(num(f.get("Id")), layoutCode, str(f.get("Name")),
                    (int) num(f.get("Mode")), (int) num(f.get("Columns")), bool(f.get("IsDefault")), fields));
        }
        return out;
    }

    public List<RuleService.RuleDto> rules() {
        Snapshot s = current();
        if (s == null) {
            return null;
        }
        Map<String, Integer> bindCount = new HashMap<>();
        for (Map<String, Object> b : s.bindings()) {
            bindCount.merge(str(b.get("RuleCode")), 1, Integer::sum);
        }
        List<RuleService.RuleDto> out = new ArrayList<>();
        int seq = 0;
        for (Map<String, Object> r : s.rules()) {
            String code = str(r.get("Code"));
            // 覆盖层只读：id 用负数，避免被误当成实时库里的规则去改
            out.add(new RuleService.RuleDto(-(++seq), code, str(r.get("Name")),
                    (int) num(r.get("RuleType")), str(r.get("Expression")), str(r.get("ErrorMessage")),
                    (int) num(r.get("Severity")), bool(r.get("IsEnabled")), str(r.get("Remark")),
                    bindCount.getOrDefault(code, 0)));
        }
        return out;
    }

    public List<RuleService.RuleBindingDto> bindings(String objectCode) {
        Snapshot s = current();
        if (s == null) {
            return null;
        }
        Map<String, Long> ruleIds = new LinkedHashMap<>();
        int seq = 0;
        for (Map<String, Object> r : s.rules()) {
            ruleIds.put(str(r.get("Code")), (long) -(++seq));
        }
        List<RuleService.RuleBindingDto> out = new ArrayList<>();
        int bseq = 0;
        for (Map<String, Object> b : s.bindings()) {
            if (objectCode != null && !objectCode.equals(str(b.get("ObjectCode")))) {
                continue;
            }
            String ruleCode = str(b.get("RuleCode"));
            out.add(new RuleService.RuleBindingDto(-(++bseq), ruleIds.getOrDefault(ruleCode, 0L), ruleCode, 0L,
                    str(b.get("ObjectCode")), str(b.get("FieldName")), (int) num(b.get("TriggerEvent")),
                    (int) num(b.get("Sort")), bool(b.get("IsEnabled"))));
        }
        return out;
    }

    public List<ActionService.ButtonDto> buttons(String objectCode) {
        Snapshot s = current();
        if (s == null) {
            return null;
        }
        List<ActionService.ButtonDto> out = new ArrayList<>();
        for (Map<String, Object> head : s.buttons()) {
            String code = str(head.get("Code"));
            List<ActionService.ActionDto> actions = new ArrayList<>();
            int aseq = 0;
            for (Map<String, Object> a : s.actions()) {
                if (!code.equals(str(a.get("ButtonCode")))) {
                    continue;
                }
                aseq++;
                actions.add(new ActionService.ActionDto(aseq, (int) num(a.get("Seq")),
                        (int) num(a.get("ActionType")), actionTypeName((int) num(a.get("ActionType"))),
                        str(a.get("BuiltinCode")), str(a.get("Target")), str(a.get("Command")),
                        str(a.get("ParamJson")), str(a.get("ConfirmText")), str(a.get("SuccessMessage")),
                        bool(a.get("NeedWorkflow")), bool(a.get("IsEnabled"))));
            }
            out.add(new ActionService.ButtonDto(num(head.get("Id")), code, str(head.get("Name")),
                    str(head.get("Text")), str(head.get("Icon")), (int) num(head.get("ButtonType")),
                    (int) num(head.get("Sort")), str(head.get("Style")), str(head.get("VisibleExpr")),
                    str(head.get("IsEnabledExpr")), null, actions));
        }
        return out;
    }

    private static String actionTypeName(int type) {
        return switch (type) {
            case 1 -> "内置";
            case 2 -> "导航";
            case 3 -> "命令";
            case 4 -> "脚本";
            default -> "未知";
        };
    }

    // ---------------------------------------------------------------- 取值工具

    private static String str(Object raw) {
        return raw == null ? null : String.valueOf(raw);
    }

    private static boolean bool(Object raw) {
        if (raw instanceof Boolean b) {
            return b;
        }
        if (raw instanceof Number n) {
            return n.intValue() != 0;
        }
        return "true".equalsIgnoreCase(String.valueOf(raw));
    }

    private static long num(Object raw) {
        if (raw instanceof Number n) {
            return n.longValue();
        }
        if (raw == null) {
            return 0;
        }
        try {
            return Long.parseLong(String.valueOf(raw));
        } catch (NumberFormatException e) {
            return 0;
        }
    }
}

package com.apserp.plat.meta;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.tenant.TenantContext;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 元数据发布与回滚。
 *
 * <p>把「当前租户的全部可配置元数据」打成一个快照存进 {@code plat.MetaVersion}，
 * 用于三件事：</p>
 * <ol>
 *   <li><b>可追溯</b>：每次发布记录发布人、时间、内容哈希、变更说明；</li>
 *   <li><b>可回滚</b>：任何一次发布都能整体还原（规则/按钮/审批/页面/权限/数据对象定义）；</li>
 *   <li><b>可比对</b>：两个版本之间做集合差，得到“新增/删除/修改”清单（设计器发布前预览用）。</li>
 * </ol>
 *
 * <p>快照范围（{@code Scope='meta'}）：</p>
 * <pre>
 *   objects + fields      数据对象与字段
 *   listViews + columns   列表视图
 *   formLayouts + fields  表单布局
 *   buttons + actions     按钮与动作
 *   rules + bindings      业务规则
 *   workflows + nodes + approvers 审批流定义
 *   pages + blocks        页面
 *   rolePermissions       角色权限
 *   fieldPermissions      字段权限
 * </pre>
 *
 * <p>回滚策略：整体替换（先删后插），在一个事务内完成；业务数据不受影响。
 * 回滚本身也记一条新版本（{@code RollbackOf} 指向被回滚的版本）。</p>
 */
@Service
public class MetaPublishService {

    private static final String SCOPE = "meta";

    private final JdbcTemplate jdbc;
    private final ObjectMapper json = new ObjectMapper();

    public MetaPublishService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    // ------------------------------------------------------------ DTO

    public record VersionDto(long id, int version, String scope, String contentHash, Long publishedBy,
                             String publishedByName, java.time.LocalDateTime publishedAt,
                             Integer rollbackOf, int status, String remark, int sizeBytes) {
    }

    public record PublishResult(int version, String contentHash, int sizeBytes) {
    }

    public record DiffItem(String kind, String action, String code) {
    }

    public record DiffResult(Integer fromVersion, Integer toVersion, List<DiffItem> items) {
    }

    // ------------------------------------------------------------ 发布

    @Transactional
    public PublishResult publish(String remark) {
        long tenantId = TenantContext.requireTenantId();
        Map<String, Object> snapshot = snapshot(tenantId);
        String payload = toJson(snapshot);
        String hash = md5(payload);
        int version = jdbc.queryForObject("""
                SELECT ISNULL(MAX(Version), 0) + 1 FROM plat.MetaVersion WHERE TenantId = ? AND Scope = ?
                """, Integer.class, tenantId, SCOPE);
        jdbc.update("""
                INSERT plat.MetaVersion (TenantId, Version, Scope, ContentHash, Payload, PublishedBy,
                                         PublishedAt, Status, Remark)
                VALUES (?, ?, ?, ?, ?, ?, sysutcdatetime(), 1, ?)
                """, tenantId, version, SCOPE, hash, payload, TenantContext.userId(), remark);
        return new PublishResult(version, hash, payload.getBytes(StandardCharsets.UTF_8).length);
    }

    public List<VersionDto> versions() {
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                        SELECT v.Id, v.Version, v.Scope, v.ContentHash, v.PublishedBy, u.DisplayName AS Publisher,
                               v.PublishedAt, v.RollbackOf, v.Status, v.Remark, LEN(v.Payload) AS SizeBytes
                        FROM plat.MetaVersion v
                        LEFT JOIN plat.[User] u ON u.Id = v.PublishedBy
                        WHERE v.TenantId = ? AND v.Scope = ?
                        ORDER BY v.Version DESC
                        """,
                (rs, i) -> new VersionDto(rs.getLong("Id"), rs.getInt("Version"), rs.getString("Scope"),
                        rs.getString("ContentHash"), (Long) rs.getObject("PublishedBy"),
                        rs.getString("Publisher"),
                        rs.getTimestamp("PublishedAt") == null ? null
                                : rs.getTimestamp("PublishedAt").toLocalDateTime(),
                        (Integer) rs.getObject("RollbackOf"), rs.getInt("Status"),
                        rs.getString("Remark"), rs.getInt("SizeBytes")),
                tenantId, SCOPE);
    }

    /** 取指定版本的完整快照（给前端做“查看这个版本发了什么”）。 */
    public Map<String, Object> payload(int version) {
        long tenantId = TenantContext.requireTenantId();
        String payload = jdbc.query("""
                SELECT Payload FROM plat.MetaVersion WHERE TenantId = ? AND Scope = ? AND Version = ?
                """, rs -> rs.next() ? rs.getString(1) : null, tenantId, SCOPE, version);
        if (payload == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, "版本不存在：" + version);
        }
        try {
            return json.readValue(payload, new TypeReference<Map<String, Object>>() {
            });
        } catch (Exception e) {
            throw new ApiException(ErrorCode.INTERNAL, "快照解析失败：" + e.getMessage());
        }
    }

    // ------------------------------------------------------------ 回滚

    @Transactional
    public PublishResult rollback(int version, String remark) {
        long tenantId = TenantContext.requireTenantId();
        Map<String, Object> snapshot = payload(version);
        apply(tenantId, snapshot);
        Map<String, Object> after = snapshot(tenantId);
        String payload = toJson(after);
        String hash = md5(payload);
        int newVersion = jdbc.queryForObject("""
                SELECT ISNULL(MAX(Version), 0) + 1 FROM plat.MetaVersion WHERE TenantId = ? AND Scope = ?
                """, Integer.class, tenantId, SCOPE);
        jdbc.update("""
                INSERT plat.MetaVersion (TenantId, Version, Scope, ContentHash, Payload, PublishedBy,
                                         PublishedAt, RollbackOf, Status, Remark)
                VALUES (?, ?, ?, ?, ?, ?, sysutcdatetime(), ?, 1, ?)
                """, tenantId, newVersion, SCOPE, hash, payload, TenantContext.userId(), version,
                remark == null ? ("回滚到 v" + version) : remark);
        return new PublishResult(newVersion, hash, payload.getBytes(StandardCharsets.UTF_8).length);
    }

    // ------------------------------------------------------------ 比对

    /** 比对“已发布的最新版本”与“当前库中元数据”，发布前预览用。 */
    public DiffResult diffAgainstCurrent(int baseVersion) {
        long tenantId = TenantContext.requireTenantId();
        Map<String, Object> base = payload(baseVersion);
        Map<String, Object> now = snapshot(tenantId);
        return diff(base, now, baseVersion, null);
    }

    /** 比对两个历史版本。 */
    public DiffResult diffVersions(int from, int to) {
        Map<String, Object> a = payload(from);
        Map<String, Object> b = payload(to);
        return diff(a, b, from, to);
    }

    @SuppressWarnings("unchecked")
    private DiffResult diff(Map<String, Object> a, Map<String, Object> b, Integer from, Integer to) {
        List<DiffItem> items = new ArrayList<>();
        for (String kind : List.of("objects", "listViews", "formLayouts", "buttons", "rules",
                "workflows", "pages", "rolePermissions", "fieldPermissions")) {
            Map<String, String> left = flatten((List<Map<String, Object>>) a.getOrDefault(kind, List.of()));
            Map<String, String> right = flatten((List<Map<String, Object>>) b.getOrDefault(kind, List.of()));
            for (String code : right.keySet()) {
                if (!left.containsKey(code)) {
                    items.add(new DiffItem(kind, "added", code));
                } else if (!left.get(code).equals(right.get(code))) {
                    items.add(new DiffItem(kind, "changed", code));
                }
            }
            for (String code : left.keySet()) {
                if (!right.containsKey(code)) {
                    items.add(new DiffItem(kind, "removed", code));
                }
            }
        }
        return new DiffResult(from, to, items);
    }

    private Map<String, String> flatten(List<Map<String, Object>> rows) {
        Map<String, String> out = new LinkedHashMap<>();
        for (Map<String, Object> r : rows) {
            String key = String.valueOf(r.getOrDefault("code",
                    r.getOrDefault("resourceKey", r.getOrDefault("id", "?"))));
            out.put(key, toJson(r));
        }
        return out;
    }

    // ------------------------------------------------------------ 快照/还原

    private Map<String, Object> snapshot(long tenantId) {
        Map<String, Object> s = new LinkedHashMap<>();
        String t = "TenantId = " + tenantId;

        List<Map<String, Object>> objects = jdbc.queryForList(
                "SELECT Id, Code, Name, ObjectType, SchemaName, ObjectName, PrimaryKey, DocNoField, "
                        + "OrgField, TenantField, StatusField, DefaultOrder, IsReadOnly, IsEnabled "
                        + "FROM plat.DataObject WHERE " + t + " AND IsDeleted = 0 ORDER BY Code");
        Map<Long, Long> objectIdMap = new LinkedHashMap<>();
        for (Map<String, Object> o : objects) {
            objectIdMap.put(((Number) o.get("Id")).longValue(), ((Number) o.get("Id")).longValue());
        }
        List<Map<String, Object>> fields = jdbc.queryForList(
                "SELECT o.Code AS ObjectCode, f.FieldName, f.DisplayName, f.DataType, f.MaxLength, f.Precision, "
                        + "f.Scale, f.IsNullable, f.IsPrimaryKey, f.IsIdentity, f.IsRequired, f.DefaultValue, "
                        + "f.LookupType, f.LookupSource, f.LookupValueField, f.LookupDisplayField, f.LookupFilter, "
                        + "f.Format, f.Unit, f.IsVisible, f.Sort, f.IsComputed, f.ComputeExpr "
                        + "FROM plat.DataObjectField f JOIN plat.DataObject o ON o.Id = f.DataObjectId "
                        + "WHERE o." + t + " AND o.IsDeleted = 0 ORDER BY o.Code, f.Sort");
        List<Map<String, Object>> views = jdbc.queryForList(
                "SELECT v.Id, o.Code AS ObjectCode, v.Code, v.Name, v.PageSize, v.DefaultSort, v.IsDefault "
                        + "FROM plat.ListView v JOIN plat.DataObject o ON o.Id = v.DataObjectId "
                        + "WHERE v." + t + " AND v.IsDeleted = 0 ORDER BY o.Code, v.Code");
        List<Map<String, Object>> columns = jdbc.queryForList(
                "SELECT v.Code AS ViewCode, o.Code AS ObjectCode, c.FieldName, c.Title, c.Width, c.Align, "
                        + "c.IsSum, c.IsVisible, c.Sort FROM plat.ListViewColumn c "
                        + "JOIN plat.ListView v ON v.Id = c.ListViewId "
                        + "JOIN plat.DataObject o ON o.Id = v.DataObjectId WHERE v." + t + " ORDER BY v.Code, c.Sort");
        List<Map<String, Object>> forms = jdbc.queryForList(
                "SELECT f.Id, o.Code AS ObjectCode, f.Code, f.Name, f.Mode, f.Columns, f.IsDefault "
                        + "FROM plat.FormLayout f JOIN plat.DataObject o ON o.Id = f.DataObjectId "
                        + "WHERE f." + t + " AND f.IsDeleted = 0 ORDER BY o.Code, f.Code");
        List<Map<String, Object>> formFields = jdbc.queryForList(
                "SELECT f.Code AS LayoutCode, o.Code AS ObjectCode, ff.FieldName, ff.Label, ff.ControlType, "
                        + "ff.Row, ff.Col, ff.Span, ff.IsReadOnly, ff.IsRequired, ff.IsHidden, ff.DefaultExpr, "
                        + "ff.Placeholder, ff.HelpText, ff.GroupName, ff.Sort, ff.AccessExpr "
                        + "FROM plat.FormField ff JOIN plat.FormLayout f ON f.Id = ff.FormLayoutId "
                        + "JOIN plat.DataObject o ON o.Id = f.DataObjectId WHERE f." + t + " ORDER BY f.Code, ff.Sort");
        List<Map<String, Object>> buttons = jdbc.queryForList(
                "SELECT Id, Code, Name, Text, Icon, ButtonType, FunctionId, Sort, IsVisible, VisibleExpr, "
                        + "IsEnabledExpr, Style, Remark FROM plat.Button WHERE " + t + " AND IsDeleted = 0 ORDER BY Code");
        List<Map<String, Object>> actions = jdbc.queryForList(
                "SELECT b.Code AS ButtonCode, a.Seq, a.ActionType, a.BuiltinCode, a.Target, a.Command, "
                        + "a.ParamJson, a.ConfirmText, a.SuccessMessage, a.NeedWorkflow, a.IsEnabled "
                        + "FROM plat.ButtonAction a JOIN plat.Button b ON b.Id = a.ButtonId WHERE b." + t
                        + " ORDER BY b.Code, a.Seq");
        List<Map<String, Object>> rules = jdbc.queryForList(
                "SELECT Code, Name, RuleType, Expression, ErrorMessage, Severity, IsEnabled, Remark "
                        + "FROM plat.BizRule WHERE " + t + " AND IsDeleted = 0 ORDER BY Code");
        List<Map<String, Object>> bindings = jdbc.queryForList(
                "SELECT r.Code AS RuleCode, o.Code AS ObjectCode, b.FieldName, b.TriggerEvent, b.Sort, b.IsEnabled "
                        + "FROM plat.RuleBinding b JOIN plat.BizRule r ON r.Id = b.RuleId "
                        + "JOIN plat.DataObject o ON o.Id = b.DataObjectId WHERE o." + t
                        + " ORDER BY o.Code, b.Sort");
        List<Map<String, Object>> workflows = jdbc.queryForList(
                "SELECT Id, Code, Name, DataObjectId, Version, ConditionExpr, Status, IsDefault, Remark "
                        + "FROM plat.WorkflowDef WHERE " + t + " AND IsDeleted = 0 ORDER BY Code, Version");
        List<Map<String, Object>> nodes = jdbc.queryForList(
                "SELECT d.Code AS DefCode, d.Version AS DefVersion, n.Code, n.Name, n.NodeType, n.Sort, "
                        + "n.ApproveMode, n.RejectMode, n.ConditionExpr, n.AllowAddSign, n.AllowDelegate, "
                        + "n.NextNodeCode, n.RejectNodeCode FROM plat.WorkflowNode n "
                        + "JOIN plat.WorkflowDef d ON d.Id = n.WorkflowDefId WHERE d." + t + " ORDER BY d.Code, n.Sort");
        List<Map<String, Object>> approvers = jdbc.queryForList(
                "SELECT d.Code AS DefCode, d.Version AS DefVersion, n.Code AS NodeCode, a.ApproverType, "
                        + "a.ApproverId, a.Expression, a.Sort FROM plat.WorkflowNodeApprover a "
                        + "JOIN plat.WorkflowNode n ON n.Id = a.WorkflowNodeId "
                        + "JOIN plat.WorkflowDef d ON d.Id = n.WorkflowDefId WHERE d." + t + " ORDER BY d.Code, n.Sort");
        List<Map<String, Object>> pages = jdbc.queryForList(
                "SELECT Id, Code, Name, PageType, ModuleId, Layout, Title, ParamsJson, IsEnabled, Version, Remark "
                        + "FROM plat.Page WHERE " + t + " AND IsDeleted = 0 ORDER BY Code");
        List<Map<String, Object>> blocks = jdbc.queryForList(
                "SELECT p.Code AS PageCode, b.Code, b.BlockType, b.Title, b.DataObjectId, b.ListViewId, "
                        + "b.FormLayoutId, b.ParentBlockId, b.LinkField, b.Span, b.Row, b.VisibleExpr, b.Sort "
                        + "FROM plat.PageBlock b JOIN plat.Page p ON p.Id = b.PageId WHERE p." + t + " ORDER BY p.Code, b.Sort");
        List<Map<String, Object>> rolePerms = jdbc.queryForList(
                "SELECT r.Code AS RoleCode, p.ResourceKey, 1 AS Granted FROM plat.RolePermission rp "
                        + "JOIN plat.Role r ON r.Id = rp.RoleId JOIN plat.Permission p ON p.Id = rp.PermissionId "
                        + "WHERE r." + t + " ORDER BY r.Code, p.ResourceKey");
        List<Map<String, Object>> fieldPerms = jdbc.queryForList(
                "SELECT r.Code AS RoleCode, fp.ObjectName, fp.FieldName, fp.Access FROM plat.FieldPermission fp "
                        + "JOIN plat.Role r ON r.Id = fp.RoleId WHERE fp." + t + " ORDER BY r.Code, fp.ObjectName, fp.FieldName");

        s.put("objects", objects);
        s.put("fields", fields);
        s.put("listViews", views);
        s.put("listViewColumns", columns);
        s.put("formLayouts", forms);
        s.put("formFields", formFields);
        s.put("buttons", buttons);
        s.put("buttonActions", actions);
        s.put("rules", rules);
        s.put("ruleBindings", bindings);
        s.put("workflows", workflows);
        s.put("workflowNodes", nodes);
        s.put("workflowApprovers", approvers);
        s.put("pages", pages);
        s.put("pageBlocks", blocks);
        s.put("rolePermissions", rolePerms);
        s.put("fieldPermissions", fieldPerms);
        s.put("publishedAt", java.time.LocalDateTime.now().toString());
        return s;
    }

    /**
     * 把快照整体写回。顺序很重要：先删依赖方，再删被依赖方；插入反过来。
     * 业务数据（单据、库存、往来）不动。
     */
    @SuppressWarnings("unchecked")
    @Transactional
    public void apply(long tenantId, Map<String, Object> s) {
        // ---- 删除（从叶子到根）
        jdbc.update("DELETE FROM plat.FieldPermission WHERE TenantId = ?", tenantId);
        jdbc.update("DELETE FROM plat.RolePermission WHERE RoleId IN (SELECT Id FROM plat.Role WHERE TenantId = ?)", tenantId);
        jdbc.update("DELETE FROM plat.PageBlock WHERE PageId IN (SELECT Id FROM plat.Page WHERE TenantId = ?)", tenantId);
        jdbc.update("DELETE FROM plat.Page WHERE TenantId = ?", tenantId);
        jdbc.update("DELETE FROM plat.WorkflowNodeApprover WHERE WorkflowNodeId IN "
                + "(SELECT n.Id FROM plat.WorkflowNode n JOIN plat.WorkflowDef d ON d.Id = n.WorkflowDefId WHERE d.TenantId = ?)", tenantId);
        jdbc.update("DELETE FROM plat.WorkflowNode WHERE WorkflowDefId IN (SELECT Id FROM plat.WorkflowDef WHERE TenantId = ?)", tenantId);
        jdbc.update("DELETE FROM plat.WorkflowDef WHERE TenantId = ?", tenantId);
        jdbc.update("DELETE FROM plat.RuleBinding WHERE DataObjectId IN (SELECT Id FROM plat.DataObject WHERE TenantId = ?)", tenantId);
        jdbc.update("DELETE FROM plat.BizRule WHERE TenantId = ?", tenantId);
        jdbc.update("DELETE FROM plat.ButtonAction WHERE ButtonId IN (SELECT Id FROM plat.Button WHERE TenantId = ?)", tenantId);
        jdbc.update("DELETE FROM plat.Button WHERE TenantId = ?", tenantId);
        jdbc.update("DELETE FROM plat.FormField WHERE FormLayoutId IN "
                + "(SELECT Id FROM plat.FormLayout WHERE TenantId = ?)", tenantId);
        jdbc.update("DELETE FROM plat.FormLayout WHERE TenantId = ?", tenantId);
        jdbc.update("DELETE FROM plat.ListViewColumn WHERE ListViewId IN "
                + "(SELECT Id FROM plat.ListView WHERE TenantId = ?)", tenantId);
        jdbc.update("DELETE FROM plat.ListView WHERE TenantId = ?", tenantId);
        jdbc.update("DELETE FROM plat.DataObjectField WHERE DataObjectId IN "
                + "(SELECT Id FROM plat.DataObject WHERE TenantId = ?)", tenantId);

        // ---- 插入（从根到叶子）；数据对象按 Code 对齐，保留原 Id 会与其它租户冲突，故重建
        Map<String, Long> objectIds = new LinkedHashMap<>();
        for (Map<String, Object> o : (List<Map<String, Object>>) s.getOrDefault("objects", List.of())) {
            jdbc.update("""
                    INSERT plat.DataObject (TenantId, Code, Name, ObjectType, SchemaName, ObjectName, PrimaryKey,
                                            DocNoField, OrgField, TenantField, StatusField, DefaultOrder,
                                            IsReadOnly, IsEnabled, IsDeleted, CreatedAt)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, sysutcdatetime())
                    """, tenantId, o.get("Code"), o.get("Name"), num(o.get("ObjectType")),
                    o.get("SchemaName"), o.get("ObjectName"), o.get("PrimaryKey"), o.get("DocNoField"),
                    o.get("OrgField"), o.get("TenantField"), o.get("StatusField"), o.get("DefaultOrder"),
                    bool(o.get("IsReadOnly")), bool(o.get("IsEnabled")));
            Long id = jdbc.queryForObject("SELECT Id FROM plat.DataObject WHERE TenantId = ? AND Code = ?",
                    Long.class, tenantId, o.get("Code"));
            objectIds.put(String.valueOf(o.get("Code")), id);
        }
        for (Map<String, Object> f : (List<Map<String, Object>>) s.getOrDefault("fields", List.of())) {
            Long objId = objectIds.get(String.valueOf(f.get("ObjectCode")));
            if (objId == null) {
                continue;
            }
            jdbc.update("""
                    INSERT plat.DataObjectField (DataObjectId, FieldName, DisplayName, DataType, MaxLength,
                                                 Precision, Scale, IsNullable, IsPrimaryKey, IsIdentity,
                                                 IsRequired, DefaultValue, LookupType, LookupSource,
                                                 LookupValueField, LookupDisplayField, LookupFilter, Format,
                                                 Unit, IsVisible, Sort, IsComputed, ComputeExpr)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, objId, f.get("FieldName"), f.get("DisplayName"), f.get("DataType"),
                    f.get("MaxLength"), f.get("Precision"), f.get("Scale"), bool(f.get("IsNullable")),
                    bool(f.get("IsPrimaryKey")), bool(f.get("IsIdentity")), bool(f.get("IsRequired")),
                    f.get("DefaultValue"), num(f.get("LookupType")), f.get("LookupSource"),
                    f.get("LookupValueField"), f.get("LookupDisplayField"), f.get("LookupFilter"),
                    f.get("Format"), f.get("Unit"), bool(f.get("IsVisible")), num(f.get("Sort")),
                    bool(f.get("IsComputed")), f.get("ComputeExpr"));
        }
        for (Map<String, Object> v : (List<Map<String, Object>>) s.getOrDefault("listViews", List.of())) {
            Long objId = objectIds.get(String.valueOf(v.get("ObjectCode")));
            if (objId == null) {
                continue;
            }
            jdbc.update("""
                    INSERT plat.ListView (TenantId, DataObjectId, Code, Name, PageSize, DefaultSort, IsDefault,
                                          IsDeleted, CreatedAt)
                    VALUES (?, ?, ?, ?, ?, ?, ?, 0, sysutcdatetime())
                    """, tenantId, objId, v.get("Code"), v.get("Name"), num(v.get("PageSize")),
                    v.get("DefaultSort"), bool(v.get("IsDefault")));
        }
        for (Map<String, Object> c : (List<Map<String, Object>>) s.getOrDefault("listViewColumns", List.of())) {
            Long objId = objectIds.get(String.valueOf(c.get("ObjectCode")));
            Long viewId = viewId(tenantId, objId, String.valueOf(c.get("ViewCode")));
            if (viewId == null) {
                continue;
            }
            jdbc.update("""
                    INSERT plat.ListViewColumn (ListViewId, FieldName, Title, Width, Align, IsSum, IsVisible, Sort)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """, viewId, c.get("FieldName"), c.get("Title"), c.get("Width"), c.get("Align"),
                    bool(c.get("IsSum")), bool(c.get("IsVisible")), num(c.get("Sort")));
        }
        for (Map<String, Object> f : (List<Map<String, Object>>) s.getOrDefault("formLayouts", List.of())) {
            Long objId = objectIds.get(String.valueOf(f.get("ObjectCode")));
            if (objId == null) {
                continue;
            }
            jdbc.update("""
                    INSERT plat.FormLayout (TenantId, Code, Name, DataObjectId, Mode, Columns, IsDefault,
                                            IsEnabled, IsDeleted, CreatedAt)
                    VALUES (?, ?, ?, ?, ?, ?, ?, 1, 0, sysutcdatetime())
                    """, tenantId, f.get("Code"), f.get("Name"), objId, num(f.get("Mode")),
                    num(f.get("Columns")), bool(f.get("IsDefault")));
        }
        for (Map<String, Object> ff : (List<Map<String, Object>>) s.getOrDefault("formFields", List.of())) {
            Long objId = objectIds.get(String.valueOf(ff.get("ObjectCode")));
            Long layoutId = layoutId(tenantId, objId, String.valueOf(ff.get("LayoutCode")));
            if (layoutId == null) {
                continue;
            }
            jdbc.update("""
                    INSERT plat.FormField (FormLayoutId, FieldName, Label, ControlType, Row, Col, Span,
                                           IsReadOnly, IsRequired, IsHidden, DefaultExpr, Placeholder,
                                           HelpText, GroupName, Sort, AccessExpr)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, layoutId, ff.get("FieldName"), ff.get("Label"), num(ff.get("ControlType")),
                    num(ff.get("Row")), num(ff.get("Col")), num(ff.get("Span")), bool(ff.get("IsReadOnly")),
                    bool(ff.get("IsRequired")), bool(ff.get("IsHidden")), ff.get("DefaultExpr"),
                    ff.get("Placeholder"), ff.get("HelpText"), ff.get("GroupName"), num(ff.get("Sort")),
                    ff.get("AccessExpr"));
        }
        for (Map<String, Object> b : (List<Map<String, Object>>) s.getOrDefault("buttons", List.of())) {
            jdbc.update("""
                    INSERT plat.Button (TenantId, Code, Name, Text, Icon, ButtonType, FunctionId, Sort,
                                        IsVisible, VisibleExpr, IsEnabledExpr, Style, Remark, IsDeleted,
                                        CreatedAt)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, sysutcdatetime())
                    """, tenantId, b.get("Code"), b.get("Name"), b.get("Text"), b.get("Icon"),
                    num(b.get("ButtonType")), b.get("FunctionId"), num(b.get("Sort")),
                    bool(b.get("IsVisible")), b.get("VisibleExpr"), b.get("IsEnabledExpr"),
                    b.get("Style"), b.get("Remark"));
        }
        for (Map<String, Object> a : (List<Map<String, Object>>) s.getOrDefault("buttonActions", List.of())) {
            Long buttonId = jdbc.query("SELECT Id FROM plat.Button WHERE TenantId = ? AND Code = ?",
                    rs -> rs.next() ? rs.getLong(1) : null, tenantId, a.get("ButtonCode"));
            if (buttonId == null) {
                continue;
            }
            jdbc.update("""
                    INSERT plat.ButtonAction (ButtonId, Seq, ActionType, BuiltinCode, Target, Command, ParamJson,
                                              ConfirmText, SuccessMessage, NeedWorkflow, IsEnabled)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, buttonId, num(a.get("Seq")), num(a.get("ActionType")), a.get("BuiltinCode"),
                    a.get("Target"), a.get("Command"), a.get("ParamJson"), a.get("ConfirmText"),
                    a.get("SuccessMessage"), bool(a.get("NeedWorkflow")), bool(a.get("IsEnabled")));
        }
        for (Map<String, Object> r : (List<Map<String, Object>>) s.getOrDefault("rules", List.of())) {
            jdbc.update("""
                    INSERT plat.BizRule (TenantId, Code, Name, RuleType, Expression, ErrorMessage, Severity,
                                         IsEnabled, Remark, IsDeleted, CreatedAt)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, sysutcdatetime())
                    """, tenantId, r.get("Code"), r.get("Name"), num(r.get("RuleType")), r.get("Expression"),
                    r.get("ErrorMessage"), num(r.get("Severity")), bool(r.get("IsEnabled")), r.get("Remark"));
        }
        for (Map<String, Object> b : (List<Map<String, Object>>) s.getOrDefault("ruleBindings", List.of())) {
            Long objId = objectIds.get(String.valueOf(b.get("ObjectCode")));
            Long ruleId = jdbc.query("SELECT Id FROM plat.BizRule WHERE TenantId = ? AND Code = ?",
                    rs -> rs.next() ? rs.getLong(1) : null, tenantId, b.get("RuleCode"));
            if (objId == null || ruleId == null) {
                continue;
            }
            jdbc.update("""
                    INSERT plat.RuleBinding (RuleId, DataObjectId, FieldName, TriggerEvent, Sort, IsEnabled)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """, ruleId, objId, b.get("FieldName"), num(b.get("TriggerEvent")),
                    num(b.get("Sort")), bool(b.get("IsEnabled")));
        }
        for (Map<String, Object> d : (List<Map<String, Object>>) s.getOrDefault("workflows", List.of())) {
            Long objId = d.get("DataObjectId") == null ? null : objectIds.values().stream().findFirst().orElse(null);
            jdbc.update("""
                    INSERT plat.WorkflowDef (TenantId, Code, Name, DataObjectId, Version, ConditionExpr,
                                             Status, IsDefault, Remark, IsDeleted, CreatedAt)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, sysutcdatetime())
                    """, tenantId, d.get("Code"), d.get("Name"), objId, num(d.get("Version")),
                    d.get("ConditionExpr"), num(d.get("Status")), bool(d.get("IsDefault")), d.get("Remark"));
        }
        for (Map<String, Object> n : (List<Map<String, Object>>) s.getOrDefault("workflowNodes", List.of())) {
            Long defId = jdbc.query("""
                    SELECT Id FROM plat.WorkflowDef WHERE TenantId = ? AND Code = ? AND Version = ?
                    """, rs -> rs.next() ? rs.getLong(1) : null, tenantId, n.get("DefCode"), num(n.get("DefVersion")));
            if (defId == null) {
                continue;
            }
            jdbc.update("""
                    INSERT plat.WorkflowNode (WorkflowDefId, Code, Name, NodeType, Sort, ApproveMode, RejectMode,
                                              ConditionExpr, AllowAddSign, AllowDelegate, NextNodeCode, RejectNodeCode)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, defId, n.get("Code"), n.get("Name"), num(n.get("NodeType")), num(n.get("Sort")),
                    num(n.get("ApproveMode")), num(n.get("RejectMode")), n.get("ConditionExpr"),
                    bool(n.get("AllowAddSign")), bool(n.get("AllowDelegate")), n.get("NextNodeCode"),
                    n.get("RejectNodeCode"));
        }
        for (Map<String, Object> a : (List<Map<String, Object>>) s.getOrDefault("workflowApprovers", List.of())) {
            Long defId = jdbc.query("""
                    SELECT Id FROM plat.WorkflowDef WHERE TenantId = ? AND Code = ? AND Version = ?
                    """, rs -> rs.next() ? rs.getLong(1) : null, tenantId, a.get("DefCode"), num(a.get("DefVersion")));
            if (defId == null) {
                continue;
            }
            Long nodeId = jdbc.query("""
                    SELECT Id FROM plat.WorkflowNode WHERE WorkflowDefId = ? AND Code = ?
                    """, rs -> rs.next() ? rs.getLong(1) : null, defId, a.get("NodeCode"));
            if (nodeId == null) {
                continue;
            }
            jdbc.update("""
                    INSERT plat.WorkflowNodeApprover (WorkflowNodeId, ApproverType, ApproverId, Expression, Sort)
                    VALUES (?, ?, ?, ?, ?)
                    """, nodeId, num(a.get("ApproverType")), a.get("ApproverId"), a.get("Expression"), num(a.get("Sort")));
        }
        for (Map<String, Object> p : (List<Map<String, Object>>) s.getOrDefault("pages", List.of())) {
            jdbc.update("""
                    INSERT plat.Page (TenantId, Code, Name, PageType, Layout, Title, ParamsJson, IsEnabled,
                                      Version, Remark, IsDeleted, CreatedAt)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, sysutcdatetime())
                    """, tenantId, p.get("Code"), p.get("Name"), num(p.get("PageType")), p.get("Layout"),
                    p.get("Title"), p.get("ParamsJson"), bool(p.get("IsEnabled")), num(p.get("Version")),
                    p.get("Remark"));
        }
        for (Map<String, Object> b : (List<Map<String, Object>>) s.getOrDefault("pageBlocks", List.of())) {
            Long pageId = jdbc.query("SELECT Id FROM plat.Page WHERE TenantId = ? AND Code = ?",
                    rs -> rs.next() ? rs.getLong(1) : null, tenantId, b.get("PageCode"));
            if (pageId == null) {
                continue;
            }
            jdbc.update("""
                    INSERT plat.PageBlock (PageId, Code, BlockType, Title, DataObjectId, ListViewId, FormLayoutId,
                                           ParentBlockId, LinkField, Span, Row, VisibleExpr, Sort)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, pageId, b.get("Code"), num(b.get("BlockType")), b.get("Title"),
                    b.get("DataObjectId"), b.get("ListViewId"), b.get("FormLayoutId"),
                    b.get("ParentBlockId"), b.get("LinkField"), num(b.get("Span")), num(b.get("Row")),
                    b.get("VisibleExpr"), num(b.get("Sort")));
        }
        for (Map<String, Object> r : (List<Map<String, Object>>) s.getOrDefault("rolePermissions", List.of())) {
            Long roleId = jdbc.query("SELECT Id FROM plat.Role WHERE TenantId = ? AND Code = ?",
                    rs -> rs.next() ? rs.getLong(1) : null, tenantId, r.get("RoleCode"));
            Long permId = jdbc.query("SELECT Id FROM plat.Permission WHERE TenantId = ? AND ResourceKey = ?",
                    rs -> rs.next() ? rs.getLong(1) : null, tenantId, r.get("ResourceKey"));
            if (roleId == null || permId == null) {
                continue;
            }
            jdbc.update("INSERT plat.RolePermission (RoleId, PermissionId) VALUES (?, ?)", roleId, permId);
        }
        for (Map<String, Object> f : (List<Map<String, Object>>) s.getOrDefault("fieldPermissions", List.of())) {
            Long roleId = jdbc.query("SELECT Id FROM plat.Role WHERE TenantId = ? AND Code = ?",
                    rs -> rs.next() ? rs.getLong(1) : null, tenantId, f.get("RoleCode"));
            if (roleId == null) {
                continue;
            }
            jdbc.update("""
                    INSERT plat.FieldPermission (TenantId, RoleId, ObjectName, FieldName, Access)
                    VALUES (?, ?, ?, ?, ?)
                    """, tenantId, roleId, f.get("ObjectName"), f.get("FieldName"), num(f.get("Access")));
        }
        // 元数据变更后清空会话级缓存（若后续接入缓存，在此处失效）
    }

    private Long viewId(long tenantId, Long objId, String code) {
        if (objId == null) {
            return null;
        }
        return jdbc.query("SELECT Id FROM plat.ListView WHERE TenantId = ? AND DataObjectId = ? AND Code = ?",
                rs -> rs.next() ? rs.getLong(1) : null, tenantId, objId, code);
    }

    private Long layoutId(long tenantId, Long objId, String code) {
        if (objId == null) {
            return null;
        }
        return jdbc.query("SELECT Id FROM plat.FormLayout WHERE TenantId = ? AND DataObjectId = ? AND Code = ?",
                rs -> rs.next() ? rs.getLong(1) : null, tenantId, objId, code);
    }

    private static int num(Object o) {
        return o == null ? 0 : ((Number) o).intValue();
    }

    private static boolean bool(Object o) {
        if (o == null) {
            return false;
        }
        if (o instanceof Boolean b) {
            return b;
        }
        if (o instanceof Number n) {
            return n.intValue() != 0;
        }
        return Boolean.parseBoolean(String.valueOf(o));
    }

    private String toJson(Object o) {
        try {
            return json.writeValueAsString(o);
        } catch (Exception e) {
            throw new ApiException(ErrorCode.INTERNAL, "快照序列化失败：" + e.getMessage());
        }
    }

    static String md5(String s) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] d = md.digest(s.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : d) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            return "00000000000000000000000000000000";
        }
    }
}

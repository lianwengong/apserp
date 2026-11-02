package com.apserp.plat.meta;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.tenant.TenantContext;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 权限设计器的后端：角色 × 资源、角色 × 字段。
 *
 * <p>只做“配置的读写”，判定仍由 {@code plat.ufn_Perm_Check} 与字段权限表在运行时完成，
 * 保证设计器改完即时生效、没有第二套规则。</p>
 */
@Service
public class PermissionDesignService {

    private final JdbcTemplate jdbc;

    public PermissionDesignService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    // ------------------------------------------------------------ DTO

    public record RoleDto(long id, String code, String name, int roleType, boolean enabled, int userCount) {
    }

    public record ResourceDto(long id, String key, int type, String typeName, String name, String module) {
    }

    public record RoleMatrix(long roleId, List<ResourceGrant> grants) {
    }

    public record ResourceGrant(String resourceKey, boolean granted) {
    }

    public record FieldAccessRow(String fieldName, String displayName, int access) {
    }

    public record FieldMatrix(long roleId, String objectCode, List<FieldAccessRow> fields) {
    }

    private static final Map<Integer, String> RESOURCE_TYPES = Map.of(
            1, "功能点", 2, "菜单", 3, "数据对象", 4, "动作", 5, "设计器");

    // ------------------------------------------------------------ 角色

    public List<RoleDto> listRoles() {
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                        SELECT r.Id, r.Code, r.Name, r.RoleType, r.IsEnabled,
                               (SELECT COUNT(*) FROM plat.UserRole ur WHERE ur.RoleId = r.Id) AS UserCount
                        FROM plat.Role r
                        WHERE r.TenantId = ? AND r.IsDeleted = 0
                        ORDER BY r.RoleType, r.Code
                        """,
                (rs, i) -> new RoleDto(rs.getLong("Id"), rs.getString("Code"), rs.getString("Name"),
                        rs.getInt("RoleType"), rs.getBoolean("IsEnabled"), rs.getInt("UserCount")),
                tenantId);
    }

    // ------------------------------------------------------------ 资源

    /** 可授权的资源清单：权限点表里的全部条目。 */
    public List<ResourceDto> listResources(String keyword) {
        long tenantId = TenantContext.requireTenantId();
        String like = keyword == null || keyword.isBlank() ? "%" : "%" + keyword.trim() + "%";
        return jdbc.query("""
                        SELECT p.Id, p.ResourceKey, p.ResourceType, p.Name
                        FROM plat.Permission p
                        WHERE p.TenantId = ? AND p.IsEnabled = 1 AND p.ResourceKey LIKE ?
                        ORDER BY p.ResourceType, p.ResourceKey
                        """,
                (rs, i) -> {
                    String key = rs.getString("ResourceKey");
                    String module = key.contains(":") ? key.substring(0, key.indexOf(':')) : key;
                    int type = rs.getInt("ResourceType");
                    return new ResourceDto(rs.getLong("Id"), key, type,
                            RESOURCE_TYPES.getOrDefault(type, "其它"), rs.getString("Name"), module);
                },
                tenantId, like);
    }

    public RoleMatrix getMatrix(long roleId) {
        long tenantId = TenantContext.requireTenantId();
        requireRole(tenantId, roleId);
        List<ResourceGrant> grants = jdbc.query("""
                        SELECT p.ResourceKey, CASE WHEN rp.Id IS NULL THEN 0 ELSE 1 END AS Granted
                        FROM plat.Permission p
                        LEFT JOIN plat.RolePermission rp ON rp.PermissionId = p.Id AND rp.RoleId = ?
                        WHERE p.TenantId = ? AND p.IsEnabled = 1
                        ORDER BY p.ResourceType, p.ResourceKey
                        """,
                (rs, i) -> new ResourceGrant(rs.getString("ResourceKey"), rs.getBoolean("Granted")),
                roleId, tenantId);
        return new RoleMatrix(roleId, grants);
    }

    @Transactional
    public int saveMatrix(long roleId, List<String> resourceKeys) {
        long tenantId = TenantContext.requireTenantId();
        requireRole(tenantId, roleId);
        jdbc.update("DELETE FROM plat.RolePermission WHERE RoleId = ?", roleId);
        int n = 0;
        for (String key : resourceKeys == null ? List.<String>of() : resourceKeys) {
            Long permId = jdbc.query("SELECT Id FROM plat.Permission WHERE TenantId = ? AND ResourceKey = ?",
                    rs -> rs.next() ? rs.getLong(1) : null, tenantId, key);
            if (permId == null) {
                continue;
            }
            jdbc.update("INSERT plat.RolePermission (RoleId, PermissionId) VALUES (?, ?)", roleId, permId);
            n++;
        }
        return n;
    }

    // ------------------------------------------------------------ 字段权限

    public FieldMatrix fieldMatrix(long roleId, String objectCode) {
        long tenantId = TenantContext.requireTenantId();
        requireRole(tenantId, roleId);
        Long objectId = jdbc.query("SELECT Id FROM plat.DataObject WHERE TenantId = ? AND Code = ? AND IsDeleted = 0",
                rs -> rs.next() ? rs.getLong(1) : null, tenantId, objectCode);
        if (objectId == null) {
            throw new ApiException(ErrorCode.META_OBJECT_NOT_FOUND, "数据对象不存在：" + objectCode);
        }
        List<FieldAccessRow> fields = jdbc.query("""
                        SELECT f.FieldName, f.DisplayName,
                               ISNULL((SELECT MAX(fp.Access) FROM plat.FieldPermission fp
                                       WHERE fp.RoleId = ? AND fp.TenantId = ? AND fp.ObjectName = ?
                                         AND fp.FieldName = f.FieldName), 2) AS Access
                        FROM plat.DataObjectField f
                        WHERE f.DataObjectId = ?
                        ORDER BY f.Sort, f.FieldName
                        """,
                (rs, i) -> new FieldAccessRow(rs.getString("FieldName"), rs.getString("DisplayName"),
                        rs.getInt("Access")),
                roleId, tenantId, objectCode, objectId);
        return new FieldMatrix(roleId, objectCode, fields);
    }

    /** 保存字段权限：只写“非默认(2)”的项，减少噪音。 */
    @Transactional
    public int saveFieldMatrix(long roleId, String objectCode, Map<String, Integer> accessByField) {
        long tenantId = TenantContext.requireTenantId();
        requireRole(tenantId, roleId);
        jdbc.update("DELETE FROM plat.FieldPermission WHERE RoleId = ? AND TenantId = ? AND ObjectName = ?",
                roleId, tenantId, objectCode);
        int n = 0;
        for (Map.Entry<String, Integer> e : accessByField.entrySet()) {
            int access = e.getValue() == null ? 2 : e.getValue();
            if (access < 0 || access > 2) {
                throw new ApiException(ErrorCode.BAD_REQUEST,
                        "字段权限只能是 0（不可见）/1（只读）/2（可写）：" + e.getKey());
            }
            if (access == 2) {
                continue;
            }
            jdbc.update("""
                    INSERT plat.FieldPermission (TenantId, RoleId, ObjectName, FieldName, Access)
                    VALUES (?, ?, ?, ?, ?)
                    """, tenantId, roleId, objectCode, e.getKey(), access);
            n++;
        }
        return n;
    }

    /** 设计器概览数字：一眼看到“有多少配置”。 */
    public Map<String, Object> overview() {
        long tenantId = TenantContext.requireTenantId();
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("objects", count("SELECT COUNT(*) FROM plat.DataObject WHERE TenantId = ? AND IsDeleted = 0", tenantId));
        m.put("fields", count("SELECT COUNT(*) FROM plat.DataObjectField f JOIN plat.DataObject o ON o.Id = f.DataObjectId "
                + "WHERE o.TenantId = ? AND o.IsDeleted = 0", tenantId));
        m.put("views", count("SELECT COUNT(*) FROM plat.ListView WHERE TenantId = ? AND IsDeleted = 0", tenantId));
        m.put("forms", count("SELECT COUNT(*) FROM plat.FormLayout WHERE TenantId = ? AND IsDeleted = 0", tenantId));
        m.put("rules", count("SELECT COUNT(*) FROM plat.BizRule WHERE TenantId = ? AND IsDeleted = 0", tenantId));
        m.put("buttons", count("SELECT COUNT(*) FROM plat.Button WHERE TenantId = ? AND IsDeleted = 0", tenantId));
        m.put("workflows", count("SELECT COUNT(*) FROM plat.WorkflowDef WHERE TenantId = ? AND IsDeleted = 0", tenantId));
        m.put("pages", count("SELECT COUNT(*) FROM plat.Page WHERE TenantId = ? AND IsDeleted = 0", tenantId));
        m.put("roles", count("SELECT COUNT(*) FROM plat.Role WHERE TenantId = ? AND IsDeleted = 0", tenantId));
        m.put("versions", count("SELECT COUNT(*) FROM plat.MetaVersion WHERE TenantId = ?", tenantId));
        m.put("relations", count("SELECT COUNT(*) FROM plat.DataObjectRelation WHERE TenantId = ? AND IsDeleted = 0", tenantId));
        m.put("docStatuses", count("SELECT COUNT(*) FROM plat.DocStatus WHERE TenantId = ? AND IsDeleted = 0", tenantId));
        m.put("pendingTasks", count("SELECT COUNT(*) FROM plat.WorkflowTask t JOIN plat.WorkflowInstance i "
                + "ON i.Id = t.InstanceId WHERE i.TenantId = ? AND t.ApproveStatus = 0", tenantId));
        return m;
    }

    private long count(String sql, long tenantId) {
        Long n = jdbc.queryForObject(sql, Long.class, tenantId);
        return n == null ? 0L : n;
    }

    private void requireRole(long tenantId, long roleId) {
        Long id = jdbc.query("SELECT Id FROM plat.Role WHERE TenantId = ? AND Id = ? AND IsDeleted = 0",
                rs -> rs.next() ? rs.getLong(1) : null, tenantId, roleId);
        if (id == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, "角色不存在：" + roleId);
        }
    }

    /** 给菜单/按钮设计器用的树：模块 → 功能点。 */
    public List<Map<String, Object>> functionTree() {
        long tenantId = TenantContext.requireTenantId();
        List<Map<String, Object>> modules = jdbc.query("""
                        SELECT Id, Code, Name, ParentId, Sort FROM plat.Module
                        WHERE TenantId = ? AND IsDeleted = 0 ORDER BY Sort, Code
                        """,
                (rs, i) -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("id", rs.getLong("Id"));
                    m.put("code", rs.getString("Code"));
                    m.put("name", rs.getString("Name"));
                    m.put("parentId", rs.getObject("ParentId"));
                    m.put("children", new ArrayList<>());
                    return m;
                }, tenantId);
        Map<Long, Map<String, Object>> byId = new LinkedHashMap<>();
        for (Map<String, Object> m : modules) {
            byId.put(((Number) m.get("id")).longValue(), m);
        }
        List<Map<String, Object>> roots = new ArrayList<>();
        for (Map<String, Object> m : modules) {
            Object pid = m.get("parentId");
            if (pid == null || !byId.containsKey(((Number) pid).longValue())) {
                roots.add(m);
            } else {
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> kids = (List<Map<String, Object>>) byId.get(((Number) pid).longValue())
                        .get("children");
                kids.add(m);
            }
        }
        return roots;
    }
}

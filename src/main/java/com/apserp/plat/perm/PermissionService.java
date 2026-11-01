package com.apserp.plat.perm;

import com.apserp.common.tenant.TenantContext;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/**
 * 权限服务：功能点、字段、数据范围。
 *
 * <p>判定全部下沉到数据库函数 {@code plat.ufn_Perm_Check}，Java 侧不重复实现规则——
 * 规则只有一份，改权限模型时不用改两处代码。</p>
 *
 * <p>字段权限的语义（{@code plat.FieldPermission.Access}）：</p>
 * <ul>
 *   <li>0 = 不可见（返回时剔除）</li>
 *   <li>1 = 只读（返回但标记 readonly）</li>
 *   <li>2 = 可写（默认）</li>
 * </ul>
 * <p>多个角色冲突时**取最严**：任一角色设为 0 即不可见。</p>
 */
@Service
public class PermissionService {

    private static final Logger log = LoggerFactory.getLogger(PermissionService.class);

    private static final Set<String> ACTIONS = Set.of("read", "write", "approve", "export", "delete");

    private final JdbcTemplate jdbc;

    public PermissionService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** 功能点校验：平台管理员直通，其余走数据库函数。 */
    public boolean check(String resourceKey, String action) {
        if (resourceKey == null || resourceKey.isBlank()) {
            return false;
        }
        String act = action == null ? "read" : action.toLowerCase();
        if (!ACTIONS.contains(act)) {
            throw new IllegalArgumentException("不支持的权限动作：" + action);
        }
        if (TenantContext.isPlatformAdmin()) {
            return true;
        }
        Long userId = TenantContext.userId();
        if (userId == null) {
            return false;
        }
        Boolean ok = jdbc.queryForObject(
                "SELECT plat.ufn_Perm_Check(?, ?, ?, ?)",
                Boolean.class,
                (int) TenantContext.requireTenantId(), userId, resourceKey, act);
        return Boolean.TRUE.equals(ok);
    }

    /** 当前用户可见的组织范围（含下级），数据范围过滤用。 */
    public List<Integer> orgScope() {
        Long userId = TenantContext.userId();
        if (userId == null || TenantContext.isPlatformAdmin()) {
            return List.of();
        }
        return jdbc.queryForList("SELECT OrgId FROM plat.ufn_Perm_OrgIds(?)", Integer.class, userId);
    }

    /** 当前用户的字段访问级别：fieldName -> 0/1/2，取最严。 */
    public java.util.Map<String, Integer> fieldAccess(String objectCode) {
        Long userId = TenantContext.userId();
        if (userId == null) {
            return java.util.Map.of();
        }
        if (TenantContext.isPlatformAdmin()) {
            return java.util.Map.of();
        }
        record Row(String field, int access) {
        }
        List<Row> rows = jdbc.query("""
                        SELECT fp.FieldName, MIN(fp.Access) AS Access
                        FROM plat.FieldPermission fp
                        JOIN plat.UserRole ur ON ur.RoleId = fp.RoleId
                        WHERE ur.UserId = ? AND fp.TenantId = ? AND fp.ObjectName = ?
                        GROUP BY fp.FieldName
                        """,
                (rs, i) -> new Row(rs.getString("FieldName"), rs.getInt("Access")),
                userId, TenantContext.requireTenantId(), objectCode);
        java.util.Map<String, Integer> result = new java.util.HashMap<>();
        rows.forEach(r -> result.put(r.field(), r.access()));
        return result;
    }

    /** 当前用户的权限点集合（前端菜单/按钮渲染用）。 */
    public Set<String> grantedResources() {
        Long userId = TenantContext.userId();
        if (userId == null) {
            return Set.of();
        }
        return new HashSet<>(jdbc.queryForList(
                "SELECT DISTINCT ResourceKey FROM plat.vw_Perm_UserFunction WHERE UserId = ?",
                String.class, userId));
    }

    public void logDenied(String resourceKey, String action) {
        log.warn("permission_denied tenant={} user={} resource={} action={}",
                TenantContext.tenantId(), TenantContext.userId(), resourceKey, action);
    }
}

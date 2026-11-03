package com.aschain.plat.admin;

import com.aschain.common.ApiException;
import com.aschain.common.ErrorCode;
import com.aschain.common.tenant.TenantContext;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 平台角色与权限（平台租户 {@code Id=0} 下的 Role / Permission / RolePermission）。
 *
 * <p>平台账号与业务租户解绑后，平台侧也需要「谁能做什么」：这里维护的是
 * <b>平台运营权限</b>（{@code PLAT:*}），不是某个租户内部的业务权限。
 * 角色变更立刻生效（每次请求都按 RolePermission 判定，没有缓存）。</p>
 */
@Service
public class PlatformRoleService {

    private static final Logger log = LoggerFactory.getLogger(PlatformRoleService.class);

    private static final long PLATFORM_TENANT_ID = 0L;

    private final JdbcTemplate jdbc;

    public PlatformRoleService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** members：成员账号（用户名），列表直接展示，避免只看到一个数字 */
    public record RoleDto(long id, String code, String name, boolean enabled, int memberCount,
                          List<String> members, List<String> permissions) {
    }

    public record PermissionDto(String resourceKey, String name, String parentKey) {
    }

    public record SaveRequest(Long id, String code, String name, Boolean enabled,
                              List<String> permissions) {
    }

    public List<RoleDto> roles() {
        requirePlatformScope();
        List<RoleDto> roles = jdbc.query("""
                SELECT r.Id, r.Code, r.Name, r.IsEnabled,
                       (SELECT COUNT(*) FROM plat.UserRole ur WHERE ur.RoleId = r.Id) AS MemberCount
                FROM plat.Role r
                WHERE r.TenantId = ? AND r.IsDeleted = 0
                ORDER BY r.Id
                """, (rs, i) -> new RoleDto(rs.getLong("Id"), rs.getString("Code"),
                rs.getString("Name"), rs.getBoolean("IsEnabled"), rs.getInt("MemberCount"),
                new ArrayList<>(), new ArrayList<>()), PLATFORM_TENANT_ID);
        Map<Long, RoleDto> byId = new LinkedHashMap<>();
        roles.forEach(r -> byId.put(r.id(), r));
        jdbc.query("""
                SELECT rp.RoleId, p.ResourceKey
                FROM plat.RolePermission rp
                JOIN plat.Permission p ON p.Id = rp.PermissionId
                JOIN plat.Role r ON r.Id = rp.RoleId
                WHERE r.TenantId = ? AND rp.Allow = 1
                ORDER BY p.ResourceKey
                """, rs -> {
                    RoleDto role = byId.get(rs.getLong("RoleId"));
                    if (role != null) {
                        role.permissions().add(rs.getString("ResourceKey"));
                    }
                }, PLATFORM_TENANT_ID);
        jdbc.query("""
                SELECT ur.RoleId, u.UserName
                FROM plat.UserRole ur
                JOIN plat.[User] u ON u.Id = ur.UserId AND u.IsDeleted = 0
                JOIN plat.Role r ON r.Id = ur.RoleId
                WHERE r.TenantId = ?
                ORDER BY u.UserName
                """, rs -> {
                    RoleDto role = byId.get(rs.getLong("RoleId"));
                    if (role != null) {
                        role.members().add(rs.getString("UserName"));
                    }
                }, PLATFORM_TENANT_ID);
        return new ArrayList<>(byId.values());
    }

    /** 平台权限点清单（前端勾选树用）。 */
    public List<PermissionDto> permissions() {
        requirePlatformScope();
        return jdbc.query("""
                SELECT ResourceKey, Name, ParentKey FROM plat.Permission
                WHERE TenantId = ? AND ResourceKey LIKE 'PLAT%' AND IsEnabled = 1
                ORDER BY CASE WHEN ResourceKey = 'PLAT' THEN 0 ELSE 1 END, ResourceKey
                """, (rs, i) -> new PermissionDto(rs.getString("ResourceKey"),
                rs.getString("Name"), rs.getString("ParentKey")), PLATFORM_TENANT_ID);
    }

    /** 新建或修改平台角色（code 不可改）。 */
    @Transactional
    public long save(SaveRequest req) {
        requirePlatformScope();
        String name = req.name() == null ? "" : req.name().trim();
        if (name.isEmpty()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "角色名称不能为空");
        }
        List<String> wanted = req.permissions() == null ? List.of() : req.permissions();
        long roleId;
        if (req.id() == null) {
            String code = req.code() == null ? "" : req.code().trim().toUpperCase();
            if (!code.matches("^[A-Z][A-Z0-9_]{2,29}$")) {
                throw new ApiException(ErrorCode.BAD_REQUEST,
                        "角色编码只能是 3-30 位大写字母/数字/下划线，例如 PLAT_OPS2");
            }
            Integer dup = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM plat.Role WHERE TenantId = ? AND Code = ? AND IsDeleted = 0",
                    Integer.class, PLATFORM_TENANT_ID, code);
            if (dup != null && dup > 0) {
                throw new ApiException(ErrorCode.DUPLICATE_KEY, "角色编码已存在：" + code);
            }
            jdbc.update("""
                    INSERT plat.Role (TenantId, Code, Name, RoleType, IsSystem, IsEnabled, Remark,
                                      IsDeleted, CreatedAt)
                    VALUES (?, ?, ?, 1, 0, ?, N'平台角色', 0, sysutcdatetime())
                    """, PLATFORM_TENANT_ID, code, name, req.enabled() == null || req.enabled());
            roleId = jdbc.queryForObject(
                    "SELECT Id FROM plat.Role WHERE TenantId = ? AND Code = ?",
                    Long.class, PLATFORM_TENANT_ID, code);
        } else {
            roleId = req.id();
            Map<String, Object> role = requireRole(roleId);
            if ("PLAT_ADMIN".equals(role.get("Code")) && Boolean.FALSE.equals(req.enabled())) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "平台管理员是内置角色，不能停用");
            }
            jdbc.update("""
                    UPDATE plat.Role SET Name = ?, IsEnabled = ?, ModifiedAt = sysutcdatetime()
                    WHERE Id = ? AND TenantId = ?
                    """, name, req.enabled() == null || req.enabled(), roleId, PLATFORM_TENANT_ID);
        }
        replacePermissions(roleId, wanted);
        log.info("platform_role_saved id={} name={} permissions={}", roleId, name, wanted.size());
        return roleId;
    }

    /** 覆盖式设置角色成员（平台账号）。 */
    @Transactional
    public void setMembers(long roleId, List<Long> userIds) {
        requirePlatformScope();
        requireRole(roleId);
        List<Long> wanted = userIds == null ? List.of() : userIds;
        if (!wanted.isEmpty()) {
            String in = String.join(",", wanted.stream().map(id -> "?").toList());
            List<Object> args = new ArrayList<>(wanted);
            Integer found = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM plat.[User] WHERE IsPlatformAccount = 1 AND IsDeleted = 0 "
                            + "AND Id IN (" + in + ")", Integer.class, args.toArray());
            if (found == null || found != wanted.size()) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "成员只能是平台账号");
            }
        }
        jdbc.update("DELETE FROM plat.UserRole WHERE TenantId = ? AND RoleId = ?",
                PLATFORM_TENANT_ID, roleId);
        for (Long userId : wanted) {
            jdbc.update("INSERT plat.UserRole (TenantId, UserId, RoleId) VALUES (?, ?, ?)",
                    PLATFORM_TENANT_ID, userId, roleId);
        }
        log.info("platform_role_members role={} members={}", roleId, wanted);
    }

    /** 角色成员（平台账号）。 */
    public List<Long> members(long roleId) {
        requirePlatformScope();
        requireRole(roleId);
        return jdbc.queryForList("SELECT UserId FROM plat.UserRole WHERE RoleId = ?", Long.class, roleId);
    }

    /** 角色编码默认值：PLAT_ + 名称拼音/序号太随意，这里让前端必填，不做自动生成。 */
    private void replacePermissions(long roleId, List<String> keys) {
        jdbc.update("DELETE FROM plat.RolePermission WHERE TenantId = ? AND RoleId = ?",
                PLATFORM_TENANT_ID, roleId);
        for (String key : keys) {
            jdbc.update("""
                    INSERT plat.RolePermission (TenantId, RoleId, PermissionId, Allow, CanRead,
                                                CanWrite, CanApprove, CanExport, CanDelete,
                                                DataScope, GrantedAt)
                    SELECT ?, ?, Id, 1, 1, 1, 0, 1, 0, 1, sysutcdatetime()
                    FROM plat.Permission WHERE TenantId = ? AND ResourceKey = ?
                    """, PLATFORM_TENANT_ID, roleId, PLATFORM_TENANT_ID, key);
        }
    }

    private Map<String, Object> requireRole(long roleId) {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT Id, Code, Name FROM plat.Role WHERE Id = ? AND TenantId = ? AND IsDeleted = 0",
                roleId, PLATFORM_TENANT_ID);
        if (rows.isEmpty()) {
            throw new ApiException(ErrorCode.NOT_FOUND, "平台角色不存在");
        }
        return rows.get(0);
    }

    private void requirePlatformScope() {
        if (!TenantContext.isPlatformScope()) {
            throw new ApiException(ErrorCode.FORBIDDEN,
                    "仅平台管理员可管理平台角色，请使用平台登录");
        }
    }
}

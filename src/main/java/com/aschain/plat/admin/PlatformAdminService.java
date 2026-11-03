package com.aschain.plat.admin;

import com.aschain.common.ApiException;
import com.aschain.common.ErrorCode;
import com.aschain.common.tenant.TenantContext;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/**
 * 平台管理（平台管理员视角）：租户、平台概览等只读数据。
 *
 * <p>平台管理菜单与设计器/权限页面由前端组合；这里只提供平台管理员需要的
 * 跨租户只读信息，避免前端直接拼 SQL 或依赖运维脚本。</p>
 */
@Service
public class PlatformAdminService {

    private final JdbcTemplate jdbc;

    public PlatformAdminService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * 租户列表行：除编码（不可改）外的可维护字段都带上，另外带出租户管理员
     * （首个启用中的 SYSADMIN 账号），因为「管理员口令」也要在租户管理里维护。
     */
    public record TenantDto(long id, String code, String name, String shortName, String industry,
                            String contact, String phone, Integer maxUsers, String remark,
                            boolean enabled, LocalDateTime createdAt, LocalDateTime expireAt,
                            Long adminUserId, String adminUserName) {
    }

    public List<TenantDto> tenants() {
        requirePlatformAdmin();
        return jdbc.query("""
                        SELECT t.Id, t.Code, t.Name, t.ShortName, t.Industry, t.Contact, t.Phone,
                               t.MaxUsers, t.Remark, t.IsEnabled, t.CreatedAt, t.ExpireAt,
                               admin.Id AS AdminUserId, admin.UserName AS AdminUserName
                        FROM plat.Tenant t
                        OUTER APPLY (
                            SELECT TOP 1 u.Id, u.UserName
                            FROM plat.[User] u
                            JOIN plat.UserRole ur ON ur.UserId = u.Id
                            JOIN plat.Role r ON r.Id = ur.RoleId AND r.Code = 'SYSADMIN'
                            WHERE u.TenantId = t.Id AND u.IsDeleted = 0 AND u.IsEnabled = 1
                            ORDER BY u.Id
                        ) admin
                        WHERE t.IsDeleted = 0 AND t.IsPlatformTenant = 0
                        ORDER BY t.Id
                        """,
                (rs, i) -> new TenantDto(
                        rs.getLong("Id"),
                        rs.getString("Code"),
                        rs.getString("Name"),
                        rs.getString("ShortName"),
                        rs.getString("Industry"),
                        rs.getString("Contact"),
                        rs.getString("Phone"),
                        rs.getObject("MaxUsers", Integer.class),
                        rs.getString("Remark"),
                        rs.getBoolean("IsEnabled"),
                        rs.getObject("CreatedAt", LocalDateTime.class),
                        rs.getObject("ExpireAt", LocalDateTime.class),
                        rs.getObject("AdminUserId", Long.class),
                        rs.getString("AdminUserName")));
    }

    /**
     * 平台管理接口的准入：必须是平台登录换来的会话（平台作用域），
     * 不能只靠「这个账号在自己租户里是 SYSADMIN」——那样租户管理员就能列出
     * 所有租户、跨租户操作，等于把租户隔离开了个后门。
     */
    private void requirePlatformAdmin() {
        if (!TenantContext.isPlatformAdmin() || !TenantContext.isPlatformScope()) {
            throw new ApiException(ErrorCode.FORBIDDEN,
                    "仅平台管理员可访问平台管理，请使用平台登录");
        }
    }
}

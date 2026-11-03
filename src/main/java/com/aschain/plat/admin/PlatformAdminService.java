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

    public record TenantDto(long id, String code, String name, String shortName, String industry,
                            boolean enabled, LocalDateTime createdAt, LocalDateTime expireAt) {
    }

    public List<TenantDto> tenants() {
        requirePlatformAdmin();
        return jdbc.query("""
                        SELECT Id, Code, Name, ShortName, Industry, IsEnabled, CreatedAt, ExpireAt
                        FROM plat.Tenant
                        WHERE IsDeleted = 0
                        ORDER BY Id
                        """,
                (rs, i) -> new TenantDto(
                        rs.getLong("Id"),
                        rs.getString("Code"),
                        rs.getString("Name"),
                        rs.getString("ShortName"),
                        rs.getString("Industry"),
                        rs.getBoolean("IsEnabled"),
                        rs.getObject("CreatedAt", LocalDateTime.class),
                        rs.getObject("ExpireAt", LocalDateTime.class)));
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

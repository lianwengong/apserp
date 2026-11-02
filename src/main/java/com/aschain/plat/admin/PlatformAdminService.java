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

    private void requirePlatformAdmin() {
        if (!TenantContext.isPlatformAdmin()) {
            throw new ApiException(ErrorCode.FORBIDDEN, "仅平台管理员可访问平台管理");
        }
    }
}

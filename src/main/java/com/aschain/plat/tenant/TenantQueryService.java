package com.aschain.plat.tenant;

import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/**
 * 租户只读查询：给「当前会话的租户名称」这类展示用。
 * 租户表没有 RLS，不需要平台作用域。
 */
@Service
public class TenantQueryService {

    private final JdbcTemplate jdbc;

    public TenantQueryService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public record TenantSummary(long id, String code, String name) {
    }

    public TenantSummary summary(long tenantId) {
        var rows = jdbc.queryForList(
                "SELECT Id, Code, Name FROM plat.Tenant WHERE Id = ? AND IsDeleted = 0", tenantId);
        if (rows.isEmpty()) {
            return new TenantSummary(tenantId, "", "");
        }
        Map<String, Object> row = rows.get(0);
        return new TenantSummary(((Number) row.get("Id")).longValue(),
                String.valueOf(row.get("Code")), String.valueOf(row.get("Name")));
    }
}

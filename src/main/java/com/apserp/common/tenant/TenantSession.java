package com.apserp.common.tenant;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * 在「同一条物理连接」上先设置租户上下文，再执行业务 SQL。
 *
 * <p>关键：连接池会复用连接，若只在请求开始时设置一次 SESSION_CONTEXT，
 * 后续查询可能拿到另一条连接，导致 RLS 过滤错租户（踩坑记录 1）。</p>
 */
@Component
public class TenantSession {

    private final JdbcTemplate jdbcTemplate;

    public TenantSession(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    /** 在同一个连接内执行回调，回调前已设置好 SESSION_CONTEXT。 */
    public <T> T execute(ConnectionCallback<T> callback) {
        long tenantId = TenantContext.requireTenantId();
        Long userId = TenantContext.userId();
        return jdbcTemplate.execute((Connection con) -> {
            setSessionContext(con, tenantId, userId);
            return callback.doInConnection(con);
        });
    }

    private void setSessionContext(Connection con, long tenantId, Long userId) throws SQLException {
        try (CallableStatement cs = con.prepareCall("{call plat.usp_TenantContext (?, ?, ?)}")) {
            cs.setLong(1, tenantId);
            if (userId == null) {
                cs.setNull(2, java.sql.Types.BIGINT);
            } else {
                cs.setLong(2, userId);
            }
            cs.setBoolean(3, false);
            cs.execute();
        }
    }
}

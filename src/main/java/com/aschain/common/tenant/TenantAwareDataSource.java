package com.aschain.common.tenant;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import javax.sql.DataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.datasource.DelegatingDataSource;

/**
 * 租户感知的数据源：**每次从连接池借出连接时**，把当前租户写入 SQL Server 的
 * {@code SESSION_CONTEXT}，供行级安全（RLS）使用。
 *
 * <p>为什么必须在这一层做：连接池会复用物理连接，如果在业务代码里「先设上下文、再查」，
 * 两次调用可能拿到不同的连接，租户上下文就丢了；反过来也可能把 A 租户的上下文
 * 留在连接上让 B 租户复用，造成越权。</p>
 *
 * <p>注意：会话上下文不能跨连接复用，因此这里对**每一次 getConnection** 都重设，
 * 而不是只在事务开始时设一次。</p>
 */
public class TenantAwareDataSource extends DelegatingDataSource {

    private static final Logger log = LoggerFactory.getLogger(TenantAwareDataSource.class);

    private static final String SQL_SET_TENANT =
            "{call sys.sp_set_session_context (?, ?)}";

    public TenantAwareDataSource(DataSource delegate) {
        super(delegate);
    }

    @Override
    public Connection getConnection() throws SQLException {
        return applyTenant(super.getConnection());
    }

    @Override
    public Connection getConnection(String username, String password) throws SQLException {
        return applyTenant(super.getConnection(username, password));
    }

    private Connection applyTenant(Connection con) throws SQLException {
        // 关键：每次借出连接都必须先把 BypassRls 复位。
        // Flyway 迁移脚本会执行 sp_set_session_context 'BypassRls', 1；
        // 连接归还 Hikari 后再被业务请求借出时，这个标记还在，RLS 会被绕过——
        // 等于任何一个请求都能读到所有租户的数据。
        // 例外：平台登录换来的会话（平台作用域）本来就要跨租户读写，显式置 1。
        setContext(con, "BypassRls", TenantContext.isPlatformScope() ? 1L : 0L);

        Long tenantId = TenantContext.tenantId();
        Long userId = TenantContext.userId();
        if (tenantId == null) {
            // 后台任务/运维连接：不设置租户，RLS 按 fail-closed 返回空集
            setContext(con, "TenantId", null);
            setContext(con, "UserId", null);
            return con;
        }
        setContext(con, "TenantId", tenantId);
        setContext(con, "UserId", userId);
        return con;
    }

    private void setContext(Connection con, String key, Long value) throws SQLException {
        try (CallableStatement cs = con.prepareCall(SQL_SET_TENANT)) {
            cs.setString(1, key);
            if (value == null) {
                cs.setNull(2, java.sql.Types.INTEGER);
            } else {
                cs.setObject(2, value.intValue());
            }
            cs.execute();
        } catch (SQLException ex) {
            // 上下文设置失败必须让请求失败，绝不能继续执行——否则可能读到别的租户数据
            log.error("设置租户上下文失败 key={} value={}", key, value, ex);
            throw ex;
        }
    }
}

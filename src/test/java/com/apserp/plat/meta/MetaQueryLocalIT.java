package com.apserp.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;

/**
 * 本地集成测试：直连本机 SQL Server 的空库（APSErpV3_TEST），不依赖 Docker。
 *
 * <p>运行方式：</p>
 * <pre>
 * mvn test -Dit.db=true \
 *   "-Dit.db.url=jdbc:sqlserver://localhost:1433;databaseName=APSErpV3_TEST;encrypt=false;trustServerCertificate=true" \
 *   -Dit.db.user=apserp_dev -Dit.db.password='Apserp#2026Dev'
 * </pre>
 *
 * <p>CI 上改用 {@link MetaQueryIT}（Testcontainers 起临时 SQL Server），两者互补：
 * 本地要快、要能调，CI 要可重现、要干净。</p>
 */
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class MetaQueryLocalIT {

    private static final String DEFAULT_URL =
            "jdbc:sqlserver://localhost:1433;databaseName=APSErpV3_TEST;encrypt=false;trustServerCertificate=true";

    @Test
    void schema_is_complete_after_flyway() throws Exception {
        try (Connection con = connect(true)) {
            assertThat(count(con, "sys.tables", "schema_id > 4")).isEqualTo(225);
            assertThat(count(con, "sys.foreign_keys", "1 = 1")).isEqualTo(792);
            assertThat(count(con, "sys.security_predicates", "1 = 1")).isEqualTo(180);
            assertThat(count(con, "plat.Module", "1 = 1")).isEqualTo(635);
            assertThat(count(con, "plat.ModuleFunction", "1 = 1")).isEqualTo(1432);
            assertThat(count(con, "plat.Permission", "1 = 1")).isEqualTo(2067);
        }
    }

    @Test
    void rls_is_fail_closed_without_tenant_context() throws Exception {
        try (Connection con = connect(false)) {
            // 未设置租户上下文：RLS 默认拒绝，看不到任何模块
            assertThat(count(con, "plat.Module", "1 = 1")).isZero();
            // 但全局表（未纳入 RLS 的租户清单）仍可读
            assertThat(count(con, "plat.Tenant", "1 = 1")).isGreaterThan(0);
        }
    }

    @Test
    void rls_filters_by_tenant() throws Exception {
        try (Connection con = connect(false)) {
            setTenant(con, 1);
            long tenant1 = count(con, "plat.Module", "1 = 1");
            assertThat(tenant1).isGreaterThan(0);

            setTenant(con, 2);
            long tenant2 = count(con, "plat.Module", "1 = 1");
            // 演示数据只给租户 1 建了元数据
            assertThat(tenant2).isZero();
        }
    }

    private void setTenant(Connection con, int tenantId) throws Exception {
        try (CallableStatement cs = con.prepareCall("{call sys.sp_set_session_context (?, ?)}")) {
            cs.setString(1, "TenantId");
            cs.setInt(2, tenantId);
            cs.execute();
        }
    }

    private Connection connect(boolean bypassRls) throws Exception {
        String url = System.getProperty("it.db.url", DEFAULT_URL);
        String user = System.getProperty("it.db.user", "apserp_dev");
        String pwd = System.getProperty("it.db.password", "Apserp#2026Dev");
        Connection con = DriverManager.getConnection(url, user, pwd);
        if (bypassRls) {
            try (CallableStatement cs = con.prepareCall("{call sys.sp_set_session_context (?, ?)}")) {
                cs.setString(1, "BypassRls");
                cs.setInt(2, 1);
                cs.execute();
            }
        }
        return con;
    }

    private long count(Connection con, String table, String where) throws Exception {
        try (var st = con.createStatement();
             ResultSet rs = st.executeQuery("select count(*) from " + table + " where " + where)) {
            rs.next();
            return rs.getLong(1);
        }
    }
}

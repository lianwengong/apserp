package com.apserp.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;

import com.apserp.support.ItDb;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;

/**
 * 结构级集成测试：验证「空库 + 全部 Flyway 迁移」得到的结果与设计一致，
 * 并验证 RLS 在无租户上下文时默认拒绝。
 *
 * <p>跑在一次性空库（默认 APSErpV3_TEST）上，可以随时重建，不污染开发库。</p>
 */
@EnabledIfSystemProperty(named = "it.db", matches = "true")
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
class MetaQueryLocalIT {

    @Test
    void schema_is_complete_after_flyway() throws Exception {
        try (Connection con = connect(true)) {
            // 基线 225 + V30（2）+ V32（3）+ V33（1）+ V34（2）+ V36（PrintTemplate）+ V46（PageSchema）+ V48（UserPreference）
            assertThat(count(con, "sys.tables", "schema_id > 4")).isEqualTo(236);
            assertThat(count(con, "sys.foreign_keys", "1 = 1")).isEqualTo(806);
            assertThat(count(con, "sys.security_predicates", "1 = 1")).isEqualTo(190);
            assertThat(count(con, "plat.Module", "1 = 1")).isEqualTo(635);
            assertThat(count(con, "plat.ModuleFunction", "1 = 1")).isEqualTo(1432);
            // 权限点会随数据对象/功能点增加，基线之外只做下界断言
            assertThat(count(con, "plat.Permission", "1 = 1")).isGreaterThanOrEqualTo(2067);
        }
    }

    @Test
    void rls_is_fail_closed_without_tenant_context() throws Exception {
        try (Connection con = connect(false)) {
            assertThat(count(con, "plat.Module", "1 = 1")).isZero();
            assertThat(count(con, "plat.Tenant", "1 = 1")).isGreaterThan(0);
        }
    }

    @Test
    void rls_filters_by_tenant() throws Exception {
        try (Connection con = connect(false)) {
            setTenant(con, 1);
            assertThat(count(con, "plat.Module", "1 = 1")).isGreaterThan(0);

            setTenant(con, 2);
            assertThat(count(con, "plat.Module", "1 = 1")).isZero();
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
        String url = ItDb.testSchemaUrl();
        Connection con = DriverManager.getConnection(url, ItDb.user(), ItDb.password());
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

package com.aschain.common.tenant;

import static org.assertj.core.api.Assertions.assertThat;

import com.aschain.support.ItDb;
import java.sql.Connection;
import java.sql.Statement;
import javax.sql.DataSource;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

/**
 * 回归测试：防止 {@code SESSION_CONTEXT('BypassRls')} 在连接池里泄漏。
 *
 * <p>背景：Flyway 迁移脚本会设置 BypassRls=1。连接归还 Hikari 后若不清除，
 * 下一个复用该连接的请求就绕过了行级安全，能读到所有租户的数据。</p>
 *
 * <p>为了稳定复现，把连接池大小压到 1，保证前后两次借到的是同一条物理连接。</p>
 */
@SpringBootTest(properties = {
        "spring.datasource.hikari.maximum-pool-size=1",
        "spring.datasource.hikari.minimum-idle=1"
})
@EnabledIfSystemProperty(named = "it.db", matches = "true")
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
class TenantContextLeakIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
    }

    @Autowired
    private DataSource dataSource;

    @AfterEach
    void clear() {
        TenantContext.clear();
    }

    @Test
    void bypass_flag_must_not_leak_through_connection_pool() throws Exception {
        // 1) 模拟 Flyway：在借到的连接上打开 BypassRls，然后归还
        try (Connection con = dataSource.getConnection(); Statement st = con.createStatement()) {
            st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
        }

        // 2) 模拟业务请求：设置租户后再次借连接
        TenantContext.set(1L, 1L, false);
        try (Connection con = dataSource.getConnection(); Statement st = con.createStatement()) {
            try (var rs = st.executeQuery("SELECT CAST(SESSION_CONTEXT(N'BypassRls') AS int)")) {
                assertThat(rs.next()).isTrue();
                Object bypass = rs.getObject(1);
                assertThat(bypass == null ? 0 : ((Number) bypass).intValue())
                        .as("借出的连接必须已复位 BypassRls，否则 RLS 被绕过")
                        .isZero();
            }
        }
    }

    @Test
    void tenant_switch_must_reset_context_between_borrows() throws Exception {
        TenantContext.set(1L, 1L, false);
        long tenant1;
        try (Connection con = dataSource.getConnection(); Statement st = con.createStatement();
             var rs = st.executeQuery("SELECT COUNT(*) FROM plat.Module")) {
            rs.next();
            tenant1 = rs.getLong(1);
        }
        assertThat(tenant1).isPositive();

        // 换租户 2：看不到租户 1 的任何行
        TenantContext.set(2L, null, false);
        try (Connection con = dataSource.getConnection(); Statement st = con.createStatement();
             var rs = st.executeQuery("SELECT COUNT(*) FROM plat.Module WHERE TenantId = 1")) {
            rs.next();
            assertThat(rs.getLong(1))
                    .as("换租户后绝不能看到上一个租户的数据")
                    .isZero();
        }

        // 再回到租户 1，确认上下文随连接借出被正确重设（而不是停留在租户 2）
        TenantContext.set(1L, 1L, false);
        try (Connection con = dataSource.getConnection(); Statement st = con.createStatement();
             var rs = st.executeQuery("SELECT COUNT(*) FROM plat.Module")) {
            rs.next();
            assertThat(rs.getLong(1))
                    .as("切回租户 1 后必须重新看到自己的 %d 行", tenant1)
                    .isEqualTo(tenant1);
        }
    }
}

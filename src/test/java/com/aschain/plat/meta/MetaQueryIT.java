package com.aschain.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;

import com.aschain.support.CiDb;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

/**
 * CI 集成测试：真 SQL Server + Flyway 全量迁移 + 元数据查询。
 *
 * <p>两个前提，缺一即跳过（不会让本地构建变红）：</p>
 * <ol>
 *   <li>环境变量 {@code IT_ENABLED=true}（CI 的 test 阶段设置，本地默认不设）</li>
 *   <li>环境变量 {@code IT_DB_URL / IT_DB_USER / IT_DB_PASSWORD} 指向可连的 SQL Server</li>
 * </ol>
 *
 * <p>不使用 Testcontainers：CI 由 GitLab service 容器提供数据库，
 * 测试先建测试库、再由 Flyway 在空库上重放全部迁移，本地只要装了 SQL Server 也能跑。</p>
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
class MetaQueryIT {

    static final String TEST_DB = "ASChain_TEST";

    @DynamicPropertySource
    static void props(DynamicPropertyRegistry registry) {
        String url = System.getenv("IT_DB_URL");
        String user = System.getenv("IT_DB_USER");
        String password = System.getenv("IT_DB_PASSWORD");
        if (url != null && user != null && password != null) {
            try {
                String testUrl = CiDb.ensureDatabase(url, user, password, TEST_DB);
                registry.add("spring.datasource.url", () -> testUrl);
                registry.add("spring.datasource.username", () -> user);
                registry.add("spring.datasource.password", () -> password);
            } catch (Exception e) {
                throw new IllegalStateException("CI 数据库准备失败：" + url, e);
            }
        }
        // Redis 一期未使用，CI 不启动 Redis
        registry.add("management.health.redis.enabled", () -> "false");
    }

    @Autowired
    DataSource dataSource;

    @Test
    void flyway_should_migrate_and_engine_should_query() throws Exception {
        // 1) Flyway 已在启动时执行 —— 至少 225 张业务表
        try (var con = dataSource.getConnection();
             var st = con.createStatement();
             var rs = st.executeQuery("SELECT COUNT(*) FROM sys.tables WHERE schema_id > 4")) {
            assertThat(rs.next()).isTrue();
            assertThat(rs.getInt(1)).isGreaterThanOrEqualTo(225);
        }

        // 2) 租户上下文缺失时 RLS 默认拒绝（fail-closed）
        try (var con = dataSource.getConnection();
             var st = con.createStatement();
             var rs = st.executeQuery("SELECT COUNT(*) FROM plat.Module")) {
            assertThat(rs.next()).isTrue();
            assertThat(rs.getInt(1)).isZero();
        }

        // 3) 设置租户上下文后可读到该租户的元数据，切换租户即隔离
        try (var con = dataSource.getConnection();
             var st = con.createStatement()) {
            st.execute("EXEC sys.sp_set_session_context N'TenantId', 1");
            try (var rs = st.executeQuery("SELECT COUNT(*) FROM plat.Module")) {
                assertThat(rs.next()).isTrue();
                assertThat(rs.getInt(1)).isGreaterThan(0);
            }
            st.execute("EXEC sys.sp_set_session_context N'TenantId', 2");
            try (var rs = st.executeQuery("SELECT COUNT(*) FROM plat.Module")) {
                assertThat(rs.next()).isTrue();
                assertThat(rs.getInt(1)).isZero();
            }
        }
    }
}

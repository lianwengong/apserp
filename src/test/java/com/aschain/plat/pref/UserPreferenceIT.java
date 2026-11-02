package com.aschain.plat.pref;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.aschain.common.ApiException;
import com.aschain.common.tenant.TenantContext;
import com.aschain.support.ItDb;
import java.util.Map;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

/**
 * 用户偏好集成测试：同一用户同键只一行、不同用户/租户隔离、键与大小校验、软删。
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class UserPreferenceIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    UserPreferenceService service;

    @Autowired
    JdbcTemplate jdbc;

    private static final long USER_A = 900_001L;
    private static final long USER_B = 900_002L;

    @BeforeEach
    void setUp() {
        TenantContext.set(1L, USER_A, true);
        cleanUp();
    }

    @AfterEach
    void tearDown() {
        cleanUp();
        TenantContext.clear();
    }

    private void cleanUp() {
        jdbc.update("DELETE FROM plat.UserPreference WHERE UserId IN (?, ?)", USER_A, USER_B);
    }

    @Test
    @DisplayName("写入后可读回；同键再写是更新而不是新增一行")
    void save_and_update() {
        service.save("appearance", "{\"theme\":\"rose\"}");
        assertThat(service.get("appearance")).isEqualTo("{\"theme\":\"rose\"}");

        service.save("appearance", "{\"theme\":\"cyber\"}");
        assertThat(service.get("appearance")).isEqualTo("{\"theme\":\"cyber\"}");
        Integer rows = jdbc.queryForObject(
                "SELECT COUNT(*) FROM plat.UserPreference WHERE UserId = ?", Integer.class, USER_A);
        assertThat(rows).isEqualTo(1);
    }

    @Test
    @DisplayName("all() 返回该用户全部键；不同用户互不可见")
    void isolation_between_users() {
        service.save("appearance", "{\"theme\":\"rose\"}");
        service.save("workbench", "{\"layout\":\"split\"}");
        Map<String, String> mine = service.all();
        assertThat(mine).containsKeys("appearance", "workbench");

        // 切到另一个用户：看不到上面的键
        TenantContext.set(1L, USER_B, true);
        assertThat(service.all()).isEmpty();
        assertThat(service.get("appearance")).isNull();

        service.save("appearance", "{\"theme\":\"emerald\"}");
        assertThat(service.get("appearance")).isEqualTo("{\"theme\":\"emerald\"}");

        TenantContext.set(1L, USER_A, true);
        assertThat(service.get("appearance")).isEqualTo("{\"theme\":\"rose\"}");
    }

    @Test
    @DisplayName("删除是软删：读不到，但留痕；删完再存是新增")
    void delete_is_soft() {
        service.save("appearance", "{\"theme\":\"rose\"}");
        service.delete("appearance");
        assertThat(service.get("appearance")).isNull();

        Integer deleted = jdbc.queryForObject(
                "SELECT COUNT(*) FROM plat.UserPreference WHERE UserId = ? AND IsDeleted = 1",
                Integer.class, USER_A);
        assertThat(deleted).isEqualTo(1);

        service.save("appearance", "{\"theme\":\"sand\"}");
        assertThat(service.get("appearance")).isEqualTo("{\"theme\":\"sand\"}");
        Integer active = jdbc.queryForObject(
                "SELECT COUNT(*) FROM plat.UserPreference WHERE UserId = ? AND IsDeleted = 0",
                Integer.class, USER_A);
        assertThat(active).isEqualTo(1);
    }

    @Test
    @DisplayName("键必须是合法标识符，值不能超过 64KB")
    void validation() {
        assertThatThrownBy(() -> service.save("Bad Key", "{}"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("偏好键");
        assertThatThrownBy(() -> service.save("appearance[0]", "{}"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("偏好键");
        assertThatThrownBy(() -> service.save("appearance", "x".repeat(64 * 1024 + 1)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("64KB");
    }

    @Test
    @DisplayName("未登录读写被拒绝")
    void requires_login() {
        TenantContext.clear();
        assertThatThrownBy(() -> service.get("appearance"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("未登录");
    }
}

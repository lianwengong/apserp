package com.aschain.plat.menu;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.aschain.common.ApiException;
import com.aschain.common.security.PasswordHasher;
import com.aschain.common.tenant.TenantContext;
import com.aschain.plat.auth.AuthService;
import com.aschain.support.ItDb;
import java.util.List;
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
 * 双入口（平台管理 / 业务管理）集成测试：
 * 登录时选择入口、入口准入校验、菜单树按入口彻底分开。
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class AppEntryIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    AuthService authService;

    @Autowired
    MenuService menuService;

    @Autowired
    PasswordHasher hasher;

    @Autowired
    JdbcTemplate jdbc;

    private static final String PLAIN_USER = "it_entry_user";
    private static final String PASSWORD = "AsChain@2026";

    @BeforeEach
    void setUp() {
        // 清库/建用户都要先有租户上下文，否则 RLS 会把它们过滤掉（删除 0 行、插入重复键）
        TenantContext.set(1L, 1L, true);
        cleanUp();
        String salt = hasher.newSalt();
        jdbc.update("""
                INSERT plat.[User] (TenantId, UserName, PasswordHash, PasswordSalt, DisplayName,
                                    UserType, IsEnabled, MustChangePwd, CreatedAt)
                VALUES (1, ?, ?, ?, N'入口测试用户', 1, 1, 0, sysutcdatetime())
                """, PLAIN_USER, hasher.hash(PASSWORD, salt), salt);
        TenantContext.clear();
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
        cleanUp();
    }

    private void cleanUp() {
        jdbc.update("DELETE FROM plat.[User] WHERE UserName = ?", PLAIN_USER);
    }

    @Test
    @DisplayName("管理员可以从平台管理入口登录，令牌记住入口=1")
    void admin_can_enter_platform() {
        AuthService.LoginResult result = authService.login("T001", "admin", PASSWORD,
                TenantContext.APP_PLATFORM);
        assertThat(result.appType()).isEqualTo(TenantContext.APP_PLATFORM);
        assertThat(result.token()).isNotBlank();
    }

    @Test
    @DisplayName("管理员也可以从业务管理入口登录，入口=2")
    void admin_can_enter_business() {
        AuthService.LoginResult result = authService.login("T001", "admin", PASSWORD,
                TenantContext.APP_BUSINESS);
        assertThat(result.appType()).isEqualTo(TenantContext.APP_BUSINESS);
    }

    @Test
    @DisplayName("普通账号不能从平台管理入口登录，但能进业务管理")
    void plain_user_blocked_from_platform() {
        assertThatThrownBy(() -> authService.login("T001", PLAIN_USER, PASSWORD,
                TenantContext.APP_PLATFORM))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("平台管理入口");

        AuthService.LoginResult business = authService.login("T001", PLAIN_USER, PASSWORD,
                TenantContext.APP_BUSINESS);
        assertThat(business.appType()).isEqualTo(TenantContext.APP_BUSINESS);
    }

    @Test
    @DisplayName("非法入口值被拒绝")
    void invalid_app_type_rejected() {
        assertThatThrownBy(() -> authService.login("T001", "admin", PASSWORD, 3))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("入口");
    }

    @Test
    @DisplayName("菜单树按入口彻底分开：平台只有 90 子树，业务没有 90")
    void menu_tree_is_split_by_app() {
        TenantContext.set(1L, 1L, true, TenantContext.APP_PLATFORM);
        List<MenuService.MenuNode> platform = menuService.tree(1, TenantContext.APP_PLATFORM);
        assertThat(platform).isNotEmpty();
        assertThat(platform).extracting(MenuService.MenuNode::code).containsOnly("90");
        int platformTotal = count(platform);
        assertThat(platformTotal).isGreaterThan(20);

        TenantContext.set(1L, 1L, true, TenantContext.APP_BUSINESS);
        List<MenuService.MenuNode> business = menuService.tree(1, TenantContext.APP_BUSINESS);
        assertThat(business).isNotEmpty();
        assertThat(business).extracting(MenuService.MenuNode::code)
                .doesNotContain("90")
                .contains("01");
        assertThat(business.stream().flatMap(node -> node.children().stream())
                .map(MenuService.MenuNode::code)).doesNotContain("9003");
    }

    private static int count(List<MenuService.MenuNode> nodes) {
        int total = 0;
        for (MenuService.MenuNode node : nodes) {
            total += 1 + count(node.children());
        }
        return total;
    }
}

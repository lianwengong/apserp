package com.aschain.plat.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.aschain.common.ApiException;
import com.aschain.common.security.JwtService;
import com.aschain.common.tenant.TenantContext;
import com.aschain.plat.auth.AuthService;
import com.aschain.support.ItDb;
import io.jsonwebtoken.Claims;
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
 * 平台账号管理：<b>只包含平台账号</b>，租户账号不在这里出现。
 *
 * <p>覆盖：新增、列表隔离（租户账号不出现）、启停（含不能停自己）、重置口令、
 * 拒绝操作租户账号、租户会话 403。</p>
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class PlatformUserIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    private static final String ACCOUNT = "it_ops_account";
    private static final String PASSWORD = "Ops@2026aaa";
    private static final String NEW_PASSWORD = "Ops@2026bbb";

    @Autowired
    PlatformUserService platformUser;

    @Autowired
    AuthService authService;

    @Autowired
    JwtService jwtService;

    @Autowired
    JdbcTemplate jdbc;

    private long accountId;

    @BeforeEach
    void setUp() {
        platformContext();
        jdbc.update("DELETE FROM plat.Notification WHERE RecipientId IN "
                + "(SELECT Id FROM plat.[User] WHERE UserName = ?)", ACCOUNT);
        jdbc.update("DELETE ur FROM plat.UserRole ur JOIN plat.[User] u ON u.Id = ur.UserId "
                + "WHERE u.UserName = ?", ACCOUNT);
        jdbc.update("DELETE FROM plat.[User] WHERE UserName = ?", ACCOUNT);
        PlatformUserService.UserRow created = platformUser.create(
                new PlatformUserService.CreateRequest(ACCOUNT, "测试平台账号", PASSWORD));
        accountId = created.id();
    }

    @AfterEach
    void tearDown() {
        platformContext();
        try {
            jdbc.update("UPDATE plat.[User] SET IsEnabled = 0, IsDeleted = 1 WHERE UserName = ?", ACCOUNT);
        } finally {
            TenantContext.clear();
        }
    }

    private void platformContext() {
        AuthService.LoginResult login = authService.loginPlatform("platadmin", "AsChain@2026");
        Claims claims = jwtService.parse(login.token());
        TenantContext.set(((Number) claims.get(JwtService.CLAIM_TENANT)).longValue(),
                ((Number) claims.get(JwtService.CLAIM_USER)).longValue(),
                true, TenantContext.APP_PLATFORM,
                Boolean.TRUE.equals(claims.get(JwtService.CLAIM_PLATFORM)));
    }

    @Test
    @DisplayName("列表只含平台账号：租户账号一个都不出现")
    void list_contains_only_platform_accounts() {
        List<PlatformUserService.UserRow> rows = platformUser.list(null);
        assertThat(rows).extracting(PlatformUserService.UserRow::userName)
                .contains("platadmin", ACCOUNT)
                .doesNotContain("admin", "wh01");

        assertThat(platformUser.list(ACCOUNT)).hasSize(1);
    }

    @Test
    @DisplayName("新增平台账号：能登录平台入口，首次登录要求改密")
    void created_account_can_login_platform() {
        var login = authService.loginPlatform(ACCOUNT, PASSWORD);
        assertThat(login.appType()).isEqualTo(TenantContext.APP_PLATFORM);
        assertThat(login.mustChangePassword()).isTrue();
    }

    @Test
    @DisplayName("停用后不能登录平台入口，启用后恢复")
    void disable_and_enable_account() {
        platformUser.setEnabled(accountId, false);
        assertThatThrownBy(() -> authService.loginPlatform(ACCOUNT, PASSWORD))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("停用");

        platformContext();
        platformUser.setEnabled(accountId, true);
        assertThat(authService.loginPlatform(ACCOUNT, PASSWORD).userId()).isEqualTo(accountId);
    }

    @Test
    @DisplayName("重置口令：新口令可登录且强制改密，旧口令失效")
    void reset_password() {
        platformUser.resetPassword(accountId, NEW_PASSWORD);

        var login = authService.loginPlatform(ACCOUNT, NEW_PASSWORD);
        assertThat(login.mustChangePassword()).isTrue();
        assertThatThrownBy(() -> authService.loginPlatform(ACCOUNT, PASSWORD))
                .isInstanceOf(ApiException.class);
    }

    @Test
    @DisplayName("不能停用自己；不能操作租户账号；租户会话不能调平台账号接口")
    void guards() {
        assertThatThrownBy(() -> platformUser.setEnabled(TenantContext.userId(), false))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("自己");

        // 租户管理员（T001 admin）不是平台账号，不允许在这里被操作
        Long tenantAdminId = jdbc.queryForObject("""
                SELECT Id FROM plat.[User] WHERE TenantId = 1 AND UserName = 'admin' AND IsDeleted = 0
                """, Long.class);
        assertThatThrownBy(() -> platformUser.setEnabled(tenantAdminId, false))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("业务租户");

        // 业务会话调用平台账号接口 → 403
        AuthService.LoginResult business = authService.login("T001", "admin", "AsChain@2026");
        Claims claims = jwtService.parse(business.token());
        TenantContext.set(((Number) claims.get(JwtService.CLAIM_TENANT)).longValue(),
                ((Number) claims.get(JwtService.CLAIM_USER)).longValue(),
                Boolean.TRUE.equals(claims.get(JwtService.CLAIM_ADMIN)),
                TenantContext.APP_BUSINESS,
                Boolean.TRUE.equals(claims.get(JwtService.CLAIM_PLATFORM)));
        assertThatThrownBy(() -> platformUser.list(null))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("平台登录");
    }

    @Test
    @DisplayName("账号名与口令校验")
    void create_validates_input() {
        assertThatThrownBy(() -> platformUser.create(
                new PlatformUserService.CreateRequest("1bad", "x", PASSWORD)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("平台账号");
        assertThatThrownBy(() -> platformUser.create(
                new PlatformUserService.CreateRequest(ACCOUNT, "重复", PASSWORD)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("已存在");
        assertThatThrownBy(() -> platformUser.create(
                new PlatformUserService.CreateRequest("it_ops_weak", "弱口令", "12345678")))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("字母与数字");
    }
}

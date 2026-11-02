package com.aschain.plat.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.aschain.common.ApiException;
import com.aschain.common.ErrorCode;
import com.aschain.common.security.JwtService;
import com.aschain.support.ItDb;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

/**
 * 登录认证集成测试。
 *
 * <p>特别覆盖"普通内部角色不得拿到平台管理员标记"——这是一条越权红线：
 * 曾经用 RoleType=1 判定管理员，导致仓管/采购全部成为 adm，已修复并在此锁定。</p>
 */
@SpringBootTest
@EnabledIfSystemProperty(named = "it.db", matches = "true")
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
class AuthIT {

    private static final String PLAIN_USER = "it_plain_user";

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    private AuthService authService;

    @Autowired
    private JwtService jwtService;

    @BeforeEach
    void prepare() throws Exception {
        try (Connection con = connect(); Statement st = con.createStatement()) {
            st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
            st.executeUpdate("UPDATE plat.[User] SET FailCount = 0, LockedUntil = NULL, MustChangePwd = 1 WHERE UserName = 'admin'");
            st.executeUpdate("DELETE FROM plat.UserRole WHERE UserId IN "
                    + "(SELECT Id FROM plat.[User] WHERE UserName = '" + PLAIN_USER + "')");
            st.executeUpdate("DELETE FROM plat.[User] WHERE UserName = '" + PLAIN_USER + "'");
            st.executeUpdate("INSERT INTO plat.[User] (TenantId, UserName, PasswordHash, PasswordSalt, "
                    + "DisplayName, UserType, IsEnabled, FailCount, IsDeleted) VALUES (1, '" + PLAIN_USER
                    + "', 'aAFYmgxZqeEZfVb3BWklksetxQAOT8C8wpG0hWkm1x0=', "
                    + "'Aeeawby1MJ/B1WVLHguAIw==', N'普通用户', 2, 1, 0, 0)");
            st.executeUpdate("INSERT INTO plat.UserRole (TenantId, UserId, RoleId, OrgId) "
                    + "SELECT 1, u.Id, r.Id, NULL FROM plat.[User] u JOIN plat.Role r "
                    + "ON r.TenantId = 1 AND r.Code = 'WH' WHERE u.UserName = '" + PLAIN_USER + "'");
        }
    }

    @AfterEach
    void cleanup() throws Exception {
        try (Connection con = connect(); Statement st = con.createStatement()) {
            st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
            st.executeUpdate("DELETE FROM plat.UserRole WHERE UserId IN "
                    + "(SELECT Id FROM plat.[User] WHERE UserName = '" + PLAIN_USER + "')");
            st.executeUpdate("DELETE FROM plat.[User] WHERE UserName = '" + PLAIN_USER + "'");
        }
    }

    @Test
    void admin_login_should_issue_platform_admin_token() {
        var result = authService.login("T001", "admin", "AsChain@2026");
        assertThat(result.token()).isNotBlank();
        assertThat(result.mustChangePassword()).isTrue();
        var claims = jwtService.parse(result.token());
        assertThat(claims.get(JwtService.CLAIM_ADMIN)).isEqualTo(true);
    }

    @Test
    void plain_internal_role_must_not_be_platform_admin() {
        var result = authService.login("T001", PLAIN_USER, "AsChain@2026");
        var claims = jwtService.parse(result.token());
        assertThat(claims.get(JwtService.CLAIM_ADMIN))
                .as("仓管等内部角色绝不能带平台管理员标记")
                .isEqualTo(false);
    }

    @Test
    void wrong_password_should_be_rejected_without_revealing_which_field() {
        assertThatThrownBy(() -> authService.login("T001", "admin", "wrong-password"))
                .isInstanceOf(ApiException.class)
                .hasMessage("租户或账号或口令不正确")
                .extracting(e -> ((ApiException) e).getCode())
                .isEqualTo(ErrorCode.UNAUTHORIZED);
    }

    @Test
    void unknown_tenant_should_return_same_message() {
        assertThatThrownBy(() -> authService.login("NO_SUCH_TENANT", "admin", "x"))
                .isInstanceOf(ApiException.class)
                .hasMessage("租户或账号或口令不正确");
    }

    private Connection connect() throws Exception {
        return DriverManager.getConnection(ItDb.url(), ItDb.user(), ItDb.password());
    }
}

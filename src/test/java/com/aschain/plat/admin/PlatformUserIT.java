package com.aschain.plat.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.aschain.common.ApiException;
import com.aschain.common.security.JwtService;
import com.aschain.common.security.PasswordHasher;
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
 * 平台入口：跨租户用户与权限管理。
 *
 * <p>覆盖：跨租户列表、启停、重置口令（强制改密）、分配角色（同租户校验）、
 * 不能停用自己、租户会话一律 403。</p>
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

    private static final String USER = "it_platform_user";
    private static final String PASSWORD = "User@2026a";
    private static final String NEW_PASSWORD = "User@2026b";

    @Autowired
    PlatformUserService platformUser;

    @Autowired
    AuthService authService;

    @Autowired
    JwtService jwtService;

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    PasswordHasher hasher;

    private long userId;

    @BeforeEach
    void setUp() {
        platformContext();
        jdbc.update("DELETE n FROM plat.Notification n JOIN plat.[User] u ON u.Id = n.RecipientId "
                + "WHERE u.UserName = ?", USER);
        jdbc.update("DELETE ur FROM plat.UserRole ur JOIN plat.[User] u ON u.Id = ur.UserId "
                + "WHERE u.UserName = ?", USER);
        jdbc.update("DELETE FROM plat.[User] WHERE UserName = ?", USER);
        String salt = hasher.newSalt();
        jdbc.update("""
                INSERT plat.[User] (TenantId, UserName, PasswordHash, PasswordSalt, DisplayName,
                                    UserType, IsEnabled, MustChangePwd, IsDeleted, CreatedAt)
                VALUES (1, ?, ?, ?, N'平台用户测试', 1, 1, 0, 0, sysutcdatetime())
                """, USER, hasher.hash(PASSWORD, salt), salt);
        userId = jdbc.queryForObject("SELECT Id FROM plat.[User] WHERE UserName = ?", Long.class, USER);
    }

    @AfterEach
    void tearDown() {
        platformContext();
        try {
            jdbc.update("DELETE ur FROM plat.UserRole ur JOIN plat.[User] u ON u.Id = ur.UserId "
                    + "WHERE u.UserName = ?", USER);
            jdbc.update("UPDATE plat.[User] SET IsEnabled = 0, IsDeleted = 1 WHERE UserName = ?", USER);
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
    @DisplayName("跨租户用户列表：能搜到别的租户的账号，并带角色")
    void list_users_across_tenants() {
        PlatformUserService.PageResult all = platformUser.list(null, null, 1, 200);
        assertThat(all.total()).isGreaterThanOrEqualTo(2);
        assertThat(all.items()).extracting(PlatformUserService.UserRow::tenantId).contains(1L);
        assertThat(all.items()).anySatisfy(u -> {
            assertThat(u.userName()).isEqualTo(USER);
            assertThat(u.tenantCode()).isEqualTo("T001");
        });
        assertThat(all.items().stream().filter(u -> "admin".equals(u.userName())).findFirst())
                .hasValueSatisfying(u -> assertThat(u.roles()).contains("SYSADMIN"));

        // 按租户过滤：RLS 旁路生效，查别的租户不会报错（T002 目前没有登录用户）
        PlatformUserService.PageResult tenantTwo = platformUser.list(null, 2L, 1, 20);
        assertThat(tenantTwo.items()).allMatch(u -> u.tenantId() == 2L);

        PlatformUserService.PageResult filtered = platformUser.list(USER, null, 1, 20);
        assertThat(filtered.total()).isEqualTo(1);
        assertThat(filtered.items().get(0).id()).isEqualTo(userId);
    }

    @Test
    @DisplayName("停用后不能登录，启用后恢复")
    void disable_and_enable_user() {
        platformUser.setEnabled(userId, false);
        assertThatThrownBy(() -> authService.login("T001", USER, PASSWORD))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("账号已停用");

        // login() 的 finally 会清空上下文，这里要重新建立平台会话再继续操作
        platformContext();
        platformUser.setEnabled(userId, true);
        assertThat(authService.login("T001", USER, PASSWORD).userId()).isEqualTo(userId);
    }

    @Test
    @DisplayName("重置口令：新口令可登录且强制改密，旧口令失效")
    void reset_password() {
        platformUser.resetPassword(userId, NEW_PASSWORD);

        AuthService.LoginResult login = authService.login("T001", USER, NEW_PASSWORD);
        assertThat(login.mustChangePassword()).isTrue();
        assertThatThrownBy(() -> authService.login("T001", USER, PASSWORD))
                .isInstanceOf(ApiException.class);
    }

    @Test
    @DisplayName("分配角色：覆盖式写入，跨租户角色被拒")
    void assign_roles() {
        List<PlatformUserService.RoleDto> tenantRoles = platformUser.roles(1L);
        assertThat(tenantRoles).isNotEmpty();
        long roleId = tenantRoles.stream().filter(r -> "WH".equals(r.code())).findFirst()
                .orElse(tenantRoles.get(0)).id();

        platformUser.setRoles(userId, List.of(roleId));
        assertThat(platformUser.list(USER, null, 1, 10).items().get(0).roles()).isNotEmpty();

        List<PlatformUserService.RoleDto> otherTenantRoles = platformUser.roles(2L);
        if (!otherTenantRoles.isEmpty()) {
            long foreignRole = otherTenantRoles.get(0).id();
            assertThatThrownBy(() -> platformUser.setRoles(userId, List.of(foreignRole)))
                    .isInstanceOf(ApiException.class)
                    .hasMessageContaining("不属于该用户所在租户");
        }
    }

    @Test
    @DisplayName("不能停用/改自己；租户会话不能调用平台用户接口")
    void guards() {
        Long self = TenantContext.userId();
        assertThatThrownBy(() -> platformUser.setEnabled(self, false))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("自己");
        assertThatThrownBy(() -> platformUser.setRoles(self, List.of()))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("自己的角色");

        // 切到业务会话：所有平台用户接口都应 403
        AuthService.LoginResult business = authService.login("T001", "admin", "AsChain@2026");
        Claims claims = jwtService.parse(business.token());
        TenantContext.set(((Number) claims.get(JwtService.CLAIM_TENANT)).longValue(),
                ((Number) claims.get(JwtService.CLAIM_USER)).longValue(),
                Boolean.TRUE.equals(claims.get(JwtService.CLAIM_ADMIN)),
                TenantContext.APP_BUSINESS,
                Boolean.TRUE.equals(claims.get(JwtService.CLAIM_PLATFORM)));
        assertThatThrownBy(() -> platformUser.list(null, null, 1, 10))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("平台登录");
    }
}

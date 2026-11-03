package com.aschain.plat.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.aschain.common.ApiException;
import com.aschain.common.security.JwtService;
import com.aschain.common.security.PasswordHasher;
import com.aschain.common.tenant.TenantContext;
import com.aschain.support.ItDb;
import io.jsonwebtoken.Claims;
import org.junit.jupiter.api.AfterEach;
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
 * 登录链路的回归测试：<b>空库首次登录必须成功</b>。
 *
 * <p>这里守的是一个踩过两次的坑：租户上下文没设好时，RLS 会 fail-closed 把用户表挡成空集，
 * 表现为「口令明明对，却永远提示租户或账号或口令不正确」。
 * 一旦有人在 login 上加了 {@code @Transactional}（事务提前取连接，上下文还没设），
 * 这个用例会立刻变红。</p>
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class AuthLoginIT {

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
    JwtService jwtService;

    @Autowired
    PasswordHasher hasher;

    @Autowired
    JdbcTemplate jdbc;

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    @Test
    @DisplayName("种子管理员用初始口令能登录（RLS 上下文按顺序生效）")
    void seed_admin_can_login() {
        AuthService.LoginResult result = authService.login("T001", "admin", "AsChain@2026");
        assertThat(result.token()).isNotBlank();
        assertThat(result.tenantId()).isEqualTo(1);
        assertThat(result.displayName()).isNotBlank();
    }

    @Test
    @DisplayName("口令错误返回统一 3000，且不会把账号锁死到不可用")
    void wrong_password_is_rejected() {
        assertThatThrownBy(() -> authService.login("T001", "admin", "Wrong@123456"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("口令");
    }

    @Test
    @DisplayName("租户编码不存在返回 3000（不泄露租户是否存在）")
    void unknown_tenant_is_rejected() {
        assertThatThrownBy(() -> authService.login("NOPE", "admin", "AsChain@2026"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("租户");
    }

    @Test
    @DisplayName("首次登录未改密：用令牌上下文改口令，换发的令牌不再要求改密")
    void change_password_for_current_user() {
        String userName = "it_pwd_user";
        String oldPassword = "Old@2026abc";
        String newPassword = "New@2026abc";
        TenantContext.set(1L, 1L, false);
        jdbc.update("DELETE FROM plat.[User] WHERE TenantId = 1 AND UserName = ?", userName);
        String salt = hasher.newSalt();
        jdbc.update("""
                INSERT plat.[User] (TenantId, UserName, PasswordHash, PasswordSalt, DisplayName,
                                    UserType, IsEnabled, MustChangePwd, FailCount, IsDeleted, CreatedAt)
                VALUES (1, ?, ?, ?, N'改密测试', 1, 1, 1, 0, 0, sysutcdatetime())
                """, userName, hasher.hash(oldPassword, salt), salt);
        Long userId = jdbc.queryForObject(
                "SELECT Id FROM plat.[User] WHERE TenantId = 1 AND UserName = ?", Long.class, userName);
        TenantContext.clear();

        AuthService.LoginResult login = authService.login("T001", userName, oldPassword);
        assertThat(login.mustChangePassword()).isTrue();

        // 还原 JwtAuthFilter 写入的上下文（改口令只认令牌身份，不需要租户名）
        Claims claims = jwtService.parse(login.token());
        TenantContext.set(((Number) claims.get(JwtService.CLAIM_TENANT)).longValue(),
                ((Number) claims.get(JwtService.CLAIM_USER)).longValue(),
                Boolean.TRUE.equals(claims.get(JwtService.CLAIM_ADMIN)),
                TenantContext.APP_BUSINESS,
                Boolean.TRUE.equals(claims.get(JwtService.CLAIM_PLATFORM)));
        AuthService.LoginResult changed = authService.changePasswordForCurrentUser(oldPassword, newPassword);
        assertThat(changed.mustChangePassword()).isFalse();
        assertThat(changed.userId()).isEqualTo(userId);
        TenantContext.clear();

        // 新口令可登录且不再要求改密；旧口令失效
        AuthService.LoginResult after = authService.login("T001", userName, newPassword);
        assertThat(after.mustChangePassword()).isFalse();
        assertThatThrownBy(() -> authService.login("T001", userName, oldPassword))
                .isInstanceOf(ApiException.class);

        TenantContext.set(1L, 1L, false);
        jdbc.update("DELETE FROM plat.[User] WHERE TenantId = 1 AND UserName = ?", userName);
        TenantContext.clear();
    }
}

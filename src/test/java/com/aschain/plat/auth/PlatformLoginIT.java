package com.aschain.plat.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.aschain.common.ApiException;
import com.aschain.common.security.JwtService;
import com.aschain.common.tenant.TenantContext;
import com.aschain.plat.admin.PlatformAdminService;
import com.aschain.support.ItDb;
import io.jsonwebtoken.Claims;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

/**
 * 平台登录（无租户名）集成测试。
 *
 * <p>两条约束要同时成立：</p>
 * <ul>
 *   <li>平台登录只需要账号+口令，令牌带平台作用域，能列出所有租户；</li>
 *   <li>普通租户账号不能走平台登录（否则等于绕过租户隔离）。</li>
 * </ul>
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class PlatformLoginIT {

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
    PlatformAdminService platformAdminService;

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    @Test
    @DisplayName("平台登录不需要租户名，令牌带平台作用域")
    void platform_login_without_tenant() {
        AuthService.LoginResult result = authService.loginPlatform("platadmin", "AsChain@2026");
        assertThat(result.appType()).isEqualTo(TenantContext.APP_PLATFORM);
        assertThat(result.token()).isNotBlank();

        Claims claims = jwtService.parse(result.token());
        assertThat(claims.get(JwtService.CLAIM_APP)).isEqualTo(TenantContext.APP_PLATFORM);
        assertThat(claims.get(JwtService.CLAIM_PLATFORM)).isEqualTo(true);
    }

    @Test
    @DisplayName("平台会话能看到所有租户（RLS 旁路）")
    void platform_session_sees_all_tenants() {
        AuthService.LoginResult result = authService.loginPlatform("platadmin", "AsChain@2026");
        Claims claims = jwtService.parse(result.token());
        int homeTenant = ((Number) claims.get(JwtService.CLAIM_TENANT)).intValue();
        boolean scope = Boolean.TRUE.equals(claims.get(JwtService.CLAIM_PLATFORM));

        // 还原 JwtAuthFilter 的上下文写法
        TenantContext.set((long) homeTenant,
                ((Number) claims.get(JwtService.CLAIM_USER)).longValue(),
                Boolean.TRUE.equals(claims.get(JwtService.CLAIM_ADMIN)),
                TenantContext.APP_PLATFORM, scope);

        var tenants = platformAdminService.tenants();
        assertThat(tenants).hasSizeGreaterThanOrEqualTo(1);
        assertThat(tenants).extracting(PlatformAdminService.TenantDto::code).contains("T001");
    }

    @Test
    @DisplayName("普通租户账号不能走平台登录")
    void tenant_account_cannot_use_platform_login() {
        assertThatThrownBy(() -> authService.loginPlatform("wh01", "AsChain@2026"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("平台账号");
    }

    @Test
    @DisplayName("平台登录口令错误统一提示，不区分账号是否存在")
    void platform_login_wrong_password() {
        assertThatThrownBy(() -> authService.loginPlatform("platadmin", "Wrong@123456"))
                .isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> authService.loginPlatform("no_such_platform_user", "AsChain@2026"))
                .isInstanceOf(ApiException.class);
    }

    @Test
    @DisplayName("租户登录的管理员不能访问平台管理接口（没有平台作用域）")
    void tenant_admin_cannot_reach_platform_admin() {
        AuthService.LoginResult router = authService.login("T001", "admin", "AsChain@2026");
        Claims claims = jwtService.parse(router.token());
        TenantContext.set(((Number) claims.get(JwtService.CLAIM_TENANT)).longValue(),
                ((Number) claims.get(JwtService.CLAIM_USER)).longValue(),
                Boolean.TRUE.equals(claims.get(JwtService.CLAIM_ADMIN)),
                TenantContext.APP_BUSINESS,
                Boolean.TRUE.equals(claims.get(JwtService.CLAIM_PLATFORM)));

        assertThatThrownBy(() -> platformAdminService.tenants())
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("平台管理员");
    }

    @Test
    @DisplayName("租户登录可以填租户名称，也可以填编码")
    void tenant_login_accepts_name_or_code() {
        AuthService.LoginResult byCode = authService.login("T001", "admin", "AsChain@2026");
        assertThat(byCode.tenantId()).isEqualTo(1);
        AuthService.LoginResult byName = authService.login("示例商贸有限公司", "admin", "AsChain@2026");
        assertThat(byName.tenantId()).isEqualTo(1);
    }

    @Test
    @DisplayName("租户登录仍然必须带租户名")
    void tenant_login_still_requires_tenant() {
        assertThatThrownBy(() -> authService.login(null, "admin", "AsChain@2026"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("租户");
        AuthService.LoginResult ok = authService.login("T001", "admin", "AsChain@2026");
        assertThat(ok.appType()).isEqualTo(TenantContext.APP_BUSINESS);
    }
}

package com.apserp.plat.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.apserp.common.ApiException;
import com.apserp.common.tenant.TenantContext;
import com.apserp.support.ItDb;
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

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    @Test
    @DisplayName("种子管理员用初始口令能登录（RLS 上下文按顺序生效）")
    void seed_admin_can_login() {
        AuthService.LoginResult result = authService.login("T001", "admin", "Apserp@2026");
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
        assertThatThrownBy(() -> authService.login("NOPE", "admin", "Apserp@2026"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("租户");
    }
}

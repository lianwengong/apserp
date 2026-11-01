package com.apserp.plat.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.support.ItDb;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

/**
 * 登录认证集成测试。
 *
 * <p>只验证认证链路本身；锁定策略（连续 5 次失败）不在这里测，
 * 因为会把开发库的 admin 锁住，影响后续调试。</p>
 */
@SpringBootTest
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class AuthIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    private AuthService authService;

    @BeforeEach
    void resetLockState() throws Exception {
        try (Connection con = DriverManager.getConnection(ItDb.url(), ItDb.user(), ItDb.password());
             Statement st = con.createStatement()) {
            st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
            st.executeUpdate("UPDATE plat.[User] SET FailCount = 0, LockedUntil = NULL WHERE UserName = 'admin'");
        }
    }

    @Test
    void login_with_correct_password_should_issue_token() {
        var result = authService.login("T001", "admin", "Apserp@2026");
        assertThat(result.token()).isNotBlank();
        assertThat(result.tenantId()).isPositive();
        assertThat(result.mustChangePassword()).isTrue();
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
}

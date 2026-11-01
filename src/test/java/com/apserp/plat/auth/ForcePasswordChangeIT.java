package com.apserp.plat.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.apserp.common.ApiException;
import com.apserp.support.ItDb;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

/**
 * 强制改密：未改密前除改密接口外一律拒绝。
 */
@SpringBootTest
@AutoConfigureMockMvc
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class ForcePasswordChangeIT {

    private static final String PWD = "Apserp@2026";

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
    private MockMvc mockMvc;

    @BeforeEach
    void forceFlagOn() throws Exception {
        try (Connection con = DriverManager.getConnection(ItDb.url(), ItDb.user(), ItDb.password());
             Statement st = con.createStatement()) {
            st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
            st.executeUpdate("UPDATE plat.[User] SET MustChangePwd = 1 WHERE UserName = 'admin'");
        }
    }

    @AfterEach
    void forceFlagOff() throws Exception {
        try (Connection con = DriverManager.getConnection(ItDb.url(), ItDb.user(), ItDb.password());
             Statement st = con.createStatement()) {
            st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
            st.executeUpdate("UPDATE plat.[User] SET MustChangePwd = 0 WHERE UserName = 'admin'");
        }
    }

    @Test
    void business_api_should_be_forbidden_before_change() throws Exception {
        var login = authService.login("T001", "admin", PWD);
        assertThat(login.mustChangePassword()).isTrue();

        mockMvc.perform(get("/api/meta/objects").header("Authorization", "Bearer " + login.token()))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value(3004));
    }

    @Test
    void weak_password_should_be_rejected() {
        assertThatThrownBy(() -> AuthService.validatePasswordPolicy("short1"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("8-64");
        assertThatThrownBy(() -> AuthService.validatePasswordPolicy("onlyletters"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("字母与数字");
        assertThatThrownBy(() -> AuthService.validatePasswordPolicy("12345678"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("字母与数字");
        AuthService.validatePasswordPolicy("Apserp@2027");
    }

    @Test
    void change_password_should_reissue_token() throws Exception {
        String newPwd = "Apserp@2027";
        try {
            var result = authService.changePassword("T001", "admin", PWD, newPwd);
            assertThat(result.mustChangePassword()).isFalse();

            mockMvc.perform(get("/api/meta/objects")
                            .header("Authorization", "Bearer " + result.token()))
                    .andExpect(status().isOk());
        } finally {
            // 恢复初始口令，避免污染开发库
            authService.changePassword("T001", "admin", newPwd, PWD);
        }
    }
}

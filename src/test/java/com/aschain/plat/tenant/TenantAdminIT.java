package com.aschain.plat.tenant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.aschain.common.ApiException;
import com.aschain.common.security.JwtService;
import com.aschain.common.tenant.TenantContext;
import com.aschain.plat.admin.PlatformAdminService;
import com.aschain.plat.auth.AuthService;
import com.aschain.support.ItDb;
import io.jsonwebtoken.Claims;
import java.time.LocalDateTime;
import java.util.List;
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
 * 租户开通 / 停用 集成测试。
 *
 * <p>开通不是「插一行租户」：要克隆模板租户的元数据（菜单/权限/角色/数据对象…），
 * 还要给新租户建一个能登录的管理员。停用是可逆操作：停用后登录被拒，启用后恢复。</p>
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class TenantAdminIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    private static final String PASSWORD = "AsChain@2026";
    private static final String ADMIN_PASSWORD = "Tenant@2026a";

    @Autowired
    TenantAdminService tenantAdmin;

    @Autowired
    AuthService authService;

    @Autowired
    JwtService jwtService;

    @Autowired
    PlatformAdminService platformAdminService;

    @Autowired
    JdbcTemplate jdbc;

    private String code;

    @BeforeEach
    void setUp() {
        // 每次跑用不同编码，避免与历史运行撞唯一键
        code = "IT" + LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("HHmmssSSS"));
        platformContext();
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
        // 测试租户只做「退役」不做物理删除：plat 下指向 Tenant 的外键有 731 条（业务表全挂 TenantId），
        // 逐表删既不现实也容易漏；标记删除 + 停用后，列表/登录都不再受它影响。
        // 测试库由 ci-local 每次重建，不会长期膨胀。
        platformContext();
        try {
            for (Long id : jdbc.queryForList(
                    "SELECT Id FROM plat.Tenant WHERE Code LIKE 'IT%' AND IsDeleted = 0", Long.class)) {
                jdbc.update("UPDATE plat.[User] SET IsEnabled = 0, IsDeleted = 1, "
                        + "ModifiedAt = sysutcdatetime() WHERE TenantId = ?", id);
                jdbc.update("UPDATE plat.Tenant SET IsEnabled = 0, IsDeleted = 1, "
                        + "ModifiedAt = sysutcdatetime() WHERE Id = ?", id);
            }
        } finally {
            TenantContext.clear();
        }
    }

    /** 还原 JwtAuthFilter 的平台上下文写法，避免测试里手写 set 时漏掉 pf。 */
    private void platformContext() {
        AuthService.LoginResult login = authService.loginPlatform("platadmin", PASSWORD);
        Claims claims = jwtService.parse(login.token());
        TenantContext.set(((Number) claims.get(JwtService.CLAIM_TENANT)).longValue(),
                ((Number) claims.get(JwtService.CLAIM_USER)).longValue(),
                true, TenantContext.APP_PLATFORM,
                Boolean.TRUE.equals(claims.get(JwtService.CLAIM_PLATFORM)));
    }

    @Test
    @DisplayName("开通租户：克隆元数据 + 建管理员，管理员能登录")
    void create_tenant_provisions_and_creates_admin() {
        TenantAdminService.CreateResult result = tenantAdmin.create(new TenantAdminService.CreateRequest(
                code, "集成测试租户", "测试租户", "批发", 1, "tadmin", ADMIN_PASSWORD, null));

        assertThat(result.tenantId()).isPositive();
        assertThat(result.provisioned()).containsKeys("Menu", "Module", "Permission", "Role");
        assertThat(result.provisioned().get("Menu")).isGreaterThan(100);

        // 平台列表里能看到，且默认启用
        assertThat(platformAdminService.tenants())
                .anySatisfy(t -> {
                    assertThat(t.code()).isEqualTo(code);
                    assertThat(t.enabled()).isTrue();
                });

        // 新管理员能登录业务入口（首次登录要求改密）
        AuthService.LoginResult login = authService.login(code, "tadmin", ADMIN_PASSWORD);
        assertThat(login.tenantId()).isEqualTo(result.tenantId());
        assertThat(login.mustChangePassword()).isTrue();
        assertThat(login.appType()).isEqualTo(TenantContext.APP_BUSINESS);
    }

    @Test
    @DisplayName("租户编码重复 / 非法 / 口令太弱都被拒绝")
    void create_validates_input() {
        tenantAdmin.create(new TenantAdminService.CreateRequest(
                code, "集成测试租户", null, null, 1, "tadmin", ADMIN_PASSWORD, null));

        assertThatThrownBy(() -> tenantAdmin.create(new TenantAdminService.CreateRequest(
                code.toLowerCase(), "重复", null, null, 1, "tadmin2", ADMIN_PASSWORD, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("已存在");

        assertThatThrownBy(() -> tenantAdmin.create(new TenantAdminService.CreateRequest(
                "1bad", "非法编码", null, null, 1, "tadmin3", ADMIN_PASSWORD, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("租户编码");

        assertThatThrownBy(() -> tenantAdmin.create(new TenantAdminService.CreateRequest(
                code + "X", "弱口令", null, null, 1, "tadmin4", "12345678", null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("字母与数字");
    }

    @Test
    @DisplayName("停用后该租户登录被拒，启用后恢复")
    void disable_then_enable_tenant() {
        TenantAdminService.CreateResult created = tenantAdmin.create(
                new TenantAdminService.CreateRequest(code, "可停用租户", null, null, 1, "tadmin",
                        ADMIN_PASSWORD, null));

        tenantAdmin.setEnabled(created.tenantId(), false);
        assertThatThrownBy(() -> authService.login(code, "tadmin", ADMIN_PASSWORD))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("租户已停用");

        tenantAdmin.setEnabled(created.tenantId(), true);
        assertThat(authService.login(code, "tadmin", ADMIN_PASSWORD).tenantId())
                .isEqualTo(created.tenantId());
    }

    @Test
    @DisplayName("平台账号与租户解绑：平台租户不可启停，业务租户可以正常停用")
    void platform_account_is_not_bound_to_a_tenant() {
        // 先开一个业务租户，保证不会命中「至少保留一个启用租户」的护栏
        TenantAdminService.CreateResult created = tenantAdmin.create(
                new TenantAdminService.CreateRequest(code, "解绑测试租户", null, null, 1, "tadmin",
                        ADMIN_PASSWORD, null));

        // 平台账号在平台租户（Id=0）里，停用 T001 不再有任何「所属租户」限制
        tenantAdmin.setEnabled(1L, false);
        platformContext();
        assertThatThrownBy(() -> authService.login("T001", "admin", PASSWORD))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("租户已停用");
        platformContext();
        tenantAdmin.setEnabled(1L, true);

        // 平台租户本身只承载平台账号，不参与启停
        assertThatThrownBy(() -> tenantAdmin.setEnabled(0L, false))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("平台租户");
        assertThat(created.tenantId()).isPositive();
    }

    @Test
    @DisplayName("租户会话不能开通/停用租户")
    void tenant_session_cannot_manage_tenants() {
        AuthService.LoginResult business = authService.login("T001", "admin", PASSWORD);
        Claims claims = jwtService.parse(business.token());
        TenantContext.set(((Number) claims.get(JwtService.CLAIM_TENANT)).longValue(),
                ((Number) claims.get(JwtService.CLAIM_USER)).longValue(),
                Boolean.TRUE.equals(claims.get(JwtService.CLAIM_ADMIN)),
                TenantContext.APP_BUSINESS,
                Boolean.TRUE.equals(claims.get(JwtService.CLAIM_PLATFORM)));

        assertThatThrownBy(() -> tenantAdmin.create(new TenantAdminService.CreateRequest(
                "ITDENIED", "不该建成", null, null, 1, "tadmin", ADMIN_PASSWORD, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("平台登录");
        assertThatThrownBy(() -> tenantAdmin.setEnabled(2L, false))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("平台登录");
    }
}

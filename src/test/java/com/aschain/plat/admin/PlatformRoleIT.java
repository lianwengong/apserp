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
 * 平台角色与权限：种子角色、权限勾选、成员分配，以及「无权限的平台账号」应被接口挡住。
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class PlatformRoleIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    private static final String ACCOUNT = "it_ops_role_user";
    private static final String PASSWORD = "OpsRole@2026a";
    private static final String ROLE_CODE = "IT_PLAT_AUDIT";

    @Autowired
    PlatformRoleService platformRoles;

    @Autowired
    PlatformUserService platformUsers;

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
        cleanUp();
        accountId = platformUsers.create(new PlatformUserService.CreateRequest(
                ACCOUNT, "角色测试账号", PASSWORD)).id();
    }

    @AfterEach
    void tearDown() {
        platformContext();
        try {
            cleanUp();
        } finally {
            TenantContext.clear();
        }
    }

    private void cleanUp() {
        jdbc.update("DELETE ur FROM plat.UserRole ur JOIN plat.[User] u ON u.Id = ur.UserId "
                + "WHERE u.UserName = ?", ACCOUNT);
        jdbc.update("DELETE rp FROM plat.RolePermission rp JOIN plat.Role r ON r.Id = rp.RoleId "
                + "WHERE r.TenantId = 0 AND r.Code = ?", ROLE_CODE);
        jdbc.update("DELETE FROM plat.Role WHERE TenantId = 0 AND Code = ?", ROLE_CODE);
        jdbc.update("DELETE FROM plat.Notification WHERE RecipientId IN "
                + "(SELECT Id FROM plat.[User] WHERE UserName = ?)", ACCOUNT);
        jdbc.update("DELETE FROM plat.[User] WHERE UserName = ?", ACCOUNT);
    }

    private void platformContext() {
        AuthService.LoginResult login = authService.loginPlatform("platadmin", "AsChain@2026");
        Claims claims = jwtService.parse(login.token());
        TenantContext.set(((Number) claims.get(JwtService.CLAIM_TENANT)).longValue(),
                ((Number) claims.get(JwtService.CLAIM_USER)).longValue(),
                Boolean.TRUE.equals(claims.get(JwtService.CLAIM_ADMIN)),
                TenantContext.APP_PLATFORM,
                Boolean.TRUE.equals(claims.get(JwtService.CLAIM_PLATFORM)));
    }

    @Test
    @DisplayName("种子：三个平台角色，PLAT_ADMIN 拥有全部 PLAT:* 权限")
    void seeded_roles() {
        var roles = platformRoles.roles();
        assertThat(roles).extracting(PlatformRoleService.RoleDto::code)
                .contains("PLAT_ADMIN", "PLAT_OPS", "PLAT_AUDIT");
        assertThat(roles.stream().filter(r -> "PLAT_ADMIN".equals(r.code())).findFirst())
                .hasValueSatisfying(r -> assertThat(r.permissions()).contains("PLAT:TENANT", "PLAT:ROLE"));

        // 成员名称随角色一起返回（列表直接展示，不用再点开才知道是谁）
        assertThat(roles.stream().filter(r -> "PLAT_ADMIN".equals(r.code())).findFirst())
                .hasValueSatisfying(r -> assertThat(r.members()).contains("platadmin"));

        var perms = platformRoles.permissions();
        assertThat(perms).extracting(PlatformRoleService.PermissionDto::resourceKey)
                .contains("PLAT", "PLAT:TENANT", "PLAT:ACCOUNT", "PLAT:ROLE");
    }

    @Test
    @DisplayName("新增角色 + 分配权限 + 分配成员")
    void create_role_and_assign() {
        long roleId = platformRoles.save(new PlatformRoleService.SaveRequest(
                null, ROLE_CODE, "集成测试审计", true, List.of("PLAT", "PLAT:TENANT", "PLAT:AUDIT")));

        var role = platformRoles.roles().stream().filter(r -> r.id() == roleId).findFirst().orElseThrow();
        assertThat(role.permissions()).contains("PLAT:AUDIT").doesNotContain("PLAT:ACCOUNT");

        platformRoles.setMembers(roleId, List.of(accountId));
        assertThat(platformRoles.members(roleId)).containsExactly(accountId);

        // 非平台账号不能当成员
        Long tenantAdmin = jdbc.queryForObject(
                "SELECT Id FROM plat.[User] WHERE TenantId = 1 AND UserName = 'admin' AND IsDeleted = 0",
                Long.class);
        assertThatThrownBy(() -> platformRoles.setMembers(roleId, List.of(tenantAdmin)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("平台账号");
    }

    @Test
    @DisplayName("没有 PLAT_ADMIN 的平台账号：登录后 adm=false，租户管理接口被拒")
    void non_admin_platform_account_is_limited() {
        // 账号只挂审计角色（没有 PLAT_ADMIN）
        long auditRoleId = platformRoles.roles().stream()
                .filter(r -> "PLAT_AUDIT".equals(r.code())).findFirst().orElseThrow().id();
        platformRoles.setMembers(auditRoleId, List.of(accountId));

        var login = authService.loginPlatform(ACCOUNT, PASSWORD);
        Claims claims = jwtService.parse(login.token());
        assertThat(claims.get(JwtService.CLAIM_ADMIN)).isEqualTo(false);
        assertThat(claims.get(JwtService.CLAIM_PLATFORM)).isEqualTo(true);

        TenantContext.set(((Number) claims.get(JwtService.CLAIM_TENANT)).longValue(),
                ((Number) claims.get(JwtService.CLAIM_USER)).longValue(),
                false, TenantContext.APP_PLATFORM, true);
        // 平台角色接口需要 PLAT:ROLE，审计角色没有 → 数据库函数判定拒绝
        assertThat(com.aschain.common.tenant.TenantContext.isPlatformApp()).isTrue();
        var permissionService = applicationContext.getBean(
                com.aschain.plat.perm.PermissionService.class);
        assertThat(permissionService.check("PLAT:ROLE", "read")).isFalse();
        assertThat(permissionService.check("PLAT:AUDIT", "read")).isTrue();
    }

    @Autowired
    org.springframework.context.ApplicationContext applicationContext;
}

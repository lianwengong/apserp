package com.apserp.plat.perm;

import static org.assertj.core.api.Assertions.assertThat;

import com.apserp.common.tenant.TenantContext;
import com.apserp.plat.meta.MetaDefinitionService;
import com.apserp.support.ItDb;
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
 * 权限接线集成测试：
 * 1) 无权限用户被拒（功能点权限，走 plat.ufn_Perm_Check）
 * 2) 系统管理员直通
 * 3) 字段级权限把字段从定义里剔除
 */
@SpringBootTest
@EnabledIfSystemProperty(named = "it.db", matches = "true")
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
class PermissionIT {

    private static final String TEST_USER = "it_perm_user";

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    private PermissionService permissionService;

    @Autowired
    private MetaDefinitionService definitionService;

    private long limitedUserId;

    @BeforeEach
    void setUp() throws Exception {
        try (Connection con = connect(); Statement st = con.createStatement()) {
            st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
            cleanup(st);
            st.executeUpdate("INSERT INTO plat.[User] (TenantId, UserName, PasswordHash, PasswordSalt, "
                    + "DisplayName, UserType, IsEnabled, FailCount, IsDeleted) "
                    + "VALUES (1, '" + TEST_USER + "', 'x', 'x', N'权限测试用户', 2, 1, 0, 0)");
            st.executeUpdate("INSERT INTO plat.UserRole (TenantId, UserId, RoleId, OrgId) "
                    + "SELECT 1, u.Id, r.Id, NULL FROM plat.[User] u "
                    + "JOIN plat.Role r ON r.TenantId = 1 AND r.Code = 'WH' "
                    + "WHERE u.UserName = '" + TEST_USER + "'");
        }
        try (Connection con = connect(); Statement st = con.createStatement()) {
            // 校验也要绕过 RLS，否则查不到刚插入的用户
            st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
            try (var rs = st.executeQuery("SELECT Id FROM plat.[User] WHERE UserName = '" + TEST_USER + "'")) {
                assertThat(rs.next()).isTrue();
                limitedUserId = rs.getLong(1);
            }
        }
    }

    @AfterEach
    void tearDown() throws Exception {
        TenantContext.clear();
        try (Connection con = connect(); Statement st = con.createStatement()) {
            st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
            cleanup(st);
        }
    }

    private void cleanup(Statement st) throws Exception {
        st.executeUpdate("DELETE FROM plat.FieldPermission WHERE ObjectName = 'md.brand'");
        st.executeUpdate("DELETE FROM plat.UserRole WHERE UserId IN "
                + "(SELECT Id FROM plat.[User] WHERE UserName = '" + TEST_USER + "')");
        st.executeUpdate("DELETE FROM plat.[User] WHERE UserName = '" + TEST_USER + "'");
    }

    @Test
    void user_without_permission_should_be_denied() {
        TenantContext.set(1L, limitedUserId, false);
        assertThat(permissionService.check("DATA:md.brand", "read")).isFalse();
        assertThat(permissionService.check("DATA:md.brand", "write")).isFalse();
    }

    @Test
    void system_admin_should_pass_everything() {
        TenantContext.set(1L, 1L, false);   // admin 属于 SYSADMIN 角色
        assertThat(permissionService.check("DATA:md.brand", "read")).isTrue();
        assertThat(permissionService.check("DATA:md.brand", "write")).isTrue();
    }

    @Test
    void field_level_permission_should_remove_field_from_definition() throws Exception {
        try (Connection con = connect(); Statement st = con.createStatement()) {
            st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
            st.executeUpdate("INSERT plat.FieldPermission (TenantId, RoleId, ObjectName, FieldName, Access) "
                    + "SELECT 1, r.Id, 'md.brand', 'Name', 0 FROM plat.Role r "
                    + "WHERE r.TenantId = 1 AND r.Code = 'WH'");
        }
        TenantContext.set(1L, limitedUserId, false);
        var fields = definitionService.listFields("md.brand");
        assertThat(fields).noneMatch(f -> f.fieldName().equals("Name"));
        assertThat(fields).anyMatch(f -> f.fieldName().equals("Code"));
    }

    private Connection connect() throws Exception {
        return DriverManager.getConnection(ItDb.url(), ItDb.user(), ItDb.password());
    }
}

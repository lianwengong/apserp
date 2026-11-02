package com.aschain.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;

import com.aschain.common.tenant.TenantContext;
import com.aschain.support.ItDb;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
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
 * 数据范围（DataScope）集成测试。
 *
 * <p>对象 {@code md.partner} 由 V25 迁移创建，带 {@code OrgId} 字段，因此引擎会走组织过滤。
 * 用两个不同组织的行验证：</p>
 * <ul>
 *   <li>管理员（scope=1 全部）→ 两行都能看到</li>
 *   <li>自定义范围（scope=4，只给组织 1）→ 只能看到组织 1 的那一行</li>
 *   <li>无授权（scope=0）→ 一行都看不到</li>
 * </ul>
 */
@SpringBootTest
@EnabledIfSystemProperty(named = "it.db", matches = "true")
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
class DataScopeIT {

    private static final String USER = "it_scope_user";
    private static final String CODE_SAME_ORG = "SC_ORG1";
    private static final String CODE_OTHER_ORG = "SC_ORG6";

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    private MetaQueryService queryService;

    private long userId;

    @BeforeEach
    void setUp() throws Exception {
        cleanUp();
        userId = createUserWithRole("WH");
        seedRows();
    }

    @AfterEach
    void tearDown() throws Exception {
        TenantContext.clear();
        cleanUp();
    }

    @Test
    void admin_sees_all_orgs() {
        TenantContext.set(1L, 1L, false);
        var page = queryService.query("md.partner", null, "Id", 1, 100);
        assertThat(page.rows()).extracting(r -> r.get("Code"))
                .contains(CODE_SAME_ORG, CODE_OTHER_ORG);
    }

    @Test
    void custom_scope_sees_only_granted_org() throws Exception {
        grant("DATA:md.partner", 4, "1");
        TenantContext.set(1L, userId, false);

        var page = queryService.query("md.partner", null, "Id", 1, 100);
        assertThat(page.rows()).extracting(r -> r.get("Code"))
                .contains(CODE_SAME_ORG)
                .doesNotContain(CODE_OTHER_ORG);
    }

    @Test
    void no_grant_sees_nothing() {
        TenantContext.set(1L, userId, false);
        var page = queryService.query("md.partner", null, "Id", 1, 100);
        assertThat(page.total()).isZero();
        assertThat(page.rows()).isEmpty();
    }

    // ------------------------------------------------------------ 数据准备

    private void seedRows() throws Exception {
        try (Connection con = connect(); Statement st = con.createStatement()) {
            st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
            st.executeUpdate("DELETE FROM md.Partner WHERE Code IN ('" + CODE_SAME_ORG + "','" + CODE_OTHER_ORG + "')");
            st.executeUpdate("INSERT md.Partner (TenantId, Code, Name, OrgId) VALUES "
                    + "(1,'" + CODE_SAME_ORG + "',N'总部客户',1),"
                    + "(1,'" + CODE_OTHER_ORG + "',N'中心仓客户',6)");
        }
    }

    private long createUserWithRole(String roleCode) throws Exception {
        try (Connection con = connect(); Statement st = con.createStatement()) {
            st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
            st.executeUpdate("INSERT INTO plat.[User] (TenantId, UserName, PasswordHash, PasswordSalt, "
                    + "DisplayName, UserType, IsEnabled, FailCount, IsDeleted) VALUES "
                    + "(1,'" + USER + "','x','x',N'范围测试',2,1,0,0)");
            st.executeUpdate("INSERT INTO plat.UserRole (TenantId, UserId, RoleId, OrgId) "
                    + "SELECT 1, u.Id, r.Id, NULL FROM plat.[User] u JOIN plat.Role r "
                    + "ON r.TenantId = 1 AND r.Code = '" + roleCode + "' WHERE u.UserName = '" + USER + "'");
            try (var rs = st.executeQuery("SELECT Id FROM plat.[User] WHERE UserName = '" + USER + "'")) {
                rs.next();
                return rs.getLong(1);
            }
        }
    }

    private void grant(String resourceKey, int dataScope, String scopeOrgIds) throws Exception {
        try (Connection con = connect()) {
            try (Statement st = con.createStatement()) {
                st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT plat.RolePermission (TenantId, RoleId, PermissionId, Allow, CanRead, "
                    + "CanWrite, DataScope, ScopeOrgIds, GrantedAt) "
                    + "SELECT 1, r.Id, p.Id, 1, 1, 0, ?, ?, sysutcdatetime() "
                    + "FROM plat.Role r CROSS JOIN plat.Permission p "
                    + "WHERE r.TenantId = 1 AND r.Code = 'WH' AND p.TenantId = 1 AND p.ResourceKey = ?")) {
                ps.setInt(1, dataScope);
                ps.setString(2, scopeOrgIds);
                ps.setString(3, resourceKey);
                ps.executeUpdate();
            }
        }
    }

    private void cleanUp() throws Exception {
        try (Connection con = connect(); Statement st = con.createStatement()) {
            st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
            st.executeUpdate("DELETE FROM md.Partner WHERE Code IN ('" + CODE_SAME_ORG + "','" + CODE_OTHER_ORG + "')");
            st.executeUpdate("DELETE FROM plat.RolePermission WHERE RoleId IN "
                    + "(SELECT Id FROM plat.Role WHERE TenantId = 1 AND Code = 'WH') "
                    + "AND PermissionId IN (SELECT Id FROM plat.Permission WHERE ResourceKey = 'DATA:md.partner')");
            st.executeUpdate("DELETE FROM plat.UserRole WHERE UserId IN "
                    + "(SELECT Id FROM plat.[User] WHERE UserName = '" + USER + "')");
            st.executeUpdate("DELETE FROM plat.[User] WHERE UserName = '" + USER + "'");
        }
    }

    private Connection connect() throws Exception {
        return DriverManager.getConnection(ItDb.url(), ItDb.user(), ItDb.password());
    }
}

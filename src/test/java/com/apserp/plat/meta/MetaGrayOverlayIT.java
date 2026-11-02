package com.apserp.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;

import com.apserp.common.tenant.TenantContext;
import com.apserp.support.ItDb;
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
 * 灰度「真正分用户生效」集成测试。
 *
 * <p>做法：先发布一版快照（灰度给测试用户），再改实时库的展示配置；
 * 断言灰度用户读到的是<b>快照里的旧配置</b>，而管理员读到的是<b>实时库的新配置</b>。</p>
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class MetaGrayOverlayIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    MetaOverlay overlay;

    @Autowired
    MetaDefinitionService definitionService;

    @Autowired
    MetaPublishService publishService;

    @Autowired
    RuleService ruleService;

    @Autowired
    ActionService actionService;

    @Autowired
    MetaCache cache;

    @Autowired
    JdbcTemplate jdbc;

    private long grayUser;

    @BeforeEach
    void setUp() {
        TenantContext.set(1L, 1L, true);
        cache.invalidateTenant();
        grayUser = ensureUser("it_gray_user", "灰度用户");
        // 清掉历史灰度版本，避免互相干扰
        jdbc.update("""
                DELETE g FROM plat.MetaVersionGray g
                JOIN plat.MetaVersion v ON v.Id = g.MetaVersionId
                WHERE v.TenantId = 1
                """);
        jdbc.update("UPDATE plat.MetaVersion SET Status = CASE WHEN Version = "
                + "(SELECT MAX(Version) FROM plat.MetaVersion WHERE TenantId = 1 AND Scope = 'meta') "
                + "THEN 1 ELSE 0 END WHERE TenantId = 1 AND Scope = 'meta'");
    }

    @AfterEach
    void tearDown() {
        // 还原被改动的实时配置
        jdbc.update("UPDATE plat.DataObjectField SET DisplayName = N'品牌名称' "
                + "WHERE DataObjectId IN (SELECT Id FROM plat.DataObject WHERE Code = 'md.brand') "
                + "AND FieldName = 'Name'");
        jdbc.update("UPDATE plat.Button SET Text = N'编辑' WHERE Code = 'BTN-BRAND-EDIT'");
        jdbc.update("UPDATE plat.BizRule SET Expression = 'ctx.Code != null && ctx.Code.length() <= 32' "
                + "WHERE Code = 'R-CODE-REQUIRED'");
        jdbc.update("DELETE g FROM plat.MetaVersionGray g "
                + "JOIN plat.MetaVersion v ON v.Id = g.MetaVersionId WHERE v.TenantId = 1");
        TenantContext.set(1L, 1L, true);
        cache.invalidateTenant();
        TenantContext.clear();
    }

    private long ensureUser(String userName, String displayName) {
        Long id = jdbc.query("SELECT Id FROM plat.[User] WHERE TenantId = 1 AND UserName = ?",
                rs -> rs.next() ? rs.getLong(1) : null, userName);
        if (id != null) {
            return id;
        }
        jdbc.update("""
                INSERT plat.[User] (TenantId, UserName, PasswordHash, PasswordSalt, DisplayName, UserType,
                                    IsEnabled, MustChangePwd, FailCount, IsDeleted, CreatedAt)
                VALUES (1, ?, 'x', 'x', ?, 1, 1, 0, 0, 0, sysutcdatetime())
                """, userName, displayName);
        return jdbc.queryForObject("SELECT Id FROM plat.[User] WHERE TenantId = 1 AND UserName = ?",
                Long.class, userName);
    }

    @Test
    @DisplayName("灰度用户读快照，管理员读实时库（字段显示名）")
    void gray_user_sees_snapshot_fields() {
        var grayVersion = publishService.publish("灰度字段测试", List.of(grayUser));
        // 快照发布后改实时库
        jdbc.update("UPDATE plat.DataObjectField SET DisplayName = N'品牌名称【已改】' "
                + "WHERE DataObjectId IN (SELECT Id FROM plat.DataObject WHERE Code = 'md.brand') "
                + "AND FieldName = 'Name'");

        TenantContext.set(1L, grayUser, false);
        cache.invalidateTenant();
        String grayName = displayNameOf(definitionService.listFields("md.brand"), "Name");
        assertThat(grayName).isEqualTo("品牌名称");

        TenantContext.set(1L, 1L, true);
        cache.invalidateTenant();
        String liveName = displayNameOf(definitionService.listFields("md.brand"), "Name");
        assertThat(liveName).isEqualTo("品牌名称【已改】");
        assertThat(grayVersion.version()).isPositive();
    }

    @Test
    @DisplayName("灰度用户读快照里的按钮文案，管理员读实时文案")
    void gray_user_sees_snapshot_buttons() {
        publishService.publish("灰度按钮测试", List.of(grayUser));
        jdbc.update("UPDATE plat.Button SET Text = N'编辑【已改】' WHERE Code = 'BTN-BRAND-EDIT'");

        TenantContext.set(1L, grayUser, false);
        cache.invalidateTenant();
        assertThat(buttonText(actionService.listButtons("md.brand"), "BTN-BRAND-EDIT")).isEqualTo("编辑");

        TenantContext.set(1L, 1L, true);
        cache.invalidateTenant();
        assertThat(buttonText(actionService.listButtons("md.brand"), "BTN-BRAND-EDIT")).isEqualTo("编辑【已改】");
    }

    @Test
    @DisplayName("灰度用户保存时用的规则来自快照（改实时规则不影响灰度用户）")
    void gray_user_rules_come_from_snapshot() {
        publishService.publish("灰度规则测试", List.of(grayUser));
        jdbc.update("UPDATE plat.BizRule SET Expression = 'ctx.Code == ''NEVER''' "
                + "WHERE Code = 'R-CODE-REQUIRED'");

        TenantContext.set(1L, grayUser, false);
        cache.invalidateTenant();
        String grayExpr = ruleService.rulesFor("md.brand", 1).stream()
                .filter(r -> r.code().equals("R-CODE-REQUIRED")).findFirst().orElseThrow().expression();
        assertThat(grayExpr).contains("ctx.Code.length() <= 32");

        TenantContext.set(1L, 1L, true);
        cache.invalidateTenant();
        String liveExpr = ruleService.rulesFor("md.brand", 1).stream()
                .filter(r -> r.code().equals("R-CODE-REQUIRED")).findFirst().orElseThrow().expression();
        assertThat(liveExpr).contains("NEVER");
    }

    @Test
    @DisplayName("不在灰度名单里的普通用户仍读实时库")
    void non_gray_user_reads_live() {
        publishService.publish("灰度名单测试", List.of(grayUser));
        jdbc.update("UPDATE plat.DataObjectField SET DisplayName = N'品牌名称【实时】' "
                + "WHERE DataObjectId IN (SELECT Id FROM plat.DataObject WHERE Code = 'md.brand') "
                + "AND FieldName = 'Name'");

        long other = ensureUser("it_gray_other", "非灰度用户");
        TenantContext.set(1L, other, false);
        cache.invalidateTenant();
        assertThat(displayNameOf(definitionService.listFields("md.brand"), "Name")).isEqualTo("品牌名称【实时】");
        assertThat(overlay.current()).isNull();
    }

    @Test
    @DisplayName("平台管理员永不走灰度（发布者要看到真实配置）")
    void platform_admin_bypasses_gray() {
        publishService.publish("管理员直通测试", List.of(1L));
        TenantContext.set(1L, 1L, true);
        cache.invalidateTenant();
        assertThat(overlay.current()).isNull();
    }

    @Test
    @DisplayName("灰度版本降级为历史后，用户立即回到实时库")
    void gray_superseded_returns_to_live() {
        var gray = publishService.publish("灰度将被取代", List.of(grayUser));
        TenantContext.set(1L, grayUser, false);
        cache.invalidateTenant();
        assertThat(overlay.current()).isNotNull();

        // 全量发布一版：灰度版被降为历史，名单里的用户立即回到实时库
        TenantContext.set(1L, 1L, true);
        publishService.publish("全量发布覆盖灰度", List.of());

        TenantContext.set(1L, grayUser, false);
        cache.invalidateTenant();
        assertThat(overlay.current()).isNull();
        assertThat(gray.version()).isPositive();
    }

    private static String displayNameOf(List<MetaDefinitionService.FieldDto> fields, String fieldName) {
        return fields.stream().filter(f -> f.fieldName().equals(fieldName)).findFirst()
                .orElseThrow().displayName();
    }

    private static String buttonText(List<ActionService.ButtonDto> buttons, String code) {
        return buttons.stream().filter(b -> b.code().equals(code)).findFirst().orElseThrow().text();
    }
}

package com.apserp.plat.menu;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.apserp.common.ApiException;
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
 * 终端与功能模块集成测试：「终端启用哪些模块」是唯一来源，
 * 菜单只能在已启用范围内挂；停用有菜单在用的模块必须被拒绝。
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class TerminalAdminIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    TerminalAdminService terminalAdmin;

    @Autowired
    MenuAdminService menuAdmin;

    @Autowired
    JdbcTemplate jdbc;

    private static final String PARENT_CODE = "ITTM";
    private static final String CHILD_CODE = "ITTM.SUB";

    @BeforeEach
    void setUp() {
        TenantContext.set(1L, 1L, true);
        cleanUp();
    }

    @AfterEach
    void tearDown() {
        cleanUp();
        TenantContext.clear();
    }

    private void cleanUp() {
        jdbc.update("DELETE mt FROM plat.MenuTerminal mt JOIN plat.[Menu] m ON m.Id = mt.MenuId "
                + "WHERE m.Code LIKE 'ITTMENU%'");
        jdbc.update("DELETE FROM plat.[Menu] WHERE Code LIKE 'ITTMENU%'");
        jdbc.update("DELETE mt FROM plat.ModuleTerminal mt JOIN plat.[Module] m ON m.Id = mt.ModuleId "
                + "WHERE m.Code LIKE 'ITTM%'");
        jdbc.update("DELETE FROM plat.[Module] WHERE Code LIKE 'ITTM%'");
    }

    private long newModule(String code, Long parentId, int level) {
        jdbc.update("""
                INSERT plat.[Module] (TenantId, ParentId, Code, Name, [Level], ModuleType, Sort,
                                      IsEnabled, Version, IsDeleted)
                VALUES (1, ?, ?, ?, ?, 2, 900, 1, 1, 0)
                """, parentId, code, "终端测试模块 " + code, level);
        return jdbc.queryForObject("SELECT Id FROM plat.[Module] WHERE TenantId = 1 AND Code = ?",
                Long.class, code);
    }

    @Test
    @DisplayName("终端列表：6 个终端，各自带模块/菜单/功能点计数")
    void terminals_have_counts() {
        List<TerminalAdminService.TerminalDto> list = terminalAdmin.terminals();
        assertThat(list).hasSize(6);
        assertThat(list).extracting(TerminalAdminService.TerminalDto::label)
                .containsExactly("PC", "PDA", "POS", "移动", "小程序", "其他");
        // PC 上承接了种子模块，数应为正
        assertThat(list.get(0).moduleCount()).isPositive();
        assertThat(terminalAdmin.overview()).containsKeys("terminals", "moduleTotal");
    }

    @Test
    @DisplayName("启用模块：写入 ModuleTerminal，父模块自动补齐；再停用即消失")
    void enable_and_disable_module() {
        long parent = newModule(PARENT_CODE, null, 1);
        long child = newModule(CHILD_CODE, parent, 2);

        List<TerminalAdminService.ModuleOption> after = terminalAdmin.enableModule(3, child);
        assertThat(after).filteredOn(m -> m.id() == child).allSatisfy(m -> assertThat(m.enabled()).isTrue());
        // 父模块自动补齐（否则 POS 上树断链）
        assertThat(after).filteredOn(m -> m.id() == parent).allSatisfy(m -> assertThat(m.enabled()).isTrue());
        assertThat(terminalAdmin.enabledModules(3)).extracting(TerminalAdminService.ModuleOption::id)
                .contains(parent, child);

        List<TerminalAdminService.ModuleOption> removed = terminalAdmin.disableModule(3, child);
        assertThat(removed).filteredOn(m -> m.id() == child).allSatisfy(m -> assertThat(m.enabled()).isFalse());
        assertThat(terminalAdmin.enabledModules(3)).extracting(TerminalAdminService.ModuleOption::id)
                .doesNotContain(child);
    }

    @Test
    @DisplayName("停用保护：该终端下还有菜单在用这个模块时拒绝")
    void cannot_disable_module_with_menus() {
        long moduleId = newModule(PARENT_CODE, null, 1);
        terminalAdmin.enableModule(4, moduleId);
        long menuId = menuAdmin.save(new MenuAdminService.MenuSaveRequest(
                null, null, "ITTMENU.01", "移动端菜单", 2, moduleId, null, "/object/md.brand", null, 90,
                true, 1, null, true, null, 4));
        assertThat(menuId).isPositive();

        assertThatThrownBy(() -> terminalAdmin.disableModule(4, moduleId))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("还在用这个模块");

        // 删掉菜单后可停用
        menuAdmin.delete(menuId);
        terminalAdmin.disableModule(4, moduleId);
        assertThat(terminalAdmin.enabledModules(4)).extracting(TerminalAdminService.ModuleOption::id)
                .doesNotContain(moduleId);
    }

    @Test
    @DisplayName("非法终端号被拒绝")
    void invalid_terminal_rejected() {
        assertThatThrownBy(() -> terminalAdmin.enableModule(7, 1L))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("1..6");
        assertThatThrownBy(() -> terminalAdmin.enableModule(0, 1L))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("1..6");
    }
}

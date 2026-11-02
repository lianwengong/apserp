package com.apserp.plat.menu;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.apserp.common.ApiException;
import com.apserp.common.tenant.TenantContext;
import com.apserp.support.ItDb;
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
 * 菜单设置管理集成测试：树、层级校验、路由自动补、<b>终端归属与「模块必须在该终端启用」</b>、
 * 移动/删除保护，以及「管理窗口改完，侧边栏的 MenuService 立刻能读到」这条端到端链路。
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class MenuAdminIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    MenuAdminService admin;

    @Autowired
    MenuService menuService;

    @Autowired
    TerminalAdminService terminalAdmin;

    @Autowired
    JdbcTemplate jdbc;

    private static final String PARENT_CODE = "ITMENU.ROOT";
    private static final String CHILD_CODE = "ITMENU.CHILD";
    private static final String MODULE_CODE = "ITMENM";

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
                + "WHERE m.Code LIKE 'ITMENU%'");
        jdbc.update("DELETE FROM plat.[Menu] WHERE Code LIKE 'ITMENU%'");
        jdbc.update("DELETE mt FROM plat.ModuleTerminal mt JOIN plat.[Module] m ON m.Id = mt.ModuleId "
                + "WHERE m.Code LIKE 'ITMENM%'");
        jdbc.update("DELETE FROM plat.[Module] WHERE Code LIKE 'ITMENM%'");
        jdbc.update("DELETE FROM plat.[Page] WHERE Code = 'ITPAGE.01'");
    }

    /** 测试用页面：绑页面才有「自动补路由」可验证。 */
    private long ensurePage() {
        Long existing = jdbc.query("SELECT Id FROM plat.[Page] WHERE TenantId = 1 AND Code = 'ITPAGE.01'",
                rs -> rs.next() ? rs.getLong(1) : null);
        if (existing != null) {
            return existing;
        }
        jdbc.update("""
                INSERT plat.[Page] (TenantId, Code, Name, PageType, IsEnabled, Version, IsDeleted, CreatedAt)
                VALUES (1, 'ITPAGE.01', N'测试页面', 1, 1, 1, 0, sysutcdatetime())
                """);
        return jdbc.queryForObject("SELECT Id FROM plat.[Page] WHERE TenantId = 1 AND Code = 'ITPAGE.01'",
                Long.class);
    }

    /** 测试用模块，并在指定终端启用。 */
    private long ensureModule(int... terminals) {
        Long id = jdbc.query("SELECT Id FROM plat.[Module] WHERE TenantId = 1 AND Code = ?",
                rs -> rs.next() ? rs.getLong(1) : null, MODULE_CODE);
        if (id == null) {
            jdbc.update("""
                    INSERT plat.[Module] (TenantId, Code, Name, [Level], ModuleType, Sort, IsEnabled, Version, IsDeleted)
                    VALUES (1, ?, N'菜单测试模块', 3, 2, 999, 1, 1, 0)
                    """, MODULE_CODE);
            id = jdbc.queryForObject("SELECT Id FROM plat.[Module] WHERE TenantId = 1 AND Code = ?",
                    Long.class, MODULE_CODE);
        }
        for (int t : terminals) {
            Integer exists = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM plat.ModuleTerminal WHERE TenantId = 1 AND ModuleId = ? AND TerminalType = ?
                    """, Integer.class, id, t);
            if (exists == null || exists == 0) {
                jdbc.update("""
                        INSERT plat.ModuleTerminal (TenantId, ModuleId, TerminalType, IsVisible)
                        VALUES (1, ?, ?, 1)
                        """, id, t);
            }
        }
        return id;
    }

    private long createMenu(String code, Long parentId, Long pageId, int terminalType) {
        return admin.save(new MenuAdminService.MenuSaveRequest(
                null, parentId, code, "测试菜单 " + code, 2, null, pageId, null, "Grid", 90,
                true, 1, null, true, null, terminalType));
    }

    @Test
    @DisplayName("菜单树：种子菜单结构完整，可管理（含停用节点），可按终端过滤")
    void tree_visible_for_admin() {
        List<MenuAdminService.MenuNode> tree = admin.tree(null, null, null);
        assertThat(tree).isNotEmpty();
        assertThat(admin.tree("绝对不存在的菜单", null, null)).isEmpty();

        List<MenuAdminService.MenuNode> pcOnly = admin.tree(null, null, 1);
        assertThat(pcOnly).isNotEmpty();
        assertThat(flatten(pcOnly)).allSatisfy(n -> assertThat(n.terminalType()).isEqualTo(1));

        Map<String, Object> options = admin.options();
        assertThat(options).containsKeys("modules", "pages", "menuTypes", "openModes", "terminalTypes");
        assertThat((List<?>) options.get("terminalTypes")).hasSize(6);
    }

    private static List<MenuAdminService.MenuNode> flatten(List<MenuAdminService.MenuNode> nodes) {
        List<MenuAdminService.MenuNode> out = new java.util.ArrayList<>();
        for (MenuAdminService.MenuNode n : nodes) {
            out.add(n);
            out.addAll(flatten(n.children()));
        }
        return out;
    }

    @Test
    @DisplayName("新增菜单：绑了页面但没写路由时自动补 /m/{code}，并记录终端")
    void route_auto_filled_when_page_bound() {
        long pageId = ensurePage();
        long id = createMenu(PARENT_CODE, null, pageId, 1);
        String route = jdbc.queryForObject("SELECT Route FROM plat.[Menu] WHERE Id = ?", String.class, id);
        assertThat(route).isEqualTo("/m/" + PARENT_CODE);
        assertThat(jdbc.queryForObject("SELECT TerminalType FROM plat.[Menu] WHERE Id = ?",
                Integer.class, id)).isEqualTo(1);
        // MenuTerminal 是镜像表，必须同步
        assertThat(jdbc.queryForList("SELECT TerminalType FROM plat.MenuTerminal WHERE MenuId = ?",
                Integer.class, id)).containsExactly(1);

        long id2 = admin.save(new MenuAdminService.MenuSaveRequest(
                null, null, CHILD_CODE, "自定义路由", 2, null, pageId, "/object/md.brand", null, 95,
                true, 1, null, true, null, 2));
        assertThat(jdbc.queryForObject("SELECT Route FROM plat.[Menu] WHERE Id = ?", String.class, id2))
                .isEqualTo("/object/md.brand");
        assertThat(jdbc.queryForObject("SELECT TerminalType FROM plat.[Menu] WHERE Id = ?",
                Integer.class, id2)).isEqualTo(2);
    }

    @Test
    @DisplayName("核心规则：菜单的模块必须在该终端启用，否则拒绝保存")
    void module_must_be_enabled_on_terminal() {
        long moduleId = ensureModule(1);   // 只在 PC 启用

        long ok = admin.save(new MenuAdminService.MenuSaveRequest(
                null, null, PARENT_CODE, "PC 菜单", 2, moduleId, null, null, null, 90,
                true, 1, null, true, null, 1));
        assertThat(ok).isPositive();

        assertThatThrownBy(() -> admin.save(new MenuAdminService.MenuSaveRequest(
                null, null, CHILD_CODE, "PDA 菜单却挂了 PC 模块", 2, moduleId, null, null, null, 90,
                true, 1, null, true, null, 2)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("未在终端「PDA」启用");

        // 在 PDA 启用后即可保存
        terminalAdmin.enableModule(2, moduleId);
        long pda = admin.save(new MenuAdminService.MenuSaveRequest(
                null, null, CHILD_CODE, "PDA 菜单", 2, moduleId, null, null, null, 90,
                true, 1, null, true, null, 2));
        assertThat(pda).isPositive();
    }

    @Test
    @DisplayName("校验：编码非法/重复（同层）/上级不存在/父子成环")
    void validation() {
        long parent = createMenu(PARENT_CODE, null, null, 1);

        assertThatThrownBy(() -> createMenu("1 空格", null, null, 1))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("菜单编码");

        assertThatThrownBy(() -> createMenu(PARENT_CODE, null, null, 1))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("已存在");

        assertThatThrownBy(() -> createMenu("ITMENU.X", 999_999L, null, 1))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("上级菜单不存在");

        long child = createMenu(CHILD_CODE, parent, null, 1);
        assertThatThrownBy(() -> admin.move(new MenuAdminService.MoveRequest(parent, child, 10)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("下级");
        assertThatThrownBy(() -> admin.move(new MenuAdminService.MoveRequest(parent, parent, 10)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("不能是自己");
    }

    @Test
    @DisplayName("移动：改父节点与排序；叶子节点可删，父节点有子时拒绝删除")
    void move_and_delete() {
        long parent = createMenu(PARENT_CODE, null, null, 1);
        long child = createMenu(CHILD_CODE, parent, null, 1);

        admin.move(new MenuAdminService.MoveRequest(child, null, 5));
        Long parentOfChild = jdbc.queryForObject(
                "SELECT ParentId FROM plat.[Menu] WHERE Id = ?", Long.class, child);
        assertThat(parentOfChild).isNull();

        admin.move(new MenuAdminService.MoveRequest(child, parent, 15));
        assertThat(jdbc.queryForObject("SELECT Sort FROM plat.[Menu] WHERE Id = ?", Integer.class, child))
                .isEqualTo(15);

        assertThatThrownBy(() -> admin.delete(parent))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("子菜单");

        admin.delete(child);
        admin.delete(parent);
        assertThat(admin.tree("ITMENU", null, null)).isEmpty();
    }

    @Test
    @DisplayName("管理窗口改完，侧边栏菜单树立即生效（同一张表）")
    void admin_changes_reflect_in_sidebar_tree() {
        long root = createMenu(PARENT_CODE, null, null, 1);
        admin.save(new MenuAdminService.MenuSaveRequest(
                null, root, CHILD_CODE, "子菜单", 2, null, null, "/object/md.brand", null, 10,
                true, 1, null, true, null, 1));

        List<MenuService.MenuNode> sidebar = menuService.tree(1);
        List<MenuService.MenuNode> mine = sidebar.stream()
                .filter(n -> PARENT_CODE.equals(n.code())).toList();
        assertThat(mine).hasSize(1);
        assertThat(mine.get(0).children()).extracting(MenuService.MenuNode::code).contains(CHILD_CODE);

        // 停用后侧边栏不再下发
        admin.save(new MenuAdminService.MenuSaveRequest(
                root, null, PARENT_CODE, "停用的菜单", 2, null, null, null, null, 90,
                true, 1, null, false, null, 1));
        assertThat(menuService.tree(1)).extracting(MenuService.MenuNode::code)
                .doesNotContain(PARENT_CODE);
    }

    @Test
    @DisplayName("终端隔离：PDA 的菜单不出现在 PC 菜单树里，反之亦然")
    void terminal_isolation_in_sidebar() {
        createMenu(PARENT_CODE, null, null, 2);
        assertThat(menuService.tree(1)).extracting(MenuService.MenuNode::code)
                .doesNotContain(PARENT_CODE);
        assertThat(menuService.tree(2)).extracting(MenuService.MenuNode::code)
                .contains(PARENT_CODE);

        createMenu(CHILD_CODE, null, null, 3);
        assertThat(menuService.tree(3)).extracting(MenuService.MenuNode::code).contains(CHILD_CODE);
        assertThat(menuService.tree(2)).extracting(MenuService.MenuNode::code).doesNotContain(CHILD_CODE);
    }
}

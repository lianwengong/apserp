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
 * 菜单设置管理集成测试：树、层级校验、路由自动补、终端可见性、移动/删除保护，
 * 以及「管理窗口改完，侧边栏的 MenuService 立刻能读到」这条端到端链路。
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
    JdbcTemplate jdbc;

    private static final String PARENT_CODE = "ITMENU.ROOT";
    private static final String CHILD_CODE = "ITMENU.CHILD";

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

    private long createMenu(String code, Long parentId, Long pageId, List<Integer> terminals) {
        return admin.save(new MenuAdminService.MenuSaveRequest(
                null, parentId, code, "测试菜单 " + code, 2, null, pageId, null, "Grid", 90,
                true, 1, null, true, null, terminals));
    }

    @Test
    @DisplayName("菜单树：种子菜单结构完整，管理窗口能看到停用节点")
    void tree_visible_for_admin() {
        List<MenuAdminService.MenuNode> tree = admin.tree(null, null);
        assertThat(tree).isNotEmpty();
        assertThat(admin.tree("绝对不存在的菜单", null)).isEmpty();
        Map<String, Object> options = admin.options();
        assertThat(options).containsKeys("modules", "pages", "menuTypes", "openModes", "terminalTypes");
        assertThat((List<?>) options.get("terminalTypes")).hasSize(6);
    }

    @Test
    @DisplayName("新增菜单：绑了页面但没写路由时自动补 /m/{code}")
    void route_auto_filled_when_page_bound() {
        long pageId = ensurePage();

        long id = createMenu(PARENT_CODE, null, pageId, List.of(1));
        String route = jdbc.queryForObject("SELECT Route FROM plat.[Menu] WHERE Id = ?", String.class, id);
        assertThat(route).isEqualTo("/m/" + PARENT_CODE);

        // 明确给了路由就不覆盖
        long id2 = admin.save(new MenuAdminService.MenuSaveRequest(
                null, null, CHILD_CODE, "自定义路由", 2, null, pageId, "/object/md.brand", null, 95,
                true, 1, null, true, null, List.of()));
        assertThat(jdbc.queryForObject("SELECT Route FROM plat.[Menu] WHERE Id = ?", String.class, id2))
                .isEqualTo("/object/md.brand");
    }

    @Test
    @DisplayName("校验：编码非法/重复（同层）/上级不存在/父子成环")
    void validation() {
        long parent = createMenu(PARENT_CODE, null, null, List.of());

        assertThatThrownBy(() -> createMenu("1 空格", null, null, List.of()))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("菜单编码");

        assertThatThrownBy(() -> createMenu(PARENT_CODE, null, null, List.of()))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("已存在");

        assertThatThrownBy(() -> createMenu("ITMENU.X", 999_999L, null, List.of()))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("上级菜单不存在");

        long child = createMenu(CHILD_CODE, parent, null, List.of());
        assertThatThrownBy(() -> admin.move(new MenuAdminService.MoveRequest(parent, child, 10)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("下级");
        assertThatThrownBy(() -> admin.move(new MenuAdminService.MoveRequest(parent, parent, 10)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("不能是自己");
    }

    @Test
    @DisplayName("终端可见性：保存后读回，重复保存整体替换")
    void terminals_replace() {
        long id = createMenu(PARENT_CODE, null, null, List.of(1, 2));
        assertThat(admin.terminalsOf(id)).containsExactly(1, 2);

        admin.saveTerminals(id, List.of(3, 4, 5));
        assertThat(admin.terminalsOf(id)).containsExactly(3, 4, 5);

        admin.saveTerminals(id, List.of());
        assertThat(admin.terminalsOf(id)).isEmpty();
    }

    @Test
    @DisplayName("移动：改父节点与排序；叶子节点可删，父节点有子时拒绝删除")
    void move_and_delete() {
        long parent = createMenu(PARENT_CODE, null, null, List.of());
        long child = createMenu(CHILD_CODE, parent, null, List.of());

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
        assertThat(admin.tree("ITMENU", null)).isEmpty();
    }

    @Test
    @DisplayName("管理窗口改完，侧边栏菜单树立即生效（同一张表）")
    void admin_changes_reflect_in_sidebar_tree() {
        long root = createMenu(PARENT_CODE, null, null, List.of(1));
        admin.save(new MenuAdminService.MenuSaveRequest(
                null, root, CHILD_CODE, "子菜单", 2, null, null, "/object/md.brand", null, 10,
                true, 1, null, true, null, List.of(1)));

        List<MenuService.MenuNode> sidebar = menuService.tree(1);
        List<MenuService.MenuNode> mine = sidebar.stream()
                .filter(n -> PARENT_CODE.equals(n.code())).toList();
        assertThat(mine).hasSize(1);
        assertThat(mine.get(0).children()).extracting(MenuService.MenuNode::code).contains(CHILD_CODE);

        // 停用后侧边栏不再下发
        admin.save(new MenuAdminService.MenuSaveRequest(
                root, null, PARENT_CODE, "停用的菜单", 2, null, null, null, null, 90,
                true, 1, null, false, null, List.of(1)));
        assertThat(menuService.tree(1)).extracting(MenuService.MenuNode::code)
                .doesNotContain(PARENT_CODE);
    }

    @Test
    @DisplayName("终端过滤：只勾了 PDA 的菜单不出现在 PC 菜单树里")
    void terminal_filter_in_sidebar() {
        createMenu(PARENT_CODE, null, null, List.of(2));
        assertThat(menuService.tree(1)).extracting(MenuService.MenuNode::code)
                .doesNotContain(PARENT_CODE);
        assertThat(menuService.tree(2)).extracting(MenuService.MenuNode::code)
                .contains(PARENT_CODE);
    }
}

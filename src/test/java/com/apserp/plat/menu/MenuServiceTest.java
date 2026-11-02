package com.apserp.plat.menu;

import static org.assertj.core.api.Assertions.assertThat;

import com.apserp.plat.menu.MenuService.MenuNode;
import com.apserp.plat.menu.MenuService.MenuRow;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;

class MenuServiceTest {

    private static MenuRow row(long id, Long parentId, String code, String name, String moduleCode) {
        return new MenuRow(id, parentId, code, name, "/m/" + code, null, 2, moduleCode);
    }

    private static List<MenuRow> sampleRows() {
        return List.of(
                new MenuRow(1L, null, "01", "平台与主数据", "/01", null, 1, "01"),
                new MenuRow(2L, 1L, "0101", "组织与门店", "/0101", null, 1, "0101"),
                row(3L, 2L, "010101", "公司信息", "010101"),
                row(4L, 2L, "010102", "部门信息", "010102"),
                new MenuRow(5L, null, "02", "采购与供应商", "/02", null, 1, "02"),
                row(6L, 5L, "020101", "采购计划", "020101"));
    }

    @Test
    void buildTree_groups_by_parent_and_keeps_order() {
        List<MenuNode> tree = MenuService.buildTree(sampleRows());

        assertThat(tree).hasSize(2);
        assertThat(tree.get(0).code()).isEqualTo("01");
        assertThat(tree.get(0).children()).hasSize(1);
        assertThat(tree.get(0).children().get(0).children())
                .extracting(MenuNode::code)
                .containsExactly("010101", "010102");
        assertThat(tree.get(1).code()).isEqualTo("02");
    }

    @Test
    void filterTree_keeps_ancestors_and_drops_other_branches() {
        List<MenuNode> tree = MenuService.buildTree(sampleRows());

        List<MenuNode> visible = MenuService.filterTree(tree, Set.of("FUN:010101.VIEW"));

        assertThat(visible).hasSize(1);
        MenuNode domain = visible.get(0);
        assertThat(domain.code()).isEqualTo("01");
        MenuNode module = domain.children().get(0);
        assertThat(module.code()).isEqualTo("0101");
        assertThat(module.children()).extracting(MenuNode::code).containsExactly("010101");
    }

    @Test
    void filterTree_returns_empty_without_grants() {
        List<MenuNode> tree = MenuService.buildTree(sampleRows());

        assertThat(MenuService.filterTree(tree, Set.of())).isEmpty();
        assertThat(MenuService.filterTree(tree, null)).isEmpty();
    }

    @Test
    void permitted_accepts_module_or_function_resource() {
        List<MenuNode> tree = MenuService.buildTree(sampleRows());
        MenuNode domain = tree.get(0);
        MenuNode module = domain.children().get(0);
        MenuNode leaf = module.children().get(0);

        assertThat(MenuService.permitted(domain, Set.of("MOD:01"))).isTrue();
        assertThat(MenuService.permitted(module, Set.of("MOD:0101"))).isTrue();
        assertThat(MenuService.permitted(leaf, Set.of("FUN:010101.VIEW"))).isTrue();
        assertThat(MenuService.permitted(leaf, Set.of("FUN:010102.VIEW"))).isFalse();
    }
}

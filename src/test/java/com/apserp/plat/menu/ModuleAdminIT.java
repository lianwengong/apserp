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
 * 系统功能模块管理集成测试：模块树、层级计算、权限点联动、功能点与动作链、删除保护。
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class ModuleAdminIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    ModuleAdminService admin;

    @Autowired
    JdbcTemplate jdbc;

    private static final String ROOT_CODE = "ITMOD";
    private static final String CHILD_CODE = "ITMOD.SUB";

    @BeforeEach
    void setUp() {
        TenantContext.set(1L, 1L);
        cleanUp();
    }

    @AfterEach
    void tearDown() {
        cleanUp();
        TenantContext.clear();
    }

    private void cleanUp() {
        jdbc.update("DELETE a FROM plat.FunctionAction a JOIN plat.ModuleFunction f ON f.Id = a.FunctionId "
                + "WHERE f.Code LIKE 'ITFN%'");
        jdbc.update("DELETE FROM plat.ModuleFunction WHERE Code LIKE 'ITFN%'");
        jdbc.update("DELETE FROM plat.[Menu] WHERE Code LIKE 'ITMENU%'");
        jdbc.update("DELETE FROM plat.[Module] WHERE Code LIKE 'ITMOD%'");
        jdbc.update("DELETE FROM plat.Permission WHERE ResourceKey IN ('MOD:ITMOD', 'MOD:ITMOD.SUB', "
                + "'FUN:ITFN.VIEW', 'FUN:ITFN.SAVE')");
    }

    private long createModule(String code, Long parentId, boolean perm) {
        return admin.saveModule(new ModuleAdminService.ModuleSaveRequest(
                null, parentId, code, "测试模块 " + code, code, 2, 90, "Setting", "集成测试",
                true, perm, null));
    }

    @Test
    @DisplayName("模块树：返回种子模块（10 个一级域），节点带功能点/菜单计数")
    void tree_has_seed_modules() {
        List<ModuleAdminService.ModuleNode> tree = admin.tree(null);
        assertThat(tree).isNotEmpty();
        assertThat(tree).allSatisfy(node -> assertThat(node.level()).isEqualTo(1));
        int total = count(tree);
        assertThat(total).isGreaterThanOrEqualTo(100);
        ModuleAdminService.ModuleNode first = tree.get(0);
        assertThat(first.code()).isNotBlank();
        assertThat(first.children()).isNotNull();
    }

    private static int count(List<ModuleAdminService.ModuleNode> nodes) {
        int n = 0;
        for (ModuleAdminService.ModuleNode node : nodes) {
            n += 1 + count(node.children());
        }
        return n;
    }

    @Test
    @DisplayName("关键字过滤：命中子节点时保留祖先链")
    void keyword_keeps_ancestors() {
        long parent = createModule(ROOT_CODE, null, false);
        createModule(CHILD_CODE, parent, false);

        List<ModuleAdminService.ModuleNode> hit = admin.tree("ITMOD.SUB");
        assertThat(hit).hasSize(1);
        assertThat(hit.get(0).code()).isEqualTo(ROOT_CODE);
        assertThat(hit.get(0).children()).extracting(ModuleAdminService.ModuleNode::code)
                .containsExactly(CHILD_CODE);

        assertThat(admin.tree("绝对不存在的模块")).isEmpty();
    }

    @Test
    @DisplayName("新增模块：层级按父节点 +1，并自动补权限点 MOD:xxx")
    void create_module_computes_level_and_permission() {
        long parent = createModule(ROOT_CODE, null, true);
        long child = createModule(CHILD_CODE, parent, true);

        Integer level = jdbc.queryForObject(
                "SELECT [Level] FROM plat.[Module] WHERE Id = ?", Integer.class, child);
        assertThat(level).isEqualTo(2);

        assertThat(permissionExists("MOD:" + ROOT_CODE)).isTrue();
        assertThat(permissionExists("MOD:" + CHILD_CODE)).isTrue();
        assertThat(admin.overview()).containsKeys("modules", "functions", "actions", "menus", "permissions");
    }

    @Test
    @DisplayName("模块编码重复、编码非法、名称空都被拒绝")
    void module_validation() {
        createModule(ROOT_CODE, null, false);
        assertThatThrownBy(() -> createModule(ROOT_CODE, null, false))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("已存在");

        assertThatThrownBy(() -> admin.saveModule(new ModuleAdminService.ModuleSaveRequest(
                null, null, "1 空格 非法", "坏编码", null, 1, 10, null, null, true, false, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("模块编码");

        assertThatThrownBy(() -> admin.saveModule(new ModuleAdminService.ModuleSaveRequest(
                null, null, "ITMOD2", " ", null, 1, 10, null, null, true, false, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("名称");
        jdbc.update("DELETE FROM plat.[Module] WHERE Code = 'ITMOD2'");
    }

    @Test
    @DisplayName("父子关系：不能挂到自己或自己的下级")
    void parent_cycle_guard() {
        long parent = createModule(ROOT_CODE, null, false);
        long child = createModule(CHILD_CODE, parent, false);

        assertThatThrownBy(() -> admin.saveModule(new ModuleAdminService.ModuleSaveRequest(
                parent, parent, ROOT_CODE, "自己当爹", null, 2, 10, null, null, true, false, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("不能是自己");

        assertThatThrownBy(() -> admin.saveModule(new ModuleAdminService.ModuleSaveRequest(
                parent, child, ROOT_CODE, "挂到下级", null, 2, 10, null, null, true, false, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("下级");
    }

    @Test
    @DisplayName("功能点：自动补 FUN: 权限点；重复编码拒绝；动作链整体替换")
    void function_and_actions() {
        long moduleId = createModule(ROOT_CODE, null, false);
        long fnId = admin.saveFunction(new ModuleAdminService.FunctionSaveRequest(
                null, moduleId, "ITFN.VIEW", "查看", 1, 10, true, null, null, null, null, true, null));
        assertThat(permissionExists("FUN:ITFN.VIEW")).isTrue();

        assertThatThrownBy(() -> admin.saveFunction(new ModuleAdminService.FunctionSaveRequest(
                null, moduleId, "ITFN.VIEW", "重复", 1, 20, false, null, null, null, null, true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("已存在");

        List<ModuleAdminService.ActionDto> saved = admin.saveActions(fnId, List.of(
                new ModuleAdminService.ActionSaveRequest(1, 1, "OPEN_FORM", null, null, null, false, null, 30, true),
                new ModuleAdminService.ActionSaveRequest(2, 2, null, "/object/md.brand", null, null, true, null, 0, true)));
        assertThat(saved).hasSize(2);
        assertThat(saved).extracting(ModuleAdminService.ActionDto::seq).containsExactly(10, 20);

        List<ModuleAdminService.ActionDto> replaced = admin.saveActions(fnId, List.of(
                new ModuleAdminService.ActionSaveRequest(1, 1, "DELETE", null, null, null, false, null, 30, true)));
        assertThat(replaced).hasSize(1);
        assertThat(replaced.get(0).actionCode()).isEqualTo("DELETE");

        admin.deleteFunction(fnId);
        assertThat(admin.functionsOf(moduleId)).isEmpty();
    }

    @Test
    @DisplayName("删除保护：有子模块/功能点时拒绝，force 才能删")
    void delete_guard() {
        long parent = createModule(ROOT_CODE, null, false);
        createModule(CHILD_CODE, parent, false);

        assertThatThrownBy(() -> admin.deleteModule(parent, false))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("子模块");

        admin.deleteModule(parent, true);
        assertThat(admin.tree(null).stream().flatMap(n -> n.children().stream())
                .map(ModuleAdminService.ModuleNode::code)).doesNotContain(CHILD_CODE);
    }

    @Test
    @DisplayName("改编码会连带改权限点，避免留下孤儿资源")
    void rename_code_moves_permission() {
        long id = createModule(ROOT_CODE, null, true);
        assertThat(permissionExists("MOD:" + ROOT_CODE)).isTrue();

        admin.saveModule(new ModuleAdminService.ModuleSaveRequest(
                id, null, ROOT_CODE + "X", "改名", null, 2, 90, null, null, true, false, null));
        assertThat(permissionExists("MOD:" + ROOT_CODE + "X")).isTrue();
        assertThat(permissionExists("MOD:" + ROOT_CODE)).isFalse();
        jdbc.update("DELETE FROM plat.Permission WHERE ResourceKey = ?", "MOD:" + ROOT_CODE + "X");
    }

    @Test
    @DisplayName("模型关系图：给出模块/功能点/菜单/终端的实际规模与「没接通」的警告")
    void model_map_reports_real_shape() {
        java.util.Map<String, Object> map = admin.modelMap();
        assertThat(map).containsKeys("modules", "functions", "menus", "terminals", "permissions", "subsystem", "warnings");

        @SuppressWarnings("unchecked")
        java.util.Map<String, Object> modules = (java.util.Map<String, Object>) map.get("modules");
        assertThat(((Number) modules.get("level1")).intValue()).isGreaterThanOrEqualTo(10);
        assertThat(((Number) modules.get("total")).intValue())
                .isEqualTo(((Number) modules.get("level1")).intValue()
                        + ((Number) modules.get("level2")).intValue()
                        + ((Number) modules.get("level3")).intValue());

        @SuppressWarnings("unchecked")
        java.util.Map<String, Object> menus = (java.util.Map<String, Object>) map.get("menus");
        int total = ((Number) menus.get("total")).intValue();
        int bound = ((Number) menus.get("boundToModule")).intValue();
        int unbound = ((Number) menus.get("unboundModule")).intValue();
        assertThat(bound + unbound).isEqualTo(total);

        @SuppressWarnings("unchecked")
        java.util.Map<String, Object> subsystem = (java.util.Map<String, Object>) map.get("subsystem");
        assertThat(subsystem.get("implemented")).isEqualTo(false);

        // 模块终端是空表时必须有明确警告（否则按模块配终端不会生效这件事没人知道）
        @SuppressWarnings("unchecked")
        java.util.Map<String, Object> terminals = (java.util.Map<String, Object>) map.get("terminals");
        @SuppressWarnings("unchecked")
        java.util.List<String> warnings = (java.util.List<String>) map.get("warnings");
        if (((Number) terminals.get("moduleTerminalRows")).intValue() == 0) {
            assertThat(warnings).anyMatch(w -> w.contains("ModuleTerminal"));
        }
    }

    @Test
    @DisplayName("删除模块/功能点会连带清掉权限点，不留孤儿资源")
    void delete_drops_permission() {
        long moduleId = createModule(ROOT_CODE, null, true);
        long fnId = admin.saveFunction(new ModuleAdminService.FunctionSaveRequest(
                null, moduleId, "ITFN.VIEW", "查看", 1, 10, true, null, null, null, null, true, null));
        assertThat(permissionExists("MOD:" + ROOT_CODE)).isTrue();
        assertThat(permissionExists("FUN:ITFN.VIEW")).isTrue();

        admin.deleteFunction(fnId);
        assertThat(permissionExists("FUN:ITFN.VIEW")).isFalse();

        admin.deleteModule(moduleId, false);
        assertThat(permissionExists("MOD:" + ROOT_CODE)).isFalse();
    }

    private boolean permissionExists(String key) {
        Integer n = jdbc.queryForObject(
                "SELECT COUNT(*) FROM plat.Permission WHERE TenantId = 1 AND ResourceKey = ?",
                Integer.class, key);
        return n != null && n > 0;
    }
}

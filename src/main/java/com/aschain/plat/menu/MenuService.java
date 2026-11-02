package com.aschain.plat.menu;

import com.aschain.common.tenant.TenantContext;
import com.aschain.plat.perm.PermissionService;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/**
 * 菜单树：把 plat.Menu 里已配置的功能模块按 ParentId 组装成树，供前端侧边栏渲染。
 *
 * <p>权限：平台管理员返回全量；普通用户按 {@link PermissionService#grantedResources()}
 * 过滤（MOD:模块编码 或 FUN:功能编码.动作），父节点只要有可见子节点就保留。</p>
 *
 * <p>终端：每条菜单只属于一个终端（{@code Menu.TerminalType}），按终端号直接过滤；
 * 终端能用哪些功能模块由 {@code plat.ModuleTerminal} 决定，写菜单时就已校验过
 * （见 {@link MenuAdminService#save}），所以这里不需要再校验一遍。</p>
 */
@Service
public class MenuService {

    private static final Logger log = LoggerFactory.getLogger(MenuService.class);

    private final JdbcTemplate jdbc;
    private final PermissionService permissionService;

    public MenuService(JdbcTemplate jdbc, PermissionService permissionService) {
        this.jdbc = jdbc;
        this.permissionService = permissionService;
    }

    public record MenuNode(long id, Long parentId, String code, String name, String route,
                           String icon, int menuType, String moduleCode, List<MenuNode> children) {
    }

    record MenuRow(long id, Long parentId, String code, String name, String route, String icon,
                   int menuType, String moduleCode) {
    }

    private static final String SQL_TREE = """
            SELECT m.Id, m.ParentId, m.Code, m.Name, m.Route, m.Icon, m.MenuType,
                   md.Code AS ModuleCode
            FROM plat.[Menu] m
            LEFT JOIN plat.[Module] md ON md.Id = m.ModuleId AND md.TenantId = m.TenantId
            WHERE m.TenantId = ?
              AND m.TerminalType = ?
              AND m.IsDeleted = 0 AND m.IsEnabled = 1 AND m.IsVisible = 1
            ORDER BY m.Sort, m.Id
            """;

    public List<MenuNode> tree(int terminal) {
        long tenantId = TenantContext.requireTenantId();
        int term = terminal < 1 || terminal > 6 ? 1 : terminal;
        List<MenuRow> rows = jdbc.query(SQL_TREE,
                (rs, i) -> new MenuRow(
                        rs.getLong("Id"),
                        rs.getObject("ParentId", Long.class),
                        rs.getString("Code"),
                        rs.getString("Name"),
                        rs.getString("Route"),
                        rs.getString("Icon"),
                        rs.getInt("MenuType"),
                        rs.getString("ModuleCode")),
                tenantId, term);
        List<MenuNode> all = buildTree(rows);
        if (TenantContext.isPlatformAdmin()) {
            log.debug("menu_tree tenant={} terminal={} total={}", tenantId, term, count(all));
            return all;
        }
        List<MenuNode> visible = filterTree(all, permissionService.grantedResources());
        log.debug("menu_tree tenant={} terminal={} total={} visible={}",
                tenantId, term, count(all), count(visible));
        return visible;
    }

    /** 按 ParentId 组树；父节点不在结果集里（被禁用/过滤）时提升为根，避免整棵子树消失。 */
    static List<MenuNode> buildTree(List<MenuRow> rows) {
        Map<Long, List<MenuRow>> byParent = new LinkedHashMap<>();
        Set<Long> ids = new LinkedHashSet<>();
        for (MenuRow row : rows) {
            ids.add(row.id());
            if (row.parentId() != null) {
                byParent.computeIfAbsent(row.parentId(), key -> new ArrayList<>()).add(row);
            }
        }
        List<MenuNode> roots = new ArrayList<>();
        for (MenuRow row : rows) {
            if (row.parentId() == null || !ids.contains(row.parentId())) {
                roots.add(toNode(row, byParent));
            }
        }
        return roots;
    }

    private static MenuNode toNode(MenuRow row, Map<Long, List<MenuRow>> byParent) {
        List<MenuNode> children = new ArrayList<>();
        for (MenuRow child : byParent.getOrDefault(row.id(), List.of())) {
            children.add(toNode(child, byParent));
        }
        return new MenuNode(row.id(), row.parentId(), row.code(), row.name(), row.route(),
                row.icon(), row.menuType(), row.moduleCode(), children);
    }

    static List<MenuNode> filterTree(List<MenuNode> nodes, Set<String> resources) {
        if (resources == null || resources.isEmpty()) {
            return List.of();
        }
        List<MenuNode> result = new ArrayList<>();
        for (MenuNode node : nodes) {
            MenuNode kept = filterNode(node, resources);
            if (kept != null) {
                result.add(kept);
            }
        }
        return result;
    }

    private static MenuNode filterNode(MenuNode node, Set<String> resources) {
        List<MenuNode> children = new ArrayList<>();
        for (MenuNode child : node.children()) {
            MenuNode kept = filterNode(child, resources);
            if (kept != null) {
                children.add(kept);
            }
        }
        if (children.isEmpty() && !permitted(node, resources)) {
            return null;
        }
        return new MenuNode(node.id(), node.parentId(), node.code(), node.name(), node.route(),
                node.icon(), node.menuType(), node.moduleCode(), children);
    }

    static boolean permitted(MenuNode node, Set<String> resources) {
        String moduleCode = node.moduleCode();
        if (moduleCode != null && !moduleCode.isBlank()) {
            if (resources.contains("MOD:" + moduleCode)) {
                return true;
            }
            String prefix = "MOD:" + moduleCode + ".";
            if (resources.stream().anyMatch(resource -> resource.startsWith(prefix))) {
                return true;
            }
        }
        String code = node.code();
        if (code != null && !code.isBlank()) {
            if (resources.contains("FUN:" + code)) {
                return true;
            }
            String prefix = "FUN:" + code + ".";
            if (resources.stream().anyMatch(resource -> resource.startsWith(prefix))) {
                return true;
            }
        }
        return false;
    }

    private static int count(List<MenuNode> nodes) {
        int total = 0;
        for (MenuNode node : nodes) {
            total += 1 + count(node.children());
        }
        return total;
    }
}

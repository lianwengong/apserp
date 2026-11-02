package com.apserp.plat.menu;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.tenant.TenantContext;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 菜单设置管理：维护 {@code plat.Menu} 树与 {@code plat.MenuTerminal} 终端可见性。
 *
 * <p>侧边栏渲染的就是这棵树（见 {@link MenuService#tree(int)}），所以本窗口改完立即生效，
 * 不需要发版。三件事必须在服务端把关：</p>
 * <ol>
 *   <li>父子关系不能成环（否则树渲染会无限递归）；</li>
 *   <li>同一父节点下编码唯一（历史数据里出现过同名重复菜单，已由 V37 治理）；</li>
 *   <li>绑定了页面却没写路由时，自动补 {@code /m/{code}}，避免菜单点了没反应；</li>
 *   <li><b>菜单必须指定唯一终端</b>，且它绑定的功能模块必须在该终端已启用
 *       （{@code plat.ModuleTerminal}），否则拒绝保存 —— 否则会出现「PDA 上点开一个 PC 才有的功能」。</li>
 * </ol>
 */
@Service
public class MenuAdminService {

    private static final Logger log = LoggerFactory.getLogger(MenuAdminService.class);

    private static final String CODE_PATTERN = "[A-Za-z0-9][A-Za-z0-9_.-]{0,59}";

    private final JdbcTemplate jdbc;

    public MenuAdminService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    // ---------------------------------------------------------------- DTO

    public record MenuNode(long id, Long parentId, String code, String name, int menuType,
                           Long moduleId, String moduleCode, Long pageId, String pageCode,
                           String route, String icon, int sort, boolean visible, int openMode,
                           String badgeExpr, boolean enabled, String remark,
                           int terminalType, List<MenuNode> children) {
    }

    public record MenuSaveRequest(Long id, Long parentId, String code, String name, int menuType,
                                  Long moduleId, Long pageId, String route, String icon, int sort,
                                  boolean visible, int openMode, String badgeExpr, boolean enabled,
                                  String remark, int terminalType) {
    }

    public record MoveRequest(long id, Long parentId, int sort) {
    }

    public record OptionDto(long id, String code, String name, Long parentId) {
    }

    // ---------------------------------------------------------------- 查询

    /**
     * 菜单树：管理窗口要看到停用/隐藏的节点，因此 <b>不过滤</b> IsEnabled/IsVisible。
     */
    public List<MenuNode> tree(String keyword, Long moduleId, Integer terminalType) {
        long tenantId = TenantContext.requireTenantId();
        List<MenuNode> rows = jdbc.query("""
                        SELECT m.Id, m.ParentId, m.Code, m.Name, m.MenuType, m.ModuleId,
                               md.Code AS ModuleCode, m.PageId, p.Code AS PageCode, m.Route,
                               m.Icon, m.Sort, m.IsVisible, m.OpenMode, m.BadgeExpr, m.IsEnabled,
                               m.Remark, m.TerminalType
                        FROM plat.[Menu] m
                        LEFT JOIN plat.[Module] md ON md.Id = m.ModuleId AND md.TenantId = m.TenantId
                        LEFT JOIN plat.[Page] p ON p.Id = m.PageId AND p.TenantId = m.TenantId
                        WHERE m.TenantId = ? AND m.IsDeleted = 0
                        ORDER BY m.Sort, m.Id
                        """,
                (rs, i) -> new MenuNode(rs.getLong("Id"), rs.getObject("ParentId", Long.class),
                        rs.getString("Code"), rs.getString("Name"), rs.getInt("MenuType"),
                        rs.getObject("ModuleId", Long.class), rs.getString("ModuleCode"),
                        rs.getObject("PageId", Long.class), rs.getString("PageCode"),
                        rs.getString("Route"), rs.getString("Icon"), rs.getInt("Sort"),
                        rs.getBoolean("IsVisible"), rs.getInt("OpenMode"), rs.getString("BadgeExpr"),
                        rs.getBoolean("IsEnabled"), rs.getString("Remark"),
                        rs.getInt("TerminalType"), List.of()),
                tenantId);
        List<MenuNode> tree = buildTree(rows);
        if (moduleId != null && moduleId > 0) {
            tree = filterByModule(tree, moduleId);
        }
        if (terminalType != null && terminalType >= 1 && terminalType <= 6) {
            tree = filterByTerminal(tree, terminalType);
        }
        String key = keyword == null ? "" : keyword.trim().toLowerCase();
        if (key.isEmpty()) {
            return tree;
        }
        return filter(tree, key);
    }

    private static List<MenuNode> buildTree(List<MenuNode> rows) {
        Map<Long, List<MenuNode>> byParent = new LinkedHashMap<>();
        for (MenuNode row : rows) {
            if (row.parentId() != null) {
                byParent.computeIfAbsent(row.parentId(), k -> new ArrayList<>()).add(row);
            }
        }
        List<MenuNode> roots = new ArrayList<>();
        for (MenuNode row : rows) {
            if (row.parentId() == null || rows.stream().noneMatch(r -> r.id() == row.parentId())) {
                roots.add(withChildren(row, byParent));
            }
        }
        return roots;
    }

    private static MenuNode withChildren(MenuNode row, Map<Long, List<MenuNode>> byParent) {
        List<MenuNode> children = new ArrayList<>();
        for (MenuNode child : byParent.getOrDefault(row.id(), List.of())) {
            children.add(withChildren(child, byParent));
        }
        return copy(row, children);
    }

    private static MenuNode copy(MenuNode row, List<MenuNode> children) {
        return new MenuNode(row.id(), row.parentId(), row.code(), row.name(), row.menuType(),
                row.moduleId(), row.moduleCode(), row.pageId(), row.pageCode(), row.route(),
                row.icon(), row.sort(), row.visible(), row.openMode(), row.badgeExpr(),
                row.enabled(), row.remark(), row.terminalType(), children);
    }

    private static List<MenuNode> filterByTerminal(List<MenuNode> nodes, int terminalType) {
        List<MenuNode> out = new ArrayList<>();
        for (MenuNode node : nodes) {
            List<MenuNode> children = filterByTerminal(node.children(), terminalType);
            if (node.terminalType() == terminalType || !children.isEmpty()) {
                out.add(copy(node, children));
            }
        }
        return out;
    }

    private static List<MenuNode> filterByModule(List<MenuNode> nodes, long moduleId) {
        List<MenuNode> out = new ArrayList<>();
        for (MenuNode node : nodes) {
            List<MenuNode> children = filterByModule(node.children(), moduleId);
            if ((node.moduleId() != null && node.moduleId() == moduleId) || !children.isEmpty()) {
                out.add(copy(node, children));
            }
        }
        return out;
    }

    private static List<MenuNode> filter(List<MenuNode> nodes, String keyword) {
        List<MenuNode> out = new ArrayList<>();
        for (MenuNode node : nodes) {
            List<MenuNode> children = filter(node.children(), keyword);
            boolean hit = (node.code() != null && node.code().toLowerCase().contains(keyword))
                    || (node.name() != null && node.name().toLowerCase().contains(keyword));
            if (hit || !children.isEmpty()) {
                out.add(copy(node, children));
            }
        }
        return out;
    }

    /** 表单下拉选项：模块与页面。 */
    public Map<String, Object> options() {
        long tenantId = TenantContext.requireTenantId();
        List<OptionDto> modules = jdbc.query("""
                        SELECT Id, Code, Name, ParentId FROM plat.[Module]
                        WHERE TenantId = ? AND IsDeleted = 0 ORDER BY [Level], Sort, Code
                        """,
                (rs, i) -> new OptionDto(rs.getLong("Id"), rs.getString("Code"),
                        rs.getString("Name"), rs.getObject("ParentId", Long.class)),
                tenantId);
        List<OptionDto> pages = jdbc.query("""
                        SELECT Id, Code, Name, ModuleId AS ParentId FROM plat.[Page]
                        WHERE TenantId = ? AND IsDeleted = 0 ORDER BY Code
                        """,
                (rs, i) -> new OptionDto(rs.getLong("Id"), rs.getString("Code"),
                        rs.getString("Name"), rs.getObject("ParentId", Long.class)),
                tenantId);
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("modules", modules);
        m.put("pages", pages);
        m.put("menuTypes", List.of(
                Map.of("value", 1, "label", "目录"),
                Map.of("value", 2, "label", "功能菜单"),
                Map.of("value", 3, "label", "外部链接"),
                Map.of("value", 4, "label", "分隔线")));
        m.put("openModes", List.of(
                Map.of("value", 1, "label", "当前标签页"),
                Map.of("value", 2, "label", "新窗口"),
                Map.of("value", 3, "label", "弹窗")));
        m.put("terminalTypes", List.of(
                Map.of("value", 1, "label", "PC"),
                Map.of("value", 2, "label", "PDA"),
                Map.of("value", 3, "label", "POS"),
                Map.of("value", 4, "label", "移动"),
                Map.of("value", 5, "label", "小程序"),
                Map.of("value", 6, "label", "其他")));
        return m;
    }

    // ---------------------------------------------------------------- 保存

    @Transactional
    public long save(MenuSaveRequest req) {
        long tenantId = TenantContext.requireTenantId();
        String code = req.code() == null ? "" : req.code().trim();
        if (!code.matches(CODE_PATTERN)) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "菜单编码只能是字母/数字/._-，且不超过 60 字");
        }
        if (req.name() == null || req.name().isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "菜单名称不能为空");
        }
        Long parentId = req.parentId() == null || req.parentId() <= 0 ? null : req.parentId();
        if (parentId != null) {
            if (req.id() != null && Objects.equals(req.id(), parentId)) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "上级菜单不能是自己");
            }
            Integer parentExists = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM plat.[Menu] WHERE TenantId = ? AND Id = ? AND IsDeleted = 0
                    """, Integer.class, tenantId, parentId);
            if (parentExists == null || parentExists == 0) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "上级菜单不存在");
            }
            if (req.id() != null && isDescendant(parentId, req.id())) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "不能把菜单挂到自己的下级节点下");
            }
        }
        Long moduleId = req.moduleId() == null || req.moduleId() <= 0 ? null : req.moduleId();
        int terminalType = req.terminalType() < 1 || req.terminalType() > 6 ? 1 : req.terminalType();
        if (moduleId != null) {
            Integer exists = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM plat.[Module] WHERE TenantId = ? AND Id = ? AND IsDeleted = 0
                    """, Integer.class, tenantId, moduleId);
            if (exists == null || exists == 0) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "绑定的模块不存在");
            }
            // 核心规则：菜单的功能模块必须是该终端下启用的模块
            Integer enabled = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM plat.ModuleTerminal
                    WHERE TenantId = ? AND ModuleId = ? AND TerminalType = ?
                    """, Integer.class, tenantId, moduleId, terminalType);
            if (enabled == null || enabled == 0) {
                String moduleName = jdbc.query("""
                        SELECT Code + ' ' + Name FROM plat.[Module] WHERE Id = ?
                        """, rs -> rs.next() ? rs.getString(1) : String.valueOf(moduleId), moduleId);
                throw new ApiException(ErrorCode.BAD_REQUEST,
                        "模块「" + moduleName + "」未在终端「" + TerminalAdminService.label(terminalType)
                                + "」启用，请先在「终端与功能」里为该终端启用这个模块");
            }
        }
        Long pageId = req.pageId() == null || req.pageId() <= 0 ? null : req.pageId();
        if (pageId != null) {
            Integer exists = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM plat.[Page] WHERE TenantId = ? AND Id = ? AND IsDeleted = 0
                    """, Integer.class, tenantId, pageId);
            if (exists == null || exists == 0) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "绑定的页面不存在");
            }
        }
        Integer dup = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.[Menu]
                WHERE TenantId = ? AND ISNULL(ParentId, 0) = ISNULL(?, 0) AND Code = ?
                  AND IsDeleted = 0 AND Id <> ISNULL(?, -1)
                """, Integer.class, tenantId, parentId, code, req.id());
        if (dup != null && dup > 0) {
            throw new ApiException(ErrorCode.DUPLICATE_KEY, "同一层级下菜单编码已存在：" + code);
        }

        // 绑了页面却没写路由：自动补 /m/{code}，否则点击菜单没有反应
        String route = req.route() == null ? null : req.route().trim();
        if ((route == null || route.isEmpty()) && pageId != null) {
            route = "/m/" + code;
        }
        int menuType = req.menuType() < 1 || req.menuType() > 4 ? 2 : req.menuType();
        int openMode = req.openMode() < 1 || req.openMode() > 3 ? 1 : req.openMode();

        long id;
        if (req.id() != null) {
            int n = jdbc.update("""
                    UPDATE plat.[Menu]
                    SET ParentId = ?, Code = ?, Name = ?, MenuType = ?, ModuleId = ?, PageId = ?,
                        Route = ?, Icon = ?, Sort = ?, IsVisible = ?, OpenMode = ?, BadgeExpr = ?,
                        IsEnabled = ?, Remark = ?, TerminalType = ?, ModifiedAt = sysutcdatetime()
                    WHERE Id = ? AND TenantId = ?
                    """, parentId, code, req.name(), menuType, moduleId, pageId, route, req.icon(),
                    req.sort(), req.visible() ? 1 : 0, openMode, req.badgeExpr(),
                    req.enabled() ? 1 : 0, req.remark(), terminalType, req.id(), tenantId);
            if (n == 0) {
                throw new ApiException(ErrorCode.NOT_FOUND, "菜单不存在：" + req.id());
            }
            id = req.id();
        } else {
            jdbc.update("""
                    INSERT plat.[Menu] (TenantId, ParentId, Code, Name, MenuType, ModuleId, PageId,
                                        Route, Icon, Sort, IsVisible, OpenMode, BadgeExpr, IsEnabled,
                                        Remark, TerminalType, CreatedAt)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, sysutcdatetime())
                    """, tenantId, parentId, code, req.name(), menuType, moduleId, pageId, route,
                    req.icon(), req.sort(), req.visible() ? 1 : 0, openMode, req.badgeExpr(),
                    req.enabled() ? 1 : 0, req.remark(), terminalType);
            id = jdbc.queryForObject("""
                    SELECT MAX(Id) FROM plat.[Menu]
                    WHERE TenantId = ? AND ISNULL(ParentId, 0) = ISNULL(?, 0) AND Code = ?
                    """, Long.class, tenantId, parentId, code);
        }
        syncMenuTerminal(id, terminalType, req.sort());
        log.info("menu_save tenant={} id={} code={} parent={} module={} page={} terminal={}",
                tenantId, id, code, parentId, moduleId, pageId, terminalType);
        return id;
    }

    /**
     * 让 MenuTerminal 与 Menu.TerminalType 保持一致（一个菜单一行）。
     *
     * <p>这张表从 V41 起不再是"一条菜单挂多终端"，而是终端的<b>镜像</b>，
     * 只为了保证还没改过来的旧查询（BI、运维脚本）不突然读不到数据。
     * 写入的真相只有 {@code Menu.TerminalType} 一处。</p>
     */
    private void syncMenuTerminal(long menuId, int terminalType, int sort) {
        jdbc.update("DELETE FROM plat.MenuTerminal WHERE MenuId = ?", menuId);
        jdbc.update("""
                INSERT plat.MenuTerminal (MenuId, TerminalType, IsVisible, Sort)
                VALUES (?, ?, 1, ?)
                """, menuId, terminalType, sort);
    }

    /** 拖拽/上移下移：只改父节点与排序，父子成环在这里再拦一次。 */
    @Transactional
    public void move(MoveRequest req) {
        long tenantId = TenantContext.requireTenantId();
        Long parentId = req.parentId() == null || req.parentId() <= 0 ? null : req.parentId();
        if (parentId != null) {
            if (Objects.equals(req.id(), parentId)) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "上级菜单不能是自己");
            }
            if (isDescendant(parentId, req.id())) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "不能移动到自己的下级节点下");
            }
        }
        int n = jdbc.update("""
                UPDATE plat.[Menu] SET ParentId = ?, Sort = ?, ModifiedAt = sysutcdatetime()
                WHERE Id = ? AND TenantId = ?
                """, parentId, req.sort(), req.id(), tenantId);
        if (n == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND, "菜单不存在：" + req.id());
        }
        log.info("menu_move tenant={} id={} parent={} sort={}", tenantId, req.id(), parentId, req.sort());
    }

    @Transactional
    public void delete(long id) {
        long tenantId = TenantContext.requireTenantId();
        Integer children = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.[Menu] WHERE TenantId = ? AND ParentId = ? AND IsDeleted = 0
                """, Integer.class, tenantId, id);
        if (children != null && children > 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                    "该菜单下还有 " + children + " 个子菜单，请先删除或用移动把它们挂到别处");
        }
        int n = jdbc.update("""
                UPDATE plat.[Menu] SET IsDeleted = 1, IsEnabled = 0, DeletedAt = sysutcdatetime()
                WHERE Id = ? AND TenantId = ?
                """, id, tenantId);
        if (n == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND, "菜单不存在：" + id);
        }
        jdbc.update("DELETE FROM plat.MenuTerminal WHERE MenuId = ?", id);
        log.info("menu_delete tenant={} id={}", tenantId, id);
    }

    private boolean isDescendant(long candidate, long ancestorId) {
        long tenantId = TenantContext.requireTenantId();
        Long current = candidate;
        int guard = 0;
        while (current != null && guard++ < 64) {
            Long parent = jdbc.query("""
                            SELECT ParentId FROM plat.[Menu] WHERE TenantId = ? AND Id = ?
                            """, rs -> rs.next() ? rs.getObject(1, Long.class) : null, tenantId, current);
            if (parent == null) {
                return false;
            }
            if (parent == ancestorId) {
                return true;
            }
            current = parent;
        }
        return false;
    }
}

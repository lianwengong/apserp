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
 * 系统功能模块管理：维护「功能模块 → 功能点 → 动作链」三级结构。
 *
 * <p>为什么要有这个窗口：模块（635 条）与功能点（1432 条）此前全是种子数据，
 * 加一个功能点、改一次排序都要写迁移脚本；而权限点 {@code MOD:xx} / {@code FUN:xx}
 * 又是权限设计器的数据源，两边靠人肉保持同步必然漂移。</p>
 *
 * <p>本服务把三件事绑在一起：<b>保存模块/功能点时自动补权限点</b>、
 * <b>删除前检查引用（子模块/功能点/菜单）</b>、<b>层级与排序由服务端算</b>。</p>
 */
@Service
public class ModuleAdminService {

    private static final Logger log = LoggerFactory.getLogger(ModuleAdminService.class);

    /** 模块编码：字母数字与 ._-，用于生成权限点 MOD:xxx 与前端资源标识。 */
    private static final String CODE_PATTERN = "[A-Za-z0-9][A-Za-z0-9_.-]{0,59}";

    private final JdbcTemplate jdbc;

    public ModuleAdminService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    // ---------------------------------------------------------------- DTO

    public record ModuleNode(long id, Long parentId, String code, String name, String enCode,
                             int level, int moduleType, int sort, String icon, String description,
                             boolean enabled, int functionCount, int menuCount, int childCount,
                             List<ModuleNode> children) {
    }

    public record ActionDto(long id, int seq, int phase, int actionType, String actionCode,
                            String target, String command, String paramJson,
                            boolean continueOnError, String errorMessage, int timeoutSeconds,
                            boolean enabled) {
    }

    public record FunctionDto(long id, long moduleId, String code, String name, int funType,
                              int sort, boolean permissionPoint, String confirmText,
                              String successMessage, String icon, String hotKey, boolean enabled,
                              String remark, List<ActionDto> actions) {
    }

    public record ModuleSaveRequest(Long id, Long parentId, String code, String name, String enCode,
                                    int moduleType, int sort, String icon, String description,
                                    boolean enabled, boolean createPermission, String remark) {
    }

    public record FunctionSaveRequest(Long id, Long moduleId, String code, String name, int funType,
                                      int sort, boolean permissionPoint, String confirmText,
                                      String successMessage, String icon, String hotKey,
                                      boolean enabled, String remark) {
    }

    public record ActionSaveRequest(int phase, int actionType, String actionCode, String target,
                                    String command, String paramJson, boolean continueOnError,
                                    String errorMessage, int timeoutSeconds, boolean enabled) {
    }

    // ---------------------------------------------------------------- 模块树

    /**
     * 模块树：包含停用节点（管理窗口要能改回来），按 Sort 排序。
     *
     * @param keyword 按编码/名称过滤；命中子节点时保留整条祖先链
     */
    public List<ModuleNode> tree(String keyword) {
        long tenantId = TenantContext.requireTenantId();
        List<ModuleNode> all = jdbc.query("""
                        SELECT m.Id, m.ParentId, m.Code, m.Name, m.EnCode, m.[Level], m.ModuleType,
                               m.Sort, m.Icon, m.Description, m.IsEnabled,
                               (SELECT COUNT(*) FROM plat.ModuleFunction f
                                 WHERE f.ModuleId = m.Id AND f.IsDeleted = 0) AS FunctionCount,
                               (SELECT COUNT(*) FROM plat.[Menu] mn
                                 WHERE mn.ModuleId = m.Id AND mn.IsDeleted = 0) AS MenuCount
                        FROM plat.[Module] m
                        WHERE m.TenantId = ? AND m.IsDeleted = 0
                        ORDER BY m.[Level], m.Sort, m.Id
                        """,
                (rs, i) -> new ModuleNode(rs.getLong("Id"), rs.getObject("ParentId", Long.class),
                        rs.getString("Code"), rs.getString("Name"), rs.getString("EnCode"),
                        rs.getInt("Level"), rs.getInt("ModuleType"), rs.getInt("Sort"),
                        rs.getString("Icon"), rs.getString("Description"), rs.getBoolean("IsEnabled"),
                        rs.getInt("FunctionCount"), rs.getInt("MenuCount"), 0, List.of()),
                tenantId);
        List<ModuleNode> tree = buildTree(all);
        String key = keyword == null ? "" : keyword.trim().toLowerCase();
        if (key.isEmpty()) {
            return tree;
        }
        return filter(tree, key);
    }

    private static List<ModuleNode> buildTree(List<ModuleNode> rows) {
        Map<Long, List<ModuleNode>> byParent = new LinkedHashMap<>();
        for (ModuleNode row : rows) {
            if (row.parentId() != null) {
                byParent.computeIfAbsent(row.parentId(), k -> new ArrayList<>()).add(row);
            }
        }
        List<ModuleNode> roots = new ArrayList<>();
        for (ModuleNode row : rows) {
            if (row.parentId() == null || rows.stream().noneMatch(r -> r.id() == row.parentId())) {
                roots.add(withChildren(row, byParent));
            }
        }
        return roots;
    }

    private static ModuleNode withChildren(ModuleNode row, Map<Long, List<ModuleNode>> byParent) {
        List<ModuleNode> children = new ArrayList<>();
        for (ModuleNode child : byParent.getOrDefault(row.id(), List.of())) {
            children.add(withChildren(child, byParent));
        }
        return new ModuleNode(row.id(), row.parentId(), row.code(), row.name(), row.enCode(),
                row.level(), row.moduleType(), row.sort(), row.icon(), row.description(),
                row.enabled(), row.functionCount(), row.menuCount(), children.size(), children);
    }

    /** 关键字过滤：命中节点连同祖先链一起保留，子节点继续递归。 */
    private static List<ModuleNode> filter(List<ModuleNode> nodes, String keyword) {
        List<ModuleNode> out = new ArrayList<>();
        for (ModuleNode node : nodes) {
            List<ModuleNode> children = filter(node.children(), keyword);
            boolean hit = matches(node, keyword);
            if (hit || !children.isEmpty()) {
                out.add(new ModuleNode(node.id(), node.parentId(), node.code(), node.name(),
                        node.enCode(), node.level(), node.moduleType(), node.sort(), node.icon(),
                        node.description(), node.enabled(), node.functionCount(), node.menuCount(),
                        children.size(), children));
            }
        }
        return out;
    }

    private static boolean matches(ModuleNode node, String keyword) {
        return (node.code() != null && node.code().toLowerCase().contains(keyword))
                || (node.name() != null && node.name().toLowerCase().contains(keyword));
    }

    // ---------------------------------------------------------------- 功能点

    public List<FunctionDto> functionsOf(long moduleId) {
        long tenantId = TenantContext.requireTenantId();
        List<FunctionDto> heads = jdbc.query("""
                        SELECT Id, ModuleId, Code, Name, FunType, Sort, IsPermissionPoint, ConfirmText,
                               SuccessMessage, Icon, HotKey, IsEnabled, Remark
                        FROM plat.ModuleFunction
                        WHERE TenantId = ? AND ModuleId = ? AND IsDeleted = 0
                        ORDER BY Sort, Id
                        """,
                (rs, i) -> new FunctionDto(rs.getLong("Id"), rs.getLong("ModuleId"),
                        rs.getString("Code"), rs.getString("Name"), rs.getInt("FunType"),
                        rs.getInt("Sort"), rs.getBoolean("IsPermissionPoint"),
                        rs.getString("ConfirmText"), rs.getString("SuccessMessage"),
                        rs.getString("Icon"), rs.getString("HotKey"), rs.getBoolean("IsEnabled"),
                        rs.getString("Remark"), List.of()),
                tenantId, moduleId);
        return heads.stream().map(f -> new FunctionDto(f.id(), f.moduleId(), f.code(), f.name(),
                f.funType(), f.sort(), f.permissionPoint(), f.confirmText(), f.successMessage(),
                f.icon(), f.hotKey(), f.enabled(), f.remark(), actionsOf(f.id()))).toList();
    }

    private List<ActionDto> actionsOf(long functionId) {
        return jdbc.query("""
                        SELECT Id, Seq, Phase, ActionType, ActionCode, Target, Command, ParamJson,
                               ContinueOnError, ErrorMessage, TimeoutSeconds, IsEnabled
                        FROM plat.FunctionAction
                        WHERE FunctionId = ?
                        ORDER BY Seq, Id
                        """,
                (rs, i) -> new ActionDto(rs.getLong("Id"), rs.getInt("Seq"), rs.getInt("Phase"),
                        rs.getInt("ActionType"), rs.getString("ActionCode"), rs.getString("Target"),
                        rs.getString("Command"), rs.getString("ParamJson"),
                        rs.getBoolean("ContinueOnError"), rs.getString("ErrorMessage"),
                        rs.getInt("TimeoutSeconds"), rs.getBoolean("IsEnabled")),
                functionId);
    }

    // ---------------------------------------------------------------- 保存模块

    @Transactional
    public long saveModule(ModuleSaveRequest req) {
        long tenantId = TenantContext.requireTenantId();
        String code = req.code() == null ? "" : req.code().trim();
        if (!code.matches(CODE_PATTERN)) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "模块编码只能是字母/数字/._-，且不超过 60 字");
        }
        if (req.name() == null || req.name().isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "模块名称不能为空");
        }
        int moduleType = req.moduleType() < 1 || req.moduleType() > 3 ? 1 : req.moduleType();

        Long parentId = req.parentId() == null || req.parentId() <= 0 ? null : req.parentId();
        int level = 1;
        if (parentId != null) {
            Integer parentLevel = jdbc.query("""
                            SELECT [Level] FROM plat.[Module]
                            WHERE TenantId = ? AND Id = ? AND IsDeleted = 0
                            """, rs -> rs.next() ? rs.getInt(1) : null, tenantId, parentId);
            if (parentLevel == null) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "上级模块不存在");
            }
            if (req.id() != null && Objects.equals(req.id(), parentId)) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "上级模块不能是自己");
            }
            if (req.id() != null && isDescendant(parentId, req.id())) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "不能把模块挂到自己的下级节点下");
            }
            level = parentLevel + 1;
        }

        Integer dup = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.[Module]
                WHERE TenantId = ? AND Code = ? AND IsDeleted = 0 AND Id <> ISNULL(?, -1)
                """, Integer.class, tenantId, code, req.id());
        if (dup != null && dup > 0) {
            throw new ApiException(ErrorCode.DUPLICATE_KEY, "模块编码已存在：" + code);
        }

        // 改名（编码）后权限点要跟着改：先取旧编码，改完再迁移，否则会留下孤儿资源
        String oldCode = req.id() == null ? null : jdbc.query("""
                SELECT Code FROM plat.[Module] WHERE TenantId = ? AND Id = ?
                """, rs -> rs.next() ? rs.getString(1) : null, tenantId, req.id());

        long id;
        if (req.id() != null) {
            int n = jdbc.update("""
                    UPDATE plat.[Module]
                    SET ParentId = ?, Code = ?, Name = ?, EnCode = ?, [Level] = ?, ModuleType = ?,
                        Sort = ?, Icon = ?, Description = ?, IsEnabled = ?, Remark = ?,
                        ModifiedAt = sysutcdatetime()
                    WHERE Id = ? AND TenantId = ?
                    """, parentId, code, req.name(), req.enCode(), level, moduleType, req.sort(),
                    req.icon(), req.description(), req.enabled() ? 1 : 0, req.remark(),
                    req.id(), tenantId);
            if (n == 0) {
                throw new ApiException(ErrorCode.NOT_FOUND, "模块不存在：" + req.id());
            }
            id = req.id();
            if (oldCode != null && !oldCode.equalsIgnoreCase(code)) {
                jdbc.update("""
                        UPDATE plat.Permission SET ResourceKey = ?
                        WHERE TenantId = ? AND ResourceKey = ?
                        """, "MOD:" + code, tenantId, "MOD:" + oldCode);
            }
            syncChildLevels(id, level);
        } else {
            jdbc.update("""
                    INSERT plat.[Module] (TenantId, ParentId, Code, Name, EnCode, [Level], ModuleType,
                                          Sort, Icon, Description, IsEnabled, Version, Remark, CreatedAt)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, sysutcdatetime())
                    """, tenantId, parentId, code, req.name(), req.enCode(), level, moduleType,
                    req.sort(), req.icon(), req.description(), req.enabled() ? 1 : 0, req.remark());
            id = jdbc.queryForObject("""
                    SELECT MAX(Id) FROM plat.[Module] WHERE TenantId = ? AND Code = ?
                    """, Long.class, tenantId, code);
        }
        if (req.createPermission()) {
            ensurePermission("MOD:" + code, req.name());
        }
        log.info("module_save tenant={} id={} code={} level={} ,", tenantId, id, code, level);
        return id;
    }

    /** 父节点层级变了，子树层级要跟着改，否则树排序与缩进全乱。 */
    private void syncChildLevels(long parentId, int parentLevel) {
        List<Long> children = jdbc.queryForList("""
                SELECT Id FROM plat.[Module] WHERE ParentId = ? AND IsDeleted = 0
                """, Long.class, parentId);
        for (Long child : children) {
            jdbc.update("UPDATE plat.[Module] SET [Level] = ? WHERE Id = ?", parentLevel + 1, child);
            syncChildLevels(child, parentLevel + 1);
        }
    }

    private boolean isDescendant(long candidate, long ancestorId) {
        long tenantId = TenantContext.requireTenantId();
        Long current = candidate;
        int guard = 0;
        while (current != null && guard++ < 32) {
            Long parent = jdbc.query("""
                            SELECT ParentId FROM plat.[Module] WHERE TenantId = ? AND Id = ?
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

    @Transactional
    public void deleteModule(long id, boolean force) {
        long tenantId = TenantContext.requireTenantId();
        Integer children = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.[Module] WHERE TenantId = ? AND ParentId = ? AND IsDeleted = 0
                """, Integer.class, tenantId, id);
        Integer functions = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.ModuleFunction WHERE TenantId = ? AND ModuleId = ? AND IsDeleted = 0
                """, Integer.class, tenantId, id);
        if (!force && ((children != null && children > 0) || (functions != null && functions > 0))) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                    "该模块下还有 " + children + " 个子模块、" + functions + " 个功能点，请先清理或用强制删除");
        }
        String code = jdbc.query("""
                SELECT Code FROM plat.[Module] WHERE TenantId = ? AND Id = ?
                """, rs -> rs.next() ? rs.getString(1) : null, tenantId, id);
        int n = jdbc.update("""
                UPDATE plat.[Module] SET IsDeleted = 1, IsEnabled = 0, DeletedAt = sysutcdatetime()
                WHERE Id = ? AND TenantId = ?
                """, id, tenantId);
        if (n == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND, "模块不存在：" + id);
        }
        // 模块没了，它的权限点也该收走（否则权限设计器里留一堆点不亮的孤儿资源）
        if (code != null) {
            dropPermission("MOD:" + code);
        }
        log.info("module_delete tenant={} id={} force={}", tenantId, id, force);
    }

    // ---------------------------------------------------------------- 保存功能点

    @Transactional
    public long saveFunction(FunctionSaveRequest req) {
        long tenantId = TenantContext.requireTenantId();
        if (req.moduleId() == null || req.moduleId() <= 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "功能点必须挂在某个模块下");
        }
        Integer moduleExists = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.[Module] WHERE TenantId = ? AND Id = ? AND IsDeleted = 0
                """, Integer.class, tenantId, req.moduleId());
        if (moduleExists == null || moduleExists == 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "模块不存在：" + req.moduleId());
        }
        String code = req.code() == null ? "" : req.code().trim();
        if (!code.matches(CODE_PATTERN)) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "功能点编码只能是字母/数字/._-，且不超过 60 字");
        }
        if (req.name() == null || req.name().isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "功能点名称不能为空");
        }
        Integer dup = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.ModuleFunction
                WHERE TenantId = ? AND ModuleId = ? AND Code = ? AND IsDeleted = 0
                  AND Id <> ISNULL(?, -1)
                """, Integer.class, tenantId, req.moduleId(), code, req.id());
        if (dup != null && dup > 0) {
            throw new ApiException(ErrorCode.DUPLICATE_KEY, "该模块下功能点编码已存在：" + code);
        }
        int funType = req.funType() < 1 || req.funType() > 4 ? 1 : req.funType();
        long id;
        if (req.id() != null) {
            int n = jdbc.update("""
                    UPDATE plat.ModuleFunction
                    SET ModuleId = ?, Code = ?, Name = ?, FunType = ?, Sort = ?, IsPermissionPoint = ?,
                        ConfirmText = ?, SuccessMessage = ?, Icon = ?, HotKey = ?, IsEnabled = ?,
                        Remark = ?, ModifiedAt = sysutcdatetime()
                    WHERE Id = ? AND TenantId = ?
                    """, req.moduleId(), code, req.name(), funType, req.sort(),
                    req.permissionPoint() ? 1 : 0, req.confirmText(), req.successMessage(),
                    req.icon(), req.hotKey(), req.enabled() ? 1 : 0, req.remark(), req.id(), tenantId);
            if (n == 0) {
                throw new ApiException(ErrorCode.NOT_FOUND, "功能点不存在：" + req.id());
            }
            id = req.id();
        } else {
            jdbc.update("""
                    INSERT plat.ModuleFunction (TenantId, ModuleId, Code, Name, FunType, Sort,
                                                IsPermissionPoint, ConfirmText, SuccessMessage, Icon,
                                                HotKey, IsEnabled, Remark, CreatedAt)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, sysutcdatetime())
                    """, tenantId, req.moduleId(), code, req.name(), funType, req.sort(),
                    req.permissionPoint() ? 1 : 0, req.confirmText(), req.successMessage(), req.icon(),
                    req.hotKey(), req.enabled() ? 1 : 0, req.remark());
            id = jdbc.queryForObject("""
                    SELECT MAX(Id) FROM plat.ModuleFunction
                    WHERE TenantId = ? AND ModuleId = ? AND Code = ?
                    """, Long.class, tenantId, req.moduleId(), code);
        }
        if (req.permissionPoint()) {
            ensurePermission("FUN:" + code, req.name());
        }
        log.info("function_save tenant={} id={} module={} code={} perm={}",
                tenantId, id, req.moduleId(), code, req.permissionPoint());
        return id;
    }

    @Transactional
    public void deleteFunction(long id) {
        long tenantId = TenantContext.requireTenantId();
        Integer used = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.Button WHERE TenantId = ? AND FunctionId = ? AND IsDeleted = 0
                """, Integer.class, tenantId, id);
        if (used != null && used > 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                    "有 " + used + " 个按钮引用了该功能点，先解绑再删除");
        }
        String code = jdbc.query("""
                SELECT Code FROM plat.ModuleFunction WHERE TenantId = ? AND Id = ?
                """, rs -> rs.next() ? rs.getString(1) : null, tenantId, id);
        int n = jdbc.update("""
                UPDATE plat.ModuleFunction SET IsDeleted = 1, IsEnabled = 0, DeletedAt = sysutcdatetime()
                WHERE Id = ? AND TenantId = ?
                """, id, tenantId);
        if (n == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND, "功能点不存在：" + id);
        }
        jdbc.update("DELETE FROM plat.FunctionAction WHERE FunctionId = ?", id);
        if (code != null) {
            dropPermission("FUN:" + code);
        }
        log.info("function_delete tenant={} id={}", tenantId, id);
    }

    // ---------------------------------------------------------------- 动作链

    @Transactional
    public List<ActionDto> saveActions(long functionId, List<ActionSaveRequest> actions) {
        long tenantId = TenantContext.requireTenantId();
        Integer exists = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.ModuleFunction
                WHERE TenantId = ? AND Id = ? AND IsDeleted = 0
                """, Integer.class, tenantId, functionId);
        if (exists == null || exists == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND, "功能点不存在：" + functionId);
        }
        jdbc.update("DELETE FROM plat.FunctionAction WHERE FunctionId = ?", functionId);
        int seq = 0;
        for (ActionSaveRequest a : actions == null ? List.<ActionSaveRequest>of() : actions) {
            seq += 10;
            jdbc.update("""
                    INSERT plat.FunctionAction (TenantId, FunctionId, Seq, Phase, ActionType,
                                                ActionCode, Target, Command, ParamJson,
                                                ContinueOnError, ErrorMessage, TimeoutSeconds, IsEnabled)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, tenantId, functionId, seq, a.phase() <= 0 ? 1 : a.phase(),
                    a.actionType() <= 0 ? 1 : a.actionType(), a.actionCode(), a.target(),
                    a.command(), a.paramJson(), a.continueOnError() ? 1 : 0, a.errorMessage(),
                    a.timeoutSeconds() <= 0 ? 30 : a.timeoutSeconds(), a.enabled() ? 1 : 0);
        }
        log.info("function_actions_save tenant={} function={} rows={}", tenantId, functionId, seq / 10);
        return actionsOf(functionId);
    }

    // ---------------------------------------------------------------- 权限点同步

    /** 删权限点：先删角色绑定，再删资源本身（不存在时静默跳过）。 */
    private void dropPermission(String resourceKey) {
        long tenantId = TenantContext.requireTenantId();
        jdbc.update("""
                DELETE rp FROM plat.RolePermission rp
                JOIN plat.Permission p ON p.Id = rp.PermissionId
                WHERE p.TenantId = ? AND p.ResourceKey = ?
                """, tenantId, resourceKey);
        int n = jdbc.update("""
                DELETE FROM plat.Permission WHERE TenantId = ? AND ResourceKey = ?
                """, tenantId, resourceKey);
        if (n > 0) {
            log.info("permission_dropped tenant={} key={}", tenantId, resourceKey);
        }
    }

    private void ensurePermission(String resourceKey, String name) {
        long tenantId = TenantContext.requireTenantId();
        Integer exists = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.Permission WHERE TenantId = ? AND ResourceKey = ?
                """, Integer.class, tenantId, resourceKey);
        if (exists != null && exists > 0) {
            return;
        }
        jdbc.update("""
                INSERT plat.Permission (TenantId, ResourceKey, ResourceType, Name, IsEnabled)
                VALUES (?, ?, 1, ?, 1)
                """, tenantId, resourceKey, name);
        log.info("permission_created tenant={} key={}", tenantId, resourceKey);
    }

    /** 功能点在权限设计器里的动作码（read/write/approve 等由角色矩阵控制，这里只提示）。 */
    public Map<String, Object> overview() {
        long tenantId = TenantContext.requireTenantId();
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("modules", count("SELECT COUNT(*) FROM plat.[Module] WHERE TenantId = ? AND IsDeleted = 0", tenantId));
        m.put("functions", count("SELECT COUNT(*) FROM plat.ModuleFunction WHERE TenantId = ? AND IsDeleted = 0", tenantId));
        m.put("actions", count("SELECT COUNT(*) FROM plat.FunctionAction a JOIN plat.ModuleFunction f "
                + "ON f.Id = a.FunctionId WHERE f.TenantId = ? AND f.IsDeleted = 0", tenantId));
        m.put("menus", count("SELECT COUNT(*) FROM plat.[Menu] WHERE TenantId = ? AND IsDeleted = 0", tenantId));
        m.put("permissions", count("SELECT COUNT(*) FROM plat.Permission WHERE TenantId = ?", tenantId));
        return m;
    }

    private int count(String sql, long tenantId) {
        Integer n = jdbc.queryForObject(sql, Integer.class, tenantId);
        return n == null ? 0 : n;
    }
}

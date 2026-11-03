package com.aschain.plat.menu;

import com.aschain.common.ApiException;
import com.aschain.common.ErrorCode;
import com.aschain.common.tenant.TenantContext;
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
    private final TerminalAdminService terminalAdmin;

    public ModuleAdminService(JdbcTemplate jdbc, TerminalAdminService terminalAdmin) {
        this.jdbc = jdbc;
        this.terminalAdmin = terminalAdmin;
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
        return tree(keyword, null);
    }

    /**
     * 模块树（可按租户查）。
     *
     * <p>平台作用域下可传 {@code tenantId} 查看**任意租户**的模块列表——
     * 平台目录是 {@code tenantId = 0}，业务租户是各自的副本；
     * 非平台作用域一律忽略该参数，只能看自己租户（防止越权）。</p>
     */
    public List<ModuleNode> tree(String keyword, Integer tenantId) {
        long tenantIdToUse = resolveTenant(tenantId);
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
                tenantIdToUse);
        List<ModuleNode> tree = buildTree(all);
        String key = keyword == null ? "" : keyword.trim().toLowerCase();
        if (key.isEmpty()) {
            return tree;
        }
        return filter(tree, key);
    }

    /** 解析要查询的租户：平台作用域可指定，其余强制用当前租户。 */
    private static long resolveTenant(Integer tenantId) {
        if (tenantId != null) {
            if (!TenantContext.isPlatformScope()) {
                throw new ApiException(ErrorCode.FORBIDDEN, "只有平台可以查看其他租户的模块");
            }
            return tenantId;
        }
        return TenantContext.requireTenantId();
    }

    // ---------------------------------------------------------------- 租户模块开通/停用

    /**
     * 给某个租户开通或停用某个模块。
     *
     * <p>只改该租户自己的模块副本与菜单可见性，不动平台目录，也不影响其他租户。</p>
     *
     * @return 受影响的菜单行数
     */
    @Transactional
    public int setModuleEnabled(long tenantId, String code, boolean enabled) {
        if (!TenantContext.isPlatformScope()) {
            throw new ApiException(ErrorCode.FORBIDDEN, "只有平台可以调整租户的模块开通状态");
        }
        List<Long> ids = jdbc.queryForList(
                "SELECT Id FROM plat.[Module] WHERE TenantId = ? AND Code = ? AND IsDeleted = 0",
                Long.class, tenantId, code);
        if (ids.isEmpty()) {
            throw new ApiException(ErrorCode.NOT_FOUND,
                    "该租户还没有这个模块（编码 " + code + "），请先同步产品目录");
        }
        long moduleId = ids.get(0);
        jdbc.update("UPDATE plat.[Module] SET IsEnabled = ?, ModifiedAt = sysutcdatetime() WHERE Id = ?",
                enabled, moduleId);
        int menus = jdbc.update(
                "UPDATE plat.[Menu] SET IsVisible = ? WHERE TenantId = ? AND ModuleId = ? AND IsDeleted = 0",
                enabled, tenantId, moduleId);
        log.info("tenant_module tenant={} code={} enabled={} menus={}",
                tenantId, code, enabled, menus);
        return menus;
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
        // 模块没了，它的权限点与终端启用记录也该收走
        if (code != null) {
            dropPermission("MOD:" + code);
        }
        terminalAdmin.forgetModule(id);
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

    /**
     * 模型关系图的数据源：把「子系统 / 模块 / 功能点 / 菜单 / 终端」的实际规模与连接情况
     * 一次性查出来，供管理窗口和排障使用。
     *
     * <p>为什么需要它：这四者分散在 6 张表里，靠人记不住；尤其
     * 「菜单有没有绑模块/页面」「模块终端是不是空表」这两件事，不看数字根本发现不了。</p>
     */
    public Map<String, Object> modelMap() {
        long tenantId = TenantContext.requireTenantId();
        Map<String, Object> m = new LinkedHashMap<>();

        Map<String, Object> modules = new LinkedHashMap<>();
        modules.put("total", count("SELECT COUNT(*) FROM plat.[Module] WHERE TenantId = ? AND IsDeleted = 0", tenantId));
        modules.put("level1", count("SELECT COUNT(*) FROM plat.[Module] WHERE TenantId = ? AND IsDeleted = 0 AND [Level] = 1", tenantId));
        modules.put("level2", count("SELECT COUNT(*) FROM plat.[Module] WHERE TenantId = ? AND IsDeleted = 0 AND [Level] = 2", tenantId));
        modules.put("level3", count("SELECT COUNT(*) FROM plat.[Module] WHERE TenantId = ? AND IsDeleted = 0 AND [Level] >= 3", tenantId));
        m.put("modules", modules);

        Map<String, Object> functions = new LinkedHashMap<>();
        functions.put("total", count("SELECT COUNT(*) FROM plat.ModuleFunction WHERE TenantId = ? AND IsDeleted = 0", tenantId));
        functions.put("actions", count("SELECT COUNT(*) FROM plat.FunctionAction a JOIN plat.ModuleFunction f "
                + "ON f.Id = a.FunctionId WHERE f.TenantId = ? AND f.IsDeleted = 0", tenantId));
        m.put("functions", functions);

        Map<String, Object> menus = new LinkedHashMap<>();
        menus.put("total", count("SELECT COUNT(*) FROM plat.[Menu] WHERE TenantId = ? AND IsDeleted = 0", tenantId));
        menus.put("boundToModule", count("SELECT COUNT(*) FROM plat.[Menu] WHERE TenantId = ? AND IsDeleted = 0 "
                + "AND ModuleId IS NOT NULL", tenantId));
        menus.put("unboundModule", count("SELECT COUNT(*) FROM plat.[Menu] WHERE TenantId = ? AND IsDeleted = 0 "
                + "AND ModuleId IS NULL", tenantId));
        menus.put("boundToPage", count("SELECT COUNT(*) FROM plat.[Menu] WHERE TenantId = ? AND IsDeleted = 0 "
                + "AND PageId IS NOT NULL", tenantId));
        menus.put("placeholder", count("SELECT COUNT(*) FROM plat.[Menu] WHERE TenantId = ? AND IsDeleted = 0 "
                + "AND PageId IS NULL AND (Route IS NULL OR Route = '' OR Route LIKE '/m/%')", tenantId));
        m.put("menus", menus);

        Map<String, Object> terminals = new LinkedHashMap<>();
        terminals.put("menuTerminalRows", count("SELECT COUNT(*) FROM plat.MenuTerminal mt "
                + "JOIN plat.[Menu] mn ON mn.Id = mt.MenuId WHERE mn.TenantId = ? AND mn.IsDeleted = 0", tenantId));
        terminals.put("moduleTerminalRows", count("SELECT COUNT(*) FROM plat.ModuleTerminal mt "
                + "JOIN plat.[Module] md ON md.Id = mt.ModuleId WHERE md.TenantId = ? AND md.IsDeleted = 0", tenantId));
        // 规则校验：菜单的模块必须在该终端启用（V41 之后应恒为 0）
        terminals.put("ruleViolations", count("""
                SELECT COUNT(*) FROM plat.[Menu] m
                WHERE m.TenantId = ? AND m.IsDeleted = 0 AND m.ModuleId IS NOT NULL
                  AND NOT EXISTS (SELECT 1 FROM plat.ModuleTerminal mt
                                  WHERE mt.ModuleId = m.ModuleId AND mt.TerminalType = m.TerminalType)
                """, tenantId));
        List<Map<String, Object>> byType = jdbc.queryForList("""
                SELECT mt.TerminalType AS terminalType, COUNT(*) AS menus
                FROM plat.MenuTerminal mt JOIN plat.[Menu] mn ON mn.Id = mt.MenuId
                WHERE mn.TenantId = ? AND mn.IsDeleted = 0
                GROUP BY mt.TerminalType ORDER BY mt.TerminalType
                """, tenantId);
        terminals.put("byType", byType);
        m.put("terminals", terminals);

        Map<String, Object> permissions = new LinkedHashMap<>();
        permissions.put("mod", count("SELECT COUNT(*) FROM plat.Permission WHERE TenantId = ? AND ResourceKey LIKE 'MOD:%'", tenantId));
        permissions.put("fun", count("SELECT COUNT(*) FROM plat.Permission WHERE TenantId = ? AND ResourceKey LIKE 'FUN:%'", tenantId));
        permissions.put("data", count("SELECT COUNT(*) FROM plat.Permission WHERE TenantId = ? AND ResourceKey LIKE 'DATA:%'", tenantId));
        permissions.put("design", count("SELECT COUNT(*) FROM plat.Permission WHERE TenantId = ? AND ResourceKey LIKE 'DESIGN:%'", tenantId));
        m.put("permissions", permissions);

        // 子系统：当前没有实体表，只有方案里的 57 个划分；这里如实返回「无」，
        // 避免管理窗口凭空造一个不存在的层级。
        m.put("subsystem", Map.of(
                "implemented", false,
                "note", "子系统是交付/验收单位（方案里 57 个），当前未建实体；业务域由模块 Level1（10 个）承载"));

        m.put("warnings", modelWarnings(menus, terminals));
        return m;
    }

    /** 把「看起来能用其实没接通」的地方直接点出来，省得靠人逐个表去查。 */
    private List<String> modelWarnings(Map<String, Object> menus, Map<String, Object> terminals) {
        List<String> out = new java.util.ArrayList<>();
        int unbound = ((Number) menus.getOrDefault("unboundModule", 0)).intValue();
        if (unbound > 0) {
            out.add("有 " + unbound + " 条菜单没有绑定模块，无法用 MOD:/FUN: 授权（只能平台管理员整体放行）");
        }
        int placeholder = ((Number) menus.getOrDefault("placeholder", 0)).intValue();
        if (placeholder > 0) {
            out.add("有 " + placeholder + " 条菜单没有真实页面，点击落到 /m/{code} 占位页");
        }
        int moduleTerminal = ((Number) terminals.getOrDefault("moduleTerminalRows", 0)).intValue();
        if (moduleTerminal == 0) {
            out.add("plat.ModuleTerminal 是空表：终端差异只在菜单层生效，按模块配终端不会起作用");
        }
        int violations = ((Number) terminals.getOrDefault("ruleViolations", 0)).intValue();
        if (violations > 0) {
            out.add("有 " + violations + " 条菜单的模块没在该终端启用（违反「菜单模块必须属于本终端」）");
        }
        return out;
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

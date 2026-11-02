package com.aschain.plat.menu;

import com.aschain.common.ApiException;
import com.aschain.common.ErrorCode;
import com.aschain.common.tenant.TenantContext;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 终端与功能模块：<b>终端能用哪些功能模块，只由 plat.ModuleTerminal 说了算</b>。
 *
 * <p>规则链：终端启用模块 → 该终端下才能挂这个模块的菜单 → 菜单保存时校验。
 * 所以「某个功能只给 PDA」的正确做法是：先在 PDA 终端启用该模块，再在 PDA 下建菜单；
 * 而不是先建菜单再补终端。</p>
 *
 * <p>两条保护：</p>
 * <ol>
 *   <li>停用模块时，如果该终端下还有菜单指向它 → 拒绝，并列出菜单名；</li>
 *   <li>勾选子模块时自动把上级模块一起启用，否则终端上会出现「有子功能却没有入口父节点」。</li>
 * </ol>
 */
@Service
public class TerminalAdminService {

    private static final Logger log = LoggerFactory.getLogger(TerminalAdminService.class);

    /** 终端类型：与 plat.Menu.TerminalType / plat.ModuleTerminal.TerminalType 对齐。 */
    private static final Map<Integer, String> LABELS = Map.of(
            1, "PC", 2, "PDA", 3, "POS", 4, "移动", 5, "小程序", 6, "其他");

    private final JdbcTemplate jdbc;

    public TerminalAdminService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public static String label(int terminalType) {
        return LABELS.getOrDefault(terminalType, "终端" + terminalType);
    }

    public record TerminalDto(int terminalType, String label, int moduleCount, int menuCount,
                              int functionCount) {
    }

    public record ModuleOption(long id, Long parentId, String code, String name, int level,
                               boolean enabled, int menuCount) {
    }

    // ---------------------------------------------------------------- 查询

    public List<TerminalDto> terminals() {
        long tenantId = TenantContext.requireTenantId();
        List<TerminalDto> out = new ArrayList<>();
        for (int t = 1; t <= 6; t++) {
            Integer modules = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM plat.ModuleTerminal WHERE TenantId = ? AND TerminalType = ?
                    """, Integer.class, tenantId, t);
            Integer menus = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM plat.[Menu]
                    WHERE TenantId = ? AND TerminalType = ? AND IsDeleted = 0
                    """, Integer.class, tenantId, t);
            Integer functions = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM plat.ModuleFunction f
                    JOIN plat.ModuleTerminal mt ON mt.ModuleId = f.ModuleId AND mt.TerminalType = ?
                    WHERE f.TenantId = ? AND f.IsDeleted = 0
                    """, Integer.class, t, tenantId);
            out.add(new TerminalDto(t, label(t), modules == null ? 0 : modules,
                    menus == null ? 0 : menus, functions == null ? 0 : functions));
        }
        return out;
    }

    /** 该终端已启用的模块（菜单表单只允许从这里选）。 */
    public List<ModuleOption> enabledModules(int terminalType) {
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                        SELECT m.Id, m.ParentId, m.Code, m.Name, m.[Level],
                               (SELECT COUNT(*) FROM plat.[Menu] mn
                                 WHERE mn.ModuleId = m.Id AND mn.TerminalType = ?
                                   AND mn.IsDeleted = 0) AS MenuCount
                        FROM plat.ModuleTerminal mt
                        JOIN plat.[Module] m ON m.Id = mt.ModuleId
                        WHERE mt.TenantId = ? AND mt.TerminalType = ? AND m.IsDeleted = 0
                        ORDER BY m.[Level], m.Sort, m.Code
                        """,
                (rs, i) -> new ModuleOption(rs.getLong("Id"), rs.getObject("ParentId", Long.class),
                        rs.getString("Code"), rs.getString("Name"), rs.getInt("Level"), true,
                        rs.getInt("MenuCount")),
                terminalType, tenantId, terminalType);
    }

    /** 全量模块（带该终端是否启用），供「终端与功能」勾选界面使用。 */
    public List<ModuleOption> allModules(int terminalType) {
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                        SELECT m.Id, m.ParentId, m.Code, m.Name, m.[Level],
                               CASE WHEN EXISTS (SELECT 1 FROM plat.ModuleTerminal mt
                                                 WHERE mt.ModuleId = m.Id AND mt.TerminalType = ?)
                                    THEN 1 ELSE 0 END AS Enabled,
                               (SELECT COUNT(*) FROM plat.[Menu] mn
                                 WHERE mn.ModuleId = m.Id AND mn.TerminalType = ?
                                   AND mn.IsDeleted = 0) AS MenuCount
                        FROM plat.[Module] m
                        WHERE m.TenantId = ? AND m.IsDeleted = 0
                        ORDER BY m.[Level], m.Sort, m.Code
                        """,
                (rs, i) -> new ModuleOption(rs.getLong("Id"), rs.getObject("ParentId", Long.class),
                        rs.getString("Code"), rs.getString("Name"), rs.getInt("Level"),
                        rs.getBoolean("Enabled"), rs.getInt("MenuCount")),
                terminalType, terminalType, tenantId);
    }

    // ---------------------------------------------------------------- 保存

    /** 整体替换某终端可用的功能模块（空数组 = 全部停用，但仍受"菜单在用"保护）。 */
    @Transactional
    public List<ModuleOption> saveModules(int terminalType, List<Long> moduleIds) {
        long tenantId = TenantContext.requireTenantId();
        requireTerminal(terminalType);
        Set<Long> target = moduleIds == null ? Set.of() : moduleIds.stream()
                .filter(id -> id != null && id > 0)
                .collect(Collectors.toCollection(LinkedHashSet::new));

        Set<Long> current = new LinkedHashSet<>(jdbc.queryForList("""
                SELECT ModuleId FROM plat.ModuleTerminal WHERE TenantId = ? AND TerminalType = ?
                """, Long.class, tenantId, terminalType));
        List<Long> removing = current.stream().filter(id -> !target.contains(id)).toList();

        if (!removing.isEmpty()) {
            List<String> inUse = jdbc.query("""
                            SELECT DISTINCT mn.Code + ' ' + mn.Name AS Label
                            FROM plat.[Menu] mn
                            WHERE mn.TenantId = ? AND mn.TerminalType = ? AND mn.IsDeleted = 0
                              AND mn.ModuleId IN (%s)
                            """.formatted(inClause(removing)),
                    (rs, i) -> rs.getString("Label"), tenantId, terminalType);
            if (!inUse.isEmpty()) {
                throw new ApiException(ErrorCode.BAD_REQUEST,
                        "终端「" + label(terminalType) + "」下这些菜单还在用这些模块，不能停用："
                                + String.join("、", inUse) + "。请先把这些菜单删掉或改挂到别的终端");
            }
            jdbc.update("""
                    DELETE FROM plat.ModuleTerminal
                    WHERE TenantId = ? AND TerminalType = ? AND ModuleId IN (%s)
                    """.formatted(inClause(removing)), tenantId, terminalType);
        }

        List<Long> adding = target.stream().filter(id -> !current.contains(id)).toList();
        if (!adding.isEmpty()) {
            // 模块必须存在且未删除，否则静默丢弃会让界面显示勾上但保存不生效
            List<Long> valid = jdbc.queryForList("""
                    SELECT Id FROM plat.[Module] WHERE TenantId = ? AND IsDeleted = 0 AND Id IN (%s)
                    """.formatted(inClause(adding)), Long.class, tenantId);
            for (Long id : valid) {
                jdbc.update("""
                        INSERT plat.ModuleTerminal (TenantId, ModuleId, TerminalType, IsVisible)
                        VALUES (?, ?, ?, 1)
                        """, tenantId, id, terminalType);
            }
        }

        closeAncestors(tenantId, terminalType);
        log.info("terminal_modules_save tenant={} terminal={} add={} remove={}",
                tenantId, terminalType, adding.size(), removing.size());
        return allModules(terminalType);
    }

    /** 单个启用（增量接口，避免调用方为了加一个模块还要把全量列表传回来）。 */
    @Transactional
    public List<ModuleOption> enableModule(int terminalType, long moduleId) {
        long tenantId = TenantContext.requireTenantId();
        requireTerminal(terminalType);
        Integer exists = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.[Module] WHERE TenantId = ? AND Id = ? AND IsDeleted = 0
                """, Integer.class, tenantId, moduleId);
        if (exists == null || exists == 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "模块不存在：" + moduleId);
        }
        Integer has = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.ModuleTerminal
                WHERE TenantId = ? AND ModuleId = ? AND TerminalType = ?
                """, Integer.class, tenantId, moduleId, terminalType);
        if (has == null || has == 0) {
            jdbc.update("""
                    INSERT plat.ModuleTerminal (TenantId, ModuleId, TerminalType, IsVisible)
                    VALUES (?, ?, ?, 1)
                    """, tenantId, moduleId, terminalType);
        }
        closeAncestors(tenantId, terminalType);
        return allModules(terminalType);
    }

    /** 单个停用：该终端下还有菜单引用它时拒绝。 */
    @Transactional
    public List<ModuleOption> disableModule(int terminalType, long moduleId) {
        long tenantId = TenantContext.requireTenantId();
        requireTerminal(terminalType);
        List<String> inUse = jdbc.query("""
                        SELECT DISTINCT mn.Code + ' ' + mn.Name AS Label
                        FROM plat.[Menu] mn
                        WHERE mn.TenantId = ? AND mn.TerminalType = ? AND mn.IsDeleted = 0
                          AND mn.ModuleId = ?
                        """,
                (rs, i) -> rs.getString("Label"), tenantId, terminalType, moduleId);
        if (!inUse.isEmpty()) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                    "终端「" + label(terminalType) + "」下这些菜单还在用这个模块，不能停用："
                            + String.join("、", inUse));
        }
        jdbc.update("""
                DELETE FROM plat.ModuleTerminal
                WHERE TenantId = ? AND TerminalType = ? AND ModuleId = ?
                """, tenantId, terminalType, moduleId);
        log.info("terminal_module_disable tenant={} terminal={} module={}",
                tenantId, terminalType, moduleId);
        return allModules(terminalType);
    }

    private void requireTerminal(int terminalType) {
        if (terminalType < 1 || terminalType > 6) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "终端类型只能是 1..6");
        }
    }

    /** 父模块自动补齐：子模块在终端上可见，父节点必须也在（否则树在该终端上断链）。 */
    private void closeAncestors(long tenantId, int terminalType) {
        boolean grew = true;
        int guard = 0;
        while (grew && guard++ < 32) {
            int rows = jdbc.update("""
                    INSERT plat.ModuleTerminal (TenantId, ModuleId, TerminalType, IsVisible)
                    SELECT DISTINCT p.TenantId, m.ParentId, ?, 1
                    FROM plat.ModuleTerminal p
                    JOIN plat.[Module] m ON m.Id = p.ModuleId
                    WHERE p.TenantId = ? AND p.TerminalType = ? AND m.ParentId IS NOT NULL
                      AND NOT EXISTS (SELECT 1 FROM plat.ModuleTerminal x
                                      WHERE x.ModuleId = m.ParentId AND x.TerminalType = ?)
                    """, terminalType, tenantId, terminalType, terminalType);
            grew = rows > 0;
        }
    }

    /** 模块被删除时，连带清掉它在各终端的启用记录。 */
    @Transactional
    public void forgetModule(long moduleId) {
        long tenantId = TenantContext.requireTenantId();
        int n = jdbc.update("""
                DELETE FROM plat.ModuleTerminal WHERE TenantId = ? AND ModuleId = ?
                """, tenantId, moduleId);
        if (n > 0) {
            log.info("terminal_modules_forget tenant={} module={} rows={}", tenantId, moduleId, n);
        }
    }

    /** 概览：终端 × 模块 的规模，给管理窗口顶部用。 */
    public Map<String, Object> overview() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("terminals", terminals());
        m.put("moduleTotal", jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.[Module] WHERE TenantId = ? AND IsDeleted = 0
                """, Integer.class, TenantContext.requireTenantId()));
        return m;
    }

    private static String inClause(List<Long> ids) {
        return ids.stream().map(String::valueOf).collect(Collectors.joining(","));
    }
}

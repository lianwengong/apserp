package com.apserp.plat.meta;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.tenant.TenantContext;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 主子表（明细）引擎。
 *
 * <p>关系由 {@code plat.DataObjectRelation} 声明：父对象 + JSON 别名 + 子对象 + 子表外键字段。
 * 前端把子行放进同一个保存请求的别名数组里（默认 {@code Contacts}），
 * 服务端在<b>同一个事务</b>里依次保存主表与每条子行，并把未提交的子行软删除。</p>
 *
 * <p>关键约束：子表外键与租户由服务端强制写入，前端传什么都不认；子行同样走规则引擎与审计。</p>
 */
@Service
public class MetaChildService {

    private static final Logger log = LoggerFactory.getLogger(MetaChildService.class);

    /** 单次请求最多处理的子行总数，防止前端一次提交上千行把事务撑爆。 */
    private static final int MAX_CHILD_ROWS = 500;

    private final JdbcTemplate jdbc;
    private final MetaDefinitionService definitionService;
    private final MetaQueryService queryService;
    private final RuleService ruleService;
    private final MetaSaveProc saveProc;
    private final ObjectMapper json = new ObjectMapper();

    public MetaChildService(JdbcTemplate jdbc, MetaDefinitionService definitionService,
                            MetaQueryService queryService, RuleService ruleService,
                            MetaSaveProc saveProc) {
        this.jdbc = jdbc;
        this.definitionService = definitionService;
        this.queryService = queryService;
        this.ruleService = ruleService;
        this.saveProc = saveProc;
    }

    // ---------------------------------------------------------------- DTO

    public record RelationDto(long id, String parentObjectCode, String childObjectCode,
                              String childObjectName, String alias, String foreignKeyField,
                              String displayName, int sort, int cascadeDelete, int maxRows,
                              boolean enabled) {
    }

    public record ChildGroup(String alias, String childObjectCode, String childObjectName,
                             String foreignKeyField, boolean cascadeDelete, int total,
                             List<Map<String, Object>> rows) {
    }

    // ---------------------------------------------------------------- 关系

    public List<RelationDto> relationsOf(String parentObjectCode) {
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                        SELECT r.Id, p.Code AS ParentCode, c.Code AS ChildCode, c.Name AS ChildName,
                               r.ChildAlias, r.ForeignKeyField, r.DisplayName, r.Sort,
                               r.CascadeDelete, r.MaxRows, r.IsEnabled
                        FROM plat.DataObjectRelation r
                        JOIN plat.DataObject p ON p.Id = r.ParentObjectId
                        JOIN plat.DataObject c ON c.Id = r.ChildObjectId
                        WHERE r.TenantId = ? AND r.IsDeleted = 0 AND r.IsEnabled = 1
                          AND p.Code = ?
                        ORDER BY r.Sort, r.Id
                        """,
                (rs, i) -> new RelationDto(rs.getLong("Id"), rs.getString("ParentCode"),
                        rs.getString("ChildCode"), rs.getString("ChildName"),
                        rs.getString("ChildAlias"), rs.getString("ForeignKeyField"),
                        rs.getString("DisplayName"), rs.getInt("Sort"), rs.getInt("CascadeDelete"),
                        rs.getInt("MaxRows"), rs.getBoolean("IsEnabled")),
                tenantId, parentObjectCode);
    }

    /** 设计器用：全部关系（可按父对象过滤）。 */
    public List<RelationDto> listRelations(String parentObjectCode) {
        if (parentObjectCode != null && !parentObjectCode.isBlank()) {
            return relationsOf(parentObjectCode);
        }
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                        SELECT r.Id, p.Code AS ParentCode, c.Code AS ChildCode, c.Name AS ChildName,
                               r.ChildAlias, r.ForeignKeyField, r.DisplayName, r.Sort,
                               r.CascadeDelete, r.MaxRows, r.IsEnabled
                        FROM plat.DataObjectRelation r
                        JOIN plat.DataObject p ON p.Id = r.ParentObjectId
                        JOIN plat.DataObject c ON c.Id = r.ChildObjectId
                        WHERE r.TenantId = ? AND r.IsDeleted = 0
                        ORDER BY p.Code, r.Sort, r.Id
                        """,
                (rs, i) -> new RelationDto(rs.getLong("Id"), rs.getString("ParentCode"),
                        rs.getString("ChildCode"), rs.getString("ChildName"),
                        rs.getString("ChildAlias"), rs.getString("ForeignKeyField"),
                        rs.getString("DisplayName"), rs.getInt("Sort"), rs.getInt("CascadeDelete"),
                        rs.getInt("MaxRows"), rs.getBoolean("IsEnabled")),
                tenantId);
    }

    public record RelationSaveRequest(Long id, String parentObjectCode, String childObjectCode,
                                      String alias, String foreignKeyField, String displayName,
                                      int sort, int cascadeDelete, int maxRows, boolean enabled,
                                      String remark) {
    }

    @Transactional
    public long saveRelation(RelationSaveRequest req) {
        long tenantId = TenantContext.requireTenantId();
        if (req.parentObjectCode() == null || req.parentObjectCode().isBlank()
                || req.childObjectCode() == null || req.childObjectCode().isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "父对象与子对象都必须指定");
        }
        String alias = req.alias() == null ? "" : req.alias().trim();
        if (!alias.matches("[A-Za-z][A-Za-z0-9_]{0,59}")) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "别名必须是字母开头的标识符：用于 JSON 键与子表块名");
        }
        String fk = req.foreignKeyField() == null ? "" : req.foreignKeyField().trim();
        if (!fk.matches("[A-Za-z][A-Za-z0-9_]{0,99}")) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "外键字段名不合法");
        }
        if (alias.equalsIgnoreCase("Id") || alias.equalsIgnoreCase("RowVersion")) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "别名不能与主表字段同名");
        }

        long parentId = objectIdOf(req.parentObjectCode());
        long childId = objectIdOf(req.childObjectCode());
        // 外键字段必须在子对象里登记过，否则保存时会写出「列不存在」
        Integer exists = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.DataObjectField
                WHERE DataObjectId = ? AND FieldName = ?
                """, Integer.class, childId, fk);
        if (exists == null || exists == 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                    "子对象 " + req.childObjectCode() + " 没有字段 " + fk + "，请先登记该字段");
        }
        Integer dup = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.DataObjectRelation
                WHERE TenantId = ? AND ParentObjectId = ? AND IsDeleted = 0 AND ChildAlias = ?
                  AND Id <> ISNULL(?, -1)
                """, Integer.class, tenantId, parentId, alias, req.id());
        if (dup != null && dup > 0) {
            throw new ApiException(ErrorCode.DUPLICATE_KEY, "该父对象已有别名 " + alias + " 的子表");
        }

        int cascade = req.cascadeDelete() == 2 ? 2 : 1;
        int maxRows = req.maxRows() <= 0 ? 200 : Math.min(req.maxRows(), MAX_CHILD_ROWS);
        if (req.id() != null) {
            jdbc.update("""
                    UPDATE plat.DataObjectRelation
                    SET ParentObjectId = ?, ChildObjectId = ?, ChildAlias = ?, ForeignKeyField = ?,
                        DisplayName = ?, Sort = ?, CascadeDelete = ?, MaxRows = ?, IsEnabled = ?,
                        Remark = ?, ModifiedAt = sysutcdatetime()
                    WHERE Id = ? AND TenantId = ?
                    """, parentId, childId, alias, fk, req.displayName(), req.sort(), cascade,
                    maxRows, req.enabled(), req.remark(), req.id(), tenantId);
            return req.id();
        }
        jdbc.update("""
                INSERT plat.DataObjectRelation (TenantId, ParentObjectId, ChildObjectId, ChildAlias,
                       ForeignKeyField, DisplayName, Sort, CascadeDelete, MaxRows, IsEnabled,
                       Remark, CreatedAt)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, sysutcdatetime())
                """, tenantId, parentId, childId, alias, fk, req.displayName(), req.sort(), cascade,
                maxRows, req.enabled(), req.remark());
        return jdbc.queryForObject("SELECT MAX(Id) FROM plat.DataObjectRelation WHERE TenantId = ? AND ChildAlias = ?",
                Long.class, tenantId, alias);
    }

    @Transactional
    public void deleteRelation(long id) {
        long tenantId = TenantContext.requireTenantId();
        int n = jdbc.update("""
                UPDATE plat.DataObjectRelation SET IsDeleted = 1, DeletedAt = sysutcdatetime()
                WHERE Id = ? AND TenantId = ?
                """, id, tenantId);
        if (n == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND, "子表关系不存在");
        }
    }

    private long objectIdOf(String objectCode) {
        Long id = jdbc.query("""
                SELECT Id FROM plat.DataObject WHERE TenantId = ? AND Code = ? AND IsDeleted = 0
                """, rs -> rs.next() ? rs.getLong(1) : null, TenantContext.requireTenantId(), objectCode);
        if (id == null) {
            throw new ApiException(ErrorCode.META_OBJECT_NOT_FOUND, "数据对象不存在：" + objectCode);
        }
        return id;
    }

    // ---------------------------------------------------------------- 读取

    /** 某张单据的全部子表数据，按别名分组。 */
    public List<ChildGroup> childrenOf(String parentObjectCode, long parentId) {
        List<ChildGroup> groups = new ArrayList<>();
        for (RelationDto rel : relationsOf(parentObjectCode)) {
            String filters = "[{\"f\":\"" + rel.foreignKeyField() + "\",\"op\":\"eq\",\"v\":\""
                    + parentId + "\"}]";
            MetaQueryService.PageResult page = queryService.query(
                    rel.childObjectCode(), filters, null, 1, Math.max(1, rel.maxRows()));
            groups.add(new ChildGroup(rel.alias(), rel.childObjectCode(), rel.childObjectName(),
                    rel.foreignKeyField(), rel.cascadeDelete() == 1, page.total(), page.rows()));
        }
        return groups;
    }

    // ---------------------------------------------------------------- 级联保存

    /**
     * 在主表保存之后调用（同一事务）：按别名数组逐条保存子行，并把未提交的子行软删除。
     *
     * <p>约定：请求里<b>没有</b>出现某别名 → 该子表不动（局部更新语义，避免老前端把明细清空）。</p>
     */
    public void saveChildren(String parentObjectCode, long parentId, Map<String, Object> payload,
                             long tenantId, Long userId) {
        List<RelationDto> relations = relationsOf(parentObjectCode);
        if (relations.isEmpty()) {
            return;
        }
        int total = 0;
        for (RelationDto rel : relations) {
            Object raw = payload.get(rel.alias());
            if (!(raw instanceof List<?> rows)) {
                continue;
            }
            if (rows.size() > rel.maxRows() || total + rows.size() > MAX_CHILD_ROWS) {
                throw new ApiException(ErrorCode.BAD_REQUEST,
                        "子表 " + rel.alias() + " 超过行数上限（" + rel.maxRows() + "）");
            }
            total += rows.size();
            List<Long> kept = new ArrayList<>(rows.size());
            for (Object item : rows) {
                if (!(item instanceof Map<?, ?> map)) {
                    throw new ApiException(ErrorCode.BAD_REQUEST,
                            "子表 " + rel.alias() + " 的元素必须是对象");
                }
                Map<String, Object> row = new LinkedHashMap<>();
                map.forEach((k, v) -> row.put(String.valueOf(k), v));
                // 外键与租户由服务端强制写入：前端伪造父 Id 无效
                row.put(rel.foreignKeyField(), parentId);
                row.put(tenantFieldOf(rel.childObjectCode()), tenantId);
                row.remove("RowVersion");   // 子行整体覆盖，不做逐行乐观锁
                ruleService.checkBeforeSave(rel.childObjectCode(), row);
                long childId = saveChild(rel.childObjectCode(), row, tenantId, userId);
                kept.add(childId);
            }
            if (rel.cascadeDelete() == 1) {
                int removed = deleteMissing(rel, parentId, kept, tenantId);
                if (removed > 0) {
                    log.info("child_soft_delete parent={} id={} alias={} rows={}",
                            parentObjectCode, parentId, rel.alias(), removed);
                }
            }
            log.info("child_save parent={} id={} alias={} rows={}",
                    parentObjectCode, parentId, rel.alias(), kept.size());
        }
    }

    private long saveChild(String childObjectCode, Map<String, Object> row, long tenantId, Long userId) {
        String childJson;
        try {
            childJson = json.writeValueAsString(row);
        } catch (Exception e) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "子表数据无法序列化：" + e.getMessage());
        }
        return jdbc.execute((ConnectionCallback<Long>) con ->
                saveProc.call(con, tenantId, userId, childObjectCode, childJson));
    }

    private String tenantFieldOf(String objectCode) {
        String field = definitionService.getObject(objectCode).tenantField();
        return field == null || field.isBlank() ? "TenantId" : field;
    }

    /** 软删除本次未提交的子行，返回影响行数。 */
    private int deleteMissing(RelationDto rel, long parentId, List<Long> kept, long tenantId) {
        var object = definitionService.getObject(rel.childObjectCode());
        StringBuilder sql = new StringBuilder("UPDATE ")
                .append("[").append(object.schemaName().replace("]", "]]")).append("].")
                .append("[").append(object.objectName().replace("]", "]]")).append("]")
                .append(" SET IsDeleted = 1, DeletedAt = sysutcdatetime() WHERE ")
                .append("[").append(rel.foreignKeyField().replace("]", "]]")).append("] = ?")
                .append(" AND [").append(tenantFieldOf(rel.childObjectCode()).replace("]", "]]"))
                .append("] = ? AND IsDeleted = 0");
        List<Object> args = new ArrayList<>();
        args.add(parentId);
        args.add(tenantId);
        if (!kept.isEmpty()) {
            sql.append(" AND ").append("[").append(object.primaryKey().replace("]", "]]"))
                    .append("] NOT IN (");
            sql.append(String.join(",", kept.stream().map(x -> "?").toList()));
            sql.append(")");
            args.addAll(kept);
        }
        try {
            return jdbc.update(sql.toString(), args.toArray());
        } catch (org.springframework.dao.DataAccessException ex) {
            // 子表没有 IsDeleted 列时退化为「不删除」，不阻断主表保存
            log.warn("child_delete_skipped object={} reason={}", rel.childObjectCode(), ex.getMessage());
            return 0;
        }
    }
}

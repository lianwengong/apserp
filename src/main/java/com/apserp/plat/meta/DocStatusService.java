package com.apserp.plat.meta;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.tenant.TenantContext;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 单据状态机：把 {@code DataObject.StatusField} 真正用起来。
 *
 * <p>元数据里每个状态声明「能否编辑/删除/提交、是否终态」，流转声明「动作码 → 目标状态」。
 * 引擎在三处设卡：保存（编辑门禁）、删除、提交审批；审批通过与驳回由动作码
 * {@code APPROVE} / {@code REJECT} 驱动流转。</p>
 *
 * <p>向后兼容：对象没配 {@code StatusField}，或没有配任何状态行 → 全部放行（老数据/老对象不受影响）。</p>
 */
@Service
public class DocStatusService {

    private static final Logger log = LoggerFactory.getLogger(DocStatusService.class);

    private final JdbcTemplate jdbc;
    private final MetaDefinitionService definitionService;

    public DocStatusService(JdbcTemplate jdbc, MetaDefinitionService definitionService) {
        this.jdbc = jdbc;
        this.definitionService = definitionService;
    }

    // ---------------------------------------------------------------- DTO

    public record StatusDto(long id, String objectCode, int statusValue, String statusName, int sort,
                            boolean canEdit, boolean canDelete, boolean canSubmit, boolean isFinal,
                            String colorType, boolean enabled) {
    }

    public record TransitionDto(long id, String objectCode, int fromStatus, String fromStatusName,
                                int toStatus, String toStatusName, String actionCode, String actionName,
                                int sort, boolean enabled) {
    }

    /** 某条单据当前的状态能力：前端据此置灰按钮。 */
    public record StatusCapability(String objectCode, String statusField, int statusValue,
                                   String statusName, String colorType, boolean configured,
                                   boolean canEdit, boolean canDelete, boolean canSubmit, boolean isFinal,
                                   List<TransitionDto> transitions) {
    }

    // ---------------------------------------------------------------- 读取

    public List<StatusDto> statusesOf(String objectCode) {
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                        SELECT s.Id, s.StatusValue, s.StatusName, s.Sort, s.CanEdit, s.CanDelete,
                               s.CanSubmit, s.IsFinal, s.ColorType, s.IsEnabled
                        FROM plat.DocStatus s
                        JOIN plat.DataObject o ON o.Id = s.DataObjectId
                        WHERE s.TenantId = ? AND s.IsDeleted = 0 AND o.Code = ?
                        ORDER BY s.Sort, s.StatusValue
                        """,
                (rs, i) -> new StatusDto(rs.getLong("Id"), objectCode, rs.getInt("StatusValue"),
                        rs.getString("StatusName"), rs.getInt("Sort"), rs.getBoolean("CanEdit"),
                        rs.getBoolean("CanDelete"), rs.getBoolean("CanSubmit"), rs.getBoolean("IsFinal"),
                        rs.getString("ColorType"), rs.getBoolean("IsEnabled")),
                tenantId, objectCode);
    }

    public List<TransitionDto> transitionsOf(String objectCode) {
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                        SELECT t.Id, t.FromStatus, t.ToStatus, t.ActionCode, t.ActionName, t.Sort, t.IsEnabled,
                               ISNULL(f.StatusName, '') AS FromName, ISNULL(tn.StatusName, '') AS ToName
                        FROM plat.DocTransition t
                        JOIN plat.DataObject o ON o.Id = t.DataObjectId
                        LEFT JOIN plat.DocStatus f ON f.DataObjectId = t.DataObjectId
                                 AND f.StatusValue = t.FromStatus AND f.IsDeleted = 0
                        LEFT JOIN plat.DocStatus tn ON tn.DataObjectId = t.DataObjectId
                                 AND tn.StatusValue = t.ToStatus AND tn.IsDeleted = 0
                        WHERE t.TenantId = ? AND t.IsDeleted = 0 AND o.Code = ?
                        ORDER BY t.FromStatus, t.Sort, t.ActionCode
                        """,
                (rs, i) -> new TransitionDto(rs.getLong("Id"), objectCode, rs.getInt("FromStatus"),
                        rs.getString("FromName"), rs.getInt("ToStatus"), rs.getString("ToName"),
                        rs.getString("ActionCode"), rs.getString("ActionName"), rs.getInt("Sort"),
                        rs.getBoolean("IsEnabled")),
                tenantId, objectCode);
    }

    /** 配置里声明的状态字段名；没有返回 null（表示该对象不受状态机约束）。 */
    public String statusFieldOf(String objectCode) {
        String field = definitionService.getObject(objectCode).statusField();
        return field == null || field.isBlank() ? null : field;
    }

    /** 某条单据当前状态值；没配置状态字段返回 null。 */
    public Integer currentStatus(String objectCode, long id) {
        String field = statusFieldOf(objectCode);
        if (field == null) {
            return null;
        }
        var object = definitionService.getObject(objectCode);
        String sql = "SELECT [" + field.replace("]", "]]") + "] FROM ["
                + object.schemaName().replace("]", "]]") + "].[" + object.objectName().replace("]", "]]")
                + "] WHERE [" + object.primaryKey().replace("]", "]]") + "] = ?";
        List<Integer> rows = jdbc.query(sql, (rs, i) -> rs.getObject(1) == null ? null : rs.getInt(1), id);
        return rows.isEmpty() ? null : rows.get(0);
    }

    public StatusCapability capabilityOf(String objectCode, long id) {
        List<StatusDto> statuses = statusesOf(objectCode);
        String field = statusFieldOf(objectCode);
        if (field == null || statuses.isEmpty()) {
            return new StatusCapability(objectCode, field, -1, null, null, false,
                    true, true, true, false, List.of());
        }
        Integer current = currentStatus(objectCode, id);
        int value = current == null ? -1 : current;
        StatusDto match = statuses.stream().filter(s -> s.statusValue() == value).findFirst().orElse(null);
        List<TransitionDto> transitions = transitionsOf(objectCode).stream()
                .filter(t -> t.enabled() && t.fromStatus() == value)
                .toList();
        return new StatusCapability(objectCode, field, value,
                match == null ? null : match.statusName(), match == null ? null : match.colorType(), true,
                match != null && match.canEdit(), match != null && match.canDelete(),
                match != null && match.canSubmit(), match != null && match.isFinal(), transitions);
    }

    // ---------------------------------------------------------------- 门禁

    /** 编辑门禁：状态不允许改就直接拒绝，并告诉用户当前是什么状态。 */
    public void guardEdit(String objectCode, Long id) {
        if (id == null || id <= 0) {
            return;
        }
        StatusCapability cap = capabilityOf(objectCode, id);
        if (!cap.configured() || cap.canEdit()) {
            return;
        }
        throw new ApiException(ErrorCode.BAD_REQUEST,
                "单据处于「" + nameOf(cap) + "」状态，不能修改");
    }

    public void guardDelete(String objectCode, long id) {
        StatusCapability cap = capabilityOf(objectCode, id);
        if (!cap.configured() || cap.canDelete()) {
            return;
        }
        throw new ApiException(ErrorCode.BAD_REQUEST,
                "单据处于「" + nameOf(cap) + "」状态，不能删除");
    }

    public void guardSubmit(String objectCode, long id) {
        StatusCapability cap = capabilityOf(objectCode, id);
        if (!cap.configured() || cap.canSubmit()) {
            return;
        }
        throw new ApiException(ErrorCode.BAD_REQUEST,
                "单据处于「" + nameOf(cap) + "」状态，不能提交审批");
    }

    private static String nameOf(StatusCapability cap) {
        return cap.statusName() == null ? "未知状态#" + cap.statusValue() : cap.statusName();
    }

    // ---------------------------------------------------------------- 流转

    /**
     * 按动作码流转状态。动作码在 {@code plat.DocTransition} 里声明，未声明的动作直接拒绝。
     *
     * @return 新状态值；该对象不受状态机约束时返回 null（调用方当成“无需流转”）
     */
    @Transactional
    public Integer transition(String objectCode, long id, String actionCode) {
        String field = statusFieldOf(objectCode);
        List<StatusDto> statuses = statusesOf(objectCode);
        if (field == null || statuses.isEmpty()) {
            return null;
        }
        Integer current = currentStatus(objectCode, id);
        if (current == null) {
            log.warn("doc_transition_skipped object={} id={} reason=status_null", objectCode, id);
            return null;
        }
        TransitionDto target = transitionsOf(objectCode).stream()
                .filter(t -> t.enabled() && t.fromStatus() == current && t.actionCode().equalsIgnoreCase(actionCode))
                .findFirst()
                .orElseThrow(() -> new ApiException(ErrorCode.BAD_REQUEST,
                        "当前状态「" + nameOf(capabilityOf(objectCode, id)) + "」不允许执行 " + actionCode));
        var object = definitionService.getObject(objectCode);
        String sql = "UPDATE [" + object.schemaName().replace("]", "]]") + "].["
                + object.objectName().replace("]", "]]") + "] SET [" + field.replace("]", "]]")
                + "] = ? WHERE [" + object.primaryKey().replace("]", "]]") + "] = ?";
        int n = jdbc.update(sql, target.toStatus(), id);
        if (n == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND, "记录不存在，无法流转状态");
        }
        log.info("doc_transition object={} id={} action={} from={} to={}",
                objectCode, id, actionCode, current, target.toStatus());
        return target.toStatus();
    }

    /** 审批通过：动作码 APPROVE。 */
    public Integer onApproved(String objectCode, long id) {
        return transition(objectCode, id, "APPROVE");
    }

    /** 审批驳回：动作码 REJECT。 */
    public Integer onRejected(String objectCode, long id) {
        return transition(objectCode, id, "REJECT");
    }

    /** 撤回：动作码 WITHDRAW。 */
    public Integer onWithdrawn(String objectCode, long id) {
        return transition(objectCode, id, "WITHDRAW");
    }

    // ---------------------------------------------------------------- 设计器

    public record StatusSaveRequest(Long id, String objectCode, int statusValue, String statusName,
                                    int sort, boolean canEdit, boolean canDelete, boolean canSubmit,
                                    boolean isFinal, String colorType, boolean enabled, String remark) {
    }

    @Transactional
    public long saveStatus(StatusSaveRequest req) {
        long tenantId = TenantContext.requireTenantId();
        if (req.objectCode() == null || req.objectCode().isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "必须指定数据对象");
        }
        if (req.statusValue() < 0 || req.statusValue() > 255) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "状态值必须在 0..255 之间");
        }
        if (req.statusName() == null || req.statusName().isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "状态名称不能为空");
        }
        long objectId = objectIdOf(req.objectCode());
        Integer dup = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.DocStatus
                WHERE TenantId = ? AND DataObjectId = ? AND StatusValue = ? AND IsDeleted = 0
                  AND Id <> ISNULL(?, -1)
                """, Integer.class, tenantId, objectId, req.statusValue(), req.id());
        if (dup != null && dup > 0) {
            throw new ApiException(ErrorCode.DUPLICATE_KEY, "该对象已有状态值 " + req.statusValue());
        }
        if (req.id() != null) {
            jdbc.update("""
                    UPDATE plat.DocStatus
                    SET StatusValue = ?, StatusName = ?, Sort = ?, CanEdit = ?, CanDelete = ?,
                        CanSubmit = ?, IsFinal = ?, ColorType = ?, IsEnabled = ?, Remark = ?,
                        ModifiedAt = sysutcdatetime()
                    WHERE Id = ? AND TenantId = ?
                    """, req.statusValue(), req.statusName(), req.sort(), req.canEdit() ? 1 : 0,
                    req.canDelete() ? 1 : 0, req.canSubmit() ? 1 : 0, req.isFinal() ? 1 : 0,
                    req.colorType(), req.enabled() ? 1 : 0, req.remark(), req.id(), tenantId);
            return req.id();
        }
        jdbc.update("""
                INSERT plat.DocStatus (TenantId, DataObjectId, StatusValue, StatusName, Sort, CanEdit,
                                       CanDelete, CanSubmit, IsFinal, ColorType, IsEnabled, Remark, CreatedAt)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, sysutcdatetime())
                """, tenantId, objectId, req.statusValue(), req.statusName(), req.sort(),
                req.canEdit() ? 1 : 0, req.canDelete() ? 1 : 0, req.canSubmit() ? 1 : 0,
                req.isFinal() ? 1 : 0, req.colorType(), req.enabled() ? 1 : 0, req.remark());
        return jdbc.queryForObject("""
                SELECT MAX(Id) FROM plat.DocStatus WHERE TenantId = ? AND DataObjectId = ?
                """, Long.class, tenantId, objectId);
    }

    @Transactional
    public void deleteStatus(long id) {
        long tenantId = TenantContext.requireTenantId();
        int n = jdbc.update("""
                UPDATE plat.DocStatus SET IsDeleted = 1
                WHERE Id = ? AND TenantId = ?
                """, id, tenantId);
        if (n == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND, "状态不存在");
        }
    }

    public record TransitionSaveRequest(Long id, String objectCode, int fromStatus, int toStatus,
                                        String actionCode, String actionName, int sort, boolean enabled,
                                        String remark) {
    }

    @Transactional
    public long saveTransition(TransitionSaveRequest req) {
        long tenantId = TenantContext.requireTenantId();
        if (req.actionCode() == null || !req.actionCode().trim().matches("[A-Za-z][A-Za-z0-9_]{0,29}")) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "动作码必须是字母开头的标识符（如 SUBMIT / APPROVE）");
        }
        String action = req.actionCode().trim().toUpperCase();
        long objectId = objectIdOf(req.objectCode());
        Integer dup = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.DocTransition
                WHERE TenantId = ? AND DataObjectId = ? AND FromStatus = ? AND ActionCode = ?
                  AND IsDeleted = 0 AND Id <> ISNULL(?, -1)
                """, Integer.class, tenantId, objectId, req.fromStatus(), action, req.id());
        if (dup != null && dup > 0) {
            throw new ApiException(ErrorCode.DUPLICATE_KEY,
                    "该对象在状态 " + req.fromStatus() + " 上已有动作 " + action);
        }
        if (req.id() != null) {
            jdbc.update("""
                    UPDATE plat.DocTransition
                    SET FromStatus = ?, ToStatus = ?, ActionCode = ?, ActionName = ?, Sort = ?,
                        IsEnabled = ?, Remark = ?, ModifiedAt = sysutcdatetime()
                    WHERE Id = ? AND TenantId = ?
                    """, req.fromStatus(), req.toStatus(), action, req.actionName(), req.sort(),
                    req.enabled() ? 1 : 0, req.remark(), req.id(), tenantId);
            return req.id();
        }
        jdbc.update("""
                INSERT plat.DocTransition (TenantId, DataObjectId, FromStatus, ToStatus, ActionCode,
                                          ActionName, Sort, IsEnabled, Remark, CreatedAt)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, sysutcdatetime())
                """, tenantId, objectId, req.fromStatus(), req.toStatus(), action, req.actionName(),
                req.sort(), req.enabled() ? 1 : 0, req.remark());
        return jdbc.queryForObject("""
                SELECT MAX(Id) FROM plat.DocTransition WHERE TenantId = ? AND DataObjectId = ?
                """, Long.class, tenantId, objectId);
    }

    @Transactional
    public void deleteTransition(long id) {
        long tenantId = TenantContext.requireTenantId();
        int n = jdbc.update("""
                UPDATE plat.DocTransition SET IsDeleted = 1
                WHERE Id = ? AND TenantId = ?
                """, id, tenantId);
        if (n == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND, "流转不存在");
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

    /** 所有对象的状态数量概览（设计器首页用）。 */
    public List<Map<String, Object>> overview() {
        long tenantId = TenantContext.requireTenantId();
        return jdbc.queryForList("""
                SELECT o.Code AS objectCode, o.Name AS objectName, o.StatusField AS statusField,
                       (SELECT COUNT(*) FROM plat.DocStatus s WHERE s.DataObjectId = o.Id AND s.IsDeleted = 0)
                           AS statusCount,
                       (SELECT COUNT(*) FROM plat.DocTransition t WHERE t.DataObjectId = o.Id AND t.IsDeleted = 0)
                           AS transitionCount
                FROM plat.DataObject o
                WHERE o.TenantId = ? AND o.IsDeleted = 0 AND o.IsEnabled = 1
                ORDER BY o.Code
                """, tenantId);
    }

    /** 初始化一套默认状态（草稿/审批中/已审核/已驳回）：对象没配过时用。 */
    @Transactional
    public List<StatusDto> initDefault(String objectCode) {
        long tenantId = TenantContext.requireTenantId();
        long objectId = objectIdOf(objectCode);
        if (!statusesOf(objectCode).isEmpty()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "该对象已配置状态，不能重复初始化");
        }
        List<String[]> rows = List.of(
                new String[]{"0", "草稿", "info", "1", "1", "1", "0"},
                new String[]{"1", "审批中", "warning", "0", "0", "0", "0"},
                new String[]{"2", "已审核", "success", "0", "0", "0", "1"},
                new String[]{"3", "已驳回", "danger", "1", "1", "1", "0"});
        int sort = 0;
        for (String[] r : rows) {
            sort += 10;
            jdbc.update("""
                    INSERT plat.DocStatus (TenantId, DataObjectId, StatusValue, StatusName, Sort, CanEdit,
                                           CanDelete, CanSubmit, IsFinal, ColorType, IsEnabled, CreatedAt)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, sysutcdatetime())
                    """, tenantId, objectId, Integer.parseInt(r[0]), r[1], sort,
                    Integer.parseInt(r[3]), Integer.parseInt(r[4]), Integer.parseInt(r[5]),
                    Integer.parseInt(r[6]), r[2]);
        }
        saveTransition(new TransitionSaveRequest(null, objectCode, 0, 1, "SUBMIT", "提交审批", 10, true, null));
        saveTransition(new TransitionSaveRequest(null, objectCode, 3, 1, "SUBMIT", "重新提交", 20, true, null));
        saveTransition(new TransitionSaveRequest(null, objectCode, 1, 2, "APPROVE", "审批通过", 30, true, null));
        saveTransition(new TransitionSaveRequest(null, objectCode, 1, 3, "REJECT", "审批驳回", 40, true, null));
        saveTransition(new TransitionSaveRequest(null, objectCode, 1, 0, "WITHDRAW", "撤回", 50, true, null));
        List<StatusDto> out = new ArrayList<>(statusesOf(objectCode));
        log.info("doc_status_init object={} statuses={}", objectCode, out.size());
        return out;
    }
}

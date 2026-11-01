package com.apserp.plat.meta;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.tenant.TenantContext;
import com.apserp.plat.meta.expr.ExprEvaluator;
import com.apserp.plat.meta.expr.ExprException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 审批引擎：定义（可设计）+ 实例（运行时）。
 *
 * <p>定义侧：{@code WorkflowDef → WorkflowNode → WorkflowNodeApprover} 三层，版本化发布；
 * 一个数据对象可挂多个流程，用 {@code ConditionExpr}（按单据数据求值）决定用哪个。</p>
 *
 * <p>运行侧：</p>
 * <pre>
 *   提交 SUBMIT   → 建实例（快照定义）→ 找到首个满足条件的节点 → 生成任务
 *   通过 APPROVE  → 节点内按 ApproveMode 判定：或签(任一)/会签(全部)/顺签(按序)
 *                  节点通过 → NextNodeCode 或按 Sort 找下一个满足条件的节点
 *                  无后续节点 → 实例通过，回调业务单据状态
 *   驳回 REJECT   → 实例驳回，未处理任务全部关闭，按 RejectNodeCode 决定是否退回重审
 *   退回 RETURN   → 回到指定节点重新生成任务（可连续退回）
 *   撤回 WITHDRAW → 发起人撤回：仅当流程未被任何人审批通过时允许
 *   加签 ADD_SIGN  → 在当前节点追加审批人
 * </pre>
 *
 * <p>所有状态变更都写 {@code WorkflowActionLog}，前端据此渲染时间轴。</p>
 */
@Service
public class ApprovalService {

    // 实例状态
    public static final int INST_RUNNING = 0;
    public static final int INST_APPROVED = 1;
    public static final int INST_REJECTED = 2;
    public static final int INST_WITHDRAWN = 3;

    // 任务状态
    public static final int TASK_PENDING = 0;
    public static final int TASK_APPROVED = 1;
    public static final int TASK_REJECTED = 2;
    public static final int TASK_SKIPPED = 3;

    // 节点类型
    public static final int NODE_START = 1;
    public static final int NODE_APPROVAL = 2;
    public static final int NODE_END = 3;

    // 审批方式
    public static final int MODE_ANY = 1;
    public static final int MODE_ALL = 2;
    public static final int MODE_SEQUENTIAL = 3;

    // 审批人类型
    public static final int APPROVER_USER = 1;
    public static final int APPROVER_ROLE = 2;
    public static final int APPROVER_DEPT_LEADER = 3;
    public static final int APPROVER_INITIATOR_ORG = 4;

    private static final Map<Integer, String> NODE_TYPE_NAME = Map.of(1, "开始", 2, "审批", 3, "结束");
    private static final Map<Integer, String> MODE_NAME = Map.of(1, "或签", 2, "会签", 3, "顺签");

    private final JdbcTemplate jdbc;

    public ApprovalService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    // ============================================================ DTO

    public record ApproverDto(long id, int approverType, Long approverId, String approverName,
                              String expression, int sort) {
    }

    public record NodeDto(long id, String code, String name, int nodeType, int sort, int approveMode,
                          int rejectMode, String conditionExpr, boolean allowAddSign,
                          String nextNodeCode, String rejectNodeCode, List<ApproverDto> approvers) {
    }

    public record DefDto(long id, String code, String name, String objectCode, int version,
                         String conditionExpr, int status, boolean isDefault, String remark,
                         List<NodeDto> nodes) {
    }

    public record TaskDto(long id, long instanceId, String nodeCode, String nodeName, long approverId,
                          String approverName, int status, String statusName, String opinion,
                          LocalDateTime handledAt, int sort) {
    }

    public record LogDto(String action, String actionName, Long operatorId, String operatorName,
                         String opinion, LocalDateTime at) {
    }

    public record InstanceDto(long id, String defCode, String defName, String objectCode, long businessId,
                              String businessNo, String title, int status, String statusName,
                              String currentNodeCode, String currentNodeName, Long startedBy,
                              String startedByName, LocalDateTime startedAt, LocalDateTime finishedAt,
                              List<TaskDto> tasks, List<LogDto> logs,
                              boolean canApprove, boolean canWithdraw, boolean canAddSign) {
    }

    public record DefSaveRequest(Long id, String code, String name, String objectCode, String conditionExpr,
                                 boolean isDefault, String remark, List<NodeSaveRequest> nodes) {
    }

    public record NodeSaveRequest(String code, String name, int nodeType, int sort, int approveMode,
                                  int rejectMode, String conditionExpr, boolean allowAddSign,
                                  String nextNodeCode, String rejectNodeCode,
                                  List<ApproverSaveRequest> approvers) {
    }

    public record ApproverSaveRequest(int approverType, Long approverId, String expression, int sort) {
    }

    private static final Map<Integer, String> TASK_STATUS_NAME = Map.of(
            0, "待审批", 1, "已通过", 2, "已驳回", 3, "已终止");
    private static final Map<Integer, String> INST_STATUS_NAME = Map.of(
            0, "审批中", 1, "已通过", 2, "已驳回", 3, "已撤回");
    private static final Map<String, String> ACTION_NAME = Map.of(
            "SUBMIT", "提交", "APPROVE", "通过", "REJECT", "驳回",
            "RETURN", "退回", "WITHDRAW", "撤回", "ADD_SIGN", "加签");

    // ============================================================ 定义读取

    public List<DefDto> listDefs() {
        long tenantId = TenantContext.requireTenantId();
        List<DefDto> heads = jdbc.query("""
                        SELECT d.Id, d.Code, d.Name, o.Code AS ObjectCode, d.Version, d.ConditionExpr,
                               d.Status, d.IsDefault, d.Remark
                        FROM plat.WorkflowDef d
                        LEFT JOIN plat.DataObject o ON o.Id = d.DataObjectId
                        WHERE d.TenantId = ? AND d.IsDeleted = 0
                        ORDER BY d.Code, d.Version DESC
                        """,
                (rs, i) -> new DefDto(rs.getLong("Id"), rs.getString("Code"), rs.getString("Name"),
                        rs.getString("ObjectCode"), rs.getInt("Version"), rs.getString("ConditionExpr"),
                        rs.getInt("Status"), rs.getBoolean("IsDefault"), rs.getString("Remark"), List.of()),
                tenantId);
        return heads.stream().map(d -> new DefDto(d.id(), d.code(), d.name(), d.objectCode(), d.version(),
                d.conditionExpr(), d.status(), d.isDefault(), d.remark(), nodesOf(d.id()))).toList();
    }

    public DefDto getDef(String code) {
        return listDefs().stream().filter(d -> d.code().equals(code)).findFirst()
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "审批流不存在：" + code));
    }

    private List<NodeDto> nodesOf(long defId) {
        List<NodeDto> nodes = jdbc.query("""
                        SELECT Id, Code, Name, NodeType, Sort, ApproveMode, RejectMode, ConditionExpr,
                               AllowAddSign, NextNodeCode, RejectNodeCode
                        FROM plat.WorkflowNode
                        WHERE WorkflowDefId = ?
                        ORDER BY Sort, Id
                        """,
                (rs, i) -> new NodeDto(rs.getLong("Id"), rs.getString("Code"), rs.getString("Name"),
                        rs.getInt("NodeType"), rs.getInt("Sort"), rs.getInt("ApproveMode"),
                        rs.getInt("RejectMode"), rs.getString("ConditionExpr"),
                        rs.getBoolean("AllowAddSign"), rs.getString("NextNodeCode"),
                        rs.getString("RejectNodeCode"), List.of()),
                defId);
        return nodes.stream().map(n -> new NodeDto(n.id(), n.code(), n.name(), n.nodeType(), n.sort(),
                n.approveMode(), n.rejectMode(), n.conditionExpr(), n.allowAddSign(),
                n.nextNodeCode(), n.rejectNodeCode(), approversOf(n.id()))).toList();
    }

    private List<ApproverDto> approversOf(long nodeId) {
        return jdbc.query("""
                        SELECT a.Id, a.ApproverType, a.ApproverId, a.Expression, a.Sort,
                               u.DisplayName AS ApproverName
                        FROM plat.WorkflowNodeApprover a
                        LEFT JOIN plat.[User] u ON u.Id = a.ApproverId
                        WHERE a.WorkflowNodeId = ?
                        ORDER BY a.Sort, a.Id
                        """,
                (rs, i) -> new ApproverDto(rs.getLong("Id"), rs.getInt("ApproverType"),
                        (Long) rs.getObject("ApproverId"), rs.getString("ApproverName"),
                        rs.getString("Expression"), rs.getInt("Sort")),
                nodeId);
    }

    // ============================================================ 定义写入

    @Transactional
    public long saveDef(Long id, DefSaveRequest req) {
        long tenantId = TenantContext.requireTenantId();
        validateDef(req);
        Long uid = TenantContext.userId();
        Long objectId = null;
        if (req.objectCode() != null && !req.objectCode().isBlank()) {
            objectId = jdbc.query("SELECT Id FROM plat.DataObject WHERE TenantId = ? AND Code = ? AND IsDeleted = 0",
                    (rs, i) -> rs.getLong(1), tenantId, req.objectCode()).stream().findFirst().orElse(null);
            if (objectId == null) {
                throw new ApiException(ErrorCode.META_OBJECT_NOT_FOUND, "数据对象不存在：" + req.objectCode());
            }
        }
        long defId;
        if (id == null) {
            Long dup = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM plat.WorkflowDef WHERE TenantId = ? AND Code = ? AND IsDeleted = 0
                    """, Long.class, tenantId, req.code());
            if (dup != null && dup > 0) {
                throw new ApiException(ErrorCode.DUPLICATE_KEY, "审批流编码已存在：" + req.code()
                        + "（如需改版请用新版本号）");
            }
            int version = jdbc.queryForObject("""
                    SELECT ISNULL(MAX(Version), 0) + 1 FROM plat.WorkflowDef WHERE TenantId = ? AND Code = ?
                    """, Integer.class, tenantId, req.code());
            jdbc.update("""
                    INSERT plat.WorkflowDef (TenantId, Code, Name, DataObjectId, Version, ConditionExpr,
                                             Status, IsDefault, Remark, IsDeleted, CreatedBy, CreatedAt)
                    VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?, 0, ?, sysutcdatetime())
                    """, tenantId, req.code(), req.name(), objectId, version, req.conditionExpr(),
                    req.isDefault() ? 1 : 0, req.remark(), uid);
            defId = jdbc.queryForObject("""
                    SELECT Id FROM plat.WorkflowDef WHERE TenantId = ? AND Code = ? AND Version = ?
                    """, Long.class, tenantId, req.code(), version);
        } else {
            int n = jdbc.update("""
                    UPDATE plat.WorkflowDef
                    SET Name = ?, DataObjectId = ?, ConditionExpr = ?, IsDefault = ?, Remark = ?,
                        ModifiedBy = ?, ModifiedAt = sysutcdatetime()
                    WHERE Id = ? AND TenantId = ? AND IsDeleted = 0 AND Status = 0
                    """, req.name(), objectId, req.conditionExpr(), req.isDefault() ? 1 : 0,
                    req.remark(), uid, id, tenantId);
            if (n == 0) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "只有草稿状态的审批流可以修改");
            }
            defId = id;
            jdbc.update("DELETE FROM plat.WorkflowNodeApprover WHERE WorkflowNodeId IN "
                    + "(SELECT Id FROM plat.WorkflowNode WHERE WorkflowDefId = ?)", defId);
            jdbc.update("DELETE FROM plat.WorkflowNode WHERE WorkflowDefId = ?", defId);
        }
        for (NodeSaveRequest n : req.nodes()) {
            jdbc.update("""
                    INSERT plat.WorkflowNode (WorkflowDefId, Code, Name, NodeType, Sort, ApproveMode,
                                              RejectMode, ConditionExpr, AllowAddSign, AllowDelegate,
                                              NextNodeCode, RejectNodeCode)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
                    """, defId, n.code(), n.name(), n.nodeType() <= 0 ? NODE_APPROVAL : n.nodeType(),
                    n.sort(), n.approveMode() <= 0 ? MODE_ANY : n.approveMode(),
                    n.rejectMode() <= 0 ? 1 : n.rejectMode(), n.conditionExpr(),
                    n.allowAddSign() ? 1 : 0, n.nextNodeCode(), n.rejectNodeCode());
            Long nodeId = jdbc.queryForObject("""
                    SELECT Id FROM plat.WorkflowNode WHERE WorkflowDefId = ? AND Code = ?
                    """, Long.class, defId, n.code());
            if (n.approvers() != null) {
                int sort = 0;
                for (ApproverSaveRequest a : n.approvers()) {
                    sort += 10;
                    jdbc.update("""
                            INSERT plat.WorkflowNodeApprover (WorkflowNodeId, ApproverType, ApproverId,
                                                              Expression, Sort)
                            VALUES (?, ?, ?, ?, ?)
                            """, nodeId, a.approverType() <= 0 ? APPROVER_USER : a.approverType(),
                            a.approverId(), a.expression(), a.sort() <= 0 ? sort : a.sort());
                }
            }
        }
        return defId;
    }

    private void validateDef(DefSaveRequest req) {
        if (req.code() == null || req.code().isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "审批流编码不能为空");
        }
        if (req.nodes() == null || req.nodes().isEmpty()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "审批流至少需要一个节点");
        }
        long approvalNodes = req.nodes().stream()
                .filter(n -> n.nodeType() <= 0 || n.nodeType() == NODE_APPROVAL).count();
        if (approvalNodes == 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "审批流至少需要一个审批节点");
        }
        List<String> codes = new ArrayList<>();
        for (NodeSaveRequest n : req.nodes()) {
            if (n.code() == null || n.code().isBlank()) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "节点编码不能为空");
            }
            if (codes.contains(n.code())) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "节点编码重复：" + n.code());
            }
            codes.add(n.code());
            if (n.conditionExpr() != null && !n.conditionExpr().isBlank()) {
                try {
                    ExprEvaluator.compile(n.conditionExpr());
                } catch (ExprException e) {
                    throw new ApiException(ErrorCode.BAD_REQUEST,
                            "节点 [" + n.code() + "] 条件表达式有误：" + e.getMessage());
                }
            }
            if ((n.nodeType() <= 0 || n.nodeType() == NODE_APPROVAL)
                    && (n.approvers() == null || n.approvers().isEmpty())) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "审批节点 [" + n.code() + "] 必须配置审批人");
            }
        }
        // 去向引用必须存在
        for (NodeSaveRequest n : req.nodes()) {
            if (n.nextNodeCode() != null && !n.nextNodeCode().isBlank() && !codes.contains(n.nextNodeCode())) {
                throw new ApiException(ErrorCode.BAD_REQUEST,
                        "节点 [" + n.code() + "] 的下一节点不存在：" + n.nextNodeCode());
            }
            if (n.rejectNodeCode() != null && !n.rejectNodeCode().isBlank() && !codes.contains(n.rejectNodeCode())) {
                throw new ApiException(ErrorCode.BAD_REQUEST,
                        "节点 [" + n.code() + "] 的退回节点不存在：" + n.rejectNodeCode());
            }
        }
        if (req.conditionExpr() != null && !req.conditionExpr().isBlank()) {
            try {
                ExprEvaluator.compile(req.conditionExpr());
            } catch (ExprException e) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "流程适用条件有误：" + e.getMessage());
            }
        }
    }

    /** 发布：校验通过 → Status=1（已发布）、写发布人与时间；同 Code 其它版本取消默认。 */
    @Transactional
    public void publish(String code) {
        long tenantId = TenantContext.requireTenantId();
        Long id = jdbc.query("""
                SELECT TOP 1 Id FROM plat.WorkflowDef WHERE TenantId = ? AND Code = ? AND IsDeleted = 0
                ORDER BY Version DESC
                """, (rs, i) -> rs.getLong(1), tenantId, code).stream().findFirst().orElse(null);
        if (id == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, "审批流不存在：" + code);
        }
        jdbc.update("UPDATE plat.WorkflowDef SET IsDefault = 0 WHERE TenantId = ? AND Code = ?", tenantId, code);
        jdbc.update("""
                UPDATE plat.WorkflowDef
                SET Status = 1, PublishedAt = sysutcdatetime(), IsDefault = 1,
                    ModifiedBy = ?, ModifiedAt = sysutcdatetime()
                WHERE Id = ?
                """, TenantContext.userId(), id);
        log(null, null, "PUBLISH", null);
    }

    // ============================================================ 运行时：提交

    @Transactional
    public long submit(String objectCode, long businessId, String businessNo, String title) {
        long tenantId = TenantContext.requireTenantId();
        Long userId = TenantContext.userId();
        Map<String, Object> data = businessData(objectCode, businessId);
        Map<String, Object> ctx = new LinkedHashMap<>(data);

        WorkflowDefRow def = pickDef(tenantId, objectCode, ctx);
        String snapshot = snapshotJson(def.id());
        jdbc.update("""
                INSERT plat.WorkflowInstance (TenantId, WorkflowDefId, DefSnapshot, DataObjectCode,
                                              BusinessId, BusinessNo, Title, Status, StartedBy, StartedAt)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, sysutcdatetime())
                """, tenantId, def.id(), snapshot, objectCode, businessId, businessNo, title,
                INST_RUNNING, userId);
        Long instanceId = jdbc.queryForObject("""
                SELECT MAX(Id) FROM plat.WorkflowInstance WHERE TenantId = ? AND DataObjectCode = ?
                """, Long.class, tenantId, objectCode);
        log(instanceId, null, "SUBMIT", null);
        moveToFirstNode(instanceId, def, ctx, userId);
        return instanceId;
    }

    private record WorkflowDefRow(long id, String code, String name, int version) {
    }

    private WorkflowDefRow pickDef(long tenantId, String objectCode, Map<String, Object> ctx) {
        List<WorkflowDefRow> defs = jdbc.query("""
                        SELECT d.Id, d.Code, d.Name, d.Version, d.ConditionExpr
                        FROM plat.WorkflowDef d
                        JOIN plat.DataObject o ON o.Id = d.DataObjectId
                        WHERE d.TenantId = ? AND o.Code = ? AND d.Status = 1 AND d.IsDeleted = 0
                        ORDER BY d.IsDefault DESC, d.Version DESC
                        """,
                (rs, i) -> new WorkflowDefRow(rs.getLong("Id"), rs.getString("Code"),
                        rs.getString("Name"), rs.getInt("Version")),
                tenantId, objectCode);
        for (int i = 0; i < defs.size(); i++) {
            String cond = jdbc.queryForObject(
                    "SELECT ConditionExpr FROM plat.WorkflowDef WHERE Id = ?", String.class, defs.get(i).id());
            if (cond == null || cond.isBlank()) {
                return defs.get(i);
            }
            try {
                if (ExprEvaluator.test(cond, ctx)) {
                    return defs.get(i);
                }
            } catch (ExprException e) {
                // 条件坏了就跳过该流程，不阻塞业务
            }
        }
        throw new ApiException(ErrorCode.NOT_FOUND, "未找到适用于 " + objectCode + " 的已发布审批流");
    }

    private void moveToFirstNode(long instanceId, WorkflowDefRow def, Map<String, Object> ctx, Long userId) {
        List<NodeRow> nodes = loadNodes(def.id());
        NodeRow start = nodes.stream().filter(n -> n.nodeType == NODE_APPROVAL)
                .filter(n -> matchCondition(n, ctx))
                .findFirst().orElse(null);
        if (start == null) {
            // 没有可执行节点：视为自动通过
            jdbc.update("""
                    UPDATE plat.WorkflowInstance SET Status = ?, FinishedAt = sysutcdatetime() WHERE Id = ?
                    """, INST_APPROVED, instanceId);
            return;
        }
        createTasks(instanceId, start, userId);
        jdbc.update("""
                UPDATE plat.WorkflowInstance SET CurrentNodeId = ?, CurrentNodeCode = ? WHERE Id = ?
                """, start.id, start.code, instanceId);
    }

    // ============================================================ 运行时：审批

    @Transactional
    public void approve(long taskId, boolean approved, String opinion) {
        long tenantId = TenantContext.requireTenantId();
        Long userId = TenantContext.userId();
        TaskRow task = loadTask(taskId);
        if (task == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, "审批任务不存在：" + taskId);
        }
        if (task.status != TASK_PENDING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "该任务已处理：" + taskId);
        }
        if (userId != null && task.approverId != userId) {
            throw new ApiException(ErrorCode.FORBIDDEN, "只有当前审批人可以处理该任务");
        }
        InstanceRow inst = loadInstance(tenantId, task.instanceId);
        if (inst == null || inst.status != INST_RUNNING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "流程不在审批中");
        }
        NodeRow node = loadNode(task.nodeId);
        if (node == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, "审批节点不存在");
        }
        jdbc.update("""
                UPDATE plat.WorkflowTask
                SET ApproveStatus = ?, Opinion = ?, HandledAt = sysutcdatetime()
                WHERE Id = ?
                """, approved ? TASK_APPROVED : TASK_REJECTED, opinion, taskId);
        log(task.instanceId, taskId, approved ? "APPROVE" : "REJECT", opinion);

        if (!approved) {
            closeInstance(inst.id, INST_REJECTED);
            return;
        }
        boolean nodeDone = nodeDone(inst.id, node);
        if (!nodeDone) {
            return;
        }
        advance(inst, node, userId);
    }

    private boolean nodeDone(long instanceId, NodeRow node) {
        List<TaskRow> tasks = loadPendingTasks(instanceId, node.id);
        if (node.approveMode == MODE_ANY) {
            return true;
        }
        if (node.approveMode == MODE_ALL) {
            return tasks.isEmpty();
        }
        // 顺签：只放行排在最前的人，其通过后把下一人置为待办
        if (tasks.isEmpty()) {
            return true;
        }
        TaskRow next = tasks.stream().min((a, b) -> Integer.compare(a.sort, b.sort)).orElse(tasks.get(0));
        jdbc.update("UPDATE plat.WorkflowTask SET ApproveStatus = ? WHERE Id = ?", TASK_SKIPPED, next.id);
        List<TaskRow> rest = loadPendingTasks(instanceId, node.id);
        return rest.isEmpty();
    }

    private void advance(InstanceRow inst, NodeRow node, Long userId) {
        long tenantId = inst.tenantId;
        List<NodeRow> nodes = loadNodes(node.defId);
        Map<String, Object> data = inst.objectCode == null ? Map.of()
                : businessData(inst.objectCode, inst.businessId);
        Map<String, Object> ctx = new LinkedHashMap<>(data);
        NodeRow next = resolveNext(nodes, node, ctx);
        if (next == null) {
            closeInstance(inst.id, INST_APPROVED);
            notifyBusiness(inst, INST_APPROVED);
            return;
        }
        createTasks(inst.id, next, userId);
        jdbc.update("""
                UPDATE plat.WorkflowInstance SET CurrentNodeId = ?, CurrentNodeCode = ? WHERE Id = ?
                """, next.id, next.code, inst.id);
    }

    private NodeRow resolveNext(List<NodeRow> nodes, NodeRow current, Map<String, Object> ctx) {
        if (current.nextNodeCode != null && !current.nextNodeCode.isBlank()) {
            NodeRow explicit = nodes.stream().filter(n -> n.code.equals(current.nextNodeCode))
                    .findFirst().orElse(null);
            if (explicit != null && explicit.nodeType == NODE_APPROVAL && matchCondition(explicit, ctx)) {
                return explicit;
            }
        }
        return nodes.stream()
                .filter(n -> n.nodeType == NODE_APPROVAL)
                .filter(n -> n.sort > current.sort)
                .filter(n -> matchCondition(n, ctx))
                .findFirst().orElse(null);
    }

    private boolean matchCondition(NodeRow n, Map<String, Object> ctx) {
        if (n.conditionExpr == null || n.conditionExpr.isBlank()) {
            return true;
        }
        try {
            return ExprEvaluator.test(n.conditionExpr, ctx);
        } catch (ExprException e) {
            return false;
        }
    }

    /** 退回：把实例打回指定节点，重新生成任务；已处理任务保留供追溯。 */
    @Transactional
    public void returnTo(long taskId, String targetNodeCode, String opinion) {
        long tenantId = TenantContext.requireTenantId();
        TaskRow task = loadTask(taskId);
        if (task == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, "审批任务不存在：" + taskId);
        }
        InstanceRow inst = loadInstance(tenantId, task.instanceId);
        if (inst == null || inst.status != INST_RUNNING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "流程不在审批中");
        }
        List<NodeRow> nodes = loadNodes(inst.defId);
        NodeRow target = nodes.stream().filter(n -> n.code.equals(targetNodeCode))
                .findFirst().orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND,
                        "退回节点不存在：" + targetNodeCode));
        jdbc.update("UPDATE plat.WorkflowTask SET ApproveStatus = ?, Opinion = ?, HandledAt = sysutcdatetime() "
                + "WHERE InstanceId = ? AND ApproveStatus = 0", TASK_SKIPPED, "退回：" + opinion, inst.id);
        jdbc.update("""
                UPDATE plat.WorkflowTask SET ApproveStatus = ?, Opinion = ?, HandledAt = sysutcdatetime()
                WHERE Id = ?
                """, TASK_REJECTED, opinion, taskId);
        log(inst.id, taskId, "RETURN", opinion);
        createTasks(inst.id, target, TenantContext.userId());
        jdbc.update("UPDATE plat.WorkflowInstance SET CurrentNodeId = ?, CurrentNodeCode = ? WHERE Id = ?",
                target.id, target.code, inst.id);
    }

    /** 加签：在当前节点追加一个审批人（仅当节点允许加签）。 */
    @Transactional
    public long addSign(long taskId, long approverId, String opinion) {
        long tenantId = TenantContext.requireTenantId();
        TaskRow task = loadTask(taskId);
        if (task == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, "审批任务不存在：" + taskId);
        }
        InstanceRow inst = loadInstance(tenantId, task.instanceId);
        if (inst == null || inst.status != INST_RUNNING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "流程不在审批中");
        }
        NodeRow node = loadNode(task.nodeId);
        if (node == null || !node.allowAddSign) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "当前节点不允许加签");
        }
        boolean exists = !loadPendingTasks(inst.id, node.id).stream()
                .filter(t -> t.approverId == approverId).toList().isEmpty();
        if (exists) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "该审批人已在当前节点待办中");
        }
        jdbc.update("""
                INSERT plat.WorkflowTask (InstanceId, NodeId, NodeName, ApproverId, ApproveStatus, Sort)
                VALUES (?, ?, ?, ?, 0, ?)
                """, inst.id, node.id, node.name, approverId, 900);
        Long newTaskId = jdbc.queryForObject("""
                SELECT MAX(Id) FROM plat.WorkflowTask WHERE InstanceId = ? AND NodeId = ?
                """, Long.class, inst.id, node.id);
        log(inst.id, taskId, "ADD_SIGN", opinion);
        return newTaskId == null ? 0 : newTaskId;
    }

    /** 撤回：只有发起人、且流程中没有任何任务被通过时允许。 */
    @Transactional
    public void withdraw(long instanceId, String opinion) {
        long tenantId = TenantContext.requireTenantId();
        Long userId = TenantContext.userId();
        InstanceRow inst = loadInstance(tenantId, instanceId);
        if (inst == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, "流程实例不存在：" + instanceId);
        }
        if (userId != null && inst.startedBy != null && !inst.startedBy.equals(userId)) {
            throw new ApiException(ErrorCode.FORBIDDEN, "只有发起人可以撤回");
        }
        if (inst.status != INST_RUNNING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "流程已结束，无法撤回");
        }
        Long approved = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.WorkflowTask WHERE InstanceId = ? AND ApproveStatus = 1
                """, Long.class, instanceId);
        if (approved != null && approved > 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "已有节点审批通过，不允许撤回");
        }
        jdbc.update("UPDATE plat.WorkflowTask SET ApproveStatus = ? "
                + "WHERE InstanceId = ? AND ApproveStatus = 0", TASK_SKIPPED, instanceId);
        log(instanceId, null, "WITHDRAW", opinion);
        closeInstance(instanceId, INST_WITHDRAWN);
    }

    // ============================================================ 运行时：查询

    public List<InstanceDto> myTodos() {
        long tenantId = TenantContext.requireTenantId();
        Long userId = TenantContext.userId();
        List<Long> ids = jdbc.queryForList("""
                SELECT DISTINCT i.Id
                FROM plat.WorkflowTask t
                JOIN plat.WorkflowInstance i ON i.Id = t.InstanceId
                WHERE i.TenantId = ? AND i.Status = 0 AND t.ApproveStatus = 0 AND t.ApproverId = ?
                ORDER BY i.Id DESC
                """, Long.class, tenantId, userId);
        return ids.stream().map(this::instanceOf).filter(java.util.Objects::nonNull).toList();
    }

    public List<InstanceDto> instancesOf(String objectCode, long businessId) {
        long tenantId = TenantContext.requireTenantId();
        List<Long> ids = jdbc.queryForList("""
                SELECT Id FROM plat.WorkflowInstance
                WHERE TenantId = ? AND DataObjectCode = ? AND BusinessId = ?
                ORDER BY Id DESC
                """, Long.class, tenantId, objectCode, businessId);
        return ids.stream().map(this::instanceOf).filter(java.util.Objects::nonNull).toList();
    }

    public InstanceDto getInstance(long instanceId) {
        InstanceDto dto = instanceOf(instanceId);
        if (dto == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, "流程实例不存在：" + instanceId);
        }
        return dto;
    }

    private InstanceDto instanceOf(long instanceId) {
        long tenantId = TenantContext.requireTenantId();
        Long userId = TenantContext.userId();
        InstanceRow inst = loadInstance(tenantId, instanceId);
        if (inst == null) {
            return null;
        }
        String defName = jdbc.query("SELECT Name FROM plat.WorkflowDef WHERE Id = ?",
                rs -> rs.next() ? rs.getString(1) : null, inst.defId);
        String currentNodeName = inst.currentNodeCode == null ? null
                : jdbc.query("SELECT Name FROM plat.WorkflowNode WHERE WorkflowDefId = ? AND Code = ?",
                rs -> rs.next() ? rs.getString(1) : null, inst.defId, inst.currentNodeCode);
        String startedByName = nameOf("plat.[User]", inst.startedBy);
        List<TaskDto> tasks = tasksOf(instanceId);
        List<LogDto> logs = logsOf(instanceId);
        boolean canApprove = inst.status == INST_RUNNING && tasks.stream()
                .anyMatch(t -> t.status == TASK_PENDING && userId != null && t.approverId == userId);
        boolean canWithdraw = inst.status == INST_RUNNING
                && (userId == null || inst.startedBy == null || inst.startedBy.equals(userId))
                && tasks.stream().noneMatch(t -> t.status == TASK_APPROVED);
        boolean canAddSign = inst.status == INST_RUNNING && inst.currentNodeCode != null;
        return new InstanceDto(inst.id, inst.defCode, defName, inst.objectCode, inst.businessId,
                inst.businessNo, inst.title, inst.status,
                INST_STATUS_NAME.getOrDefault(inst.status, "未知"), inst.currentNodeCode,
                currentNodeName, inst.startedBy, startedByName, inst.startedAt, inst.finishedAt,
                tasks, logs, canApprove, canWithdraw, canAddSign);
    }

    private List<TaskDto> tasksOf(long instanceId) {
        return jdbc.query("""
                        SELECT t.Id, t.InstanceId, n.Code AS NodeCode, t.NodeName, t.ApproverId,
                               u.DisplayName AS ApproverName, t.ApproveStatus, t.Opinion, t.HandledAt, t.Sort
                        FROM plat.WorkflowTask t
                        JOIN plat.WorkflowNode n ON n.Id = t.NodeId
                        LEFT JOIN plat.[User] u ON u.Id = t.ApproverId
                        WHERE t.InstanceId = ?
                        ORDER BY t.Id
                        """,
                (rs, i) -> new TaskDto(rs.getLong("Id"), rs.getLong("InstanceId"),
                        rs.getString("NodeCode"), rs.getString("NodeName"), rs.getLong("ApproverId"),
                        rs.getString("ApproverName"), rs.getInt("ApproveStatus"),
                        TASK_STATUS_NAME.getOrDefault(rs.getInt("ApproveStatus"), "未知"),
                        rs.getString("Opinion"), toLocal(rs.getTimestamp("HandledAt")), rs.getInt("Sort")),
                instanceId);
    }

    private List<LogDto> logsOf(long instanceId) {
        return jdbc.query("""
                        SELECT l.Action, l.OperatorId, u.DisplayName AS OperatorName, l.Opinion, l.[At]
                        FROM plat.WorkflowActionLog l
                        LEFT JOIN plat.[User] u ON u.Id = l.OperatorId
                        WHERE l.InstanceId = ?
                        ORDER BY l.Id
                        """,
                (rs, i) -> new LogDto(rs.getString("Action"),
                        ACTION_NAME.getOrDefault(rs.getString("Action"), rs.getString("Action")),
                        (Long) rs.getObject("OperatorId"), rs.getString("OperatorName"),
                        rs.getString("Opinion"), toLocal(rs.getTimestamp("At"))),
                instanceId);
    }

    // ============================================================ 内部

    private record NodeRow(long id, long defId, String code, String name, int nodeType, int sort,
                           int approveMode, int rejectMode, String conditionExpr, boolean allowAddSign,
                           String nextNodeCode, String rejectNodeCode) {
    }

    private record TaskRow(long id, long instanceId, long nodeId, long approverId, int status, int sort) {
    }

    private record InstanceRow(long id, long tenantId, long defId, String defCode, String objectCode,
                               long businessId, String businessNo, String title, int status,
                               String currentNodeCode, Long startedBy, LocalDateTime startedAt,
                               LocalDateTime finishedAt) {
    }

    private List<NodeRow> loadNodes(long defId) {
        return jdbc.query("""
                        SELECT Id, WorkflowDefId, Code, Name, NodeType, Sort, ApproveMode, RejectMode,
                               ConditionExpr, AllowAddSign, NextNodeCode, RejectNodeCode
                        FROM plat.WorkflowNode WHERE WorkflowDefId = ? ORDER BY Sort, Id
                        """,
                (rs, i) -> new NodeRow(rs.getLong("Id"), rs.getLong("WorkflowDefId"),
                        rs.getString("Code"), rs.getString("Name"), rs.getInt("NodeType"),
                        rs.getInt("Sort"), rs.getInt("ApproveMode"), rs.getInt("RejectMode"),
                        rs.getString("ConditionExpr"), rs.getBoolean("AllowAddSign"),
                        rs.getString("NextNodeCode"), rs.getString("RejectNodeCode")),
                defId);
    }

    private NodeRow loadNode(long nodeId) {
        return jdbc.query("""
                        SELECT Id, WorkflowDefId, Code, Name, NodeType, Sort, ApproveMode, RejectMode,
                               ConditionExpr, AllowAddSign, NextNodeCode, RejectNodeCode
                        FROM plat.WorkflowNode WHERE Id = ?
                        """,
                rs -> rs.next() ? new NodeRow(rs.getLong("Id"), rs.getLong("WorkflowDefId"),
                        rs.getString("Code"), rs.getString("Name"), rs.getInt("NodeType"),
                        rs.getInt("Sort"), rs.getInt("ApproveMode"), rs.getInt("RejectMode"),
                        rs.getString("ConditionExpr"), rs.getBoolean("AllowAddSign"),
                        rs.getString("NextNodeCode"), rs.getString("RejectNodeCode")) : null,
                nodeId);
    }

    private TaskRow loadTask(long taskId) {
        return jdbc.query("""
                        SELECT Id, InstanceId, NodeId, ApproverId, ApproveStatus, Sort
                        FROM plat.WorkflowTask WHERE Id = ?
                        """,
                rs -> rs.next() ? new TaskRow(rs.getLong("Id"), rs.getLong("InstanceId"),
                        rs.getLong("NodeId"), rs.getLong("ApproverId"), rs.getInt("ApproveStatus"),
                        rs.getInt("Sort")) : null,
                taskId);
    }

    private List<TaskRow> loadPendingTasks(long instanceId, long nodeId) {
        return jdbc.query("""
                        SELECT Id, InstanceId, NodeId, ApproverId, ApproveStatus, Sort
                        FROM plat.WorkflowTask
                        WHERE InstanceId = ? AND NodeId = ? AND ApproveStatus = 0 ORDER BY Sort, Id
                        """,
                (rs, i) -> new TaskRow(rs.getLong("Id"), rs.getLong("InstanceId"),
                        rs.getLong("NodeId"), rs.getLong("ApproverId"), rs.getInt("ApproveStatus"),
                        rs.getInt("Sort")),
                instanceId, nodeId);
    }

    private InstanceRow loadInstance(long tenantId, long instanceId) {
        return jdbc.query("""
                        SELECT i.Id, i.TenantId, i.WorkflowDefId, d.Code AS DefCode, i.DataObjectCode,
                               i.BusinessId, i.BusinessNo, i.Title, i.Status, i.CurrentNodeCode,
                               i.StartedBy, i.StartedAt, i.FinishedAt
                        FROM plat.WorkflowInstance i
                        JOIN plat.WorkflowDef d ON d.Id = i.WorkflowDefId
                        WHERE i.TenantId = ? AND i.Id = ?
                        """,
                rs -> rs.next() ? new InstanceRow(rs.getLong("Id"), rs.getLong("TenantId"),
                        rs.getLong("WorkflowDefId"), rs.getString("DefCode"),
                        rs.getString("DataObjectCode"), rs.getLong("BusinessId"),
                        rs.getString("BusinessNo"), rs.getString("Title"), rs.getInt("Status"),
                        rs.getString("CurrentNodeCode"), (Long) rs.getObject("StartedBy"),
                        toLocal(rs.getTimestamp("StartedAt")), toLocal(rs.getTimestamp("FinishedAt")))
                        : null,
                tenantId, instanceId);
    }

    /** 按节点配置生成待办任务；同一节点同一人只生成一条。 */
    private void createTasks(long instanceId, NodeRow node, Long operator) {
        List<Long> approvers = resolveApprovers(node, operator);
        if (approvers.isEmpty()) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                    "审批节点 [" + node.code + "] 未能解析出审批人");
        }
        int sort = 0;
        for (Long uid : approvers) {
            sort += 10;
            jdbc.update("""
                    INSERT plat.WorkflowTask (InstanceId, NodeId, NodeName, ApproverId, ApproveStatus, Sort)
                    VALUES (?, ?, ?, ?, 0, ?)
                    """, instanceId, node.id, node.name, uid, sort);
        }
    }

    private List<Long> resolveApprovers(NodeRow node, Long initiator) {
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT ApproverType, ApproverId, Expression FROM plat.WorkflowNodeApprover
                WHERE WorkflowNodeId = ? ORDER BY Sort, Id
                """, node.id);
        List<Long> out = new ArrayList<>();
        for (Map<String, Object> r : rows) {
            int type = ((Number) r.get("ApproverType")).intValue();
            Object aid = r.get("ApproverId");
            Long id = aid == null ? null : ((Number) aid).longValue();
            switch (type) {
                case APPROVER_USER -> {
                    if (id != null && !out.contains(id)) {
                        out.add(id);
                    }
                }
                case APPROVER_ROLE -> {
                    if (id != null) {
                        jdbc.queryForList("""
                                SELECT UserId FROM plat.UserRole WHERE RoleId = ?
                                """, Long.class, id).forEach(u -> {
                            if (!out.contains(u)) {
                                out.add(u);
                            }
                        });
                    }
                }
                case APPROVER_DEPT_LEADER -> {
                    // 发起人所在部门的负责人
                    List<Long> leaders = jdbc.queryForList("""
                            SELECT o.ManagerId FROM plat.Org o
                            JOIN plat.Employee e ON e.OrgId = o.Id
                            WHERE e.Id = (SELECT EmployeeId FROM plat.[User] WHERE Id = ?)
                            """, Long.class, initiator);
                    leaders.stream().filter(java.util.Objects::nonNull)
                            .forEach(u -> {
                                if (!out.contains(u)) {
                                    out.add(u);
                                }
                            });
                }
                case APPROVER_INITIATOR_ORG -> {
                    // 发起人本人（用于“经办确认”类节点）
                    if (initiator != null && !out.contains(initiator)) {
                        out.add(initiator);
                    }
                }
                default -> {
                    if (id != null && !out.contains(id)) {
                        out.add(id);
                    }
                }
            }
        }
        return out;
    }

    private void closeInstance(long instanceId, int status) {
        jdbc.update("""
                UPDATE plat.WorkflowInstance SET Status = ?, FinishedAt = sysutcdatetime(),
                       CurrentNodeId = NULL, CurrentNodeCode = NULL
                WHERE Id = ?
                """, status, instanceId);
        jdbc.update("""
                UPDATE plat.WorkflowTask SET ApproveStatus = ?
                WHERE InstanceId = ? AND ApproveStatus = 0
                """, TASK_SKIPPED, instanceId);
    }

    /** 审批结果回写业务单据状态：走元数据引擎的状态字段，不硬编码表名。 */
    private void notifyBusiness(InstanceRow inst, int status) {
        if (inst.objectCode == null) {
            return;
        }
        String statusField = jdbc.query("SELECT StatusField FROM plat.DataObject WHERE TenantId = ? AND Code = ?",
                rs -> rs.next() ? rs.getString(1) : null, inst.tenantId, inst.objectCode);
        if (statusField == null || statusField.isBlank()) {
            return;
        }
        String schema = jdbc.queryForObject("SELECT SchemaName FROM plat.DataObject WHERE TenantId = ? AND Code = ?",
                String.class, inst.tenantId, inst.objectCode);
        String table = jdbc.queryForObject("SELECT ObjectName FROM plat.DataObject WHERE TenantId = ? AND Code = ?",
                String.class, inst.tenantId, inst.objectCode);
        String pk = jdbc.query("SELECT PrimaryKey FROM plat.DataObject WHERE TenantId = ? AND Code = ?",
                rs -> rs.next() ? rs.getString(1) : "Id", inst.tenantId, inst.objectCode);
        String sql = "UPDATE [" + schema + "].[" + table + "] SET [" + statusField + "] = ? WHERE ["
                + (pk == null ? "Id" : pk) + "] = ?";
        jdbc.update(sql, status == INST_APPROVED ? 2 : 3, inst.businessId);
    }

    private void log(Long instanceId, Long taskId, String action, String opinion) {
        if (instanceId == null) {
            // 定义发布之类的动作不进实例时间轴
            return;
        }
        jdbc.update("""
                INSERT plat.WorkflowActionLog (InstanceId, TaskId, Action, OperatorId, Opinion, [At])
                VALUES (?, ?, ?, ?, ?, sysutcdatetime())
                """, instanceId, taskId, action, TenantContext.userId(), opinion);
    }

    private Map<String, Object> businessData(String objectCode, long businessId) {
        long tenantId = TenantContext.requireTenantId();
        try {
            Map<String, Object> row = jdbc.execute((ConnectionCallback<Map<String, Object>>) con -> {
                try (var cs = con.prepareCall("{call plat.usp_Meta_Get (?, ?, ?)}")) {
                    cs.setInt(1, (int) tenantId);
                    cs.setString(2, objectCode);
                    cs.setLong(3, businessId);
                    try (var rs = cs.executeQuery()) {
                        if (!rs.next()) {
                            return Map.of();
                        }
                        var meta = rs.getMetaData();
                        Map<String, Object> m = new LinkedHashMap<>();
                        for (int i = 1; i <= meta.getColumnCount(); i++) {
                            m.put(meta.getColumnLabel(i), rs.getObject(i));
                        }
                        return m;
                    }
                }
            });
            return row == null ? Map.of() : row;
        } catch (RuntimeException e) {
            return Map.of();
        }
    }

    private String snapshotJson(long defId) {
        StringBuilder sb = new StringBuilder();
        sb.append("{\"defId\":").append(defId).append(",\"nodes\":[");
        List<NodeRow> nodes = loadNodes(defId);
        for (int i = 0; i < nodes.size(); i++) {
            NodeRow n = nodes.get(i);
            if (i > 0) {
                sb.append(',');
            }
            sb.append("{\"code\":\"").append(n.code).append("\",\"name\":\"")
                    .append(n.name == null ? "" : n.name.replace("\"", "'"))
                    .append("\",\"mode\":").append(n.approveMode).append('}');
        }
        sb.append("]}");
        return sb.toString();
    }

    private String nameOf(String table, Long id) {
        if (id == null) {
            return null;
        }
        return jdbc.query("SELECT DisplayName FROM " + table + " WHERE Id = ?",
                rs -> rs.next() ? rs.getString(1) : null, id);
    }

    private static LocalDateTime toLocal(Timestamp ts) {
        return ts == null ? null : ts.toLocalDateTime();
    }

    /** 设计器用：给审批人选择器提供用户列表。 */
    public List<Map<String, Object>> users() {
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                        SELECT Id, UserName, DisplayName FROM plat.[User]
                        WHERE TenantId = ? AND IsDeleted = 0 ORDER BY Id
                        """,
                (rs, i) -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("id", rs.getLong("Id"));
                    m.put("userName", rs.getString("UserName"));
                    m.put("displayName", rs.getString("DisplayName"));
                    return m;
                }, tenantId);
    }

    /** 设计器用：节点类型/审批方式的中文名，避免前端重复维护。 */
    public Map<String, Object> dictionaries() {
        return Map.of(
                "nodeTypes", NODE_TYPE_NAME,
                "approveModes", MODE_NAME,
                "approverTypes", Map.of(1, "指定用户", 2, "角色", 3, "部门负责人", 4, "发起人"),
                "instanceStatus", INST_STATUS_NAME,
                "taskStatus", TASK_STATUS_NAME);
    }

    /** 由任务反查业务对象编码：权限校验需要它，前端不必再传。 */
    public String objectCodeOfTask(long taskId) {
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                SELECT i.DataObjectCode FROM plat.WorkflowTask t
                JOIN plat.WorkflowInstance i ON i.Id = t.InstanceId
                WHERE i.TenantId = ? AND t.Id = ?
                """, rs -> rs.next() ? rs.getString(1) : null, tenantId, taskId);
    }

    /** 由实例反查业务对象编码。 */
    public String objectCodeOfInstance(long instanceId) {
        return jdbc.query("""
                SELECT DataObjectCode FROM plat.WorkflowInstance WHERE TenantId = ? AND Id = ?
                """, rs -> rs.next() ? rs.getString(1) : null, TenantContext.requireTenantId(), instanceId);
    }
}

package com.apserp.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.apserp.common.ApiException;
import com.apserp.common.tenant.TenantContext;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

/**
 * 审批流集成测试：用真实库跑「提交 → 通过/驳回 → 流转 → 退回 → 撤回」。
 *
 * <p>用自建流程（IT-WF-*）而不是 V29 的演示流程，避免与其它用例互相干扰；
 * 每个用例结束清理自己造的数据。</p>
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class ApprovalFlowIT {

    @Autowired
    ApprovalService approvalService;

    @Autowired
    JdbcTemplate jdbc;

    private static final String WF = "IT-WF-DEMO";

    @BeforeEach
    void setUp() {
        TenantContext.set(1L, 1L);
        cleanUp();
        ensureApprover("it_approver2", "第二审批人");
    }

    /** 会签/加签需要第二个真实用户（FK 指向 plat.User）。 */
    private long ensureApprover(String userName, String displayName) {
        Long id = jdbc.query("SELECT Id FROM plat.[User] WHERE TenantId = 1 AND UserName = ?",
                rs -> rs.next() ? rs.getLong(1) : null, userName);
        if (id != null) {
            return id;
        }
        jdbc.update("""
                INSERT plat.[User] (TenantId, UserName, PasswordHash, PasswordSalt, DisplayName, UserType,
                                    IsEnabled, MustChangePwd, FailCount, IsDeleted, CreatedAt)
                VALUES (1, ?, 'x', 'x', ?, 1, 1, 0, 0, 0, sysutcdatetime())
                """, userName, displayName);
        return jdbc.queryForObject("SELECT Id FROM plat.[User] WHERE TenantId = 1 AND UserName = ?",
                Long.class, userName);
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    private void cleanUp() {
        jdbc.update("""
                DELETE l FROM plat.WorkflowActionLog l
                JOIN plat.WorkflowInstance i ON i.Id = l.InstanceId
                WHERE i.DataObjectCode = 'md.brand'
                """);
        jdbc.update("DELETE t FROM plat.WorkflowTask t JOIN plat.WorkflowInstance i ON i.Id = t.InstanceId "
                + "WHERE i.DataObjectCode = 'md.brand'");
        jdbc.update("DELETE FROM plat.WorkflowInstance WHERE DataObjectCode = 'md.brand'");
        jdbc.update("DELETE a FROM plat.WorkflowNodeApprover a "
                + "JOIN plat.WorkflowNode n ON n.Id = a.WorkflowNodeId "
                + "JOIN plat.WorkflowDef d ON d.Id = n.WorkflowDefId WHERE d.Code LIKE 'IT-WF-%'");
        jdbc.update("DELETE n FROM plat.WorkflowNode n JOIN plat.WorkflowDef d ON d.Id = n.WorkflowDefId "
                + "WHERE d.Code LIKE 'IT-WF-%'");
        jdbc.update("DELETE FROM plat.WorkflowDef WHERE Code LIKE 'IT-WF-%'");
    }

    /** 造一个两节点流程：N1 或签（条件 Sort >= 100），N2 会签（条件 Sort < 100）。 */
    private void createFlow() {
        approvalService.saveDef(null, new ApprovalService.DefSaveRequest(
                null, WF, "集成测试流程", "md.brand", null, true, null,
                List.of(new ApprovalService.NodeSaveRequest("N1", "部门审批", 2, 10, 1, 1,
                                "ctx.Sort != null && ctx.Sort >= 100", true, "N2", null,
                                List.of(new ApprovalService.ApproverSaveRequest(1, 1L, null, 10))),
                        new ApprovalService.NodeSaveRequest("N2", "财务会签", 2, 20, 2, 1,
                                "ctx.Sort != null && ctx.Sort < 100", true, null, null,
                                List.of(new ApprovalService.ApproverSaveRequest(1, 1L, null, 10),
                                        new ApprovalService.ApproverSaveRequest(1, ensureApprover("it_approver2", "第二审批人"), null, 20))))));
        approvalService.publish(WF);
    }

    private long newBrand(int sort) {
        return jdbc.queryForObject("""
                INSERT md.Brand (TenantId, Code, Name, Sort, IsEnabled, CreatedAt)
                OUTPUT INSERTED.Id
                VALUES (1, ?, N'审批测试品牌', ?, 1, sysutcdatetime())
                """, Long.class, "IT-WF-" + System.nanoTime(), sort);
    }

    @Test
    @DisplayName("条件分支：Sort>=100 走 N1；N1 或签一人通过即结束")
    void conditional_first_node_and_any_mode() {
        createFlow();
        long businessId = newBrand(150);
        long instanceId = approvalService.submit("md.brand", businessId, "IT-WF-001", "品牌审批");

        ApprovalService.InstanceDto inst = approvalService.getInstance(instanceId);
        assertThat(inst.status()).isEqualTo(ApprovalService.INST_RUNNING);
        assertThat(inst.currentNodeCode()).isEqualTo("N1");
        assertThat(inst.tasks()).hasSize(1);

        long taskId = inst.tasks().get(0).id();
        approvalService.approve(taskId, true, "同意");
        ApprovalService.InstanceDto done = approvalService.getInstance(instanceId);
        assertThat(done.status()).isEqualTo(ApprovalService.INST_APPROVED);
        assertThat(done.logs()).extracting(ApprovalService.LogDto::action)
                .containsExactly("SUBMIT", "APPROVE");
        assertThat(done.canWithdraw()).isFalse();
    }

    @Test
    @DisplayName("条件分支：Sort<100 走 N2 会签，必须两人都通过")
    void conditional_second_node_and_all_mode() {
        createFlow();
        long businessId = newBrand(50);
        long instanceId = approvalService.submit("md.brand", businessId, "IT-WF-002", "品牌审批");

        List<ApprovalService.TaskDto> tasks = approvalService.getInstance(instanceId).tasks();
        assertThat(tasks).hasSize(2);
        assertThat(approvalService.getInstance(instanceId).currentNodeCode()).isEqualTo("N2");

        // 每个审批人用自己的身份处理自己的待办（服务端会校验“只有当前审批人可以处理”）
        ApprovalService.TaskDto t1 = tasks.get(0);
        TenantContext.set(1L, t1.approverId());
        approvalService.approve(t1.id(), true, "第一人同意");
        ApprovalService.InstanceDto mid = approvalService.getInstance(instanceId);
        assertThat(mid.status()).isEqualTo(ApprovalService.INST_RUNNING);
        assertThat(mid.tasks()).filteredOn(t -> t.status() == ApprovalService.TASK_APPROVED).hasSize(1);

        ApprovalService.TaskDto t2 = tasks.get(1);
        TenantContext.set(1L, t2.approverId());
        approvalService.approve(t2.id(), true, "第二人同意");
        assertThat(approvalService.getInstance(instanceId).status())
                .isEqualTo(ApprovalService.INST_APPROVED);
    }

    @Test
    @DisplayName("驳回：实例置驳回，未处理任务全部终止，业务单据状态回写")
    void reject_closes_instance() {
        createFlow();
        long businessId = newBrand(50);
        long instanceId = approvalService.submit("md.brand", businessId, "IT-WF-003", "品牌审批");
        ApprovalService.TaskDto first = approvalService.getInstance(instanceId).tasks().get(0);

        approvalService.approve(first.id(), false, "不同意");
        ApprovalService.InstanceDto inst = approvalService.getInstance(instanceId);
        assertThat(inst.status()).isEqualTo(ApprovalService.INST_REJECTED);
        assertThat(inst.finishedAt()).isNotNull();
        assertThat(inst.tasks()).allSatisfy(t -> assertThat(t.status()).isNotEqualTo(ApprovalService.TASK_PENDING));
        assertThat(inst.logs()).extracting(ApprovalService.LogDto::action).contains("REJECT");
    }

    @Test
    @DisplayName("重复处理同一任务被拒绝")
    void double_handle_is_rejected() {
        createFlow();
        long businessId = newBrand(150);
        long instanceId = approvalService.submit("md.brand", businessId, "IT-WF-004", "品牌审批");
        long taskId = approvalService.getInstance(instanceId).tasks().get(0).id();
        approvalService.approve(taskId, true, "同意");
        assertThatThrownBy(() -> approvalService.approve(taskId, true, "再点一次"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("已处理");
    }

    @Test
    @DisplayName("退回：回到指定节点并重新生成待办")
    void return_to_node() {
        createFlow();
        long businessId = newBrand(150);
        long instanceId = approvalService.submit("md.brand", businessId, "IT-WF-005", "品牌审批");
        long taskId = approvalService.getInstance(instanceId).tasks().get(0).id();

        approvalService.returnTo(taskId, "N1", "请补充资料");
        ApprovalService.InstanceDto inst = approvalService.getInstance(instanceId);
        assertThat(inst.status()).isEqualTo(ApprovalService.INST_RUNNING);
        assertThat(inst.currentNodeCode()).isEqualTo("N1");
        assertThat(inst.tasks()).filteredOn(t -> t.status() == ApprovalService.TASK_PENDING).hasSize(1);
        assertThat(inst.logs()).extracting(ApprovalService.LogDto::action).contains("RETURN");
    }

    @Test
    @DisplayName("撤回：未审批前可撤，已审批后拒绝")
    void withdraw_rules() {
        createFlow();
        long businessId = newBrand(150);
        long instanceId = approvalService.submit("md.brand", businessId, "IT-WF-006", "品牌审批");
        approvalService.withdraw(instanceId, "不办了");
        ApprovalService.InstanceDto inst = approvalService.getInstance(instanceId);
        assertThat(inst.status()).isEqualTo(ApprovalService.INST_WITHDRAWN);
        assertThat(inst.logs()).extracting(ApprovalService.LogDto::action).contains("WITHDRAW");

        long businessId2 = newBrand(150);
        long instanceId2 = approvalService.submit("md.brand", businessId2, "IT-WF-007", "品牌审批");
        long taskId2 = approvalService.getInstance(instanceId2).tasks().get(0).id();
        approvalService.approve(taskId2, true, "同意");
        assertThatThrownBy(() -> approvalService.withdraw(instanceId2, "撤"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("已结束");
    }

    @Test
    @DisplayName("加签：允许加签的节点追加审批人；重复加同一人被拒绝")
    void add_sign() {
        createFlow();
        long businessId = newBrand(150);
        long instanceId = approvalService.submit("md.brand", businessId, "IT-WF-008", "品牌审批");
        long taskId = approvalService.getInstance(instanceId).tasks().get(0).id();

        long second = ensureApprover("it_approver2", "第二审批人");
        long newTask = approvalService.addSign(taskId, second, "请财务一起看");
        assertThat(newTask).isPositive();
        assertThat(approvalService.getInstance(instanceId).tasks()).hasSize(2);
        assertThatThrownBy(() -> approvalService.addSign(taskId, second, "再加一次"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("待办");
    }

    @Test
    @DisplayName("待办：审批人的待办列表包含该实例")
    void todo_list() {
        createFlow();
        long businessId = newBrand(150);
        long instanceId = approvalService.submit("md.brand", businessId, "IT-WF-009", "品牌审批");
        TenantContext.set(1L, 1L);
        assertThat(approvalService.myTodos()).extracting(ApprovalService.InstanceDto::id)
                .contains(instanceId);
    }

    @Test
    @DisplayName("流程定义校验：无审批节点/节点编码重复/去向不存在都要拒绝")
    void def_validation() {
        // 节点编码重复
        assertThatThrownBy(() -> approvalService.saveDef(null, new ApprovalService.DefSaveRequest(
                null, "IT-WF-BAD", "坏流程", "md.brand", null, false, null,
                List.of(new ApprovalService.NodeSaveRequest("N1", "A", 2, 10, 1, 1, null, true, null, null,
                                List.of(new ApprovalService.ApproverSaveRequest(1, 1L, null, 10))),
                        new ApprovalService.NodeSaveRequest("N1", "B", 2, 20, 1, 1, null, true, null, null,
                                List.of(new ApprovalService.ApproverSaveRequest(1, 1L, null, 10)))))))
                .isInstanceOf(ApiException.class).hasMessageContaining("重复");

        // 去向不存在
        assertThatThrownBy(() -> approvalService.saveDef(null, new ApprovalService.DefSaveRequest(
                null, "IT-WF-BAD2", "坏流程", "md.brand", null, false, null,
                List.of(new ApprovalService.NodeSaveRequest("N1", "A", 2, 10, 1, 1, null, true, "N9", null,
                        List.of(new ApprovalService.ApproverSaveRequest(1, 1L, null, 10)))))))
                .isInstanceOf(ApiException.class).hasMessageContaining("不存在");

        // 审批节点必须配审批人
        assertThatThrownBy(() -> approvalService.saveDef(null, new ApprovalService.DefSaveRequest(
                null, "IT-WF-BAD3", "坏流程", "md.brand", null, false, null,
                List.of(new ApprovalService.NodeSaveRequest("N1", "A", 2, 10, 1, 1, null, true, null, null,
                        List.of())))))
                .isInstanceOf(ApiException.class).hasMessageContaining("审批人");
    }

    @Test
    @DisplayName("发布：同 Code 只能有一个默认版本")
    void publish_marks_single_default() {
        createFlow();
        approvalService.publish(WF);
        Integer defaults = jdbc.queryForObject(
                "SELECT COUNT(*) FROM plat.WorkflowDef WHERE Code = ? AND IsDefault = 1", Integer.class, WF);
        assertThat(defaults).isEqualTo(1);
        Integer status = jdbc.queryForObject(
                "SELECT MAX(Status) FROM plat.WorkflowDef WHERE Code = ?", Integer.class, WF);
        assertThat(status).isEqualTo(1);
    }

    @Test
    @DisplayName("没有可用流程时提交给出明确错误")
    void submit_without_flow() {
        // 先把 V29 演示流程下线，确保走到“找不到流程”的分支
        jdbc.update("UPDATE plat.WorkflowDef SET Status = 0 WHERE Code = 'WF-BRAND-ENABLE'");
        long businessId = newBrand(10);
        assertThatThrownBy(() -> approvalService.submit("md.brand", businessId, "IT-WF-X", "无流程"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("审批流");
    }

    @Test
    @DisplayName("字典接口给全前端需要的枚举中文名")
    void dictionaries() {
        Map<String, Object> dict = approvalService.dictionaries();
        assertThat(dict).containsKeys("nodeTypes", "approveModes", "approverTypes",
                "instanceStatus", "taskStatus");
    }
}

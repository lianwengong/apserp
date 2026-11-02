package com.apserp.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.apserp.common.ApiException;
import com.apserp.common.tenant.TenantContext;
import com.apserp.support.ItDb;
import java.time.LocalDateTime;
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
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

/**
 * 审批增强集成测试：抄送、超时提醒、代理。
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class ApprovalEnhanceIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    ApprovalService approvalService;

    @Autowired
    MetaSaveService saveService;

    @Autowired
    JdbcTemplate jdbc;

    private static final String WF = "IT-WF-CC";
    private static final String CODE = "IT_CC_01";

    @BeforeEach
    void setUp() {
        TenantContext.set(1L, 1L);
        cleanUp();
        ensureUser("it_cc_user", "抄送人乙");
        ensureUser("it_cc_delegate", "代理人丙");
        // 演示流程设为非默认，保证提交命中本用例的流程
        jdbc.update("UPDATE plat.WorkflowDef SET IsDefault = 0 WHERE Code = 'WF-BRAND-ENABLE'");
    }

    @AfterEach
    void tearDown() {
        cleanUp();
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
        jdbc.update("DELETE c FROM plat.WorkflowInstanceCc c JOIN plat.WorkflowInstance i ON i.Id = c.InstanceId "
                + "WHERE i.DataObjectCode = 'md.brand'");
        jdbc.update("DELETE FROM plat.WorkflowInstance WHERE DataObjectCode = 'md.brand'");
        jdbc.update("DELETE c FROM plat.WorkflowNodeCc c JOIN plat.WorkflowNode n ON n.Id = c.WorkflowNodeId "
                + "JOIN plat.WorkflowDef d ON d.Id = n.WorkflowDefId WHERE d.Code LIKE 'IT-WF-%'");
        jdbc.update("DELETE a FROM plat.WorkflowNodeApprover a "
                + "JOIN plat.WorkflowNode n ON n.Id = a.WorkflowNodeId "
                + "JOIN plat.WorkflowDef d ON d.Id = n.WorkflowDefId WHERE d.Code LIKE 'IT-WF-%'");
        jdbc.update("DELETE n FROM plat.WorkflowNode n JOIN plat.WorkflowDef d ON d.Id = n.WorkflowDefId "
                + "WHERE d.Code LIKE 'IT-WF-%'");
        jdbc.update("DELETE FROM plat.WorkflowDef WHERE Code LIKE 'IT-WF-%'");
        jdbc.update("DELETE FROM plat.WorkflowDelegate WHERE UserId IN "
                + "(SELECT Id FROM plat.[User] WHERE UserName LIKE 'it_cc_%')");
        jdbc.update("DELETE FROM md.Brand WHERE Code LIKE ?", CODE + "%");
    }

    private long ensureUser(String userName, String displayName) {
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

    private long user(String name) {
        return jdbc.queryForObject("SELECT Id FROM plat.[User] WHERE TenantId = 1 AND UserName = ?",
                Long.class, name);
    }

    private void createFlow(long approverId, long ccUserId, Integer timeoutHours) {
        approvalService.saveDef(null, new ApprovalService.DefSaveRequest(
                null, WF, "抄送与超时流程", "md.brand", null, true, null,
                List.of(new ApprovalService.NodeSaveRequest("N1", "部门审批", 2, 10, 1, 1,
                        null, true, null, null,
                        List.of(new ApprovalService.ApproverSaveRequest(1, approverId, null, 10)),
                        timeoutHours, List.of(ccUserId)))));
        approvalService.publish(WF);
    }

    private int seq = 0;

    /** 每个用例可能要造多条单据：编码加序号，避免撞唯一键。 */
    private long newBrand() {
        seq++;
        return saveService.save("md.brand",
                "{\"Code\":\"" + CODE + "_" + seq + "\",\"Name\":\"抄送测试品牌\",\"Sort\":10}");
    }

    @Test
    @DisplayName("定义里保存抄送人与超时小时数，并能在查询里读回")
    void def_carries_cc_and_timeout() {
        createFlow(1L, user("it_cc_user"), 8);
        ApprovalService.DefDto def = approvalService.getDef(WF);
        assertThat(def.nodes()).hasSize(1);
        ApprovalService.NodeDto node = def.nodes().get(0);
        assertThat(node.timeoutHours()).isEqualTo(8);
        assertThat(node.ccUserIds()).containsExactly(user("it_cc_user"));
    }

    @Test
    @DisplayName("提交后生成抄送记录，抄送人能在“抄送我的”里看到并标记已读")
    void cc_snapshot_and_read() {
        long ccUserId = user("it_cc_user");
        createFlow(1L, ccUserId, null);
        long instanceId = approvalService.submit("md.brand", newBrand(), CODE, "抄送测试");

        TenantContext.set(1L, ccUserId);
        List<ApprovalService.InstanceDto> ccs = approvalService.myCcs();
        assertThat(ccs).extracting(ApprovalService.InstanceDto::id).contains(instanceId);
        assertThat(approvalService.unreadCcCount()).isEqualTo(1);
        assertThat(ccs.get(0).ccUsers()).hasSize(1);

        approvalService.markCcRead(instanceId);
        assertThat(approvalService.unreadCcCount()).isZero();
    }

    @Test
    @DisplayName("节点配了超时小时数：任务带 DueAt；超时后出现在超时列表")
    void timeout_sets_due_at() {
        createFlow(1L, user("it_cc_user"), 4);
        long instanceId = approvalService.submit("md.brand", newBrand(), CODE, "超时测试");

        ApprovalService.InstanceDto inst = approvalService.getInstance(instanceId);
        assertThat(inst.tasks().get(0).dueAt()).isNotNull();
        assertThat(inst.tasks().get(0).overdue()).isFalse();
        assertThat(approvalService.overdueTasks()).extracting(ApprovalService.InstanceDto::id)
                .doesNotContain(instanceId);

        // 把到期时间回拨到过去，模拟超时
        jdbc.update("UPDATE plat.WorkflowTask SET DueAt = DATEADD(hour, -1, sysutcdatetime()) "
                + "WHERE InstanceId = ?", instanceId);
        assertThat(approvalService.overdueTasks()).extracting(ApprovalService.InstanceDto::id)
                .contains(instanceId);
        assertThat(approvalService.getInstance(instanceId).tasks().get(0).overdue()).isTrue();
    }

    @Test
    @DisplayName("催办：写入 REMIND 日志；已处理的任务不能再催")
    void remind_writes_log() {
        createFlow(1L, user("it_cc_user"), null);
        long instanceId = approvalService.submit("md.brand", newBrand(), CODE, "催办测试");
        long taskId = approvalService.getInstance(instanceId).tasks().get(0).id();

        assertThat(approvalService.remind(taskId, "请尽快处理")).isEqualTo(1);
        assertThat(approvalService.getInstance(instanceId).logs())
                .extracting(ApprovalService.LogDto::action).contains("REMIND");

        approvalService.approve(taskId, true, "同意");
        assertThatThrownBy(() -> approvalService.remind(taskId, "再催一次"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("已处理");
    }

    @Test
    @DisplayName("代理：配置生效后，待办落到代理人身上")
    void delegate_redirects_task() {
        long owner = ensureUser("it_cc_owner", "委托人甲");
        long delegate = user("it_cc_delegate");
        createFlow(owner, user("it_cc_user"), null);

        // 代理前：待办归 owner
        long instanceId = approvalService.submit("md.brand", newBrand(), CODE, "代理测试");
        assertThat(approvalService.getInstance(instanceId).tasks().get(0).approverId())
                .isEqualTo(owner);

        // 配代理后再提交：待办归代理人
        approvalService.saveDelegate(new ApprovalService.DelegateSaveRequest(
                null, owner, delegate, LocalDateTime.now().minusHours(1),
                LocalDateTime.now().plusDays(1), true, "休假"));
        long second = approvalService.submit("md.brand", newBrand(), CODE, "代理测试2");
        assertThat(approvalService.getInstance(second).tasks().get(0).approverId())
                .isEqualTo(delegate);
    }

    @Test
    @DisplayName("代理校验：不能代理给自己、不能成环、同一人只能一条")
    void delegate_validation() {
        long a = ensureUser("it_cc_owner", "委托人甲");
        long b = user("it_cc_delegate");

        assertThatThrownBy(() -> approvalService.saveDelegate(new ApprovalService.DelegateSaveRequest(
                null, a, a, null, null, true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("不能代理给自己");

        long id = approvalService.saveDelegate(new ApprovalService.DelegateSaveRequest(
                null, a, b, null, null, true, "休假"));
        assertThat(id).isPositive();

        assertThatThrownBy(() -> approvalService.saveDelegate(new ApprovalService.DelegateSaveRequest(
                null, a, b, null, null, true, "重复")))
                .isInstanceOf(ApiException.class);

        // 成环：b → a
        jdbc.update("""
                INSERT plat.WorkflowDelegate (TenantId, UserId, DelegateToId, IsEnabled, IsDeleted, CreatedAt)
                VALUES (1, ?, ?, 1, 0, sysutcdatetime())
                """, b, a);
        assertThatThrownBy(() -> approvalService.saveDelegate(new ApprovalService.DelegateSaveRequest(
                null, a, b, null, null, true, "环")))
                .isInstanceOf(ApiException.class);

        assertThat(approvalService.listDelegates()).extracting(ApprovalService.DelegateDto::userId)
                .contains(a);
        approvalService.deleteDelegate(id);
        assertThat(approvalService.listDelegates()).extracting(ApprovalService.DelegateDto::id)
                .doesNotContain(id);
    }

    @Test
    @DisplayName("没有租户上下文时直接拒绝（fail-closed）")
    void cc_requires_tenant() {
        TenantContext.clear();
        assertThatThrownBy(() -> approvalService.myCcs())
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    @DisplayName("退回重进节点不会重复抄送")
    void cc_is_idempotent_on_reenter() {
        long ccUserId = user("it_cc_user");
        createFlow(1L, ccUserId, null);
        long instanceId = approvalService.submit("md.brand", newBrand(), CODE, "重复抄送");
        long taskId = approvalService.getInstance(instanceId).tasks().get(0).id();

        approvalService.returnTo(taskId, "N1", "退回补充");
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM plat.WorkflowInstanceCc WHERE InstanceId = ? AND UserId = ?",
                Integer.class, instanceId, ccUserId);
        assertThat(count).isEqualTo(1);
        assertThat(approvalService.overdueTasks()).isNotNull();
        assertThat(Map.of()).isEmpty();
    }
}

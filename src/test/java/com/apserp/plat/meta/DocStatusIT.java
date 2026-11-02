package com.apserp.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.apserp.common.ApiException;
import com.apserp.common.tenant.TenantContext;
import com.apserp.support.ItDb;
import java.util.List;
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
 * 单据状态机集成测试：状态定义、编辑/删除/提交门禁、审批驱动流转、设计器 CRUD。
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class DocStatusIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    DocStatusService docStatus;

    @Autowired
    MetaSaveService saveService;

    @Autowired
    ActionExecutor executor;

    @Autowired
    ApprovalService approvalService;

    @Autowired
    JdbcTemplate jdbc;

    private static final String CODE = "IT_DOC_STATUS";
    private static final String WF = "IT-WF-STATUS";

    @BeforeEach
    void setUp() {
        TenantContext.set(1L, 1L);
        cleanUp();
        jdbc.update("UPDATE plat.WorkflowDef SET IsDefault = 0 WHERE Code = 'WF-BRAND-ENABLE'");
        approvalService.saveDef(null, new ApprovalService.DefSaveRequest(
                null, WF, "状态机测试流程", "md.brand", null, true, null,
                List.of(new ApprovalService.NodeSaveRequest("N1", "审批", 2, 10, 1, 1, null, true, null, null,
                        List.of(new ApprovalService.ApproverSaveRequest(1, 1L, null, 10))))));
        approvalService.publish(WF);
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
        jdbc.update("DELETE a FROM plat.WorkflowNodeApprover a JOIN plat.WorkflowNode n ON n.Id = a.WorkflowNodeId "
                + "JOIN plat.WorkflowDef d ON d.Id = n.WorkflowDefId WHERE d.Code LIKE 'IT-WF-%'");
        jdbc.update("DELETE n FROM plat.WorkflowNode n JOIN plat.WorkflowDef d ON d.Id = n.WorkflowDefId "
                + "WHERE d.Code LIKE 'IT-WF-%'");
        jdbc.update("DELETE FROM plat.WorkflowDef WHERE Code LIKE 'IT-WF-%'");
        jdbc.update("DELETE FROM md.Brand WHERE Code LIKE ?", CODE + "%");
        // 设计器用例可能留下测试状态/流转，先清掉保证幂等
        jdbc.update("""
                DELETE t FROM plat.DocTransition t JOIN plat.DataObject o ON o.Id = t.DataObjectId
                WHERE o.Code = 'md.brand' AND t.ActionCode = 'ARCHIVE'
                """);
        jdbc.update("""
                DELETE s FROM plat.DocStatus s JOIN plat.DataObject o ON o.Id = s.DataObjectId
                WHERE o.Code = 'md.brand' AND s.StatusValue = 9
                """);
    }

    private long newBrand(String suffix) {
        return saveService.save("md.brand",
                "{\"Code\":\"" + CODE + "_" + suffix + "\",\"Name\":\"状态机测试品牌\",\"Sort\":10}");
    }

    private int statusOf(long id) {
        Integer v = jdbc.queryForObject("SELECT Status FROM md.Brand WHERE Id = ?", Integer.class, id);
        return v == null ? -1 : v;
    }

    @Test
    @DisplayName("种子状态：品牌四个状态 + 五条流转")
    void seed_statuses() {
        List<DocStatusService.StatusDto> statuses = docStatus.statusesOf("md.brand");
        assertThat(statuses).extracting(DocStatusService.StatusDto::statusName)
                .containsExactly("草稿", "审批中", "已审核", "已驳回");
        assertThat(docStatus.transitionsOf("md.brand")).extracting(DocStatusService.TransitionDto::actionCode)
                .contains("SUBMIT", "APPROVE", "REJECT", "WITHDRAW");
        assertThat(docStatus.statusFieldOf("md.brand")).isEqualTo("Status");
    }

    @Test
    @DisplayName("新建单据默认草稿：可编辑/可删除/可提交")
    void draft_is_editable() {
        long id = newBrand("DRAFT");
        var cap = docStatus.capabilityOf("md.brand", id);
        assertThat(cap.configured()).isTrue();
        assertThat(cap.statusName()).isEqualTo("草稿");
        assertThat(cap.canEdit()).isTrue();
        assertThat(cap.canDelete()).isTrue();
        assertThat(cap.canSubmit()).isTrue();
        assertThat(cap.transitions()).extracting(DocStatusService.TransitionDto::actionCode).contains("SUBMIT");
    }

    @Test
    @DisplayName("提交审批：状态→审批中，且此后不能编辑/不能再次提交")
    void submit_moves_to_running_and_blocks_edit() {
        long id = newBrand("SUBMIT");
        approvalService.submit("md.brand", id, CODE, "状态机提交");
        assertThat(statusOf(id)).isEqualTo(1);

        var cap = docStatus.capabilityOf("md.brand", id);
        assertThat(cap.statusName()).isEqualTo("审批中");
        assertThat(cap.canEdit()).isFalse();
        assertThat(cap.canSubmit()).isFalse();

        assertThatThrownBy(() -> saveService.save("md.brand",
                "{\"Id\":" + id + ",\"Code\":\"" + CODE + "_SUBMIT\",\"Name\":\"改不了的品牌\",\"Sort\":10}"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("不能修改");
        assertThatThrownBy(() -> approvalService.submit("md.brand", id, CODE, "重复提交"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("不能提交");
    }

    @Test
    @DisplayName("审批通过：状态→已审核（终态），编辑与删除都被拒")
    void approve_moves_to_final() {
        long id = newBrand("APPROVE");
        long instanceId = approvalService.submit("md.brand", id, CODE, "状态机通过");
        long taskId = approvalService.getInstance(instanceId).tasks().get(0).id();
        approvalService.approve(taskId, true, "同意");

        assertThat(statusOf(id)).isEqualTo(2);
        var cap = docStatus.capabilityOf("md.brand", id);
        assertThat(cap.statusName()).isEqualTo("已审核");
        assertThat(cap.isFinal()).isTrue();
        assertThatThrownBy(() -> docStatus.guardDelete("md.brand", id))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("不能删除");
    }

    @Test
    @DisplayName("审批驳回：状态→已驳回，可以改也可以重新提交")
    void reject_allows_edit_again() {
        long id = newBrand("REJECT");
        long instanceId = approvalService.submit("md.brand", id, CODE, "状态机驳回");
        long taskId = approvalService.getInstance(instanceId).tasks().get(0).id();
        approvalService.approve(taskId, false, "不同意");

        assertThat(statusOf(id)).isEqualTo(3);
        var cap = docStatus.capabilityOf("md.brand", id);
        assertThat(cap.statusName()).isEqualTo("已驳回");
        assertThat(cap.canEdit()).isTrue();
        assertThat(cap.canSubmit()).isTrue();

        saveService.save("md.brand", "{\"Id\":" + id + ",\"Code\":\"" + CODE + "_REJECT\""
                + ",\"Name\":\"驳回后改名\",\"Sort\":20}");
        assertThat(jdbc.queryForObject("SELECT Name FROM md.Brand WHERE Id = ?", String.class, id))
                .isEqualTo("驳回后改名");
    }

    @Test
    @DisplayName("删除门禁：审批中的单据不能删")
    void delete_guard() {
        long id = newBrand("DELETE");
        approvalService.submit("md.brand", id, CODE, "状态机删除");
        assertThatThrownBy(() -> executor.execute(new ActionExecutor.ExecuteRequest(
                "md.brand", id, "BTN-BRAND-DELETE", java.util.Map.of())))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("不能删除");
    }

    @Test
    @DisplayName("未声明的动作码被拒绝（不能凭空造流转）")
    void unknown_action_rejected() {
        long id = newBrand("UNKNOWN");
        assertThatThrownBy(() -> docStatus.transition("md.brand", id, "HACK"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("不允许执行");
    }

    @Test
    @DisplayName("没配状态机的对象不受影响（向后兼容）")
    void object_without_status_is_unconstrained() {
        var cap = docStatus.capabilityOf("md.partner", 1L);
        assertThat(cap.configured()).isFalse();
        assertThat(cap.canEdit()).isTrue();
        assertThat(docStatus.transition("md.partner", 1L, "SUBMIT")).isNull();
    }

    @Test
    @DisplayName("设计器：新增状态/流转、重复校验、删除")
    void designer_crud() {
        long brandId = jdbc.queryForObject(
                "SELECT Id FROM plat.DataObject WHERE TenantId = 1 AND Code = 'md.brand'", Long.class);

        long id = docStatus.saveStatus(new DocStatusService.StatusSaveRequest(
                null, "md.brand", 9, "归档", 90, false, false, false, true, "info", true, "测试"));
        assertThat(id).isPositive();

        assertThatThrownBy(() -> docStatus.saveStatus(new DocStatusService.StatusSaveRequest(
                null, "md.brand", 9, "重复", 95, true, true, true, false, null, true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("已有状态值");

        long tid = docStatus.saveTransition(new DocStatusService.TransitionSaveRequest(
                null, "md.brand", 2, 9, "ARCHIVE", "归档", 60, true, null));
        assertThat(tid).isPositive();

        assertThatThrownBy(() -> docStatus.saveTransition(new DocStatusService.TransitionSaveRequest(
                null, "md.brand", 2, 9, "ARCHIVE", "重复", 70, true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("已有动作");

        assertThatThrownBy(() -> docStatus.saveTransition(new DocStatusService.TransitionSaveRequest(
                null, "md.brand", 2, 9, "1BAD", "非法", 80, true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("动作码");

        docStatus.deleteTransition(tid);
        docStatus.deleteStatus(id);
        assertThat(docStatus.statusesOf("md.brand")).extracting(DocStatusService.StatusDto::statusValue)
                .doesNotContain(9);
        assertThat(docStatus.overview()).extracting(m -> m.get("objectCode")).contains("md.brand");
        assertThat(brandId).isPositive();
    }
}

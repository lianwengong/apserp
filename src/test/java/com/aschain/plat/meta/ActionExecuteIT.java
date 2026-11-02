package com.aschain.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.aschain.common.ApiException;
import com.aschain.common.tenant.TenantContext;
import com.aschain.support.ItDb;
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
 * 动作执行器集成测试：内置删除、导航、命令（导出/复制/操作日志/提交审批）、未注册命令拒绝。
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class ActionExecuteIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    ActionExecutor executor;

    @Autowired
    ActionService actionService;

    @Autowired
    MetaSaveService saveService;

    @Autowired
    JdbcTemplate jdbc;

    private static final String CODE = "IT_ACT_01";

    @BeforeEach
    void setUp() {
        TenantContext.set(1L, 1L);
        cleanUp();
    }

    @AfterEach
    void tearDown() {
        cleanUp();
        TenantContext.clear();
    }

    private void cleanUp() {
        jdbc.update("DELETE FROM md.BrandContact WHERE BrandId IN (SELECT Id FROM md.Brand WHERE Code LIKE ?)",
                CODE + "%");
        jdbc.update("DELETE FROM md.Brand WHERE Code LIKE ?", CODE + "%");
        for (String code : List.of("BTN-IT-NAV", "BTN-IT-CMD-EXPORT", "BTN-IT-CMD-COPY",
                "BTN-IT-CMD-AUDIT", "BTN-IT-BAD-CMD", "BTN-IT-DEL")) {
            try {
                actionService.deleteButton(code);
            } catch (RuntimeException ignored) {
                // 不存在即已清理
            }
        }
    }

    private long createBrand(String code, String name) {
        return saveService.save("md.brand",
                "{\"Code\":\"" + code + "\",\"Name\":\"" + name + "\",\"Sort\":10}");
    }

    private long button(String code, int actionType, String builtin, String command, String target) {
        return actionService.saveButton(null, new ActionService.ButtonSaveRequest(
                null, code, code, code, null, 2, 0, 90, true, null, null, "", null,
                List.of(new ActionService.ActionSaveRequest(actionType, builtin, target, command,
                        null, null, null, false))));
    }

    @Test
    @DisplayName("内置 DELETE：软删记录，返回 refresh")
    void builtin_delete_soft_deletes() {
        long id = createBrand(CODE, "待删品牌");
        button("BTN-IT-DEL", 1, "DELETE", null, null);

        ActionExecutor.ExecuteResult r = executor.execute(
                new ActionExecutor.ExecuteRequest("md.brand", id, "BTN-IT-DEL", Map.of()));
        assertThat(r.kind()).isEqualTo("refresh");
        Integer deleted = jdbc.queryForObject(
                "SELECT COUNT(*) FROM md.Brand WHERE Id = ? AND IsDeleted = 1", Integer.class, id);
        assertThat(deleted).isEqualTo(1);

        // 再删一次：记录已不存在
        assertThatThrownBy(() -> executor.execute(
                new ActionExecutor.ExecuteRequest("md.brand", id, "BTN-IT-DEL", Map.of())))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("已被删除");
    }

    @Test
    @DisplayName("导航动作：返回路由，{id} 占位被替换")
    void navigation_returns_route() {
        long id = createBrand(CODE, "导航品牌");
        button("BTN-IT-NAV", 2, null, null, "/object/md.brand/print/{id}");

        ActionExecutor.ExecuteResult r = executor.execute(
                new ActionExecutor.ExecuteRequest("md.brand", id, "BTN-IT-NAV", Map.of()));
        assertThat(r.kind()).isEqualTo("navigate");
        assertThat(r.route()).isEqualTo("/object/md.brand/print/" + id);
    }

    @Test
    @DisplayName("命令 export.csv：返回下载地址，导出内容是带 BOM 的 CSV")
    void command_export_csv() {
        createBrand(CODE, "导出品牌");
        button("BTN-IT-CMD-EXPORT", 3, null, "export.csv", null);

        ActionExecutor.ExecuteResult r = executor.execute(
                new ActionExecutor.ExecuteRequest("md.brand", null, "BTN-IT-CMD-EXPORT",
                        Map.of("filters", "[{\"f\":\"Code\",\"op\":\"eq\",\"v\":\"" + CODE + "\"}]")));
        assertThat(r.kind()).isEqualTo("download");
        assertThat(r.downloadUrl()).contains("/api/runtime/export").contains("md.brand");

        String csv = executor.exportCsv("md.brand",
                "[{\"f\":\"Code\",\"op\":\"eq\",\"v\":\"" + CODE + "\"}]", null, 100);
        assertThat(csv).startsWith("\uFEFF");
        assertThat(csv).contains("品牌编码").contains("导出品牌");
    }

    @Test
    @DisplayName("命令 copy.record：复制出一条新记录，编码带 -COPY 后缀")
    void command_copy_record() {
        long id = createBrand(CODE, "复制源品牌");
        button("BTN-IT-CMD-COPY", 3, null, "copy.record", null);

        ActionExecutor.ExecuteResult r = executor.execute(
                new ActionExecutor.ExecuteRequest("md.brand", id, "BTN-IT-CMD-COPY", Map.of()));
        assertThat(r.kind()).isEqualTo("refresh");
        long newId = ((Number) r.data().get("newId")).longValue();
        assertThat(newId).isNotEqualTo(id);
        String newCode = jdbc.queryForObject("SELECT Code FROM md.Brand WHERE Id = ?", String.class, newId);
        assertThat(newCode).isEqualTo(CODE + "-COPY");
        jdbc.update("DELETE FROM md.Brand WHERE Id = ?", newId);
    }

    @Test
    @DisplayName("命令 audit.log：返回该记录的操作日志")
    void command_audit_log() {
        long id = createBrand(CODE, "审计品牌");
        button("BTN-IT-CMD-AUDIT", 3, null, "audit.log", null);

        ActionExecutor.ExecuteResult r = executor.execute(
                new ActionExecutor.ExecuteRequest("md.brand", id, "BTN-IT-CMD-AUDIT", Map.of()));
        assertThat(r.kind()).isEqualTo("message");
        Object logs = r.data().get("logs");
        assertThat(logs).isInstanceOf(List.class);
        assertThat((List<?>) logs).isNotEmpty();
    }

    @Test
    @DisplayName("未注册命令被拒绝，并列出可用命令")
    void unknown_command_rejected() {
        long id = createBrand(CODE, "坏命令");
        // 用 ActionType=3（命令）绕过保存期的脚本白名单，验证执行期的命令注册表同样拒绝
        button("BTN-IT-BAD-CMD", 3, null, "rm -rf /", null);

        assertThatThrownBy(() -> executor.execute(
                new ActionExecutor.ExecuteRequest("md.brand", id, "BTN-IT-BAD-CMD", Map.of())))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("未注册")
                .hasMessageContaining("export.csv");
    }

    @Test
    @DisplayName("按钮不存在时给出明确错误")
    void unknown_button_rejected() {
        assertThatThrownBy(() -> executor.execute(
                new ActionExecutor.ExecuteRequest("md.brand", 1L, "BTN-NOT-EXIST", Map.of())))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("没有这个按钮");
    }

    @Test
    @DisplayName("种子按钮 BTN-BRAND-SUBMIT 通过执行器提交审批")
    void seed_submit_button_starts_workflow() {
        long id = createBrand(CODE, "提交审批品牌");
        ActionExecutor.ExecuteResult r = executor.execute(new ActionExecutor.ExecuteRequest(
                "md.brand", id, "BTN-BRAND-SUBMIT", Map.of("businessNo", CODE)));
        assertThat(r.kind()).isEqualTo("refresh");
        assertThat(r.data()).containsKey("instanceId");
        jdbc.update("DELETE t FROM plat.WorkflowTask t JOIN plat.WorkflowInstance i ON i.Id = t.InstanceId "
                + "WHERE i.DataObjectCode = 'md.brand' AND i.BusinessId = ?", id);
        jdbc.update("DELETE l FROM plat.WorkflowActionLog l JOIN plat.WorkflowInstance i ON i.Id = l.InstanceId "
                + "WHERE i.DataObjectCode = 'md.brand' AND i.BusinessId = ?", id);
        jdbc.update("DELETE FROM plat.WorkflowInstance WHERE DataObjectCode = 'md.brand' AND BusinessId = ?", id);
    }

    @Test
    @DisplayName("可用命令列表与注册表一致")
    void available_commands() {
        assertThat(executor.availableCommands())
                .containsExactly("export.csv", "copy.record", "audit.log", "workflow.submit");
    }
}

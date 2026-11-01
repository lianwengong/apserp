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
import com.apserp.support.ItSupport;
import org.springframework.boot.test.context.SpringBootTest;

/**
 * 动作/按钮引擎集成测试：V29 种子给 md.brand 配了 4 个按钮（编辑/删除/提交审批/导出）。
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class ActionEngineIT extends ItSupport {

    @Autowired
    ActionService actionService;

    @BeforeEach
    void setUp() {
        TenantContext.set(1L, 1L);
        purge("BTN-IT-CRUD");
        purge("BTN-PRINT");
        purge("BTN-BAD");
        purge("BTN-SCRIPT");
    }

    /** 幂等：先清掉上次失败可能残留的按钮。 */
    private void purge(String code) {
        try {
            actionService.deleteButton(code);
        } catch (RuntimeException ignored) {
            // 不存在即视为已清理
        }
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    @Test
    @DisplayName("种子按钮按 Sort 下发，且动作随按钮返回")
    void seed_buttons() {
        List<ActionService.ButtonDto> buttons = actionService.listButtons("md.brand");
        assertThat(buttons).extracting(ActionService.ButtonDto::code)
                .contains("BTN-BRAND-EDIT", "BTN-BRAND-DELETE", "BTN-BRAND-SUBMIT", "BTN-BRAND-EXPORT");
        assertThat(buttons.get(0).sort()).isLessThanOrEqualTo(buttons.get(1).sort());
        ActionService.ButtonDto submit = buttons.stream()
                .filter(b -> b.code().equals("BTN-BRAND-SUBMIT")).findFirst().orElseThrow();
        assertThat(submit.actions()).hasSize(1);
        assertThat(submit.actions().get(0).builtinCode()).isEqualTo("SUBMIT");
        assertThat(submit.actions().get(0).needWorkflow()).isTrue();
        assertThat(submit.actions().get(0).confirmText()).contains("确认提交");
    }

    @Test
    @DisplayName("运行时求值：IsEnabled=true 时编辑可用；false 时编辑置灰、删除隐藏")
    void resolve_by_row_data() {
        List<ActionService.ResolvedButton> enabled = actionService.resolve("md.brand", Map.of("IsEnabled", true));
        ActionService.ResolvedButton edit = enabled.stream()
                .filter(b -> b.code().equals("BTN-BRAND-EDIT")).findFirst().orElseThrow();
        assertThat(edit.enabled()).isTrue();
        assertThat(edit.visible()).isTrue();

        List<ActionService.ResolvedButton> disabled = actionService.resolve("md.brand", Map.of("IsEnabled", false));
        ActionService.ResolvedButton edit2 = disabled.stream()
                .filter(b -> b.code().equals("BTN-BRAND-EDIT")).findFirst().orElseThrow();
        assertThat(edit2.enabled()).isFalse();
        assertThat(edit2.disableReason()).contains("条件");
        // 删除按钮的可见表达式是 IsEnabled == true，禁用行不应下发
        assertThat(disabled).extracting(ActionService.ResolvedButton::code)
                .doesNotContain("BTN-BRAND-DELETE");
    }

    @Test
    @DisplayName("坏表达式：保存时即被拒绝，坏配置进不了库")
    void broken_expression_is_safe() {
        assertThatThrownBy(() -> actionService.saveButton(null, new ActionService.ButtonSaveRequest(
                null, "BTN-BAD-EXPR", "坏表达式", "坏", "Delete", 1, 0, 90, true,
                "ctx.X &&", null, "", null, List.of())))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("可见表达式有误");
        assertThat(actionService.listButtons("md.brand"))
                .extracting(ActionService.ButtonDto::code).doesNotContain("BTN-BAD-EXPR");
    }

    @Test
    @DisplayName("保存按钮时语法错误当场拒绝")
    void invalid_expression_rejected() {
        assertThatThrownBy(() -> actionService.saveButton(null, new ActionService.ButtonSaveRequest(
                null, "BTN-BAD", "坏", "坏", "Delete", 1, 0, 90, true,
                null, "ctx.X ==", "", null, List.of())))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("可用表达式有误");
    }

    @Test
    @DisplayName("脚本动作只允许白名单命令")
    void script_whitelist() {
        assertThatThrownBy(() -> actionService.saveButton(null, new ActionService.ButtonSaveRequest(
                null, "BTN-SCRIPT", "脚本", "脚本", "", 1, 0, 95, true,
                null, null, "", null,
                List.of(new ActionService.ActionSaveRequest(4, null, null, "rm -rf /", null, null, null, false)))))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("白名单");

        long id = actionService.saveButton(null, new ActionService.ButtonSaveRequest(
                null, "BTN-PRINT", "打印", "打印", "Printer", 2, 0, 96, true,
                null, null, "", null,
                List.of(new ActionService.ActionSaveRequest(4, null, null, "PRINT", null, null, null, false))));
        assertThat(id).isPositive();
        actionService.deleteButton("BTN-PRINT");
    }

    @Test
    @DisplayName("按钮增删改：更新会重建动作列表")
    void crud_rebuilds_actions() {
        long id = actionService.saveButton(null, new ActionService.ButtonSaveRequest(
                null, "BTN-IT-CRUD", "测试", "测试", "Edit", 2, 0, 97, true,
                null, null, "", "备注", List.of(
                        new ActionService.ActionSaveRequest(1, "OPEN_FORM", null, null, null, "打开", null, false))));
        assertThat(id).isPositive();

        actionService.saveButton(id, new ActionService.ButtonSaveRequest(
                id, "BTN-IT-CRUD", "测试2", "测试2", "Edit", 2, 0, 97, true,
                null, null, "primary", "改过", List.of(
                        new ActionService.ActionSaveRequest(1, "OPEN_FORM", null, null, null, "打开2", null, false),
                        new ActionService.ActionSaveRequest(1, "DELETE", null, null, null, "删除", "已删", false))));
        ActionService.ButtonDto dto = actionService.listButtons("md.brand").stream()
                .filter(b -> b.code().equals("BTN-IT-CRUD")).findFirst().orElseThrow();
        assertThat(dto.name()).isEqualTo("测试2");
        assertThat(dto.actions()).hasSize(2);

        actionService.deleteButton("BTN-IT-CRUD");
        assertThat(actionService.listButtons("md.brand"))
                .extracting(ActionService.ButtonDto::code).doesNotContain("BTN-IT-CRUD");
    }
}

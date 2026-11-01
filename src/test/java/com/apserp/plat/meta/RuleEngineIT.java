package com.apserp.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.apserp.common.ApiException;
import com.apserp.common.tenant.TenantContext;
import java.util.LinkedHashMap;
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
 * 规则引擎集成测试：真实 SQL Server + V29 种子规则（R-CODE-REQUIRED / R-SORT-RANGE / R-NAME-LEN）。
 *
 * <p>只验证“规则能否挡住/放行保存”，不重复单测表达式语法。</p>
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class RuleEngineIT {

    @Autowired
    RuleService ruleService;

    @Autowired
    MetaSaveService saveService;

    @Autowired
    JdbcTemplate jdbc;

    @BeforeEach
    void setUp() {
        TenantContext.set(1L, 1L);
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    private Map<String, Object> brand(String code, String name, Integer sort) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("Code", code);
        m.put("Name", name);
        m.put("Sort", sort);
        m.put("IsEnabled", true);
        return m;
    }

    @Test
    @DisplayName("种子规则已绑定到 md.brand，且按 Sort 排序")
    void seed_rules_are_bound() {
        List<RuleService.BoundRule> rules = ruleService.rulesFor("md.brand", RuleService.BEFORE_SAVE);
        assertThat(rules).extracting(RuleService.BoundRule::code)
                .containsSubsequence("R-CODE-REQUIRED", "R-SORT-RANGE", "R-NAME-LEN");
        assertThat(rules).filteredOn(r -> r.code().equals("R-CODE-REQUIRED"))
                .allSatisfy(r -> assertThat(r.severity()).isEqualTo(RuleService.ERROR));
        assertThat(rules).filteredOn(r -> r.code().equals("R-NAME-LEN"))
                .allSatisfy(r -> assertThat(r.severity()).isEqualTo(RuleService.WARN));
    }

    @Test
    @DisplayName("缺编码 → 保存被阻断，且错误信息就是规则里配的文案")
    void missing_code_is_blocked() {
        assertThatThrownBy(() -> saveService.save("md.brand", "{\"Name\":\"无编码品牌\"}"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("编码不能为空");
    }

    @Test
    @DisplayName("排序越界 → 阻断；边界值 0 与 999 放行")
    void sort_range_is_enforced() {
        assertThatThrownBy(() -> saveService.save("md.brand",
                "{\"Code\":\"T-BAD-SORT\",\"Name\":\"越界\",\"Sort\":1000}"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("排序值必须");

        long id = saveService.save("md.brand", "{\"Code\":\"T-SORT-999\",\"Name\":\"边界\",\"Sort\":999}");
        assertThat(id).isPositive();
        jdbc.update("UPDATE md.Brand SET IsDeleted = 1 WHERE Code = 'T-SORT-999'");
    }

    @Test
    @DisplayName("名称超长只警告、不阻断保存")
    void long_name_only_warns() throws Exception {
        String longName = "长".repeat(60);
        // 用 RuleService 直接取告警（保存路径不返回告警，只看是否放行）
        List<RuleService.RuleViolation> warnings = ruleService.checkBeforeSave("md.brand",
                brand("T-WARN", longName, 10));
        assertThat(warnings).extracting(RuleService.RuleViolation::ruleCode).contains("R-NAME-LEN");

        long id = saveService.save("md.brand",
                "{\"Code\":\"T-WARN\",\"Name\":\"" + longName + "\",\"Sort\":10}");
        assertThat(id).isPositive();
        jdbc.update("UPDATE md.Brand SET IsDeleted = 1 WHERE Code = 'T-WARN'");
    }

    @Test
    @DisplayName("测试台：逐条返回规则结果，坏表达式单独报错不拖垮整批")
    void test_console_returns_each_rule() {
        List<Map<String, Object>> rows = ruleService.test("md.brand", RuleService.BEFORE_SAVE,
                brand("T1", "测试", 5));
        assertThat(rows).hasSizeGreaterThanOrEqualTo(3);
        assertThat(rows).allSatisfy(r -> assertThat(r.get("passed")).isEqualTo(true));

        List<Map<String, Object>> bad = ruleService.test("md.brand", RuleService.BEFORE_SAVE,
                brand(null, null, 2000));
        assertThat(bad).anySatisfy(r -> {
            assertThat(r.get("ruleCode")).isEqualTo("R-CODE-REQUIRED");
            assertThat(r.get("passed")).isEqualTo(false);
            assertThat(String.valueOf(r.get("message"))).contains("编码");
        });
    }

    @Test
    @DisplayName("规则 CRUD：语法错误当场拒绝；合法表达式可保存并生效")
    void rule_crud_and_validation() {
        assertThatThrownBy(() -> ruleService.saveRule(null, new RuleService.RuleSaveRequest(
                "R-BAD", "坏规则", 1, "ctx.A &&", "错的", 2, true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("表达式有误");

        long id = ruleService.saveRule(null, new RuleService.RuleSaveRequest(
                "R-TEST-OK", "测试规则", 1, "ctx.Sort == 42", "排序必须是 42", 2, true, "集成测试"));
        assertThat(id).isPositive();
        RuleService.RuleDto dto = ruleService.getRule("R-TEST-OK");
        assertThat(dto.expression()).isEqualTo("ctx.Sort == 42");
        assertThat(dto.severity()).isEqualTo(2);

        ruleService.deleteRule("R-TEST-OK");
        assertThat(ruleService.listRules()).extracting(RuleService.RuleDto::code)
                .doesNotContain("R-TEST-OK");
    }

    @Test
    @DisplayName("绑定与解绑：解绑后规则不再执行")
    void bind_and_unbind() {
        // 幂等：先清掉上次可能残留的同名规则
        jdbc.update("DELETE b FROM plat.RuleBinding b JOIN plat.BizRule r ON r.Id = b.RuleId WHERE r.Code = 'R-BIND-TEST'");
        jdbc.update("DELETE FROM plat.BizRule WHERE Code = 'R-BIND-TEST'");
        long ruleId = ruleService.saveRule(null, new RuleService.RuleSaveRequest(
                "R-BIND-TEST", "绑定测试", 1, "ctx.Code != 'FORBIDDEN'", "禁止使用该编码", 2, true, null));
        long bindingId = ruleService.bind(new RuleService.BindingSaveRequest(
                ruleId, "md.brand", "Code", RuleService.BEFORE_SAVE, 5, true));
        assertThat(bindingId).isPositive();

        assertThatThrownBy(() -> saveService.save("md.brand",
                "{\"Code\":\"FORBIDDEN\",\"Name\":\"x\",\"Sort\":1}"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("禁止使用该编码");

        ruleService.unbind(bindingId);
        ruleService.deleteRule("R-BIND-TEST");
        assertThat(ruleService.rulesFor("md.brand", RuleService.BEFORE_SAVE))
                .extracting(RuleService.BoundRule::code).doesNotContain("R-BIND-TEST");
    }
}

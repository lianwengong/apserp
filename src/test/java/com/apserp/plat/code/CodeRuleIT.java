package com.apserp.plat.code;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.apserp.common.ApiException;
import com.apserp.common.tenant.TenantContext;
import com.apserp.support.ItDb;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
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
 * 编号引擎集成测试：格式化、按期间重置、并发不重号、规则校验与示例维护。
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class CodeRuleIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    CodeRuleService service;

    @Autowired
    JdbcTemplate jdbc;

    private static final String DAILY = "IT_CODE_DAILY";
    private static final String YEARLY = "IT_CODE_YEARLY";
    private static final String NODATE = "IT_CODE_NODATE";

    @BeforeEach
    void setUp() {
        TenantContext.set(1L, 1L, true);
        cleanUp();
        saveRule(DAILY, "ITD", "yyyyMMdd", 3, 3);
        saveRule(YEARLY, "ITY", "yyyyMMdd", 4, 1);
        saveRule(NODATE, "ITN", "", 5, 0);
    }

    @AfterEach
    void tearDown() {
        cleanUp();
        TenantContext.clear();
    }

    private void cleanUp() {
        jdbc.update("DELETE FROM plat.CodeSerial WHERE RuleCode LIKE 'IT_CODE%'");
        jdbc.update("DELETE FROM plat.[CodeRule] WHERE Code LIKE 'IT_CODE%'");
    }

    private void saveRule(String code, String prefix, String datePattern, int digits, int cycle) {
        service.save(new CodeRuleService.RuleSaveRequest(null, code, "测试规则 " + code, null,
                prefix, datePattern, "-", digits, cycle, true, null));
    }

    @Test
    @DisplayName("取号：前缀 + 日期 + 分隔符 + 补零流水，连续递增")
    void next_formats_and_increments() {
        String first = service.next(DAILY);
        String second = service.next(DAILY);
        String today = LocalDate.now().toString().replace("-", "");
        assertThat(first).isEqualTo("ITD" + today + "-001");
        assertThat(second).isEqualTo("ITD" + today + "-002");
    }

    @Test
    @DisplayName("预览不消耗流水：预览多次结果相同，取号后才推进")
    void preview_does_not_consume() {
        String p1 = service.preview(DAILY);
        String p2 = service.preview(DAILY);
        assertThat(p1).isEqualTo(p2);
        assertThat(service.next(DAILY)).isEqualTo(p1);
        assertThat(service.preview(DAILY)).isNotEqualTo(p1);
    }

    @Test
    @DisplayName("期间隔离：昨天/明年的流水不影响今天/今年")
    void period_isolation() {
        long tenantId = 1L;
        LocalDate today = LocalDate.now();
        // 手工塞一条「上一天」的流水，今天仍从 1 开始
        jdbc.update("""
                INSERT plat.CodeSerial (TenantId, RuleCode, Period, CurrentValue)
                VALUES (?, ?, ?, 99)
                """, tenantId, DAILY, today.minusDays(1).toString().replace("-", ""));
        assertThat(service.next(DAILY)).endsWith("-001");

        // 按年重置的规则：去年 99，今年从 1 开始
        jdbc.update("""
                INSERT plat.CodeSerial (TenantId, RuleCode, Period, CurrentValue)
                VALUES (?, ?, ?, 99)
                """, tenantId, YEARLY, String.valueOf(today.getYear() - 1));
        assertThat(service.next(YEARLY)).endsWith("-0001");
    }

    @Test
    @DisplayName("不重置的规则：跨年也继续递增（期间键为空串）")
    void no_reset_keeps_incrementing() {
        assertThat(service.next(NODATE)).isEqualTo("ITN-00001");
        assertThat(service.next(NODATE)).isEqualTo("ITN-00002");
        String period = jdbc.queryForObject(
                "SELECT Period FROM plat.CodeSerial WHERE RuleCode = ?", String.class, NODATE);
        assertThat(period).isEmpty();
    }

    @Test
    @DisplayName("并发取号：8 线程 × 5 次，40 个号互不重复")
    void concurrent_unique() throws Exception {
        int threads = 8;
        int perThread = 5;
        ExecutorService pool = Executors.newFixedThreadPool(threads);
        try {
            List<Callable<List<String>>> tasks = new ArrayList<>();
            for (int t = 0; t < threads; t++) {
                tasks.add(() -> {
                    TenantContext.set(1L, 1L, true);
                    List<String> got = new ArrayList<>();
                    for (int i = 0; i < perThread; i++) {
                        got.add(service.next(DAILY));
                    }
                    return got;
                });
            }
            List<String> all = new ArrayList<>();
            for (Future<List<String>> future : pool.invokeAll(tasks)) {
                all.addAll(future.get());
            }
            Set<String> unique = new HashSet<>(all);
            assertThat(all).hasSize(threads * perThread);
            assertThat(unique).hasSize(all.size());
            assertThat(service.next(DAILY)).endsWith("-041");
        } finally {
            pool.shutdownNow();
            TenantContext.set(1L, 1L, true);
        }
    }

    @Test
    @DisplayName("规则校验：未知/停用/非法格式都被拒绝")
    void rule_validation() {
        assertThatThrownBy(() -> service.next("不存在"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("不存在");

        service.save(new CodeRuleService.RuleSaveRequest(
                service.get(DAILY).id(), DAILY, "停用规则", null, "ITD", "yyyyMMdd", "-", 3, 3,
                false, null));
        assertThatThrownBy(() -> service.next(DAILY))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("已停用");

        assertThatThrownBy(() -> service.save(new CodeRuleService.RuleSaveRequest(
                null, "IT_CODE_BAD", "坏格式", null, "XX", "yyyy-MM-dd", "-", 4, 0, true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("日期格式");

        assertThatThrownBy(() -> service.save(new CodeRuleService.RuleSaveRequest(
                null, "IT_CODE_BAD2", "位数越界", null, "XX", "yyyyMMdd", "-", 20, 0, true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("1..12");
    }

    @Test
    @DisplayName("保存规则会刷新示例号，管理窗口能直接看到样例")
    void save_refreshes_sample() {
        String sample = service.get(DAILY).sample();
        assertThat(sample).startsWith("ITD");
        assertThat(sample).endsWith("-001");

        service.save(new CodeRuleService.RuleSaveRequest(
                service.get(DAILY).id(), DAILY, "改前缀", null, "NEW", "yyyyMM", "/", 5, 2, true, null));
        assertThat(service.get(DAILY).sample()).startsWith("NEW").contains("/").endsWith("00001");
    }

    @Test
    @DisplayName("统计：返回当前期间、当前值与各期间流水")
    void statistics() {
        service.next(DAILY);
        service.next(DAILY);
        var stat = service.statistics(DAILY);
        assertThat(stat).containsKeys("code", "period", "currentValue", "next", "periods");
        assertThat(((Number) stat.get("currentValue")).longValue()).isEqualTo(2L);
        assertThat(stat.get("next").toString()).endsWith("-003");
        assertThat((List<?>) stat.get("periods")).isNotEmpty();
    }
}

package com.apserp.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.apserp.common.ApiException;
import com.apserp.common.tenant.TenantContext;
import com.apserp.support.ItDb;
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
 * 打印模板集成测试：模板 CRUD、占位符替换、子表区块、转义、PRINT 动作。
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class PrintTemplateIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    PrintService printService;

    @Autowired
    MetaSaveService saveService;

    @Autowired
    ActionExecutor executor;

    @Autowired
    JdbcTemplate jdbc;

    private static final String CODE = "IT_PRINT_BRAND";

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
        jdbc.update("DELETE FROM md.BrandContact WHERE BrandId IN (SELECT Id FROM md.Brand WHERE Code = ?)", CODE);
        jdbc.update("DELETE FROM md.Brand WHERE Code = ?", CODE);
        jdbc.update("DELETE FROM plat.PrintTemplate WHERE Code LIKE 'pt.it%'");
        try {
            actionServiceCleanup();
        } catch (RuntimeException ignored) {
            // 清理失败不影响用例结论
        }
    }

    @Autowired
    ActionService actionService;

    private void actionServiceCleanup() {
        try {
            actionService.deleteButton("BTN-IT-PRINT");
        } catch (RuntimeException ignored) {
            // 不存在即可
        }
    }

    private long newBrandWithContacts() {
        return saveService.save("md.brand", """
                {"Code":"%s","Name":"打印测试品牌","Sort":10,"Contacts":[
                  {"ContactName":"张三","Mobile":"13800000001"},
                  {"ContactName":"李四","Mobile":"13800000002"}
                ]}
                """.formatted(CODE));
    }

    @Test
    @DisplayName("种子模板：品牌档案可用，渲染出单据与联系人明细")
    void seed_template_renders() {
        long id = newBrandWithContacts();
        List<PrintService.TemplateDto> templates = printService.list("md.brand");
        assertThat(templates).extracting(PrintService.TemplateDto::code).contains("pt.brand");

        String html = printService.render("md.brand", id, "pt.brand");
        assertThat(html).contains("打印测试品牌");
        assertThat(html).contains(CODE);
        assertThat(html).contains("张三").contains("李四");
        assertThat(html).contains("13800000001");
        assertThat(html).doesNotContain("{{");
    }

    @Test
    @DisplayName("子表区块：没有子行时区块内容为空，占位符不残留")
    void section_with_no_rows() {
        long id = newBrandWithContacts();
        jdbc.update("DELETE FROM md.BrandContact WHERE BrandId = ?", id);
        String html = printService.render("md.brand", id, "pt.brand");
        assertThat(html).contains("联系人");
        assertThat(html).doesNotContain("{{#Contacts}}").doesNotContain("{{/Contacts}}");
    }

    @Test
    @DisplayName("占位符转义：单据里的 <script> 不会原样进打印页")
    void placeholder_is_escaped() {
        long id = saveService.save("md.brand", """
                {"Code":"%s","Name":"<script>alert(1)</script>","Sort":10}
                """.formatted(CODE));
        String html = printService.render("md.brand", id, null);
        assertThat(html).doesNotContain("<script>alert(1)</script>");
        assertThat(html).contains("&lt;script&gt;");
    }

    @Test
    @DisplayName("打印时间占位符有值")
    void printed_at() {
        long id = newBrandWithContacts();
        String html = printService.render("md.brand", id, "pt.brand");
        assertThat(html).doesNotContain("{{PrintedAt}}");
        assertThat(html).matches("(?s).*\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}.*");
    }

    @Test
    @DisplayName("模板 CRUD：新增/改/删 + 编码重复与内容为空被拒")
    void template_crud() {
        long id = printService.save(new PrintService.TemplateSaveRequest(
                null, "md.brand", "pt.it1", "测试模板", "<p>{{Name}}</p>", "A4", false, true, "测试"));
        assertThat(id).isPositive();

        assertThatThrownBy(() -> printService.save(new PrintService.TemplateSaveRequest(
                null, "md.brand", "pt.it1", "重复", "<p>x</p>", "A4", false, true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("已存在");

        assertThatThrownBy(() -> printService.save(new PrintService.TemplateSaveRequest(
                null, "md.brand", "pt.it2", "空内容", "  ", "A4", false, true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("模板内容不能为空");

        assertThatThrownBy(() -> printService.save(new PrintService.TemplateSaveRequest(
                null, "md.brand", "1bad", "坏编码", "<p>x</p>", "A4", false, true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("模板编码");

        printService.save(new PrintService.TemplateSaveRequest(
                id, "md.brand", "pt.it1", "改过的模板", "<p>改过 {{Name}}</p>", "A5", true, true, "改"));
        PrintService.TemplateDto dto = printService.list("md.brand").stream()
                .filter(t -> t.code().equals("pt.it1")).findFirst().orElseThrow();
        assertThat(dto.name()).isEqualTo("改过的模板");
        assertThat(dto.paperSize()).isEqualTo("A5");
        assertThat(dto.isDefault()).isTrue();

        printService.delete(id);
        assertThat(printService.list("md.brand")).extracting(PrintService.TemplateDto::code)
                .doesNotContain("pt.it1");
    }

    @Test
    @DisplayName("没有模板时给出明确错误")
    void no_template() {
        jdbc.update("UPDATE plat.PrintTemplate SET IsEnabled = 0 WHERE Code = 'pt.brand'");
        try {
            long id = newBrandWithContacts();
            assertThatThrownBy(() -> printService.render("md.brand", id, null))
                    .isInstanceOf(ApiException.class)
                    .hasMessageContaining("打印模板");
        } finally {
            jdbc.update("UPDATE plat.PrintTemplate SET IsEnabled = 1 WHERE Code = 'pt.brand'");
        }
    }

    @Test
    @DisplayName("PRINT 动作返回 print 类型与渲染地址")
    void print_action() {
        long id = newBrandWithContacts();
        actionService.saveButton(null, new ActionService.ButtonSaveRequest(
                null, "BTN-IT-PRINT", "打印", "打印", "Printer", 2, 0, 95, true, null, null, "", null,
                List.of(new ActionService.ActionSaveRequest(1, "PRINT", null, null, null, null, null, false))));

        ActionExecutor.ExecuteResult r = executor.execute(new ActionExecutor.ExecuteRequest(
                "md.brand", id, "BTN-IT-PRINT", Map.of()));
        assertThat(r.kind()).isEqualTo("print");
        assertThat(r.downloadUrl()).contains("/api/runtime/print").contains("id=" + id);
    }

    @Test
    @DisplayName("占位符提示：包含字段与子表别名")
    void placeholders() {
        List<String> hints = printService.placeholders("md.brand");
        assertThat(hints).contains("PrintedAt", "Code", "Name", "#Contacts");
    }
}

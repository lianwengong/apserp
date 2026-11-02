package com.aschain.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.aschain.common.ApiException;
import com.aschain.common.tenant.TenantContext;
import com.aschain.support.ItDb;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

/**
 * 元数据定义 + 保存引擎的集成测试（连本机开发库）。
 *
 * <pre>
 * set IT_DB_PASSWORD=***
 * mvn test -Dit.db=true
 * </pre>
 */
@SpringBootTest
@EnabledIfSystemProperty(named = "it.db", matches = "true")
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
class MetaDefinitionIT {

    private static final String TEST_CODE = "IT_TMP01";

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    private MetaDefinitionService definitionService;

    @Autowired
    private MetaQueryService queryService;

    @Autowired
    private MetaSaveService saveService;

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

    @Test
    void objects_should_contain_brand() {
        var objects = definitionService.listObjects();
        assertThat(objects).isNotEmpty();
        assertThat(objects).anyMatch(o -> o.code().equals("md.brand"));
    }

    @Test
    void fields_of_brand_should_match_dictionary() {
        var fields = definitionService.listFields("md.brand");
        // 8 个业务字段 + V31 追加的 IsDeleted（隐藏字段，用于列表引擎过滤软删行）`n        assertThat(fields).hasSizeGreaterThanOrEqualTo(8);
        assertThat(fields.get(0).fieldName()).isEqualTo("Id");
        assertThat(fields.get(0).primaryKey()).isTrue();
        assertThat(fields).anyMatch(f -> f.fieldName().equals("Name") && f.required());
        assertThat(fields).anyMatch(f -> f.fieldName().equals("ManufacturerId") && f.lookupType() == 2);
    }

    @Test
    void unknown_object_should_report_clear_error() {
        assertThatThrownBy(() -> definitionService.getObject("md.not_exist"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("未配置此数据对象");
    }

    @Test
    void illegal_object_code_should_be_rejected_before_hitting_db() {
        assertThatThrownBy(() -> queryService.query("md.brand; DROP TABLE x", null, null, 1, 10))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("非法的数据对象编码");
    }

    @Test
    void save_engine_should_insert_and_be_queryable() {
        long id = saveService.save("md.brand",
                "{\"Code\":\"" + TEST_CODE + "\",\"Name\":\"集成测试品牌\",\"Sort\":999}");
        assertThat(id).isPositive();

        var page = queryService.query("md.brand", null, "Sort", 1, 100);
        assertThat(page.rows()).anyMatch(r -> TEST_CODE.equals(r.get("Code")));
    }

    // ------------------------------------------------------------ 清理（测试自带，不留脏数据）

    private void cleanUp() {
        try (Connection con = DriverManager.getConnection(ItDb.url(), ItDb.user(), ItDb.password())) {
            try (var st = con.createStatement()) {
                st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
            }
            try (PreparedStatement ps = con.prepareStatement("DELETE FROM md.Brand WHERE Code = ?")) {
                ps.setString(1, TEST_CODE);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "DELETE FROM plat.AuditLog WHERE TenantId = 1 AND ObjectType = ?")) {
                ps.setString(1, "Brand");
                ps.executeUpdate();
            }
        } catch (Exception ex) {
            throw new IllegalStateException("清理测试数据失败", ex);
        }
    }
}

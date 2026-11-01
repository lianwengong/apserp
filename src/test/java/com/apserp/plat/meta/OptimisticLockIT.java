package com.apserp.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.tenant.TenantContext;
import com.apserp.support.ItDb;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.Statement;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

/**
 * 乐观并发：同一行带旧版本号提交时必须被拒绝。
 *
 * <p>场景：用户 A 打开编辑页，用户 B 先保存，A 再保存 —— A 的数据不能覆盖 B。</p>
 */
@SpringBootTest
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class OptimisticLockIT {

    private static final String CODE = "IT_LOCK01";

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    private MetaSaveService saveService;

    @Autowired
    private MetaQueryService queryService;

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
    void stale_row_version_must_be_rejected() {
        long id = saveService.save("md.brand",
                "{\"Code\":\"" + CODE + "\",\"Name\":\"并发测试\",\"Sort\":1}");

        long v1 = currentVersion(id);
        // 第一次改：带 v1，成功
        saveService.save("md.brand",
                "{\"Id\":" + id + ",\"Name\":\"并发测试-A\",\"RowVersion\":" + v1 + "}");

        // 第二次改：仍用旧版本号 v1（模拟前端没刷新），必须被拒绝
        assertThatThrownBy(() -> saveService.save("md.brand",
                "{\"Id\":" + id + ",\"Name\":\"并发测试-B\",\"RowVersion\":" + v1 + "}"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("已被他人修改")
                .extracting(e -> ((ApiException) e).getCode())
                .isEqualTo(ErrorCode.CONCURRENT_MODIFY);
    }

    @Test
    void fresh_row_version_should_succeed() {
        long id = saveService.save("md.brand",
                "{\"Code\":\"" + CODE + "\",\"Name\":\"并发测试2\",\"Sort\":2}");
        long v = currentVersion(id);
        saveService.save("md.brand",
                "{\"Id\":" + id + ",\"Name\":\"并发测试2-改\",\"RowVersion\":" + v + "}");
        var page = queryService.query("md.brand", null, "Id", 1, 100);
        assertThat(page.rows()).anyMatch(r -> "并发测试2-改".equals(r.get("Name"))
                || "并发测试2-改".equals(String.valueOf(r.get("Name"))));
    }

    private long currentVersion(long id) {
        try (Connection con = DriverManager.getConnection(ItDb.url(), ItDb.user(), ItDb.password());
             Statement st = con.createStatement()) {
            st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
            try (var rs = st.executeQuery(
                    "SELECT CONVERT(bigint, RowVersion) FROM md.Brand WHERE Id = " + id)) {
                rs.next();
                return rs.getLong(1);
            }
        } catch (Exception ex) {
            throw new IllegalStateException("读取行版本失败", ex);
        }
    }

    private void cleanUp() {
        try (Connection con = DriverManager.getConnection(ItDb.url(), ItDb.user(), ItDb.password())) {
            try (Statement st = con.createStatement()) {
                st.execute("EXEC sys.sp_set_session_context N'BypassRls', 1");
            }
            try (PreparedStatement ps = con.prepareStatement("DELETE FROM md.Brand WHERE Code = ?")) {
                ps.setString(1, CODE);
                ps.executeUpdate();
            }
        } catch (Exception ex) {
            throw new IllegalStateException("清理失败", ex);
        }
    }
}

package com.apserp.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.apserp.common.ApiException;
import com.apserp.common.tenant.TenantContext;
import com.apserp.support.ItDb;
import java.nio.charset.StandardCharsets;
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
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

/**
 * 附件引擎集成测试：上传/列表/下载/删除、扩展名白名单、大小上限、跨单据隔离。
 *
 * <p>用 {@code MockMultipartFile} 直接打 service，不经过 HTTP，避免测试依赖 multipart 解析；
 * HTTP 层只做参数与权限转发，另有手工验证（见 README）。</p>
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class AttachmentIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
        registry.add("app.attachment.dir", () -> System.getProperty("java.io.tmpdir") + "/apserp-it-attach");
    }

    @Autowired
    AttachmentService attachments;

    @Autowired
    JdbcTemplate jdbc;

    private static final String OBJECT = "md.brand";
    private static final long BIZ = 999_001L;

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
        jdbc.update("DELETE FROM plat.Attachment WHERE BusinessType = ? AND BusinessId = ?", OBJECT, BIZ);
    }

    private static MockMultipartFile fileOf(String name, String content) {
        return new MockMultipartFile("file", name, "application/octet-stream",
                content.getBytes(StandardCharsets.UTF_8));
    }

    @Test
    @DisplayName("上传-列表-下载-删除 全链路")
    void upload_list_download_delete() {
        var dto = attachments.upload(OBJECT, BIZ, fileOf("报价单.pdf", "hello pdf"));
        assertThat(dto.id()).isPositive();
        assertThat(dto.fileName()).isEqualTo("报价单.pdf");
        assertThat(dto.ext()).isEqualTo("pdf");
        assertThat(dto.fileSize()).isEqualTo("hello pdf".getBytes(StandardCharsets.UTF_8).length);
        assertThat(dto.url()).contains("/attachments/" + dto.id() + "/download");

        List<AttachmentService.AttachmentDto> list = attachments.list(OBJECT, BIZ);
        assertThat(list).extracting(AttachmentService.AttachmentDto::id).contains(dto.id());

        var download = attachments.download(dto.id());
        assertThat(download.fileName()).isEqualTo("报价单.pdf");
        assertThat(download.resource().exists()).isTrue();

        attachments.delete(dto.id());
        assertThat(attachments.list(OBJECT, BIZ)).isEmpty();
        assertThatThrownBy(() -> attachments.download(dto.id()))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("附件不存在");
    }

    @Test
    @DisplayName("扩展名白名单：可执行文件被拒绝，允许的类型通过")
    void extension_whitelist() {
        assertThatThrownBy(() -> attachments.upload(OBJECT, BIZ, fileOf("evil.exe", "MZ")))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("不支持的文件类型");
        assertThatThrownBy(() -> attachments.upload(OBJECT, BIZ, fileOf("noext", "x")))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("不支持的文件类型");

        assertThat(attachments.upload(OBJECT, BIZ, fileOf("图.PNG", "img")).ext()).isEqualTo("png");
        assertThat(attachments.upload(OBJECT, BIZ, fileOf("表.xlsx", "xls")).ext()).isEqualTo("xlsx");
    }

    @Test
    @DisplayName("空文件与超大文件被拒绝")
    void size_guard() {
        assertThatThrownBy(() -> attachments.upload(OBJECT, BIZ,
                new MockMultipartFile("file", "empty.pdf", "application/pdf", new byte[0])))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("文件为空");

        byte[] big = new byte[11 * 1024 * 1024];
        assertThatThrownBy(() -> attachments.upload(OBJECT, BIZ,
                new MockMultipartFile("file", "big.pdf", "application/pdf", big)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("MB 限制");
    }

    @Test
    @DisplayName("文件名只保留名字部分（路径不落库，防穿越）")
    void file_name_is_sanitized() {
        var dto = attachments.upload(OBJECT, BIZ, fileOf("..\\..\\etc\\passwd.txt", "content"));
        assertThat(dto.fileName()).isEqualTo("passwd.txt");
        String stored = jdbc.queryForObject(
                "SELECT Path FROM plat.Attachment WHERE Id = ?", String.class, dto.id());
        assertThat(stored).doesNotContain("..").doesNotContain("passwd");
        assertThat(stored).startsWith("1/");
    }

    @Test
    @DisplayName("附件按单据隔离：A 单据的附件不会出现在 B 单据")
    void isolated_by_business() {
        attachments.upload(OBJECT, BIZ, fileOf("a.pdf", "a"));
        assertThat(attachments.list(OBJECT, BIZ + 1)).isEmpty();
        assertThat(attachments.list(OBJECT, BIZ)).hasSize(1);
    }

    @Test
    @DisplayName("按业务单据批量清理（删单据时用）")
    void purge_by_business() {
        attachments.upload(OBJECT, BIZ, fileOf("a.pdf", "a"));
        attachments.upload(OBJECT, BIZ, fileOf("b.pdf", "b"));
        assertThat(attachments.deleteByBusiness(OBJECT, BIZ)).isEqualTo(2);
        assertThat(attachments.list(OBJECT, BIZ)).isEmpty();
    }

    @Test
    @DisplayName("文档不存在时给出明确错误")
    void not_found() {
        assertThatThrownBy(() -> attachments.get(987_654_321L))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("附件不存在");
        assertThatThrownBy(() -> attachments.delete(987_654_321L))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("附件不存在");
    }
}

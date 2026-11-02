package com.apserp.plat.meta;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.tenant.TenantContext;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

/**
 * 附件引擎：任何数据对象都能挂附件，不需要为每张单据加一张附表。
 *
 * <p>存本地磁盘（{@code app.attachment.dir}），库里只存元数据 + 相对路径。
 * 换对象存储时只改 {@link #store}，接口与表结构不动。</p>
 *
 * <p>安全边界：扩展名白名单、单文件大小上限、文件名不落盘（用 UUID + 原扩展名），
 * 下载必须带租户与权限校验，路径不允许穿越。</p>
 */
@Service
public class AttachmentService {

    private static final Logger log = LoggerFactory.getLogger(AttachmentService.class);

    /** 允许的扩展名：文档、图片、压缩包、常见表格。其它一律拒绝（禁止上传可执行文件）。 */
    private static final Set<String> ALLOWED_EXT = Set.of(
            "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "csv",
            "png", "jpg", "jpeg", "gif", "bmp", "webp",
            "zip", "rar", "7z");

    private final JdbcTemplate jdbc;
    private final Path root;
    private final long maxBytes;

    public AttachmentService(JdbcTemplate jdbc,
                             @Value("${app.attachment.dir:./data/attachments}") String dir,
                             @Value("${app.attachment.max-size-mb:10}") int maxSizeMb) {
        this.jdbc = jdbc;
        this.root = Paths.get(dir).toAbsolutePath().normalize();
        this.maxBytes = Math.max(1, maxSizeMb) * 1024L * 1024L;
    }

    public record AttachmentDto(long id, String objectCode, long businessId, String fileName,
                                String ext, long fileSize, String url, String uploadedAt,
                                Long uploadedBy) {
    }

    // ---------------------------------------------------------------- 上传

    @Transactional
    public AttachmentDto upload(String objectCode, long businessId, MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "文件为空");
        }
        if (objectCode == null || objectCode.isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "缺少数据对象编码");
        }
        if (file.getSize() > maxBytes) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                    "文件超过 " + (maxBytes / 1024 / 1024) + "MB 限制");
        }
        String original = safeName(file.getOriginalFilename());
        String ext = extensionOf(original);
        if (!ALLOWED_EXT.contains(ext)) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                    "不支持的文件类型：" + (ext.isEmpty() ? "（无扩展名）" : ext)
                            + "，允许：" + String.join("/", ALLOWED_EXT.stream().sorted().toList()));
        }

        long tenantId = TenantContext.requireTenantId();
        Long userId = TenantContext.userId();
        String relative = tenantId + "/" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"))
                + "/" + UUID.randomUUID().toString().replace("-", "") + "." + ext;
        Path target = root.resolve(relative).normalize();
        if (!target.startsWith(root)) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "非法的存储路径");
        }

        String hash;
        try (InputStream in = file.getInputStream()) {
            Files.createDirectories(target.getParent());
            Files.copy(in, target);
            hash = sha256(target);
        } catch (IOException e) {
            throw new ApiException(ErrorCode.INTERNAL, "保存文件失败：" + e.getMessage(), e);
        }

        jdbc.update("""
                INSERT plat.Attachment (TenantId, BusinessType, BusinessId, FileName, Ext, FileSize,
                                        StorageType, Path, Url, FileHash, UploadedBy, UploadedAt)
                VALUES (?, ?, ?, ?, ?, ?, 1, ?, NULL, ?, ?, sysutcdatetime())
                """, tenantId, objectCode, businessId, original, ext, file.getSize(),
                relative, hash, userId);
        Long id = jdbc.queryForObject("""
                SELECT MAX(Id) FROM plat.Attachment WHERE TenantId = ? AND BusinessType = ?
                """, Long.class, tenantId, objectCode);
        log.info("attachment_upload tenant={} object={} id={} file={} size={}",
                tenantId, objectCode, businessId, original, file.getSize());
        return get(id);
    }

    // ---------------------------------------------------------------- 读取

    public List<AttachmentDto> list(String objectCode, long businessId) {
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                        SELECT Id, BusinessType, BusinessId, FileName, Ext, FileSize, UploadedBy,
                               CONVERT(varchar(19), UploadedAt, 120) AS UploadedAt
                        FROM plat.Attachment
                        WHERE TenantId = ? AND BusinessType = ? AND BusinessId = ?
                        ORDER BY Id DESC
                        """,
                (rs, i) -> new AttachmentDto(rs.getLong("Id"), rs.getString("BusinessType"),
                        rs.getLong("BusinessId"), rs.getString("FileName"), rs.getString("Ext"),
                        rs.getLong("FileSize"), downloadUrl(rs.getLong("Id")),
                        rs.getString("UploadedAt"), (Long) rs.getObject("UploadedBy")),
                tenantId, objectCode, businessId);
    }

    public AttachmentDto get(long id) {
        long tenantId = TenantContext.requireTenantId();
        List<AttachmentDto> rows = jdbc.query("""
                        SELECT Id, BusinessType, BusinessId, FileName, Ext, FileSize, UploadedBy,
                               CONVERT(varchar(19), UploadedAt, 120) AS UploadedAt
                        FROM plat.Attachment WHERE TenantId = ? AND Id = ?
                        """,
                (rs, i) -> new AttachmentDto(rs.getLong("Id"), rs.getString("BusinessType"),
                        rs.getLong("BusinessId"), rs.getString("FileName"), rs.getString("Ext"),
                        rs.getLong("FileSize"), downloadUrl(rs.getLong("Id")),
                        rs.getString("UploadedAt"), (Long) rs.getObject("UploadedBy")),
                tenantId, id);
        if (rows.isEmpty()) {
            throw new ApiException(ErrorCode.NOT_FOUND, "附件不存在：" + id);
        }
        return rows.get(0);
    }

    /** 下载：返回文件资源（文件名由调用方写进 Content-Disposition）。 */
    public record Download(Resource resource, String fileName) {
    }

    public Download download(long id) {
        long tenantId = TenantContext.requireTenantId();
        List<java.util.Map<String, Object>> rows = jdbc.queryForList("""
                SELECT FileName, Path FROM plat.Attachment WHERE TenantId = ? AND Id = ?
                """, tenantId, id);
        if (rows.isEmpty()) {
            throw new ApiException(ErrorCode.NOT_FOUND, "附件不存在：" + id);
        }
        String stored = String.valueOf(rows.get(0).get("Path"));
        Path file = root.resolve(stored).normalize();
        if (!file.startsWith(root) || !Files.isReadable(file)) {
            throw new ApiException(ErrorCode.NOT_FOUND, "附件文件已丢失：" + rows.get(0).get("FileName"));
        }
        try {
            return new Download(new UrlResource(file.toUri()), String.valueOf(rows.get(0).get("FileName")));
        } catch (Exception e) {
            throw new ApiException(ErrorCode.INTERNAL, "读取附件失败", e);
        }
    }

    // ---------------------------------------------------------------- 删除

    @Transactional
    public void delete(long id) {
        long tenantId = TenantContext.requireTenantId();
        List<String> paths = jdbc.queryForList("""
                SELECT Path FROM plat.Attachment WHERE TenantId = ? AND Id = ?
                """, String.class, tenantId, id);
        if (paths.isEmpty()) {
            throw new ApiException(ErrorCode.NOT_FOUND, "附件不存在：" + id);
        }
        int n = jdbc.update("DELETE FROM plat.Attachment WHERE TenantId = ? AND Id = ?", tenantId, id);
        if (n == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND, "附件不存在：" + id);
        }
        try {
            Path file = root.resolve(paths.get(0)).normalize();
            if (file.startsWith(root)) {
                Files.deleteIfExists(file);
            }
        } catch (IOException e) {
            // 库记录已删，磁盘残留不影响业务；记日志便于清理
            log.warn("attachment_file_orphan id={} path={}", id, paths.get(0));
        }
        log.info("attachment_delete tenant={} id={}", tenantId, id);
    }

    /** 业务单据删除时清理附件（暂只删库记录，文件保留一轮便于追溯）。 */
    @Transactional
    public int deleteByBusiness(String objectCode, long businessId) {
        long tenantId = TenantContext.requireTenantId();
        int n = jdbc.update("""
                DELETE FROM plat.Attachment WHERE TenantId = ? AND BusinessType = ? AND BusinessId = ?
                """, tenantId, objectCode, businessId);
        if (n > 0) {
            log.info("attachment_purge tenant={} object={} id={} rows={}",
                    tenantId, objectCode, businessId, n);
        }
        return n;
    }

    // ---------------------------------------------------------------- 工具

    private static String downloadUrl(long id) {
        return "/api/runtime/attachments/" + id + "/download";
    }

    /** 只取文件名，去掉路径与危险字符（原始文件名只用于展示与下载）。 */
    private static String safeName(String raw) {
        String name = raw == null ? "" : raw;
        int slash = Math.max(name.lastIndexOf('/'), name.lastIndexOf('\\'));
        if (slash >= 0) {
            name = name.substring(slash + 1);
        }
        name = name.replace("\u0000", "").trim();
        if (name.isEmpty()) {
            name = "unnamed";
        }
        return name.length() > 200 ? name.substring(name.length() - 200) : name;
    }

    private static String extensionOf(String fileName) {
        int dot = fileName.lastIndexOf('.');
        if (dot < 0 || dot == fileName.length() - 1) {
            return "";
        }
        return fileName.substring(dot + 1).toLowerCase(Locale.ROOT);
    }

    private static String sha256(Path file) throws IOException {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            try (InputStream in = Files.newInputStream(file)) {
                byte[] buf = new byte[8192];
                int n;
                while ((n = in.read(buf)) > 0) {
                    digest.update(buf, 0, n);
                }
            }
            return HexFormat.of().formatHex(digest.digest());
        } catch (java.security.NoSuchAlgorithmException e) {
            return null;
        }
    }
}

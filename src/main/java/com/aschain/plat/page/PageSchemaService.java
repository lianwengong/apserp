package com.aschain.plat.page;

import com.aschain.common.ApiException;
import com.aschain.common.ErrorCode;
import com.aschain.common.tenant.TenantContext;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Pattern;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 远程 PageSchema：页面组合的持久化与校验。
 *
 * <p>界面的字段/视图仍来自 {@code plat.DataObjectField}/{@code ListView}/{@code FormLayout}；
 * 这里只存“页面由哪些块组成”（对象列表、页签、看板卡、快捷入口）。前端读不到远程定义时
 * 回退本地版本，因此本表不可用不会导致白屏。</p>
 */
@Service
public class PageSchemaService {

    private static final Pattern CODE_PATTERN = Pattern.compile("[A-Za-z0-9][A-Za-z0-9_.-]{0,63}");
    private static final Set<String> KINDS = Set.of("object", "tabs", "dashboard", "placeholder");

    private final JdbcTemplate jdbc;
    private final ObjectMapper mapper;

    public PageSchemaService(JdbcTemplate jdbc, ObjectMapper mapper) {
        this.jdbc = jdbc;
        this.mapper = mapper;
    }

    public record PageSchemaDto(long id, String code, String title, String kind, String configJson,
                                int version, boolean enabled, String remark,
                                LocalDateTime createdAt, LocalDateTime modifiedAt) {
    }

    public record SaveRequest(Long id, String code, String title, String kind, String configJson,
                              Boolean enabled, String remark) {
    }

    public List<PageSchemaDto> list(String keyword) {
        long tenantId = TenantContext.requireTenantId();
        String key = keyword == null ? "" : keyword.trim().toLowerCase();
        String like = "%" + key + "%";
        return jdbc.query("""
                        SELECT Id, Code, Title, Kind, ConfigJson, Version, IsEnabled, Remark,
                               CreatedAt, ModifiedAt
                        FROM plat.PageSchema
                        WHERE TenantId = ? AND IsDeleted = 0
                          AND (? = '' OR LOWER(Code) LIKE ? OR LOWER(Title) LIKE ? OR LOWER(Kind) LIKE ?)
                        ORDER BY Code
                        """,
                (rs, i) -> mapRow(rs),
                tenantId, key, like, like, like);
    }

    public Optional<PageSchemaDto> findEnabled(String code) {
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                        SELECT Id, Code, Title, Kind, ConfigJson, Version, IsEnabled, Remark,
                               CreatedAt, ModifiedAt
                        FROM plat.PageSchema
                        WHERE TenantId = ? AND Code = ? AND IsEnabled = 1 AND IsDeleted = 0
                        """,
                (rs, i) -> mapRow(rs), tenantId, code).stream().findFirst();
    }

    public PageSchemaDto get(long id) {
        long tenantId = TenantContext.requireTenantId();
        List<PageSchemaDto> rows = jdbc.query("""
                        SELECT Id, Code, Title, Kind, ConfigJson, Version, IsEnabled, Remark,
                               CreatedAt, ModifiedAt
                        FROM plat.PageSchema
                        WHERE TenantId = ? AND Id = ? AND IsDeleted = 0
                        """,
                (rs, i) -> mapRow(rs), tenantId, id);
        return rows.stream().findFirst()
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "页面定义不存在"));
    }

    /**
     * 新增或更新。校验必须服务端做：前端编辑器只是第一道提示，绕过前端仍要挡住坏 JSON。
     */
    @Transactional
    public long save(SaveRequest req) {
        long tenantId = TenantContext.requireTenantId();
        String code = trim(req.code());
        if (!CODE_PATTERN.matcher(code).matches()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "页面编码只能包含字母、数字、下划线、点和短横线");
        }
        String title = trim(req.title());
        if (title.isEmpty()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "页面标题不能为空");
        }
        String kind = trim(req.kind());
        if (!KINDS.contains(kind)) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "页面类型必须是 object/tabs/dashboard/placeholder");
        }
        String config = normalizeConfig(code, title, kind, req.configJson());
        boolean enabled = req.enabled() == null || req.enabled();
        Long userId = TenantContext.userId();

        if (req.id() == null || req.id() <= 0) {
            try {
                jdbc.update("""
                                INSERT plat.PageSchema
                                    (TenantId, Code, Title, Kind, ConfigJson, Version, IsEnabled, Remark,
                                     IsDeleted, CreatedBy, CreatedAt)
                                VALUES (?, ?, ?, ?, ?, 1, ?, ?, 0, ?, sysutcdatetime())
                                """,
                        tenantId, code, title, kind, config, enabled ? 1 : 0, trim(req.remark()), userId);
            } catch (DuplicateKeyException ex) {
                throw new ApiException(ErrorCode.DUPLICATE_KEY, "页面编码已存在：" + code);
            }
            return jdbc.queryForObject(
                    "SELECT Id FROM plat.PageSchema WHERE TenantId = ? AND Code = ? AND IsDeleted = 0",
                    Long.class, tenantId, code);
        }

        PageSchemaDto current = get(req.id());
        if (!current.code().equals(code)) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "页面编码不可修改，请新建页面");
        }
        int rows = jdbc.update("""
                        UPDATE plat.PageSchema
                        SET Title = ?, Kind = ?, ConfigJson = ?, Version = Version + 1,
                            IsEnabled = ?, Remark = ?, ModifiedBy = ?, ModifiedAt = sysutcdatetime()
                        WHERE TenantId = ? AND Id = ? AND IsDeleted = 0
                        """,
                title, kind, config, enabled ? 1 : 0, trim(req.remark()), userId, tenantId, req.id());
        if (rows == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND, "页面定义不存在");
        }
        return req.id();
    }

    @Transactional
    public void delete(long id) {
        long tenantId = TenantContext.requireTenantId();
        int rows = jdbc.update("""
                        UPDATE plat.PageSchema
                        SET IsDeleted = 1, Version = Version + 1, ModifiedBy = ?, ModifiedAt = sysutcdatetime()
                        WHERE TenantId = ? AND Id = ? AND IsDeleted = 0
                        """,
                TenantContext.userId(), tenantId, id);
        if (rows == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND, "页面定义不存在");
        }
    }

    /**
     * 页面 JSON 的硬校验：
     * - code/title/kind 必须与列表字段一致；
     * - object 必须有 objectCode；tabs 至少一个页签且 key 不重复；dashboard 必须有 cards。
     */
    private String normalizeConfig(String code, String title, String kind, String raw) {
        if (raw == null || raw.isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "页面配置 JSON 不能为空");
        }
        JsonNode parsed;
        try {
            parsed = mapper.readTree(raw);
        } catch (Exception ex) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "页面配置不是合法 JSON：" + ex.getMessage());
        }
        if (!parsed.isObject()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "页面配置必须是 JSON 对象");
        }
        ObjectNode node = (ObjectNode) parsed;
        if (!node.hasNonNull("code")) node.put("code", code);
        if (!node.hasNonNull("title")) node.put("title", title);
        if (!node.hasNonNull("kind")) node.put("kind", kind);
        if (!code.equals(node.get("code").asText())) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "页面配置里的 code 必须与列表一致");
        }
        if (!kind.equals(node.get("kind").asText())) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "页面配置里的 kind 必须与列表一致");
        }
        if (!title.equals(node.get("title").asText())) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "页面配置里的 title 必须与列表一致");
        }
        switch (kind) {
            case "object" -> {
                if (!node.hasNonNull("objectCode") || node.get("objectCode").asText().isBlank()) {
                    throw new ApiException(ErrorCode.BAD_REQUEST, "object 页面必须配置 objectCode");
                }
            }
            case "tabs" -> {
                JsonNode tabs = node.get("tabs");
                if (tabs == null || !tabs.isArray() || tabs.isEmpty()) {
                    throw new ApiException(ErrorCode.BAD_REQUEST, "tabs 页面至少配置一个页签");
                }
                Set<String> keys = new java.util.HashSet<>();
                for (JsonNode tab : tabs) {
                    String key = tab.path("key").asText("");
                    String label = tab.path("label").asText("");
                    if (key.isBlank() || label.isBlank()) {
                        throw new ApiException(ErrorCode.BAD_REQUEST, "每个页签必须有 key 和 label");
                    }
                    if (!keys.add(key)) {
                        throw new ApiException(ErrorCode.BAD_REQUEST, "页签 key 重复：" + key);
                    }
                    if (tab.path("objectCode").asText("").isBlank()
                            && tab.path("pageCode").asText("").isBlank()) {
                        throw new ApiException(ErrorCode.BAD_REQUEST,
                                "页签 " + key + " 必须配置 objectCode 或 pageCode");
                    }
                }
            }
            case "dashboard" -> {
                JsonNode dashboard = node.get("dashboard");
                if (dashboard == null || !dashboard.isObject()
                        || !dashboard.path("cards").isArray() || dashboard.path("cards").isEmpty()) {
                    throw new ApiException(ErrorCode.BAD_REQUEST, "dashboard 页面必须配置 dashboard.cards");
                }
            }
            default -> {
                // placeholder 不要求额外字段
            }
        }
        try {
            return mapper.writerWithDefaultPrettyPrinter().writeValueAsString(node);
        } catch (Exception ex) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "页面配置序列化失败");
        }
    }

    private static String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private static PageSchemaDto mapRow(java.sql.ResultSet rs) throws java.sql.SQLException {
        return new PageSchemaDto(
                rs.getLong("Id"),
                rs.getString("Code"),
                rs.getString("Title"),
                rs.getString("Kind"),
                rs.getString("ConfigJson"),
                rs.getInt("Version"),
                rs.getBoolean("IsEnabled"),
                rs.getString("Remark"),
                rs.getObject("CreatedAt", LocalDateTime.class),
                rs.getObject("ModifiedAt", LocalDateTime.class));
    }
}

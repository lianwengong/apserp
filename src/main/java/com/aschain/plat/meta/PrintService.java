package com.aschain.plat.meta;

import com.aschain.common.ApiException;
import com.aschain.common.ErrorCode;
import com.aschain.common.tenant.TenantContext;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 打印模板：HTML + 占位符，运行时用单据数据渲染成可打印页面。
 *
 * <p>占位符（刻意做小，不做模板语言）：
 * <ul>
 *   <li>{@code {{FieldName}}} —— 主表字段，HTML 转义后输出；</li>
 *   <li>{@code {{#ChildAlias}}…{{/ChildAlias}}} —— 子表区块，区块内 {@code {{Field}}}
 *       先取子行、取不到再取主表；</li>
 *   <li>{@code {{PrintedAt}}} —— 渲染时间。</li>
 * </ul>
 *
 * <p>为什么不引 Freemarker/Thymeleaf：模板由业务人员在设计器里写，占位符越少越不容易写错；
 * 真正复杂排版应交给子表区块 + CSS。</p>
 */
@Service
public class PrintService {

    private static final Logger log = LoggerFactory.getLogger(PrintService.class);

    private static final Pattern SECTION = Pattern.compile(
            "\\{\\{#([A-Za-z][A-Za-z0-9_]*)\\}\\}([\\s\\S]*?)\\{\\{/\\1\\}\\}");
    private static final Pattern FIELD = Pattern.compile("\\{\\{([A-Za-z][A-Za-z0-9_]*)\\}\\}");

    private final JdbcTemplate jdbc;
    private final MetaDefinitionService definitionService;
    private final MetaQueryService queryService;
    private final MetaChildService childService;
    private final DocStatusService docStatusService;

    public PrintService(JdbcTemplate jdbc, MetaDefinitionService definitionService,
                        MetaQueryService queryService, MetaChildService childService,
                        DocStatusService docStatusService) {
        this.jdbc = jdbc;
        this.definitionService = definitionService;
        this.queryService = queryService;
        this.childService = childService;
        this.docStatusService = docStatusService;
    }

    // ---------------------------------------------------------------- DTO

    public record TemplateDto(long id, String objectCode, String code, String name, String content,
                              String paperSize, boolean isDefault, boolean enabled, String remark) {
    }

    public record TemplateSaveRequest(Long id, String objectCode, String code, String name,
                                      String content, String paperSize, boolean isDefault,
                                      boolean enabled, String remark) {
    }

    // ---------------------------------------------------------------- 模板 CRUD

    public List<TemplateDto> list(String objectCode) {
        long tenantId = TenantContext.requireTenantId();
        String sql = """
                SELECT t.Id, o.Code AS ObjectCode, t.Code, t.Name, t.Content, t.PaperSize,
                       t.IsDefault, t.IsEnabled, t.Remark
                FROM plat.PrintTemplate t
                JOIN plat.DataObject o ON o.Id = t.DataObjectId
                WHERE t.TenantId = ? AND t.IsDeleted = 0
                """;
        if (objectCode == null || objectCode.isBlank()) {
            return jdbc.query(sql + " ORDER BY o.Code, t.Code",
                    (rs, i) -> map(rs), tenantId);
        }
        return jdbc.query(sql + " AND o.Code = ? ORDER BY t.IsDefault DESC, t.Code",
                (rs, i) -> map(rs), tenantId, objectCode);
    }

    private TemplateDto map(java.sql.ResultSet rs) throws java.sql.SQLException {
        return new TemplateDto(rs.getLong("Id"), rs.getString("ObjectCode"), rs.getString("Code"),
                rs.getString("Name"), rs.getString("Content"), rs.getString("PaperSize"),
                rs.getBoolean("IsDefault"), rs.getBoolean("IsEnabled"), rs.getString("Remark"));
    }

    @Transactional
    public long save(TemplateSaveRequest req) {
        long tenantId = TenantContext.requireTenantId();
        if (req.code() == null || !req.code().trim().matches("[A-Za-z][A-Za-z0-9_.]{0,59}")) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "模板编码必须是字母开头的标识符（如 pt.brand）");
        }
        if (req.content() == null || req.content().isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "模板内容不能为空");
        }
        if (req.content().length() > 200_000) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "模板内容过长（上限 200KB）");
        }
        long objectId = objectIdOf(req.objectCode());
        String code = req.code().trim();
        Integer dup = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.PrintTemplate
                WHERE TenantId = ? AND Code = ? AND IsDeleted = 0 AND Id <> ISNULL(?, -1)
                """, Integer.class, tenantId, code, req.id());
        if (dup != null && dup > 0) {
            throw new ApiException(ErrorCode.DUPLICATE_KEY, "模板编码已存在：" + code);
        }
        if (req.isDefault()) {
            jdbc.update("""
                    UPDATE plat.PrintTemplate SET IsDefault = 0
                    WHERE TenantId = ? AND DataObjectId = ?
                    """, tenantId, objectId);
        }
        if (req.id() != null) {
            jdbc.update("""
                    UPDATE plat.PrintTemplate
                    SET DataObjectId = ?, Code = ?, Name = ?, Content = ?, PaperSize = ?,
                        IsDefault = ?, IsEnabled = ?, Remark = ?, ModifiedAt = sysutcdatetime()
                    WHERE Id = ? AND TenantId = ?
                    """, objectId, code, req.name(), req.content(),
                    req.paperSize() == null || req.paperSize().isBlank() ? "A4" : req.paperSize(),
                    req.isDefault() ? 1 : 0, req.enabled() ? 1 : 0, req.remark(), req.id(), tenantId);
            return req.id();
        }
        jdbc.update("""
                INSERT plat.PrintTemplate (TenantId, DataObjectId, Code, Name, Content, PaperSize,
                                           IsDefault, IsEnabled, Remark, CreatedAt)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, sysutcdatetime())
                """, tenantId, objectId, code, req.name(), req.content(),
                req.paperSize() == null || req.paperSize().isBlank() ? "A4" : req.paperSize(),
                req.isDefault() ? 1 : 0, req.enabled() ? 1 : 0, req.remark());
        return jdbc.queryForObject(
                "SELECT MAX(Id) FROM plat.PrintTemplate WHERE TenantId = ? AND Code = ?",
                Long.class, tenantId, code);
    }

    @Transactional
    public void delete(long id) {
        long tenantId = TenantContext.requireTenantId();
        int n = jdbc.update("""
                UPDATE plat.PrintTemplate SET IsDeleted = 1 WHERE Id = ? AND TenantId = ?
                """, id, tenantId);
        if (n == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND, "打印模板不存在");
        }
    }

    private long objectIdOf(String objectCode) {
        Long id = jdbc.query("""
                SELECT Id FROM plat.DataObject WHERE TenantId = ? AND Code = ? AND IsDeleted = 0
                """, rs -> rs.next() ? rs.getLong(1) : null, TenantContext.requireTenantId(), objectCode);
        if (id == null) {
            throw new ApiException(ErrorCode.META_OBJECT_NOT_FOUND, "数据对象不存在：" + objectCode);
        }
        return id;
    }

    // ---------------------------------------------------------------- 渲染

    /**
     * 渲染单据打印 HTML。
     *
     * @param templateCode 为空时取该对象的默认模板，没有默认模板则用第一个启用的
     */
    public String render(String objectCode, long businessId, String templateCode) {
        TemplateDto template = pickTemplate(objectCode, templateCode);
        Map<String, Object> row = single(objectCode, businessId);
        if (row.isEmpty()) {
            throw new ApiException(ErrorCode.NOT_FOUND, "单据不存在或无权查看");
        }
        List<MetaChildService.ChildGroup> groups = childService.childrenOf(objectCode, businessId);
        // 状态字段打成中文：打印件上出现「0」没人看得懂
        row = withStatusName(objectCode, row);
        String html = renderContent(template.content(), row, groups);
        log.info("print_render object={} id={} template={} bytes={}",
                objectCode, businessId, template.code(), html.length());
        return html;
    }

    /** 把状态字段的值换成中文名（没配状态机的对象原样返回）。 */
    private Map<String, Object> withStatusName(String objectCode, Map<String, Object> row) {
        String field = docStatusService.statusFieldOf(objectCode);
        if (field == null || !row.containsKey(field)) {
            return row;
        }
        Object raw = row.get(field);
        String name = docStatusService.statusesOf(objectCode).stream()
                .filter(s -> raw != null && s.statusValue() == Integer.parseInt(String.valueOf(raw)))
                .map(DocStatusService.StatusDto::statusName)
                .findFirst()
                .orElse(null);
        if (name == null) {
            return row;
        }
        Map<String, Object> copy = new java.util.LinkedHashMap<>(row);
        copy.put(field, name);
        return copy;
    }

    private TemplateDto pickTemplate(String objectCode, String templateCode) {
        List<TemplateDto> templates = list(objectCode).stream().filter(TemplateDto::enabled).toList();
        if (templates.isEmpty()) {
            throw new ApiException(ErrorCode.NOT_FOUND, "该对象还没有可用的打印模板：" + objectCode);
        }
        if (templateCode == null || templateCode.isBlank()) {
            return templates.stream().filter(TemplateDto::isDefault).findFirst().orElse(templates.get(0));
        }
        return templates.stream().filter(t -> t.code().equals(templateCode)).findFirst()
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "打印模板不存在：" + templateCode));
    }

    /** 纯函数式渲染，便于单测。 */
    String renderContent(String content, Map<String, Object> master,
                         List<MetaChildService.ChildGroup> groups) {
        String withSections = renderSections(content, master, groups);
        return fillFields(withSections, master);
    }

    private String renderSections(String content, Map<String, Object> master,
                                  List<MetaChildService.ChildGroup> groups) {
        Matcher m = SECTION.matcher(content);
        StringBuilder out = new StringBuilder();
        while (m.find()) {
            String alias = m.group(1);
            String body = m.group(2);
            MetaChildService.ChildGroup group = groups.stream()
                    .filter(g -> g.alias().equals(alias)).findFirst().orElse(null);
            StringBuilder block = new StringBuilder();
            if (group != null) {
                for (Map<String, Object> child : group.rows()) {
                    block.append(fillFields(body, child, master));
                }
            }
            m.appendReplacement(out, Matcher.quoteReplacement(block.toString()));
        }
        m.appendTail(out);
        return out.toString();
    }

    private String fillFields(String text, Map<String, Object> row) {
        return fillFields(text, row, Map.of());
    }

    /** 区块内取子行，取不到再回落到主表；{@code PrintedAt} 是内置占位符。 */
    private String fillFields(String text, Map<String, Object> row, Map<String, Object> master) {
        Matcher m = FIELD.matcher(text);
        StringBuilder out = new StringBuilder();
        while (m.find()) {
            String name = m.group(1);
            String value;
            if ("PrintedAt".equals(name)) {
                value = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));
            } else if (row.containsKey(name)) {
                value = text(row.get(name));
            } else if (master.containsKey(name)) {
                value = text(master.get(name));
            } else {
                value = "";
            }
            m.appendReplacement(out, Matcher.quoteReplacement(escape(value)));
        }
        m.appendTail(out);
        return out.toString();
    }

    private static String text(Object raw) {
        if (raw == null) {
            return "";
        }
        if (raw instanceof Boolean b) {
            return b ? "是" : "否";
        }
        return String.valueOf(raw);
    }

    /** 模板占位符一律转义：防止单据里带 <script> 直接把打印页打穿。 */
    static String escape(String raw) {
        return raw.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }

    private Map<String, Object> single(String objectCode, long businessId) {
        var page = queryService.query(objectCode,
                "[{\"f\":\"Id\",\"op\":\"eq\",\"v\":\"" + businessId + "\"}]", null, 1, 1);
        return page.rows().isEmpty() ? Map.of() : page.rows().get(0);
    }

    /** 模板里可用的占位符提示（设计器右侧提示用）。 */
    public List<String> placeholders(String objectCode) {
        List<String> out = new ArrayList<>();
        out.add("PrintedAt");
        for (MetaDefinitionService.FieldDto f : definitionService.listFields(objectCode)) {
            if (!f.primaryKey()) {
                out.add(f.fieldName());
            }
        }
        for (MetaChildService.RelationDto rel : childService.relationsOf(objectCode)) {
            out.add("#" + rel.alias());
        }
        return out;
    }
}

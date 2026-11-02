package com.apserp.plat.meta;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.tenant.TenantContext;
import com.apserp.plat.perm.PermissionService;
import java.util.Map;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/**
 * 元数据定义读取：数据对象、字段、列表视图、表单布局。
 *
 * <p>前端渲染列表/表单所需的全部信息都从这里来，业务代码不再硬编码任何字段。</p>
 *
 * <p>租户隔离：连接由 TenantAwareDataSource 在借出时设置 SESSION_CONTEXT，
 * 查询额外显式带 TenantId 条件，既走索引也便于排查。</p>
 */
@Service
public class MetaDefinitionService {

    private final JdbcTemplate jdbc;
    private final PermissionService permissionService;
    private final MetaCache cache;
    private final MetaOverlay overlay;

    public MetaDefinitionService(JdbcTemplate jdbc, PermissionService permissionService,
                                 MetaCache cache, MetaOverlay overlay) {
        this.jdbc = jdbc;
        this.permissionService = permissionService;
        this.cache = cache;
        this.overlay = overlay;
    }

    // ---------------------------------------------------------------- DTO

    public record DataObjectDto(long id, String code, String name, int objectType,
                                String schemaName, String objectName, String primaryKey,
                                String docNoField, String tenantField, String defaultOrder,
                                boolean readOnly) {
    }

    public record FieldDto(String fieldName, String displayName, String dataType, Integer maxLength,
                           boolean nullable, boolean primaryKey, boolean identity, boolean required,
                           int lookupType, String lookupSource, String lookupDisplayField,
                           String format, int sort) {
    }

    public record ColumnDto(String fieldName, String title, Integer width, String align,
                            boolean sum, boolean visible, int sort) {
    }

    public record ListViewDto(long id, String code, String name, int pageSize,
                              String defaultSort, boolean isDefault, List<ColumnDto> columns) {
    }

    public record FormFieldDto(String fieldName, String label, String controlType, int row, int col,
                               int span, boolean readOnly, boolean required, boolean hidden,
                               String groupName, int sort) {
    }

    public record FormLayoutDto(long id, String code, String name, int mode, int columns,
                                boolean isDefault, List<FormFieldDto> fields) {
    }

    // ---------------------------------------------------------------- 查询

    public List<DataObjectDto> listObjects() {
        // 灰度用户读灰度版本快照；其余人（含平台管理员）走实时库 + 缓存
        List<DataObjectDto> gray = overlay.objects();
        if (gray != null) {
            return gray;
        }
        return cache.get("objects", "-", this::loadObjects);
    }

    private List<DataObjectDto> loadObjects() {
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                        SELECT Id, Code, Name, ObjectType, SchemaName, ObjectName, PrimaryKey,
                               DocNoField, TenantField, DefaultOrder, IsReadOnly
                        FROM plat.DataObject
                        WHERE TenantId = ? AND IsDeleted = 0 AND IsEnabled = 1
                        ORDER BY Code
                        """,
                (rs, i) -> new DataObjectDto(rs.getLong("Id"), rs.getString("Code"),
                        rs.getString("Name"), rs.getInt("ObjectType"), rs.getString("SchemaName"),
                        rs.getString("ObjectName"), rs.getString("PrimaryKey"),
                        rs.getString("DocNoField"), rs.getString("TenantField"),
                        rs.getString("DefaultOrder"), rs.getBoolean("IsReadOnly")),
                tenantId);
    }

    public DataObjectDto getObject(String objectCode) {
        MetaQueryService.requireValidObjectCode(objectCode);
        long tenantId = TenantContext.requireTenantId();
        List<DataObjectDto> hit = jdbc.query("""
                        SELECT Id, Code, Name, ObjectType, SchemaName, ObjectName, PrimaryKey,
                               DocNoField, TenantField, DefaultOrder, IsReadOnly
                        FROM plat.DataObject
                        WHERE TenantId = ? AND Code = ? AND IsDeleted = 0
                        """,
                (rs, i) -> new DataObjectDto(rs.getLong("Id"), rs.getString("Code"),
                        rs.getString("Name"), rs.getInt("ObjectType"), rs.getString("SchemaName"),
                        rs.getString("ObjectName"), rs.getString("PrimaryKey"),
                        rs.getString("DocNoField"), rs.getString("TenantField"),
                        rs.getString("DefaultOrder"), rs.getBoolean("IsReadOnly")),
                tenantId, objectCode);
        if (hit.isEmpty()) {
            throw new ApiException(ErrorCode.META_OBJECT_NOT_FOUND,
                    "该租户未配置此数据对象：" + objectCode);
        }
        return hit.get(0);
    }

    /**
     * 字段定义。**已按字段级权限过滤**：Access=0 的字段不下发，
     * Access=1 的字段标记为只读（前端渲染时应据此禁用输入）。
     */
    public List<FieldDto> listFields(String objectCode) {
        List<FieldDto> gray = overlay.fields(objectCode);
        if (gray != null) {
            return gray;
        }
        return cache.get("fields", objectCode, () -> loadFields(objectCode));
    }

    private List<FieldDto> loadFields(String objectCode) {
        DataObjectDto obj = getObject(objectCode);
        Map<String, Integer> access = permissionService.fieldAccess(objectCode);
        List<FieldDto> raw = jdbc.query("""
                        SELECT FieldName, DisplayName, DataType, MaxLength, IsNullable, IsPrimaryKey,
                               IsIdentity, IsRequired, LookupType, LookupSource, LookupDisplayField,
                               Format, Sort
                        FROM plat.DataObjectField
                        WHERE DataObjectId = ?
                        ORDER BY Sort, FieldName
                        """,
                (rs, i) -> new FieldDto(rs.getString("FieldName"), rs.getString("DisplayName"),
                        rs.getString("DataType"), (Integer) rs.getObject("MaxLength"),
                        rs.getBoolean("IsNullable"), rs.getBoolean("IsPrimaryKey"),
                        rs.getBoolean("IsIdentity"), rs.getBoolean("IsRequired"),
                        rs.getInt("LookupType"), rs.getString("LookupSource"),
                        rs.getString("LookupDisplayField"), rs.getString("Format"),
                        rs.getInt("Sort")),
                obj.id());
        return raw.stream()
                .filter(f -> access.getOrDefault(f.fieldName(), 2) > 0)
                .map(f -> access.getOrDefault(f.fieldName(), 2) == 1
                        ? new FieldDto(f.fieldName(), f.displayName(), f.dataType(), f.maxLength(),
                                f.nullable(), f.primaryKey(), f.identity(), f.required(), f.lookupType(),
                                f.lookupSource(), f.lookupDisplayField(), f.format(), f.sort())
                        : f)
                .toList();
    }

    public List<ListViewDto> listViews(String objectCode) {
        List<ListViewDto> gray = overlay.views(objectCode);
        if (gray != null) {
            return gray;
        }
        return cache.get("views", objectCode, () -> loadViews(objectCode));
    }

    private List<ListViewDto> loadViews(String objectCode) {
        DataObjectDto obj = getObject(objectCode);
        List<ListViewDto> heads = jdbc.query("""
                        SELECT Id, Code, Name, PageSize, DefaultSort, IsDefault
                        FROM plat.ListView
                        WHERE DataObjectId = ? AND TenantId = ? AND IsDeleted = 0
                        ORDER BY IsDefault DESC, Code
                        """,
                (rs, i) -> new ListViewDto(rs.getLong("Id"), rs.getString("Code"),
                        rs.getString("Name"), rs.getInt("PageSize"), rs.getString("DefaultSort"),
                        rs.getBoolean("IsDefault"), List.of()),
                obj.id(), TenantContext.requireTenantId());
        return heads.stream()
                .map(v -> new ListViewDto(v.id(), v.code(), v.name(), v.pageSize(), v.defaultSort(),
                        v.isDefault(), columnsOf(v.id())))
                .toList();
    }

    private List<ColumnDto> columnsOf(long listViewId) {
        return jdbc.query("""
                        SELECT FieldName, Title, Width, Align, IsSum, IsVisible, Sort
                        FROM plat.ListViewColumn
                        WHERE ListViewId = ?
                        ORDER BY Sort, Id
                        """,
                (rs, i) -> new ColumnDto(rs.getString("FieldName"), rs.getString("Title"),
                        (Integer) rs.getObject("Width"), rs.getString("Align"),
                        rs.getBoolean("IsSum"), rs.getBoolean("IsVisible"), rs.getInt("Sort")),
                listViewId);
    }

    public List<FormLayoutDto> listFormLayouts(String objectCode) {
        List<FormLayoutDto> gray = overlay.forms(objectCode);
        if (gray != null) {
            return gray;
        }
        return cache.get("forms", objectCode, () -> loadFormLayouts(objectCode));
    }

    private List<FormLayoutDto> loadFormLayouts(String objectCode) {
        DataObjectDto obj = getObject(objectCode);
        List<FormLayoutDto> heads = jdbc.query("""
                        SELECT Id, Code, Name, Mode, Columns, IsDefault
                        FROM plat.FormLayout
                        WHERE DataObjectId = ? AND TenantId = ? AND IsDeleted = 0
                        ORDER BY IsDefault DESC, Code
                        """,
                (rs, i) -> new FormLayoutDto(rs.getLong("Id"), rs.getString("Code"),
                        rs.getString("Name"), rs.getInt("Mode"), rs.getInt("Columns"),
                        rs.getBoolean("IsDefault"), List.of()),
                obj.id(), TenantContext.requireTenantId());
        return heads.stream()
                .map(f -> new FormLayoutDto(f.id(), f.code(), f.name(), f.mode(), f.columns(),
                        f.isDefault(), formFieldsOf(f.id())))
                .toList();
    }

    private List<FormFieldDto> formFieldsOf(long layoutId) {
        return jdbc.query("""
                        SELECT FieldName, Label, ControlType, Row, Col, Span, IsReadOnly,
                               IsRequired, IsHidden, GroupName, Sort
                        FROM plat.FormField
                        WHERE FormLayoutId = ?
                        ORDER BY Sort, Id
                        """,
                (rs, i) -> new FormFieldDto(rs.getString("FieldName"), rs.getString("Label"),
                        rs.getString("ControlType"), rs.getInt("Row"), rs.getInt("Col"),
                        rs.getInt("Span"), rs.getBoolean("IsReadOnly"), rs.getBoolean("IsRequired"),
                        rs.getBoolean("IsHidden"), rs.getString("GroupName"), rs.getInt("Sort")),
                layoutId);
    }
}

package com.apserp.plat.meta;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.tenant.TenantContext;
import com.apserp.plat.perm.PermissionService;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/**
 * 元数据驱动的列表查询：调用数据库引擎 {@code plat.usp_Meta_List}。
 *
 * <p>业务代码不得绕过本服务直接写 SQL 查业务表——所有过滤、排序、分页、数据权限
 * 都由引擎在数据库内完成。</p>
 */
@Service
public class MetaQueryService {

    private static final Logger log = LoggerFactory.getLogger(MetaQueryService.class);

    /** 数据对象编码：schema.object。只允许字母数字下划线，杜绝注入面。 */
    static final Pattern OBJECT_CODE = Pattern.compile("^[a-z][a-z0-9]{1,7}\\.[A-Za-z][A-Za-z0-9_]{0,63}$");

    private static final int MAX_PAGE_SIZE = 500;

    private final JdbcTemplate jdbc;
    private final PermissionService permissionService;

    public MetaQueryService(JdbcTemplate jdbc, PermissionService permissionService) {
        this.jdbc = jdbc;
        this.permissionService = permissionService;
    }

    public PageResult query(String objectCode, String filtersJson, String sort, int page, int size) {
        requireValidObjectCode(objectCode);
        int safePage = Math.max(page, 1);
        int safeSize = resolvePageSize(size);
        try {
            PageResult result = jdbc.execute((ConnectionCallback<PageResult>) con ->
                    callList(con, objectCode, filtersJson, sort, safePage, safeSize));
            return maskFields(objectCode, result);
        } catch (DataAccessException ex) {
            throw translate(objectCode, ex);
        }
    }

    private PageResult callList(Connection con, String objectCode, String filtersJson, String sort,
                                int page, int size) throws SQLException {
        try (CallableStatement cs = con.prepareCall("{call plat.usp_Meta_List (?, ?, ?, ?, ?, ?, ?, ?)}")) {
            cs.setInt(1, (int) TenantContext.requireTenantId());
            Long userId = TenantContext.userId();
            if (userId == null) {
                cs.setNull(2, Types.BIGINT);
            } else {
                cs.setLong(2, userId);
            }
            cs.setString(3, objectCode);
            cs.setString(4, filtersJson);
            cs.setString(5, sort);
            cs.setInt(6, page);
            cs.setInt(7, size);
            cs.registerOutParameter(8, Types.INTEGER);

            boolean hasResult = cs.execute();
            List<Map<String, Object>> rows = new ArrayList<>();
            if (hasResult) {
                try (ResultSet rs = cs.getResultSet()) {
                    ResultSetMetaData md = rs.getMetaData();
                    int cols = md.getColumnCount();
                    while (rs.next()) {
                        Map<String, Object> row = new LinkedHashMap<>();
                        for (int i = 1; i <= cols; i++) {
                            row.put(md.getColumnLabel(i), rs.getObject(i));
                        }
                        rows.add(row);
                    }
                }
            }
            return new PageResult(page, size, cs.getInt(8), rows);
        }
    }

    /**
     * 把数据库异常翻译成业务错误：只有「数据对象不存在」是用户可理解的，
     * 其余一律按系统错误处理，绝不伪装成业务错误。
     */
    private ApiException translate(String objectCode, Exception ex) {
        String msg = ex.getMessage() == null ? "" : ex.getMessage();
        if (msg.contains("数据对象不存在")) {
            return new ApiException(ErrorCode.META_OBJECT_NOT_FOUND,
                    "该租户未配置此数据对象：" + objectCode, ex);
        }
        log.error("meta_list_failed object={}", objectCode, ex);
        return new ApiException(ErrorCode.INTERNAL, "查询失败，请联系管理员", ex);
    }

    /** 分页大小钳制：1..500，防止一次拉全表拖垮数据库。 */
    static int resolvePageSize(int size) {
        return Math.min(Math.max(size, 1), MAX_PAGE_SIZE);
    }

    /** 字段级权限：Access=0 的列从结果里剔除，避免"看不见但能导出"。 */
    private PageResult maskFields(String objectCode, PageResult page) {
        Map<String, Integer> access = permissionService.fieldAccess(objectCode);
        if (access.isEmpty()) {
            return page;
        }
        List<Map<String, Object>> masked = page.rows().stream()
                .map(row -> {
                    Map<String, Object> copy = new LinkedHashMap<>(row);
                    access.forEach((field, level) -> {
                        if (level != null && level == 0) {
                            copy.remove(field);
                        }
                    });
                    return copy;
                })
                .toList();
        return new PageResult(page.page(), page.size(), page.total(), masked);
    }

    static void requireValidObjectCode(String objectCode) {
        if (objectCode == null || !OBJECT_CODE.matcher(objectCode).matches()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "非法的数据对象编码：" + objectCode);
        }
    }

    public record PageResult(int page, int size, int total, List<Map<String, Object>> rows) {
    }
}

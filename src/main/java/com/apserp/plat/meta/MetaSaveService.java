package com.apserp.plat.meta;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.tenant.TenantContext;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 保存引擎：把前端提交的 JSON 交给数据库过程 {@code plat.usp_Meta_Save}。
 *
 * <p>新增与修改同一个入口：JSON 含主键即修改，不含即新增。字段校验、类型转换、
 * 默认值、审计字段全部由元数据驱动，Java 侧不写任何业务规则。</p>
 */
@Service
public class MetaSaveService {

    private static final Logger log = LoggerFactory.getLogger(MetaSaveService.class);

    private static final int MAX_JSON_BYTES = 512 * 1024;

    private final JdbcTemplate jdbc;
    private final MetaDefinitionService definitionService;

    public MetaSaveService(JdbcTemplate jdbc, MetaDefinitionService definitionService) {
        this.jdbc = jdbc;
        this.definitionService = definitionService;
    }

    /**
     * @return 新增或修改后的主键 Id
     */
    @Transactional
    public long save(String objectCode, String json) {
        MetaQueryService.requireValidObjectCode(objectCode);
        if (json == null || json.isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "请求体不能为空");
        }
        if (json.length() > MAX_JSON_BYTES) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "请求体超过 512KB 限制");
        }

        long tenantId = TenantContext.requireTenantId();
        Long userId = TenantContext.userId();
        assertNotStale(objectCode, json);
        try {
            long id = jdbc.execute((ConnectionCallback<Long>) con -> callSave(con, tenantId, userId, objectCode, json));
            log.info("meta_save tenant={} object={} id={}", tenantId, objectCode, id);
            return id;
        } catch (org.springframework.dao.DataAccessException ex) {
            throw translate(objectCode, ex);
        }
    }

    /**
     * 乐观并发校验：请求里同时带 {@code Id} 与 {@code RowVersion} 时，
     * 先比对数据库中的行版本；不一致说明数据已被他人修改，直接拒绝。
     *
     * <p>说明：这是"读-比较-写"的乐观检查，与随后的保存存在极小的竞态窗口；
     * 彻底消除需要在 UPDATE 的 WHERE 里比对版本（涉及存储过程改造，另行安排）。
     * 当前的实现已覆盖最常见场景：用户开着旧页面提交。</p>
     */
    private void assertNotStale(String objectCode, String json) {
        Long id = readLong(json, "Id");
        Long expected = readLong(json, "RowVersion");
        if (id == null || expected == null) {
            return;   // 新增，或前端未带版本号（兼容旧调用）
        }
        var object = definitionService.getObject(objectCode);
        String sql = "SELECT CONVERT(bigint, [RowVersion]) FROM " + quote(object.schemaName()) + "."
                + quote(object.objectName()) + " WHERE " + quote(object.primaryKey()) + " = ?";
        List<Long> actual;
        try {
            actual = jdbc.queryForList(sql, Long.class, id);
        } catch (org.springframework.dao.DataAccessException ex) {
            // 表没有 RowVersion 列：不做并发校验
            return;
        }
        if (actual.isEmpty()) {
            throw new ApiException(ErrorCode.NOT_FOUND, "记录不存在或已被删除");
        }
        if (!actual.get(0).equals(expected)) {
            log.warn("concurrent_modify object={} id={} expected={} actual={}",
                    objectCode, id, expected, actual.get(0));
            throw new ApiException(ErrorCode.CONCURRENT_MODIFY, "数据已被他人修改，请刷新后重试");
        }
    }

    private static Long readLong(String json, String key) {
        String token = "\"" + key + "\"";
        int i = json.indexOf(token);
        if (i < 0) {
            return null;
        }
        int colon = json.indexOf(':', i + token.length());
        if (colon < 0) {
            return null;
        }
        int end = colon + 1;
        while (end < json.length() && " \t\r\n".indexOf(json.charAt(end)) >= 0) {
            end++;
        }
        int start = end;
        while (end < json.length() && (Character.isDigit(json.charAt(end)) || json.charAt(end) == '-')) {
            end++;
        }
        if (end == start) {
            return null;
        }
        try {
            return Long.valueOf(json.substring(start, end));
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    /** 标识符加方括号：表名/主键来自元数据（已登记），仍做转义防御。 */
    private static String quote(String identifier) {
        return "[" + identifier.replace("]", "]]") + "]";
    }

    private long callSave(Connection con, long tenantId, Long userId, String objectCode, String json)
            throws SQLException {
        try (CallableStatement cs = con.prepareCall("{call plat.usp_Meta_Save (?, ?, ?, ?, ?)}")) {
            cs.setInt(1, (int) tenantId);
            if (userId == null) {
                cs.setNull(2, Types.BIGINT);
            } else {
                cs.setLong(2, userId);
            }
            cs.setString(3, objectCode);
            cs.setString(4, json);
            cs.registerOutParameter(5, Types.BIGINT);
            cs.execute();
            return cs.getLong(5);
        }
    }

    private ApiException translate(String objectCode, Exception ex) {
        String msg = ex.getMessage() == null ? "" : ex.getMessage();
        if (msg.contains("数据对象不存在")) {
            return new ApiException(ErrorCode.META_OBJECT_NOT_FOUND, "该租户未配置此数据对象：" + objectCode, ex);
        }
        if (msg.contains("违反唯一") || msg.contains("UNIQUE") || msg.contains("重复")) {
            return new ApiException(ErrorCode.DUPLICATE_KEY, "数据重复，请检查唯一字段", ex);
        }
        log.error("meta_save_failed object={}", objectCode, ex);
        return new ApiException(ErrorCode.INTERNAL, "保存失败，请联系管理员", ex);
    }
}

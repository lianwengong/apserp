package com.apserp.plat.meta;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.tenant.TenantContext;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
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

    public MetaSaveService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
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
        try {
            long id = jdbc.execute((ConnectionCallback<Long>) con -> callSave(con, tenantId, userId, objectCode, json));
            log.info("meta_save tenant={} object={} id={}", tenantId, objectCode, id);
            return id;
        } catch (org.springframework.dao.DataAccessException ex) {
            throw translate(objectCode, ex);
        }
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

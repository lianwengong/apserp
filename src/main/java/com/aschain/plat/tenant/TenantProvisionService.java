package com.aschain.plat.tenant;

import com.aschain.common.ApiException;
import com.aschain.common.ErrorCode;
import com.aschain.common.tenant.TenantContext;
import java.util.LinkedHashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/**
 * 租户开通：把模板租户的元数据克隆到新租户（调用 {@code plat.usp_Tenant_Provision}）。
 *
 * <p>权限：仅平台管理员可调用（JWT 中的 {@code adm} 声明）。</p>
 */
@Service
public class TenantProvisionService {

    private static final Logger log = LoggerFactory.getLogger(TenantProvisionService.class);

    private final JdbcTemplate jdbc;

    public TenantProvisionService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Map<String, Long> provision(int templateTenantId, int newTenantId) {
        // 开通租户是跨租户操作：必须来自平台登录（平台作用域），租户管理员不行
        if (!TenantContext.isPlatformAdmin() || !TenantContext.isPlatformScope()) {
            throw new ApiException(ErrorCode.FORBIDDEN, "只有平台管理员可以开通租户，请使用平台登录");
        }
        if (templateTenantId == newTenantId) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "模板租户与新租户不能相同");
        }
        try {
            Map<String, Long> result = jdbc.execute((ConnectionCallback<Map<String, Long>>) con -> {
                try (var cs = con.prepareCall("{call plat.usp_Tenant_Provision (?, ?)}")) {
                    cs.setInt(1, templateTenantId);
                    cs.setInt(2, newTenantId);
                    boolean hasResult = cs.execute();
                    Map<String, Long> counts = new LinkedHashMap<>();
                    if (hasResult) {
                        try (var rs = cs.getResultSet()) {
                            while (rs.next()) {
                                counts.put(rs.getString("TableName"), rs.getLong("Copied"));
                            }
                        }
                    }
                    return counts;
                }
            });
            log.info("tenant_provision template={} new={} result={}", templateTenantId, newTenantId, result);
            return result;
        } catch (org.springframework.dao.DataAccessException ex) {
            String msg = ex.getMessage() == null ? "" : ex.getMessage();
            if (msg.contains("禁止重复开通")) {
                throw new ApiException(ErrorCode.DUPLICATE_KEY, "该租户已开通元数据，不能重复执行", ex);
            }
            if (msg.contains("目标租户不存在")) {
                throw new ApiException(ErrorCode.NOT_FOUND, "目标租户不存在，请先创建租户", ex);
            }
            log.error("tenant_provision_failed template={} new={}", templateTenantId, newTenantId, ex);
            throw new ApiException(ErrorCode.INTERNAL, "开通失败，请联系管理员", ex);
        }
    }
}

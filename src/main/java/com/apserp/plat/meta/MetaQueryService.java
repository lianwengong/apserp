package com.apserp.plat.meta;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.tenant.TenantContext;
import com.apserp.common.tenant.TenantSession;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;

/**
 * 元数据驱动的列表查询：调用数据库引擎 plat.usp_Meta_List。
 * 业务代码不得绕过本服务直接写 SQL 查业务表。
 */
@Service
public class MetaQueryService {

    private final TenantSession tenantSession;

    public MetaQueryService(TenantSession tenantSession) {
        this.tenantSession = tenantSession;
    }

    public PageResult query(String objectCode, String filtersJson, String sort,
                            int page, int size) {
        int safePage = Math.max(page, 1);
        int safeSize = Math.min(Math.max(size, 1), 500);
        return tenantSession.execute(con -> {
            try (CallableStatement cs = con.prepareCall(
                    "{call plat.usp_Meta_List (?, ?, ?, ?, ?, ?, ?, ?)}")) {
                cs.setLong(1, TenantContext.requireTenantId());
                Long userId = TenantContext.userId();
                if (userId == null) {
                    cs.setNull(2, java.sql.Types.BIGINT);
                } else {
                    cs.setLong(2, userId);
                }
                cs.setString(3, objectCode);
                cs.setString(4, filtersJson);
                cs.setString(5, sort);
                cs.setInt(6, safePage);
                cs.setInt(7, safeSize);
                cs.registerOutParameter(8, java.sql.Types.INTEGER);

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
                int total = cs.getInt(8);
                return new PageResult(safePage, safeSize, total, rows);
            } catch (java.sql.SQLException ex) {
                throw new ApiException(ErrorCode.META_OBJECT_NOT_FOUND,
                        "查询失败：" + objectCode + "，" + ex.getMessage());
            }
        });
    }

    public record PageResult(int page, int size, int total, List<Map<String, Object>> rows) {
    }
}

package com.apserp.plat.meta;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
import org.springframework.stereotype.Component;

/**
 * 保存引擎的调用入口：只做一件事——把一段 JSON 交给 {@code plat.usp_Meta_Save}。
 *
 * <p>单独抽出来是因为主子表级联保存要「一次事务内多次调用」同一个过程：
 * 主表一次、每条子行一次。租户、审计、类型转换、必填校验全在过程里，
 * Java 侧不重复实现。</p>
 */
@Component
public class MetaSaveProc {

    /**
     * @return 新增或修改后的主键
     */
    public long call(Connection con, long tenantId, Long userId, String objectCode, String json)
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
}

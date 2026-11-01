package com.apserp.support;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * CI 集成测试的数据库准备：把 SA 连接指向的真实库改成测试库。
 *
 * <p>CI 用 service 容器启动 SQL Server（库还不存在）；本类先建库、再切库，
 * 之后 Spring 的 Flyway 在空库上重放全部迁移。本地没有 Docker 时不进入本流程。</p>
 */
public final class CiDb {

    private CiDb() {
    }

    /** 把 jdbc url 里的 databaseName 替换成指定库。 */
    public static String withDatabase(String url, String db) {
        return url.replaceAll("(?i)databaseName=[^;]+", "databaseName=" + db);
    }

    /** 用 SA 连接 master 建库（已存在则跳过）。 */
    public static void createDatabase(String saUrl, String user, String password, String db) throws SQLException {
        String master = withDatabase(saUrl, "master");
        try (Connection con = DriverManager.getConnection(master, user, password);
             Statement st = con.createStatement()) {
            st.execute("IF DB_ID(N'" + db + "') IS NULL CREATE DATABASE [" + db + "] COLLATE Chinese_PRC_CI_AS");
        }
    }

    /** 确保测试库存在并返回指向测试库的 url。 */
    public static String ensureDatabase(String saUrl, String user, String password, String db) throws SQLException {
        createDatabase(saUrl, user, password, db);
        return withDatabase(saUrl, db);
    }
}

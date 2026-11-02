package com.aschain.support;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * CI 用：在空的 SQL Server 上建出测试库。
 *
 * <p>CI 的 service 容器只有系统库，Flyway 不负责建库（见 V1 脚本说明），
 * 所以流水线在跑测试前先执行本类的 main：</p>
 *
 * <pre>
 * mvn -q exec:java -Dexec.classpathScope=test -Dexec.mainClass=com.aschain.support.CiDbInit
 * </pre>
 *
 * 依赖环境变量 {@code IT_DB_URL / IT_DB_USER / IT_DB_PASSWORD}。
 */
public final class CiDbInit {

    private CiDbInit() {
    }

    public static void main(String[] args) throws Exception {
        String url = System.getenv("IT_DB_URL");
        String user = System.getenv("IT_DB_USER");
        String password = System.getenv("IT_DB_PASSWORD");
        if (url == null || user == null || password == null) {
            throw new IllegalStateException("缺少 IT_DB_URL / IT_DB_USER / IT_DB_PASSWORD");
        }
        String db = extractDatabase(url);
        String master = CiDb.withDatabase(url, "master");
        try (Connection con = DriverManager.getConnection(master, user, password);
             Statement st = con.createStatement()) {
            st.execute("IF DB_ID(N'" + db + "') IS NULL CREATE DATABASE [" + db + "] COLLATE Chinese_PRC_CI_AS");
        }
        System.out.println("[CiDbInit] database ready: " + db);
    }

    /** 从 jdbc url 里取 databaseName，缺省 ASChain_TEST。 */
    public static String extractDatabase(String url) {
        var m = java.util.regex.Pattern.compile("(?i)databaseName=([^;]+)").matcher(url);
        return m.find() ? m.group(1) : "ASChain_TEST";
    }
}

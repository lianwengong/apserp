package com.apserp.support;

/**
 * 集成测试的连接参数读取：**禁止把口令写进源码**。
 *
 * <p>优先级：系统属性 → 环境变量 → 默认值（默认值只给 url/user，口令必须显式提供）。</p>
 *
 * <pre>
 * set IT_DB_PASSWORD=***
 * mvn test -Dit.db=true
 * </pre>
 */
public final class ItDb {

    public static final String DEV_URL =
            "jdbc:sqlserver://localhost:1433;databaseName=APSErpV3;encrypt=false;trustServerCertificate=true";
    public static final String TEST_URL =
            "jdbc:sqlserver://localhost:1433;databaseName=APSErpV3_TEST;encrypt=false;trustServerCertificate=true";

    private ItDb() {
    }

    public static boolean enabled() {
        return Boolean.parseBoolean(System.getProperty("it.db", env("IT_DB", "false")));
    }

    public static String url() {
        return first(System.getProperty("it.db.url"), env("IT_DB_URL", null), DEV_URL);
    }

    public static String testSchemaUrl() {
        return first(System.getProperty("it.schema.url"), env("IT_SCHEMA_URL", null), TEST_URL);
    }

    public static String user() {
        return first(System.getProperty("it.db.user"), env("IT_DB_USER", null), "apserp_dev");
    }

    public static String password() {
        String p = first(System.getProperty("it.db.password"), env("IT_DB_PASSWORD", null), null);
        if (p == null) {
            throw new IllegalStateException(
                    "未提供数据库口令：请设置环境变量 IT_DB_PASSWORD，或 -Dit.db.password=***");
        }
        return p;
    }

    private static String env(String key, String fallback) {
        String v = System.getenv(key);
        return v == null || v.isBlank() ? fallback : v;
    }

    private static String first(String a, String b, String fallback) {
        if (a != null && !a.isBlank()) {
            return a;
        }
        if (b != null && !b.isBlank()) {
            return b;
        }
        return fallback;
    }
}

package com.apserp.common.tenant;

/**
 * 请求级租户上下文。由 TenantFilter 写入、请求结束清理。
 * 注意：这只是线程内传递，数据库层的隔离靠 TenantSession 设置 SESSION_CONTEXT + RLS。
 */
public final class TenantContext {

    private static final ThreadLocal<Long> TENANT = new ThreadLocal<>();
    private static final ThreadLocal<Long> USER = new ThreadLocal<>();
    private static final ThreadLocal<Boolean> ADMIN = new ThreadLocal<>();

    private TenantContext() {
    }

    public static void set(Long tenantId, Long userId) {
        set(tenantId, userId, false);
    }

    public static void set(Long tenantId, Long userId, boolean platformAdmin) {
        TENANT.set(tenantId);
        USER.set(userId);
        ADMIN.set(platformAdmin);
    }

    /** 平台管理员标记：来自 JWT 的 adm 声明，用于租户开通等跨租户操作。 */
    public static boolean isPlatformAdmin() {
        return Boolean.TRUE.equals(ADMIN.get());
    }

    public static Long tenantId() {
        return TENANT.get();
    }

    public static Long userId() {
        return USER.get();
    }

    public static long requireTenantId() {
        Long id = TENANT.get();
        if (id == null) {
            throw new IllegalStateException("tenant context missing");
        }
        return id;
    }

    public static void clear() {
        TENANT.remove();
        USER.remove();
        ADMIN.remove();
    }
}

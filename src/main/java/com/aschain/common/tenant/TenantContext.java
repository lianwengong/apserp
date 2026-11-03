package com.aschain.common.tenant;

/**
 * 请求级租户上下文。由 TenantFilter 写入、请求结束清理。
 * 注意：这只是线程内传递，数据库层的隔离靠 TenantSession 设置 SESSION_CONTEXT + RLS。
 *
 * <p>除了租户与用户，还带一个「入口」：{@link #APP_PLATFORM}（平台管理）与
 * {@link #APP_BUSINESS}（业务管理）。同一个账号可能同时有平台与业务权限，
 * 但一次会话只在一个入口里工作（登录时选择），菜单树与首页都按它过滤。</p>
 */
public final class TenantContext {

    /** 平台管理入口 */
    public static final int APP_PLATFORM = 1;
    /** 业务管理入口 */
    public static final int APP_BUSINESS = 2;

    private static final ThreadLocal<Long> TENANT = new ThreadLocal<>();
    private static final ThreadLocal<Long> USER = new ThreadLocal<>();
    private static final ThreadLocal<Boolean> ADMIN = new ThreadLocal<>();
    private static final ThreadLocal<Integer> APP = new ThreadLocal<>();
    /** 平台作用域：跨租户读写（RLS 旁路）。只有平台登录换来的会话才有这个标记。 */
    private static final ThreadLocal<Boolean> PLATFORM_SCOPE = new ThreadLocal<>();

    private TenantContext() {
    }

    public static void set(Long tenantId, Long userId) {
        set(tenantId, userId, false);
    }

    public static void set(Long tenantId, Long userId, boolean platformAdmin) {
        set(tenantId, userId, platformAdmin, APP_BUSINESS);
    }

    public static void set(Long tenantId, Long userId, boolean platformAdmin, int appType) {
        set(tenantId, userId, platformAdmin, appType, false);
    }

    public static void set(Long tenantId, Long userId, boolean platformAdmin, int appType,
                           boolean platformScope) {
        TENANT.set(tenantId);
        USER.set(userId);
        ADMIN.set(platformAdmin);
        APP.set(appType);
        PLATFORM_SCOPE.set(platformScope);
    }

    /** 平台管理员标记：来自 JWT 的 adm 声明，用于租户开通等跨租户操作。 */
    public static boolean isPlatformAdmin() {
        return Boolean.TRUE.equals(ADMIN.get());
    }

    /** 平台作用域：为真时数据源把 BypassRls 置 1，可跨租户读写。 */
    public static boolean isPlatformScope() {
        return Boolean.TRUE.equals(PLATFORM_SCOPE.get());
    }

    /** 当前会话的入口：未设置时按业务管理处理（兼容定时任务与直接调用服务的测试）。 */
    public static int appType() {
        Integer app = APP.get();
        return app == null ? APP_BUSINESS : app;
    }

    public static boolean isPlatformApp() {
        return appType() == APP_PLATFORM;
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
        APP.remove();
        PLATFORM_SCOPE.remove();
    }
}

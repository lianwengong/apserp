package com.aschain.plat.auth;

import com.aschain.common.ApiException;
import com.aschain.common.ErrorCode;
import com.aschain.common.security.JwtService;
import com.aschain.common.security.PasswordHasher;
import com.aschain.common.tenant.TenantContext;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/**
 * 登录认证。
 *
 * <p>关键点：登录时还不知道租户，而 {@code plat.User} 受 RLS 保护。
 * 所以必须先按租户编码解析租户（{@code plat.Tenant} 不在 RLS 范围内），
 * 写入上下文后再查用户——否则永远查不到人。</p>
 *
 * <p>失败处理：连续 5 次失败锁定 15 分钟；成功登录清零。错误信息统一为
 * "租户或账号或口令不正确"，不区分哪一项错，避免账号枚举。</p>
 */
@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private static final int MAX_FAIL = 5;
    private static final int LOCK_MINUTES = 15;

    /**
     * 租户登录按「租户名称或编码」解析：用户填的是名字（例如「示例商贸有限公司」），
     * 老脚本与文档里用的是编码（T001），两者都认。同名租户由唯一约束挡住。
     */
    private static final String SQL_TENANT =
            "SELECT Id, IsEnabled FROM plat.Tenant "
            + "WHERE (Code = ? OR Name = ?) AND IsDeleted = 0";

    private static final String SQL_USER = """
            SELECT u.Id, u.UserName, u.PasswordHash, u.PasswordSalt, u.DisplayName,
                   u.IsEnabled, u.LockedUntil, u.MustChangePwd, u.TenantId,
                   u.IsPlatformAccount,
                   -- 注意：RoleType=1 只是"内部角色"（仓管/采购/财务都是 1），
                   -- 平台管理员必须按角色编码 SYSADMIN 判定，否则所有人都会拿到 adm=true
                   CASE WHEN u.UserType = 1 AND EXISTS (
                       SELECT 1 FROM plat.UserRole ur
                       JOIN plat.Role r ON r.Id = ur.RoleId
                       WHERE ur.UserId = u.Id AND r.Code = 'SYSADMIN' AND r.IsEnabled = 1
                   ) THEN 1 ELSE 0 END AS IsAdmin
            FROM plat.[User] u
            WHERE u.TenantId = ? AND u.UserName = ? AND u.IsDeleted = 0
            """;

    /** 已登录用户按 Id 取自己（改口令用；租户由令牌上下文带入，走 RLS）。 */
    private static final String SQL_USER_BY_ID = """
            SELECT u.Id, u.UserName, u.PasswordHash, u.PasswordSalt, u.DisplayName,
                   u.IsEnabled, u.LockedUntil, u.MustChangePwd, u.TenantId,
                   u.IsPlatformAccount,
                   CASE WHEN u.UserType = 1 AND EXISTS (
                       SELECT 1 FROM plat.UserRole ur
                       JOIN plat.Role r ON r.Id = ur.RoleId
                       WHERE ur.UserId = u.Id AND r.Code = 'SYSADMIN' AND r.IsEnabled = 1
                   ) THEN 1 ELSE 0 END AS IsAdmin
            FROM plat.[User] u
            WHERE u.Id = ? AND u.IsDeleted = 0
            """;

    /**
     * 平台登录：没有租户名，按「平台账号」标记跨租户找人。
     * 运行时依赖平台作用域把 RLS 放开，否则 plat.User 是 fail-closed 空的。
     */
    private static final String SQL_PLATFORM_USER = """
            SELECT u.Id, u.UserName, u.PasswordHash, u.PasswordSalt, u.DisplayName,
                   u.IsEnabled, u.LockedUntil, u.MustChangePwd, u.TenantId,
                   u.IsPlatformAccount, 1 AS IsAdmin
            FROM plat.[User] u
            WHERE u.IsPlatformAccount = 1 AND u.UserName = ? AND u.IsDeleted = 0
            """;

    private static final String SQL_FAIL =
            "UPDATE plat.[User] SET FailCount = FailCount + 1, "
            + "LockedUntil = CASE WHEN FailCount + 1 >= ? "
            + "THEN DATEADD(MINUTE, ?, sysutcdatetime()) ELSE LockedUntil END "
            + "WHERE Id = ?";

    private static final String SQL_CHANGE_PWD =
            "UPDATE plat.[User] SET PasswordHash = ?, PasswordSalt = ?, PasswordUpdatedAt = sysutcdatetime(), "
            + "MustChangePwd = 0, FailCount = 0, LockedUntil = NULL WHERE Id = ?";

    private static final String SQL_OK =
            "UPDATE plat.[User] SET FailCount = 0, LockedUntil = NULL, "
            + "LastLoginAt = sysutcdatetime() WHERE Id = ?";

    private final JdbcTemplate jdbc;
    private final PasswordHasher hasher;
    private final JwtService jwtService;

    public AuthService(JdbcTemplate jdbc, PasswordHasher hasher, JwtService jwtService) {
        this.jdbc = jdbc;
        this.hasher = hasher;
        this.jwtService = jwtService;
    }

    public record LoginResult(String token, long userId, int tenantId, String displayName,
                              boolean mustChangePassword, int appType) {
    }

    private record UserRow(long id, long tenantId, String userName, String hash, String salt,
                           String displayName, boolean enabled, LocalDateTime lockedUntil,
                           boolean mustChange, boolean admin, boolean platformAccount) {
    }

    /**
     * 老签名：默认走业务管理入口（兼容既有调用与测试）。
     */
    public LoginResult login(String tenantCode, String userName, String rawPassword) {
        return login(tenantCode, userName, rawPassword, TenantContext.APP_BUSINESS);
    }

    /**
     * 平台登录：<b>没有租户名</b>，只凭平台账号（{@code plat.User.IsPlatformAccount=1}）登录，
     * 拿到的是平台作用域令牌——可以管理所有租户。
     *
     * <p>为什么不能复用租户登录：{@code plat.User} 受 RLS 保护，没有租户上下文时是空集；
     * 这里先把平台作用域打开（BypassRls=1），跨租户按用户名找平台账号，校验后再签发令牌。
     * 令牌里带 {@code pf=true}，{@code JwtAuthFilter} 会把它还原成平台作用域。</p>
     */
    public LoginResult loginPlatform(String userName, String rawPassword) {
        if (userName == null || rawPassword == null) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "账号、口令不能为空");
        }
        TenantContext.set(null, null, true, TenantContext.APP_PLATFORM, true);
        try {
            List<UserRow> rows = jdbc.query(SQL_PLATFORM_USER,
                    (rs, i) -> mapUser(rs),
                    userName);
            if (rows.isEmpty()) {
                throw new ApiException(ErrorCode.UNAUTHORIZED, "平台账号或口令不正确");
            }
            UserRow user = rows.get(0);
            if (!user.enabled()) {
                throw new ApiException(ErrorCode.FORBIDDEN, "账号已停用");
            }
            if (user.lockedUntil() != null && user.lockedUntil().isAfter(LocalDateTime.now())) {
                throw new ApiException(ErrorCode.FORBIDDEN, "账号已锁定，请稍后再试");
            }
            if (!hasher.matches(rawPassword, user.hash(), user.salt())) {
                recordFailure(user.id());
                throw new ApiException(ErrorCode.UNAUTHORIZED, "平台账号或口令不正确");
            }
            recordSuccess(user.id());
            String token = jwtService.issue(user.id(), (int) user.tenantId(), user.userName(),
                    true, user.mustChange(), TenantContext.APP_PLATFORM, true);
            log.info("platform_login_ok homeTenant={} user={}", user.tenantId(), user.userName());
            return new LoginResult(token, user.id(), (int) user.tenantId(), user.displayName(),
                    user.mustChange(), TenantContext.APP_PLATFORM);
        } finally {
            TenantContext.clear();
        }
    }

    /**
     * 注意：这里**不能**加 {@code @Transactional}。事务会在方法体执行前就取走连接，
     * 那时租户上下文还没设置，RLS 会把用户表挡住，导致永远登录失败。
     * 因此改为自动提交、逐语句执行（失败计数与登录时间都是单语句更新）。
     *
     * @param appType 入口：1 平台管理 / 2 业务管理。平台入口要求账号具备平台管理能力
     *                （SYSADMIN 角色标记或任一 DESIGN: 权限），否则拒绝登录该入口。
     */
    public LoginResult login(String tenantCode, String userName, String rawPassword, int appType) {
        if (tenantCode == null || userName == null || rawPassword == null) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "租户、账号、口令不能为空");
        }
        if (appType != TenantContext.APP_PLATFORM && appType != TenantContext.APP_BUSINESS) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "入口只能是 1（平台管理）或 2（业务管理）");
        }

        List<Map<String, Object>> tenants = jdbc.queryForList(SQL_TENANT, tenantCode, tenantCode);
        if (tenants.isEmpty()) {
            throw new ApiException(ErrorCode.UNAUTHORIZED, "租户或账号或口令不正确");
        }
        int tenantId = ((Number) tenants.get(0).get("Id")).intValue();
        if (!Boolean.TRUE.equals(tenants.get(0).get("IsEnabled"))) {
            throw new ApiException(ErrorCode.FORBIDDEN, "租户已停用");
        }

        // 写入上下文后，后续查询才会被 RLS 放行
        TenantContext.set((long) tenantId, null, false, appType);
        try {
            UserRow user = findUser(tenantId, userName);
            if (user == null) {
                throw new ApiException(ErrorCode.UNAUTHORIZED, "租户或账号或口令不正确");
            }
            if (!user.enabled()) {
                throw new ApiException(ErrorCode.FORBIDDEN, "账号已停用");
            }
            if (user.lockedUntil() != null && user.lockedUntil().isAfter(LocalDateTime.now())) {
                throw new ApiException(ErrorCode.FORBIDDEN, "账号已锁定，请稍后再试");
            }
            if (!hasher.matches(rawPassword, user.hash(), user.salt())) {
                recordFailure(user.id());
                throw new ApiException(ErrorCode.UNAUTHORIZED, "租户或账号或口令不正确");
            }
            if (appType == TenantContext.APP_PLATFORM && !canUsePlatformApp(user.id(), user.admin())) {
                throw new ApiException(ErrorCode.FORBIDDEN,
                        "该账号没有平台管理入口权限，请从业务管理入口登录");
            }
            recordSuccess(user.id());
            String token = jwtService.issue(user.id(), tenantId, user.userName(), user.admin(),
                    user.mustChange(), appType);
            log.info("login_ok tenant={} user={} app={}", tenantId, user.userName(), appType);
            return new LoginResult(token, user.id(), tenantId, user.displayName(), user.mustChange(),
                    appType);
        } finally {
            TenantContext.clear();
        }
    }

    /**
     * 平台入口准入：SYSADMIN（user.admin）或持有任一 DESIGN: 权限点。
     * 业务入口对通过认证的账号一律开放（业务菜单本身还会按权限过滤）。
     */
    private boolean canUsePlatformApp(long userId, boolean admin) {
        if (admin) {
            return true;
        }
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.vw_Perm_UserFunction
                WHERE UserId = ? AND ResourceKey LIKE 'DESIGN:%'
                """, Integer.class, userId);
        return count != null && count > 0;
    }

    /**
     * 修改口令（首次登录强制走这里）。
     *
     * <p>规则：新旧口令不能相同、长度 8-64、必须同时包含字母与数字。</p>
     */
    public LoginResult changePassword(String tenantCode, String userName, String oldPassword,
                                      String newPassword) {
        return changePassword(tenantCode, userName, oldPassword, newPassword,
                TenantContext.APP_BUSINESS);
    }

    public LoginResult changePassword(String tenantCode, String userName, String oldPassword,
                                      String newPassword, int appType) {
        validatePasswordPolicy(newPassword);
        if (oldPassword != null && oldPassword.equals(newPassword)) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "新口令不能与旧口令相同");
        }
        LoginResult login = login(tenantCode, userName, oldPassword, appType);
        TenantContext.set((long) login.tenantId(), login.userId(), false, appType);
        try {
            String salt = hasher.newSalt();
            String hash = hasher.hash(newPassword, salt);
            jdbc.update(SQL_CHANGE_PWD, hash, salt, login.userId());
            log.info("password_changed tenant={} user={}", login.tenantId(), userName);
        } finally {
            TenantContext.clear();
        }
        // 旧令牌仍带 mpwd=true，必须换发
        return login(tenantCode, userName, newPassword, appType);
    }

    /**
     * 已登录用户改口令：不依赖租户名/用户名，直接用令牌里的上下文。
     *
     * <p>首次登录未改密时，拦截器只放行这一个入口（{@code /api/me/password}），
     * 所以它必须在「没有租户名」的情况下也能工作——平台账号同样适用。</p>
     */
    public LoginResult changePasswordForCurrentUser(String oldPassword, String newPassword) {
        Long tenantId = TenantContext.tenantId();
        Long userId = TenantContext.userId();
        if (tenantId == null || userId == null) {
            throw new ApiException(ErrorCode.UNAUTHORIZED, "未登录或登录已失效");
        }
        validatePasswordPolicy(newPassword);
        if (oldPassword == null || oldPassword.equals(newPassword)) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "新口令不能与旧口令相同");
        }
        List<UserRow> rows = jdbc.query(SQL_USER_BY_ID, (rs, i) -> mapUser(rs), userId);
        if (rows.isEmpty()) {
            throw new ApiException(ErrorCode.UNAUTHORIZED, "账号不存在");
        }
        UserRow user = rows.get(0);
        if (!hasher.matches(oldPassword, user.hash(), user.salt())) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "原口令不正确");
        }
        String salt = hasher.newSalt();
        String hash = hasher.hash(newPassword, salt);
        jdbc.update(SQL_CHANGE_PWD, hash, salt, userId);
        log.info("password_changed_self tenant={} user={}", tenantId, user.userName());
        // 换发令牌：旧令牌仍带 mpwd=true，会一直被拦截器挡住
        String token = jwtService.issue(user.id(), tenantId.intValue(), user.userName(),
                user.admin(), false, TenantContext.appType(), TenantContext.isPlatformScope());
        return new LoginResult(token, user.id(), tenantId.intValue(), user.displayName(),
                false, TenantContext.appType());
    }

    static void validatePasswordPolicy(String raw) {
        if (raw == null || raw.length() < 8 || raw.length() > 64) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "口令长度必须为 8-64 位");
        }
        boolean hasLetter = raw.chars().anyMatch(Character::isLetter);
        boolean hasDigit = raw.chars().anyMatch(Character::isDigit);
        if (!hasLetter || !hasDigit) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "口令必须同时包含字母与数字");
        }
    }

    private UserRow findUser(int tenantId, String userName) {
        List<UserRow> rows = jdbc.query(SQL_USER, (rs, i) -> mapUser(rs), tenantId, userName);
        return rows.isEmpty() ? null : rows.get(0);
    }

    private static UserRow mapUser(java.sql.ResultSet rs) throws java.sql.SQLException {
        return new UserRow(rs.getLong("Id"), rs.getLong("TenantId"), rs.getString("UserName"),
                rs.getString("PasswordHash"), rs.getString("PasswordSalt"),
                rs.getString("DisplayName"), rs.getBoolean("IsEnabled"),
                rs.getObject("LockedUntil", LocalDateTime.class),
                rs.getBoolean("MustChangePwd"), rs.getInt("IsAdmin") == 1,
                rs.getBoolean("IsPlatformAccount"));
    }

    private void recordFailure(long userId) {
        jdbc.update(SQL_FAIL, MAX_FAIL, LOCK_MINUTES, userId);
    }

    private void recordSuccess(long userId) {
        jdbc.update(SQL_OK, userId);
    }
}

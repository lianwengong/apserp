package com.apserp.plat.auth;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.security.JwtService;
import com.apserp.common.security.PasswordHasher;
import com.apserp.common.tenant.TenantContext;
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

    private static final String SQL_TENANT =
            "SELECT Id, IsEnabled FROM plat.Tenant WHERE Code = ? AND IsDeleted = 0";

    private static final String SQL_USER = """
            SELECT u.Id, u.UserName, u.PasswordHash, u.PasswordSalt, u.DisplayName,
                   u.IsEnabled, u.LockedUntil, u.MustChangePwd,
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

    private static final String SQL_FAIL =
            "UPDATE plat.[User] SET FailCount = FailCount + 1, "
            + "LockedUntil = CASE WHEN FailCount + 1 >= ? "
            + "THEN DATEADD(MINUTE, ?, sysutcdatetime()) ELSE LockedUntil END "
            + "WHERE Id = ?";

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
                              boolean mustChangePassword) {
    }

    private record UserRow(long id, String userName, String hash, String salt, String displayName,
                           boolean enabled, LocalDateTime lockedUntil, boolean mustChange,
                           boolean admin) {
    }

    /**
     * 注意：这里**不能**加 {@code @Transactional}。事务会在方法体执行前就取走连接，
     * 那时租户上下文还没设置，RLS 会把用户表挡住，导致永远登录失败。
     * 因此改为自动提交、逐语句执行（失败计数与登录时间都是单语句更新）。
     */
    public LoginResult login(String tenantCode, String userName, String rawPassword) {
        if (tenantCode == null || userName == null || rawPassword == null) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "租户、账号、口令不能为空");
        }

        List<Map<String, Object>> tenants = jdbc.queryForList(SQL_TENANT, tenantCode);
        if (tenants.isEmpty()) {
            throw new ApiException(ErrorCode.UNAUTHORIZED, "租户或账号或口令不正确");
        }
        int tenantId = ((Number) tenants.get(0).get("Id")).intValue();
        if (!Boolean.TRUE.equals(tenants.get(0).get("IsEnabled"))) {
            throw new ApiException(ErrorCode.FORBIDDEN, "租户已停用");
        }

        // 写入上下文后，后续查询才会被 RLS 放行
        TenantContext.set((long) tenantId, null, false);
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
            recordSuccess(user.id());
            String token = jwtService.issue(user.id(), tenantId, user.userName(), user.admin());
            log.info("login_ok tenant={} user={}", tenantId, user.userName());
            return new LoginResult(token, user.id(), tenantId, user.displayName(), user.mustChange());
        } finally {
            TenantContext.clear();
        }
    }

    private UserRow findUser(int tenantId, String userName) {
        List<UserRow> rows = jdbc.query(SQL_USER,
                (rs, i) -> new UserRow(rs.getLong("Id"), rs.getString("UserName"),
                        rs.getString("PasswordHash"), rs.getString("PasswordSalt"),
                        rs.getString("DisplayName"), rs.getBoolean("IsEnabled"),
                        rs.getObject("LockedUntil", LocalDateTime.class),
                        rs.getBoolean("MustChangePwd"), rs.getInt("IsAdmin") == 1),
                tenantId, userName);
        return rows.isEmpty() ? null : rows.get(0);
    }

    private void recordFailure(long userId) {
        jdbc.update(SQL_FAIL, MAX_FAIL, LOCK_MINUTES, userId);
    }

    private void recordSuccess(long userId) {
        jdbc.update(SQL_OK, userId);
    }
}

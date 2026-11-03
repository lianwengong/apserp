package com.aschain.plat.admin;

import com.aschain.common.ApiException;
import com.aschain.common.ErrorCode;
import com.aschain.common.security.PasswordHasher;
import com.aschain.common.tenant.TenantContext;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 平台管理（平台管理员视角）：跨租户的登录用户与权限。
 *
 * <p>与租户内的"用户管理"不同：这里不受租户上下文限制，能看/改所有租户的账号，
 * 因此准入必须同时满足 {@code platformScope}（平台登录换来的会话）。</p>
 */
@Service
public class PlatformUserService {

    private static final Logger log = LoggerFactory.getLogger(PlatformUserService.class);

    private final JdbcTemplate jdbc;
    private final PasswordHasher hasher;

    public PlatformUserService(JdbcTemplate jdbc, PasswordHasher hasher) {
        this.jdbc = jdbc;
        this.hasher = hasher;
    }

    public record UserRow(long id, long tenantId, String tenantCode, String userName,
                          String displayName, String mobile, String email, boolean enabled,
                          boolean mustChangePwd, boolean locked, boolean platformAccount,
                          LocalDateTime lastLoginAt, List<String> roles) {
    }

    public record PageResult(List<UserRow> items, long total) {
    }

    public record RoleDto(long id, long tenantId, String code, String name, boolean enabled) {
    }

    public PageResult list(String keyword, Long tenantId, int page, int size) {
        requirePlatformScope();
        String like = keyword == null || keyword.isBlank() ? null : "%" + keyword.trim() + "%";
        int pageSize = size < 1 || size > 200 ? 20 : size;
        int offset = Math.max(0, (Math.max(1, page) - 1) * pageSize);

        String where = """
                WHERE u.IsDeleted = 0
                  AND (? IS NULL OR u.UserName LIKE ? OR u.DisplayName LIKE ? OR u.Mobile LIKE ?)
                  AND (? IS NULL OR u.TenantId = ?)
                """;
        Object[] args = {like, like, like, like, tenantId, tenantId};

        Long total = jdbc.queryForObject(
                "SELECT COUNT(*) FROM plat.[User] u " + where, Long.class, args);
        List<UserRow> items = jdbc.query("""
                SELECT u.Id, u.TenantId, t.Code AS TenantCode, u.UserName, u.DisplayName,
                       u.Mobile, u.Email, u.IsEnabled, u.MustChangePwd, u.LockedUntil,
                       u.IsPlatformAccount, u.LastLoginAt
                FROM plat.[User] u
                LEFT JOIN plat.Tenant t ON t.Id = u.TenantId
                """ + where + """
                ORDER BY u.TenantId, u.Id
                OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
                """,
                userMapper(), like, like, like, like, tenantId, tenantId, offset, pageSize);
        items.forEach(row -> row.roles().addAll(roleCodes(row.id())));
        return new PageResult(items, total == null ? 0 : total);
    }

    /** 租户下的角色，供前端「分配角色」下拉。 */
    public List<RoleDto> roles(long tenantId) {
        requirePlatformScope();
        return jdbc.query("""
                SELECT Id, TenantId, Code, Name, IsEnabled FROM plat.Role
                WHERE TenantId = ? AND IsDeleted = 0 ORDER BY Code
                """,
                (rs, i) -> new RoleDto(rs.getLong("Id"), rs.getLong("TenantId"),
                        rs.getString("Code"), rs.getString("Name"), rs.getBoolean("IsEnabled")),
                tenantId);
    }

    @Transactional
    public void setEnabled(long userId, boolean enabled) {
        requirePlatformScope();
        Map<String, Object> user = requireUser(userId);
        checkNotSelf(userId, "不能停用自己的账号");
        if (!enabled && Boolean.TRUE.equals(user.get("IsPlatformAccount"))) {
            // 停用最后一个可用的平台账号会让平台入口无人能登
            Integer others = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM plat.[User]
                    WHERE IsPlatformAccount = 1 AND IsDeleted = 0 AND IsEnabled = 1 AND Id <> ?
                    """, Integer.class, userId);
            if (others != null && others == 0) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "至少要保留一个可用的平台账号");
            }
        }
        jdbc.update("UPDATE plat.[User] SET IsEnabled = ?, ModifiedAt = sysutcdatetime() WHERE Id = ?",
                enabled, userId);
        log.info("platform_user_enabled user={} enabled={}", userId, enabled);
    }

    /**
     * 重置口令：管理员给用户设一个新口令，并强制对方下次登录改密；
     * 同时清失败计数与锁定，避免「改了密码还是登不进」。
     */
    @Transactional
    public void resetPassword(long userId, String newPassword) {
        requirePlatformScope();
        requireUser(userId);
        validatePassword(newPassword);
        String salt = hasher.newSalt();
        String hash = hasher.hash(newPassword, salt);
        jdbc.update("""
                UPDATE plat.[User]
                SET PasswordHash = ?, PasswordSalt = ?, PasswordUpdatedAt = sysutcdatetime(),
                    MustChangePwd = 1, FailCount = 0, LockedUntil = NULL, ModifiedAt = sysutcdatetime()
                WHERE Id = ?
                """, hash, salt, userId);
        log.info("platform_user_password_reset user={}", userId);
    }

    /** 覆盖式分配角色：必须是同一租户的角色。 */
    @Transactional
    public void setRoles(long userId, List<Long> roleIds) {
        requirePlatformScope();
        Map<String, Object> user = requireUser(userId);
        long tenantId = ((Number) user.get("TenantId")).longValue();
        checkNotSelf(userId, "不能修改自己的角色，请让另一个平台管理员操作");

        List<Long> wanted = roleIds == null ? List.of() : new ArrayList<>(roleIds);
        if (!wanted.isEmpty()) {
            String in = String.join(",", wanted.stream().map(id -> "?").toList());
            List<Object> args = new ArrayList<>();
            args.add(tenantId);
            args.addAll(wanted);
            Integer found = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM plat.Role WHERE TenantId = ? AND IsDeleted = 0 AND Id IN (" + in + ")",
                    Integer.class, args.toArray());
            if (found == null || found != wanted.size()) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "角色不属于该用户所在租户");
            }
        }
        jdbc.update("DELETE FROM plat.UserRole WHERE UserId = ? AND TenantId = ?", userId, tenantId);
        for (Long roleId : wanted) {
            jdbc.update("INSERT plat.UserRole (TenantId, UserId, RoleId) VALUES (?, ?, ?)",
                    tenantId, userId, roleId);
        }
        log.info("platform_user_roles user={} roles={}", userId, wanted);
    }

    private List<String> roleCodes(long userId) {
        return jdbc.queryForList("""
                SELECT r.Code FROM plat.UserRole ur JOIN plat.Role r ON r.Id = ur.RoleId
                WHERE ur.UserId = ? AND r.IsDeleted = 0
                """, String.class, userId);
    }

    private Map<String, Object> requireUser(long userId) {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT Id, TenantId, UserName, IsPlatformAccount FROM plat.[User] WHERE Id = ? AND IsDeleted = 0",
                userId);
        if (rows.isEmpty()) {
            throw new ApiException(ErrorCode.NOT_FOUND, "用户不存在");
        }
        return rows.get(0);
    }

    private void checkNotSelf(long userId, String message) {
        Long self = TenantContext.userId();
        if (self != null && self == userId) {
            throw new ApiException(ErrorCode.BAD_REQUEST, message);
        }
    }

    private static void validatePassword(String raw) {
        if (raw == null || raw.length() < 8 || raw.length() > 64) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "口令长度必须为 8-64 位");
        }
        boolean hasLetter = raw.chars().anyMatch(Character::isLetter);
        boolean hasDigit = raw.chars().anyMatch(Character::isDigit);
        if (!hasLetter || !hasDigit) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "口令必须同时包含字母与数字");
        }
    }

    private static RowMapper<UserRow> userMapper() {
        return (rs, i) -> new UserRow(
                rs.getLong("Id"),
                rs.getLong("TenantId"),
                rs.getString("TenantCode"),
                rs.getString("UserName"),
                rs.getString("DisplayName"),
                rs.getString("Mobile"),
                rs.getString("Email"),
                rs.getBoolean("IsEnabled"),
                rs.getBoolean("MustChangePwd"),
                rs.getObject("LockedUntil", LocalDateTime.class) != null,
                rs.getBoolean("IsPlatformAccount"),
                rs.getObject("LastLoginAt", LocalDateTime.class),
                new ArrayList<>());
    }

    private void requirePlatformScope() {
        if (!TenantContext.isPlatformAdmin() || !TenantContext.isPlatformScope()) {
            throw new ApiException(ErrorCode.FORBIDDEN,
                    "仅平台管理员可管理跨租户用户，请使用平台登录");
        }
    }
}

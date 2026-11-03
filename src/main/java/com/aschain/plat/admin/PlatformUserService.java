package com.aschain.plat.admin;

import com.aschain.common.ApiException;
import com.aschain.common.ErrorCode;
import com.aschain.common.security.PasswordHasher;
import com.aschain.common.tenant.TenantContext;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 平台管理（平台管理员视角）：<b>只管平台账号</b>。
 *
 * <p>平台账号与业务租户解绑，统一挂在保留租户 {@code Id=0/T000 平台运营} 下、
 * 带 {@code IsPlatformAccount=1}。租户里的账号属于租户自己的用户管理，
 * 不在这里出现——否则「平台用户管理」和「租户用户管理」两个概念又会混在一起。</p>
 */
@Service
public class PlatformUserService {

    private static final Logger log = LoggerFactory.getLogger(PlatformUserService.class);

    /** 平台账号固定挂在这个保留租户下（见 V55） */
    private static final long PLATFORM_TENANT_ID = 0L;

    private final JdbcTemplate jdbc;
    private final PasswordHasher hasher;

    public PlatformUserService(JdbcTemplate jdbc, PasswordHasher hasher) {
        this.jdbc = jdbc;
        this.hasher = hasher;
    }

    public record UserRow(long id, String userName, String displayName, String mobile, String email,
                          boolean enabled, boolean mustChangePwd, boolean locked,
                          LocalDateTime lastLoginAt) {
    }

    public record CreateRequest(String userName, String displayName, String password) {
    }

    public UserRow create(CreateRequest req) {
        requirePlatformScope();
        String userName = req.userName() == null ? "" : req.userName().trim();
        String displayName = req.displayName() == null ? "" : req.displayName().trim();
        if (!userName.matches("^[A-Za-z][A-Za-z0-9_.-]{1,49}$")) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                    "平台账号只能是字母开头的 2-50 位字母/数字/下划线/点/短横线");
        }
        if (displayName.isEmpty()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "显示名称不能为空");
        }
        validatePassword(req.password());
        Integer dup = jdbc.queryForObject(
                "SELECT COUNT(*) FROM plat.[User] WHERE IsPlatformAccount = 1 AND UserName = ? AND IsDeleted = 0",
                Integer.class, userName);
        if (dup != null && dup > 0) {
            throw new ApiException(ErrorCode.DUPLICATE_KEY, "平台账号已存在：" + userName);
        }
        String salt = hasher.newSalt();
        String hash = hasher.hash(req.password(), salt);
        jdbc.update("""
                INSERT plat.[User] (TenantId, UserName, PasswordHash, PasswordSalt, DisplayName,
                                    UserType, IsEnabled, MustChangePwd, FailCount, IsPlatformAccount,
                                    IsDeleted, CreatedAt)
                VALUES (?, ?, ?, ?, ?, 1, 1, 1, 0, 1, 0, sysutcdatetime())
                """, PLATFORM_TENANT_ID, userName, hash, salt, displayName);
        log.info("platform_account_created userName={}", userName);
        Long id = jdbc.queryForObject(
                "SELECT Id FROM plat.[User] WHERE IsPlatformAccount = 1 AND UserName = ? AND IsDeleted = 0",
                Long.class, userName);
        return findById(id == null ? 0L : id);
    }

    /** 平台账号列表（只含 {@code IsPlatformAccount=1}）。 */
    public List<UserRow> list(String keyword) {
        requirePlatformScope();
        String like = keyword == null || keyword.isBlank() ? null : "%" + keyword.trim() + "%";
        return jdbc.query("""
                SELECT Id, UserName, DisplayName, Mobile, Email, IsEnabled, MustChangePwd,
                       LockedUntil, LastLoginAt
                FROM plat.[User]
                WHERE IsPlatformAccount = 1 AND IsDeleted = 0
                  AND (? IS NULL OR UserName LIKE ? OR DisplayName LIKE ?)
                ORDER BY Id
                """, mapper(), like, like, like);
    }

    @Transactional
    public void setEnabled(long userId, boolean enabled) {
        requirePlatformScope();
        requirePlatformAccount(userId);
        if (!enabled) {
            Long self = TenantContext.userId();
            if (self != null && self == userId) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "不能停用自己的账号");
            }
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
        log.info("platform_account_enabled user={} enabled={}", userId, enabled);
    }

    /** 重置平台账号口令：强制下次登录改密，并清失败计数与锁定。 */
    @Transactional
    public String resetPassword(long userId, String newPassword) {
        requirePlatformScope();
        Map<String, Object> user = requirePlatformAccount(userId);
        validatePassword(newPassword);
        String salt = hasher.newSalt();
        String hash = hasher.hash(newPassword, salt);
        jdbc.update("""
                UPDATE plat.[User]
                SET PasswordHash = ?, PasswordSalt = ?, PasswordUpdatedAt = sysutcdatetime(),
                    MustChangePwd = 1, FailCount = 0, LockedUntil = NULL, ModifiedAt = sysutcdatetime()
                WHERE Id = ?
                """, hash, salt, userId);
        log.info("platform_account_password_reset user={}", userId);
        return String.valueOf(user.get("UserName"));
    }

    private UserRow findById(long userId) {
        List<UserRow> rows = jdbc.query("""
                SELECT Id, UserName, DisplayName, Mobile, Email, IsEnabled, MustChangePwd,
                       LockedUntil, LastLoginAt
                FROM plat.[User] WHERE Id = ? AND IsDeleted = 0
                """, mapper(), userId);
        if (rows.isEmpty()) {
            throw new ApiException(ErrorCode.NOT_FOUND, "账号不存在");
        }
        return rows.get(0);
    }

    /** 只允许操作平台账号：租户账号请到对应租户的用户管理里维护。 */
    private Map<String, Object> requirePlatformAccount(long userId) {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT Id, UserName, IsPlatformAccount FROM plat.[User] WHERE Id = ? AND IsDeleted = 0",
                userId);
        if (rows.isEmpty()) {
            throw new ApiException(ErrorCode.NOT_FOUND, "账号不存在");
        }
        if (!Boolean.TRUE.equals(rows.get(0).get("IsPlatformAccount"))) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                    "该账号属于业务租户，请到租户自己的用户管理里维护");
        }
        return rows.get(0);
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

    private static RowMapper<UserRow> mapper() {
        return (rs, i) -> new UserRow(
                rs.getLong("Id"),
                rs.getString("UserName"),
                rs.getString("DisplayName"),
                rs.getString("Mobile"),
                rs.getString("Email"),
                rs.getBoolean("IsEnabled"),
                rs.getBoolean("MustChangePwd"),
                rs.getObject("LockedUntil", LocalDateTime.class) != null,
                rs.getObject("LastLoginAt", LocalDateTime.class));
    }

    private void requirePlatformScope() {
        if (!TenantContext.isPlatformAdmin() || !TenantContext.isPlatformScope()) {
            throw new ApiException(ErrorCode.FORBIDDEN,
                    "仅平台管理员可管理平台账号，请使用平台登录");
        }
    }
}

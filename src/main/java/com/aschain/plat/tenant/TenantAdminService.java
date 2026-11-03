package com.aschain.plat.tenant;

import com.aschain.common.ApiException;
import com.aschain.common.ErrorCode;
import com.aschain.common.security.PasswordHasher;
import com.aschain.common.tenant.TenantContext;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 租户生命周期：开通（建租户 + 克隆元数据 + 建管理员）与停用/启用。
 *
 * <p>两个动作都要求平台登录换来的会话（{@code isPlatformScope()}）：
 * 租户管理员不能给自己开新租户，也不能停用别人的租户。</p>
 *
 * <p>「停用」只置 {@code plat.Tenant.IsEnabled=0}，不动数据：停用后该租户的登录
 * 立刻被拒（AuthService 会返回「租户已停用」），重新启用即可恢复，属于可逆操作。</p>
 */
@Service
public class TenantAdminService {

    private static final Logger log = LoggerFactory.getLogger(TenantAdminService.class);

    /** 租户编码：大写字母/数字/下划线，2-20 位，作为库内唯一标识 */
    private static final Pattern CODE = Pattern.compile("^[A-Za-z][A-Za-z0-9_]{1,19}$");

    private final JdbcTemplate jdbc;
    private final TenantProvisionService provisionService;
    private final PasswordHasher hasher;

    public TenantAdminService(JdbcTemplate jdbc, TenantProvisionService provisionService,
                              PasswordHasher hasher) {
        this.jdbc = jdbc;
        this.provisionService = provisionService;
        this.hasher = hasher;
    }

    public record CreateRequest(String code, String name, String shortName, String industry,
                                Integer templateTenantId, String adminUserName, String adminPassword,
                                String expireAt) {
    }

    /**
     * 编辑租户：编码是库内唯一标识，<b>不可修改</b>；其余展示/联系/到期/上限字段都可改。
     * 请求里即使带了 code 也会被忽略，避免前端误改。
     */
    public record UpdateRequest(String name, String shortName, String industry, String contact,
                                String phone, Integer maxUsers, String remark, String expireAt) {
    }

    public record CreateResult(long tenantId, String code, String name, String adminUserName,
                               Map<String, Long> provisioned) {
    }

    /** 修改租户资料（编码除外）。 */
    @Transactional
    public void update(long tenantId, UpdateRequest req) {
        requirePlatformScope();
        Map<String, Object> tenant = requireBusinessTenant(tenantId);

        String name = req.name() == null ? "" : req.name().trim();
        if (name.isEmpty()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "租户名称不能为空");
        }
        if (name.length() > 200) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "租户名称不能超过 200 字");
        }
        if (req.shortName() != null && req.shortName().trim().length() > 100) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "简称不能超过 100 字");
        }
        if (req.industry() != null && req.industry().trim().length() > 100) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "行业不能超过 100 字");
        }
        if (req.contact() != null && req.contact().trim().length() > 100) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "联系人不能超过 100 字");
        }
        if (req.phone() != null && req.phone().trim().length() > 30) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "联系电话不能超过 30 字");
        }
        if (req.remark() != null && req.remark().trim().length() > 1000) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "备注不能超过 1000 字");
        }
        if (req.maxUsers() != null && req.maxUsers() < 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "用户上限不能为负数");
        }
        jdbc.update("""
                UPDATE plat.Tenant
                SET Name = ?, ShortName = ?, Industry = ?, Contact = ?, Phone = ?,
                    MaxUsers = ?, Remark = ?,
                    ExpireAt = CASE WHEN ? IS NULL THEN NULL ELSE TRY_CONVERT(datetime2, ?) END,
                    ModifiedAt = sysutcdatetime()
                WHERE Id = ? AND IsDeleted = 0
                """,
                name, blankToNull(req.shortName()), blankToNull(req.industry()),
                blankToNull(req.contact()), blankToNull(req.phone()),
                req.maxUsers(), blankToNull(req.remark()),
                blankToNull(req.expireAt()), blankToNull(req.expireAt()), tenantId);
        log.info("tenant_updated tenant={} code={}", tenantId, tenant.get("Code"));
    }

    /**
     * 维护租户管理员口令：找该租户首个启用中的 SYSADMIN 账号重置，
     * 并强制对方下次登录改密、清失败计数与锁定。
     */
    @Transactional
    public String resetTenantAdminPassword(long tenantId, String newPassword) {
        requirePlatformScope();
        requireBusinessTenant(tenantId);
        validatePassword(newPassword);

        List<Map<String, Object>> admins = jdbc.queryForList("""
                SELECT TOP 1 u.Id, u.UserName
                FROM plat.[User] u
                JOIN plat.UserRole ur ON ur.UserId = u.Id
                JOIN plat.Role r ON r.Id = ur.RoleId AND r.Code = 'SYSADMIN'
                WHERE u.TenantId = ? AND u.IsDeleted = 0
                ORDER BY u.IsEnabled DESC, u.Id
                """, tenantId);
        if (admins.isEmpty()) {
            // 存量租户可能只有角色、没有用户（种子租户就是这种）：这里直接补建管理员，
            // 让「维护管理员口令」成为自愈操作，而不是让人先去用户页手动建账号。
            long createdUserId = insertTenantAdmin(tenantId, "admin", newPassword);
            log.info("tenant_admin_created_on_reset tenant={} user=admin id={}", tenantId, createdUserId);
            return "admin";
        }
        long userId = ((Number) admins.get(0).get("Id")).longValue();
        String userName = String.valueOf(admins.get(0).get("UserName"));
        String salt = hasher.newSalt();
        String hash = hasher.hash(newPassword, salt);
        jdbc.update("""
                UPDATE plat.[User]
                SET PasswordHash = ?, PasswordSalt = ?, PasswordUpdatedAt = sysutcdatetime(),
                    MustChangePwd = 1, FailCount = 0, LockedUntil = NULL, ModifiedAt = sysutcdatetime()
                WHERE Id = ?
                """, hash, salt, userId);
        log.info("tenant_admin_password_reset tenant={} user={}", tenantId, userName);
        return userName;
    }

    /** 平台租户只承载平台账号，不允许当业务租户编辑。 */
    private Map<String, Object> requireBusinessTenant(long tenantId) {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT Id, Code, IsPlatformTenant FROM plat.Tenant WHERE Id = ? AND IsDeleted = 0",
                tenantId);
        if (rows.isEmpty()) {
            throw new ApiException(ErrorCode.NOT_FOUND, "租户不存在");
        }
        if (Boolean.TRUE.equals(rows.get(0).get("IsPlatformTenant"))) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                    "平台租户只承载平台账号，不支持编辑");
        }
        return rows.get(0);
    }

    /**
     * 开通租户：三步要么都成、要么都不留痕。
     *
     * <p>注意顺序：先建租户行（克隆过程要求目标租户存在），再克隆元数据，
     * 最后建管理员用户——克隆里会复制出 SYSADMIN 角色，管理员必须绑定克隆后的角色，
     * 所以用户名要放到最后一步。</p>
     */
    @Transactional
    public CreateResult create(CreateRequest req) {
        requirePlatformScope();

        String code = normalizeCode(req.code());
        String name = req.name() == null ? "" : req.name().trim();
        if (name.isEmpty()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "租户名称不能为空");
        }
        if (name.length() > 200) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "租户名称不能超过 200 字");
        }
        Integer existing = jdbc.queryForObject(
                "SELECT COUNT(*) FROM plat.Tenant WHERE Code = ? AND IsDeleted = 0",
                Integer.class, code);
        if (existing != null && existing > 0) {
            throw new ApiException(ErrorCode.DUPLICATE_KEY, "租户编码已存在：" + code);
        }

        // 模板租户：平台账号现在归属「平台租户」(Id=0)，那里没有业务元数据，
        // 所以默认取第一个启用中的业务租户作为模板；显式传入时也不允许指向平台租户。
        Integer templateTenantId = req.templateTenantId();
        if (templateTenantId == null) {
            List<Integer> candidates = jdbc.queryForList(
                    "SELECT TOP 1 Id FROM plat.Tenant "
                            + "WHERE IsDeleted = 0 AND IsPlatformTenant = 0 AND IsEnabled = 1 "
                            + "ORDER BY Id", Integer.class);
            if (candidates.isEmpty()) {
                throw new ApiException(ErrorCode.BAD_REQUEST,
                        "没有可用的模板租户，请先启用一个业务租户");
            }
            templateTenantId = candidates.get(0);
        }
        if (templateTenantId <= 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "模板租户不正确");
        }
        List<Map<String, Object>> template = jdbc.queryForList(
                "SELECT Id, IsPlatformTenant FROM plat.Tenant WHERE Id = ? AND IsDeleted = 0",
                templateTenantId);
        if (template.isEmpty()) {
            throw new ApiException(ErrorCode.NOT_FOUND, "模板租户不存在");
        }
        if (Boolean.TRUE.equals(template.get(0).get("IsPlatformTenant"))) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "平台租户不能作为业务模板");
        }

        String adminUserName = req.adminUserName() == null || req.adminUserName().isBlank()
                ? "admin" : req.adminUserName().trim();
        if (adminUserName.length() > 50) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "管理员用户名不能超过 50 字");
        }
        String adminPassword = req.adminPassword();
        validatePassword(adminPassword);

        long tenantId = insertTenant(code, name, req.shortName(), req.industry(), req.expireAt());
        // 克隆元数据（模块/菜单/权限/角色/数据对象/列表视图/编码规则/字典…）
        Map<String, Long> copied = provisionService.provision(templateTenantId, (int) tenantId);
        long adminUserId = insertTenantAdmin(tenantId, adminUserName, adminPassword);

        log.info("tenant_created tenant={} code={} admin={} userId={} copied={}",
                tenantId, code, adminUserName, adminUserId, copied);
        return new CreateResult(tenantId, code, name, adminUserName, copied);
    }

    /** 停用 / 启用：可逆，只改 IsEnabled。 */
    @Transactional
    public void setEnabled(long tenantId, boolean enabled) {
        requirePlatformScope();

        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT Id, Code, IsEnabled, IsPlatformTenant FROM plat.Tenant "
                        + "WHERE Id = ? AND IsDeleted = 0", tenantId);
        if (rows.isEmpty()) {
            throw new ApiException(ErrorCode.NOT_FOUND, "租户不存在");
        }
        if (Boolean.TRUE.equals(rows.get(0).get("IsPlatformTenant"))) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                    "平台租户只承载平台账号，不参与启停；请管理具体业务租户");
        }
        boolean current = Boolean.TRUE.equals(rows.get(0).get("IsEnabled"));
        if (current == enabled) {
            return;
        }
        if (!enabled) {
            // 平台账号与租户解绑后，这里只需要保证业务租户不被全部停掉
            Integer enabledCount = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM plat.Tenant "
                            + "WHERE IsEnabled = 1 AND IsDeleted = 0 AND IsPlatformTenant = 0",
                    Integer.class);
            if (enabledCount != null && enabledCount <= 1) {
                throw new ApiException(ErrorCode.BAD_REQUEST, "至少要保留一个启用状态的租户");
            }
        }
        jdbc.update("UPDATE plat.Tenant SET IsEnabled = ?, ModifiedAt = sysutcdatetime() "
                + "WHERE Id = ? AND IsDeleted = 0", enabled, tenantId);
        log.info("tenant_enabled tenant={} enabled={}", tenantId, enabled);
    }

    private long insertTenant(String code, String name, String shortName, String industry,
                              String expireAt) {
        KeyHolder keys = new GeneratedKeyHolder();
        jdbc.update(con -> {
            var ps = con.prepareStatement("""
                    INSERT plat.Tenant (Code, Name, ShortName, Industry, TimeZone, CurrencyCode,
                                        DeploymentMode, ShardId, IsEnabled, ExpireAt, IsDeleted, CreatedAt)
                    VALUES (?, ?, ?, ?, 'Asia/Shanghai', 'CNY', 1, 0, 1,
                            CASE WHEN ? IS NULL THEN NULL ELSE TRY_CONVERT(datetime2, ?) END, 0, sysutcdatetime())
                    """, new String[] {"Id"});
            ps.setString(1, code);
            ps.setString(2, name);
            ps.setString(3, blankToNull(shortName));
            ps.setString(4, blankToNull(industry));
            ps.setString(5, blankToNull(expireAt));
            ps.setString(6, blankToNull(expireAt));
            return ps;
        }, keys);
        Number id = keys.getKey();
        if (id == null) {
            throw new ApiException(ErrorCode.INTERNAL, "租户创建失败：未返回主键");
        }
        return id.longValue();
    }

    /**
     * 给新租户建管理员：绑定克隆出来的 SYSADMIN 角色。
     * 初始口令强制修改（MustChangePwd=1），和种子管理员一致。
     */
    private long insertTenantAdmin(long tenantId, String userName, String rawPassword) {
        Integer dup = jdbc.queryForObject(
                "SELECT COUNT(*) FROM plat.[User] WHERE TenantId = ? AND UserName = ? AND IsDeleted = 0",
                Integer.class, tenantId, userName);
        if (dup != null && dup > 0) {
            throw new ApiException(ErrorCode.DUPLICATE_KEY, "该租户下管理员用户名已存在");
        }
        String salt = hasher.newSalt();
        String hash = hasher.hash(rawPassword, salt);
        KeyHolder keys = new GeneratedKeyHolder();
        jdbc.update(con -> {
            var ps = con.prepareStatement("""
                    INSERT plat.[User] (TenantId, UserName, PasswordHash, PasswordSalt, DisplayName,
                                        UserType, IsEnabled, MustChangePwd, FailCount, IsDeleted, CreatedAt)
                    VALUES (?, ?, ?, ?, N'租户管理员', 1, 1, 1, 0, 0, sysutcdatetime())
                    """, new String[] {"Id"});
            ps.setLong(1, tenantId);
            ps.setString(2, userName);
            ps.setString(3, hash);
            ps.setString(4, salt);
            return ps;
        }, keys);
        Number userId = keys.getKey();
        if (userId == null) {
            throw new ApiException(ErrorCode.INTERNAL, "租户管理员创建失败：未返回主键");
        }
        // 克隆会把角色一起复制过来；模板没配 SYSADMIN 时补建一个，保证租户一定有人能管
        List<Long> roleIds = jdbc.queryForList(
                "SELECT Id FROM plat.Role WHERE TenantId = ? AND Code = 'SYSADMIN' AND IsDeleted = 0",
                Long.class, tenantId);
        long roleId;
        if (roleIds.isEmpty()) {
            jdbc.update("""
                    INSERT plat.Role (TenantId, Code, Name, RoleType, IsSystem, IsEnabled, Remark,
                                      IsDeleted, CreatedAt)
                    VALUES (?, 'SYSADMIN', N'系统管理员', 1, 1, 1, N'租户管理员（自动补建）', 0, sysutcdatetime())
                    """, tenantId);
            roleId = jdbc.queryForObject(
                    "SELECT Id FROM plat.Role WHERE TenantId = ? AND Code = 'SYSADMIN' AND IsDeleted = 0",
                    Long.class, tenantId);
        } else {
            roleId = roleIds.get(0);
        }
        jdbc.update("INSERT plat.UserRole (TenantId, UserId, RoleId) VALUES (?, ?, ?)",
                tenantId, userId.longValue(), roleId);
        return userId.longValue();
    }

    private static String normalizeCode(String raw) {
        String code = raw == null ? "" : raw.trim().toUpperCase();
        if (!CODE.matcher(code).matches()) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                    "租户编码只能是字母开头的 2-20 位字母/数字/下划线，例如 T003");
        }
        return code;
    }

    private static void validatePassword(String raw) {
        if (raw == null || raw.length() < 8 || raw.length() > 64) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "管理员口令长度必须为 8-64 位");
        }
        boolean hasLetter = raw.chars().anyMatch(Character::isLetter);
        boolean hasDigit = raw.chars().anyMatch(Character::isDigit);
        if (!hasLetter || !hasDigit) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "管理员口令必须同时包含字母与数字");
        }
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private void requirePlatformScope() {
        if (!TenantContext.isPlatformAdmin() || !TenantContext.isPlatformScope()) {
            throw new ApiException(ErrorCode.FORBIDDEN,
                    "仅平台管理员可开通/停用租户，请使用平台登录");
        }
    }
}

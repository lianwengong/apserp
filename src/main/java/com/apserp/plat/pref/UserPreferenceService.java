package com.apserp.plat.pref;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.common.tenant.TenantContext;
import java.util.LinkedHashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 用户偏好：按（租户，用户，键）存一段 JSON，供外观/布局等前端设置跨设备同步。
 *
 * <p>为什么放服务端：localStorage 是设备级的，同一账号换机器就回默认；
 * 而且「谁改了哪些偏好」在排障时是有用的线索。</p>
 *
 * <p>边界：</p>
 * <ul>
 *   <li>只接 {@code appearance} 这类**纯展示**配置，不存业务参数（业务参数走系统参数表）；</li>
 *   <li>值上限 64KB，防止把整个页面配置塞进来；</li>
 *   <li>键只能是小写标识符，避免前端随手写 {@code "a.b[0]"} 之类路径。</li>
 * </ul>
 */
@Service
public class UserPreferenceService {

    private static final Logger log = LoggerFactory.getLogger(UserPreferenceService.class);

    private static final int MAX_VALUE_LENGTH = 64 * 1024;
    private static final String KEY_PATTERN = "[a-z][a-z0-9_.-]{0,59}";

    private final JdbcTemplate jdbc;

    public UserPreferenceService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** 读一个键；没有时返回 null（前端据此决定是否用本地值）。 */
    public String get(String key) {
        long userId = requireUserId();
        long tenantId = TenantContext.requireTenantId();
        checkKey(key);
        return jdbc.query("""
                SELECT PrefValue FROM plat.UserPreference
                WHERE TenantId = ? AND UserId = ? AND PrefKey = ? AND IsDeleted = 0
                """, rs -> rs.next() ? rs.getString(1) : null, tenantId, userId, key);
    }

    /** 读全部偏好（登录后一次拉回，减少请求数）。 */
    public Map<String, String> all() {
        long userId = requireUserId();
        long tenantId = TenantContext.requireTenantId();
        Map<String, String> out = new LinkedHashMap<>();
        jdbc.query("""
                SELECT PrefKey, PrefValue FROM plat.UserPreference
                WHERE TenantId = ? AND UserId = ? AND IsDeleted = 0 ORDER BY PrefKey
                """, rs -> {
            out.put(rs.getString("PrefKey"), rs.getString("PrefValue"));
        }, tenantId, userId);
        return out;
    }

    /** 写入（存在则更新）：同一用户的同一个键只会有一行。 */
    @Transactional
    public void save(String key, String value) {
        long userId = requireUserId();
        long tenantId = TenantContext.requireTenantId();
        checkKey(key);
        if (value != null && value.length() > MAX_VALUE_LENGTH) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "偏好内容过大（上限 64KB）");
        }
        int updated = jdbc.update("""
                UPDATE plat.UserPreference
                SET PrefValue = ?, ModifiedAt = sysutcdatetime()
                WHERE TenantId = ? AND UserId = ? AND PrefKey = ? AND IsDeleted = 0
                """, value, tenantId, userId, key);
        if (updated == 0) {
            jdbc.update("""
                    INSERT plat.UserPreference (TenantId, UserId, PrefKey, PrefValue, CreatedAt)
                    VALUES (?, ?, ?, ?, sysutcdatetime())
                    """, tenantId, userId, key, value);
        }
        log.info("preference_save tenant={} user={} key={} bytes={}",
                tenantId, userId, key, value == null ? 0 : value.length());
    }

    /** 删除（恢复默认）：软删，保留痕迹。 */
    @Transactional
    public void delete(String key) {
        long userId = requireUserId();
        long tenantId = TenantContext.requireTenantId();
        checkKey(key);
        int n = jdbc.update("""
                UPDATE plat.UserPreference SET IsDeleted = 1
                WHERE TenantId = ? AND UserId = ? AND PrefKey = ? AND IsDeleted = 0
                """, tenantId, userId, key);
        if (n > 0) {
            log.info("preference_delete tenant={} user={} key={}", tenantId, userId, key);
        }
    }

    private long requireUserId() {
        Long userId = TenantContext.userId();
        if (userId == null) {
            throw new ApiException(ErrorCode.UNAUTHORIZED, "未登录，无法读写偏好");
        }
        return userId;
    }

    private void checkKey(String key) {
        if (key == null || !key.matches(KEY_PATTERN)) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                    "偏好键只能是小写字母开头的标识符（如 appearance）");
        }
    }
}

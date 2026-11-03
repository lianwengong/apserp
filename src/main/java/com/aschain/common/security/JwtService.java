package com.aschain.common.security;

import com.aschain.common.ApiException;
import com.aschain.common.ErrorCode;
import com.aschain.common.tenant.TenantContext;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.Map;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * JWT 签发与校验（HS256）。
 *
 * <p>密钥从配置读取，长度不足 32 字节直接启动失败——不允许"用默认密钥跑起来再说"。</p>
 */
@Service
public class JwtService {

    public static final String CLAIM_TENANT = "tid";
    public static final String CLAIM_USER = "uid";
    public static final String CLAIM_NAME = "uname";
    public static final String CLAIM_ADMIN = "adm";
    /** 首次登录未改密：除改密接口外一律拒绝。 */
    public static final String CLAIM_MUST_CHANGE = "mpwd";
    /** 会话入口：1 平台管理 / 2 业务管理（登录时选择，菜单与首页按它过滤） */
    public static final String CLAIM_APP = "app";

    private final SecretKey key;
    private final Duration ttl;

    public JwtService(@Value("${app.jwt.secret}")
                      @SuppressWarnings("unused") String secret,
                      @Value("${app.jwt.ttl-minutes:480}") long ttlMinutes) {
        if (secret == null || secret.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException(
                    "app.jwt.secret 至少 32 字节，请通过环境变量 APP_JWT_SECRET 提供");
        }
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.ttl = Duration.ofMinutes(ttlMinutes);
    }

    public String issue(long userId, int tenantId, String userName, boolean platformAdmin,
                        boolean mustChangePassword) {
        return issue(userId, tenantId, userName, platformAdmin, mustChangePassword,
                TenantContext.APP_BUSINESS);
    }

    public String issue(long userId, int tenantId, String userName, boolean platformAdmin,
                        boolean mustChangePassword, int appType) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(Long.toString(userId))
                .claims(Map.of(
                        CLAIM_TENANT, tenantId,
                        CLAIM_USER, userId,
                        CLAIM_NAME, userName,
                        CLAIM_ADMIN, platformAdmin,
                        CLAIM_MUST_CHANGE, mustChangePassword,
                        CLAIM_APP, appType))
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plus(ttl)))
                .signWith(key)
                .compact();
    }

    public Claims parse(String token) {
        try {
            return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
        } catch (JwtException | IllegalArgumentException ex) {
            throw new ApiException(ErrorCode.UNAUTHORIZED, "登录已失效，请重新登录", ex);
        }
    }
}

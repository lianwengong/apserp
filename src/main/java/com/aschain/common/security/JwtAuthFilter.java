package com.aschain.common.security;

import com.aschain.common.tenant.TenantContext;
import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * 认证过滤器：解析 {@code Authorization: Bearer <jwt>}，把租户与用户写入上下文。
 *
 * <p>安全约定：</p>
 * <ul>
 *   <li>默认只认 JWT；请求头 {@code X-Tenant-Id} 只有在
 *       {@code app.security.allow-header-auth=true} 时才生效（仅开发环境）。</li>
 *   <li>未通过认证的请求直接 401，不进入业务代码。</li>
 * </ul>
 */
@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    /** 请求属性：首次登录未改密。 */
    public static final String ATTR_MUST_CHANGE = "aschain.mustChangePassword";

    private final JwtService jwtService;
    private final boolean allowHeaderAuth;

    public JwtAuthFilter(JwtService jwtService,
                         @Value("${app.security.allow-header-auth:false}") boolean allowHeaderAuth) {
        this.jwtService = jwtService;
        this.allowHeaderAuth = allowHeaderAuth;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            Claims claims;
            try {
                claims = jwtService.parse(header.substring(7));
            } catch (RuntimeException ex) {
                unauthorized(response);
                return;
            }
            long userId = ((Number) claims.get(JwtService.CLAIM_USER)).longValue();
            int tenantId = ((Number) claims.get(JwtService.CLAIM_TENANT)).intValue();
            boolean admin = Boolean.TRUE.equals(claims.get(JwtService.CLAIM_ADMIN));
            boolean mustChange = Boolean.TRUE.equals(claims.get(JwtService.CLAIM_MUST_CHANGE));
            // 入口从令牌来：老令牌没有 app 声明时按业务管理处理
            Object appClaim = claims.get(JwtService.CLAIM_APP);
            int appType = appClaim instanceof Number number
                    ? number.intValue() : TenantContext.APP_BUSINESS;
            // 平台作用域：只有平台登录换来的令牌带 pf=true，允许跨租户读写
            boolean platformScope = Boolean.TRUE.equals(claims.get(JwtService.CLAIM_PLATFORM));
            TenantContext.set((long) tenantId, userId, admin, appType, platformScope);
            request.setAttribute(ATTR_MUST_CHANGE, mustChange);
        } else if (allowHeaderAuth && request.getHeader("X-Tenant-Id") != null) {
            TenantContext.set(Long.valueOf(request.getHeader("X-Tenant-Id")),
                    request.getHeader("X-User-Id") == null
                            ? null : Long.valueOf(request.getHeader("X-User-Id")), false);
        } else {
            unauthorized(response);
            return;
        }
        try {
            chain.doFilter(request, response);
        } finally {
            TenantContext.clear();
        }
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String uri = request.getRequestURI();
        return uri.startsWith("/actuator") || uri.startsWith("/error") || uri.startsWith("/api/auth/");
    }

    private void unauthorized(HttpServletResponse response) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write("{\"code\":3001,\"message\":\"未登录或登录已失效\",\"data\":null}");
    }
}

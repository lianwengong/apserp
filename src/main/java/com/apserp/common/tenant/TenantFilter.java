package com.apserp.common.tenant;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * 从请求头解析租户与用户，写入 TenantContext。
 * 生产环境应改为从 JWT 解析，这里的 Header 方式仅用于第一周联调。
 */
@Component
public class TenantFilter extends OncePerRequestFilter {

    private static final String H_TENANT = "X-Tenant-Id";
    private static final String H_USER = "X-User-Id";

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String tenant = request.getHeader(H_TENANT);
        String user = request.getHeader(H_USER);
        if (tenant == null || tenant.isBlank()) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"code\":3001,\"message\":\"缺少租户标识\",\"data\":null}");
            return;
        }
        try {
            TenantContext.set(Long.valueOf(tenant), user == null ? null : Long.valueOf(user));
            chain.doFilter(request, response);
        } catch (NumberFormatException ex) {
            throw new ApiException(ErrorCode.TENANT_MISSING, "租户标识格式错误");
        } finally {
            TenantContext.clear();
        }
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String uri = request.getRequestURI();
        return uri.startsWith("/actuator") || uri.startsWith("/error");
    }
}

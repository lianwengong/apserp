package com.apserp.common.security;

import com.apserp.common.ApiException;
import com.apserp.common.ErrorCode;
import com.apserp.plat.perm.PermissionService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.HandlerMapping;

/**
 * 权限拦截器：在进入 Controller 之前校验 {@link RequiresPermission}。
 *
 * <p>放在拦截器而不是 AOP，是因为这里能直接拿到路径变量，用于解析
 * {@code DATA:{objectCode}} 这类动态权限点。</p>
 */
@Component
public class PermissionInterceptor implements HandlerInterceptor {

    private static final Logger log = LoggerFactory.getLogger(PermissionInterceptor.class);

    private final PermissionService permissionService;

    public PermissionInterceptor(PermissionService permissionService) {
        this.permissionService = permissionService;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        if (!(handler instanceof HandlerMethod method)) {
            return true;
        }
        RequiresPermission ann = method.getMethodAnnotation(RequiresPermission.class);
        if (ann == null) {
            ann = method.getBeanType().getAnnotation(RequiresPermission.class);
        }
        if (ann == null) {
            return true;
        }

        String resource = resolve(ann.value(), request);
        if (resource == null || resource.isBlank()) {
            // 权限点解析不出来就不放行，避免"配置写错却默认放开"
            throw new ApiException(ErrorCode.FORBIDDEN, "无法确定权限点，拒绝访问");
        }
        if (!permissionService.check(resource, ann.action())) {
            permissionService.logDenied(resource, ann.action());
            throw new ApiException(ErrorCode.FORBIDDEN,
                    "没有权限：" + resource + "（" + ann.action() + "）");
        }
        return true;
    }

    /** 把 {name} 换成路径变量值；路径变量不存在则返回 null（fail-closed）。 */
    @SuppressWarnings("unchecked")
    static String resolve(String template, HttpServletRequest request) {
        if (!template.contains("{")) {
            return template;
        }
        Object attr = request.getAttribute(HandlerMapping.URI_TEMPLATE_VARIABLES_ATTRIBUTE);
        if (!(attr instanceof Map<?, ?> vars)) {
            return null;
        }
        String result = template;
        for (Object key : vars.keySet()) {
            Object value = vars.get(key);
            result = result.replace("{" + key + "}", value == null ? "" : value.toString());
        }
        return result.contains("{") ? null : result;
    }
}

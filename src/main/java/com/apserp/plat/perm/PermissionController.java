package com.apserp.plat.perm;

import com.apserp.common.ApiResult;
import com.apserp.common.tenant.TenantContext;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 当前用户的权限视图：前端据此渲染菜单与按钮，不再自己猜。
 */
@RestController
@RequestMapping("/api/perm")
public class PermissionController {

    private final PermissionService permissionService;

    public PermissionController(PermissionService permissionService) {
        this.permissionService = permissionService;
    }

    public record MeResult(long userId, long tenantId, boolean platformAdmin,
                           Set<String> resources, List<Integer> orgScope) {
    }

    @GetMapping("/me")
    public ApiResult<MeResult> me() {
        return ApiResult.ok(new MeResult(
                TenantContext.userId() == null ? 0 : TenantContext.userId(),
                TenantContext.tenantId() == null ? 0 : TenantContext.tenantId(),
                TenantContext.isPlatformAdmin(),
                permissionService.grantedResources(),
                permissionService.orgScope()));
    }

    /** 字段级权限：返回某数据对象下当前用户不可见/只读的字段。 */
    @GetMapping("/fields")
    public ApiResult<Map<String, Integer>> fields(String objectCode) {
        return ApiResult.ok(permissionService.fieldAccess(objectCode));
    }
}

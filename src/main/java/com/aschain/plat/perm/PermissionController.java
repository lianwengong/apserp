package com.aschain.plat.perm;

import com.aschain.common.ApiResult;
import com.aschain.common.tenant.TenantContext;
import com.aschain.plat.tenant.TenantQueryService;
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
    private final TenantQueryService tenantQuery;

    public PermissionController(PermissionService permissionService,
                                TenantQueryService tenantQuery) {
        this.permissionService = permissionService;
        this.tenantQuery = tenantQuery;
    }

    public record MeResult(long userId, long tenantId, String tenantCode, String tenantName,
                           boolean platformAdmin, Set<String> resources, List<Integer> orgScope) {
    }

    @GetMapping("/me")
    public ApiResult<MeResult> me() {
        long tenantId = TenantContext.tenantId() == null ? 0 : TenantContext.tenantId();
        var tenant = tenantQuery.summary(tenantId);
        return ApiResult.ok(new MeResult(
                TenantContext.userId() == null ? 0 : TenantContext.userId(),
                tenantId,
                tenant.code(),
                tenant.name(),
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

package com.aschain.plat.admin;

import com.aschain.common.ApiResult;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 平台管理：跨租户登录用户与权限。
 *
 * <pre>
 * GET  /api/admin/users?keyword=&tenantId=&page=&size=   用户列表（跨租户）
 * GET  /api/admin/users/roles?tenantId=                  该租户可选角色
 * PUT  /api/admin/users/{id}/enabled                     启用/停用
 * POST /api/admin/users/{id}/reset-password              重置口令（强制改密）
 * PUT  /api/admin/users/{id}/roles                       覆盖式分配角色
 * </pre>
 *
 * <p>都要求平台登录（平台作用域）；租户会话调用 403。</p>
 */
@RestController
@RequestMapping("/api/admin/users")
public class PlatformUserController {

    private final PlatformUserService platformUser;

    public PlatformUserController(PlatformUserService platformUser) {
        this.platformUser = platformUser;
    }

    public record EnabledRequest(boolean enabled) {
    }

    public record ResetPasswordRequest(String newPassword) {
    }

    public record RolesRequest(List<Long> roleIds) {
    }

    @GetMapping
    public ApiResult<PlatformUserService.PageResult> list(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Long tenantId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ApiResult.ok(platformUser.list(keyword, tenantId, page, size));
    }

    @GetMapping("/roles")
    public ApiResult<List<PlatformUserService.RoleDto>> roles(@RequestParam long tenantId) {
        return ApiResult.ok(platformUser.roles(tenantId));
    }

    @PutMapping("/{id}/enabled")
    public ApiResult<Void> setEnabled(@PathVariable long id, @RequestBody EnabledRequest req) {
        platformUser.setEnabled(id, req.enabled());
        return ApiResult.ok(null);
    }

    @PostMapping("/{id}/reset-password")
    public ApiResult<Void> resetPassword(@PathVariable long id,
                                         @RequestBody ResetPasswordRequest req) {
        platformUser.resetPassword(id, req.newPassword());
        return ApiResult.ok(null);
    }

    @PutMapping("/{id}/roles")
    public ApiResult<Void> setRoles(@PathVariable long id, @RequestBody RolesRequest req) {
        platformUser.setRoles(id, req.roleIds());
        return ApiResult.ok(null);
    }
}

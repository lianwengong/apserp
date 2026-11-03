package com.aschain.plat.admin;

import com.aschain.common.ApiResult;
import com.aschain.common.security.RequiresPermission;
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
 * 平台管理：<b>平台账号</b>（不含租户里的账号）。
 *
 * <pre>
 * GET  /api/admin/users?keyword=      平台账号列表
 * POST /api/admin/users               新增平台账号
 * PUT  /api/admin/users/{id}/enabled  启用/停用
 * POST /api/admin/users/{id}/reset-password 重置口令（强制改密）
 * </pre>
 *
 * <p>都要求平台登录（平台作用域）；租户会话调用 403。
 * 租户自己的账号在租户的用户管理里维护，不从这里进。</p>
 */
@RestController
@RequiresPermission("PLAT:ACCOUNT")
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

    @GetMapping
    public ApiResult<List<PlatformUserService.UserRow>> list(
            @RequestParam(required = false) String keyword) {
        return ApiResult.ok(platformUser.list(keyword));
    }

    @PostMapping
    public ApiResult<PlatformUserService.UserRow> create(
            @RequestBody PlatformUserService.CreateRequest req) {
        return ApiResult.ok(platformUser.create(req));
    }

    @PutMapping("/{id}/enabled")
    public ApiResult<Void> setEnabled(@PathVariable long id, @RequestBody EnabledRequest req) {
        platformUser.setEnabled(id, req.enabled());
        return ApiResult.ok(null);
    }

    @PostMapping("/{id}/reset-password")
    public ApiResult<java.util.Map<String, String>> resetPassword(
            @PathVariable long id, @RequestBody ResetPasswordRequest req) {
        String userName = platformUser.resetPassword(id, req.newPassword());
        return ApiResult.ok(java.util.Map.of("userName", userName));
    }
}

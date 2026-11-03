package com.aschain.plat.auth;

import com.aschain.common.ApiResult;
import com.aschain.common.tenant.TenantContext;
import jakarta.validation.constraints.NotBlank;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 登录入口（不需要认证）。 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    /** 租户登录：租户名必填；appType 不传按业务管理处理（兼容旧前端与脚本）。 */
    public record LoginRequest(@NotBlank String tenantCode, @NotBlank String userName,
                               @NotBlank String password, Integer appType) {
    }

    /** 平台登录：没有租户名，只有平台账号与口令。 */
    public record PlatformLoginRequest(@NotBlank String userName, @NotBlank String password) {
    }

    public record ChangePasswordRequest(@NotBlank String tenantCode, @NotBlank String userName,
                                        @NotBlank String oldPassword, @NotBlank String newPassword,
                                        Integer appType) {
    }

    @PostMapping("/login")
    public ApiResult<AuthService.LoginResult> login(@RequestBody LoginRequest req) {
        int appType = req.appType() == null ? TenantContext.APP_BUSINESS : req.appType();
        return ApiResult.ok(authService.login(req.tenantCode(), req.userName(), req.password(), appType));
    }

    /**
     * 平台登录：不填租户名，跨租户按「平台账号」标记找人，令牌带平台作用域。
     * 与租户登录分开成两个接口，是为了让「平台账号」这件事在契约上就是显式的一步。
     */
    @PostMapping("/platform-login")
    public ApiResult<AuthService.LoginResult> platformLogin(@RequestBody PlatformLoginRequest req) {
        return ApiResult.ok(authService.loginPlatform(req.userName(), req.password()));
    }

    /** 修改口令：首次登录必须调用，成功后换发新令牌（入口沿用登录时选择）。 */
    @PostMapping("/change-password")
    public ApiResult<AuthService.LoginResult> changePassword(@RequestBody ChangePasswordRequest req) {
        int appType = req.appType() == null ? TenantContext.APP_BUSINESS : req.appType();
        return ApiResult.ok(authService.changePassword(req.tenantCode(), req.userName(),
                req.oldPassword(), req.newPassword(), appType));
    }

    /** 两个入口的元信息：登录页据此渲染选择卡片（不暴露任何账号信息）。 */
    @GetMapping("/entrances")
    public ApiResult<List<Map<String, Object>>> entrances() {
        return ApiResult.ok(List.of(
                Map.of("value", TenantContext.APP_PLATFORM, "label", "平台管理",
                        "hint", "租户、组织、元数据、发布与监控", "home", "/platform"),
                Map.of("value", TenantContext.APP_BUSINESS, "label", "业务管理",
                        "hint", "主数据、采购、销售、库存等日常业务", "home", "/")));
    }
}

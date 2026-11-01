package com.apserp.plat.auth;

import com.apserp.common.ApiResult;
import jakarta.validation.constraints.NotBlank;
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

    public record LoginRequest(@NotBlank String tenantCode, @NotBlank String userName,
                               @NotBlank String password) {
    }

    public record ChangePasswordRequest(@NotBlank String tenantCode, @NotBlank String userName,
                                        @NotBlank String oldPassword, @NotBlank String newPassword) {
    }

    @PostMapping("/login")
    public ApiResult<AuthService.LoginResult> login(@RequestBody LoginRequest req) {
        return ApiResult.ok(authService.login(req.tenantCode(), req.userName(), req.password()));
    }

    /** 修改口令：首次登录必须调用，成功后换发新令牌。 */
    @PostMapping("/change-password")
    public ApiResult<AuthService.LoginResult> changePassword(@RequestBody ChangePasswordRequest req) {
        return ApiResult.ok(authService.changePassword(req.tenantCode(), req.userName(),
                req.oldPassword(), req.newPassword()));
    }
}

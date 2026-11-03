package com.aschain.plat.auth;

import com.aschain.common.ApiResult;
import jakarta.validation.constraints.NotBlank;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 当前会话自己的操作（走 JWT，不需要租户名）。
 *
 * <pre>
 * POST /api/me/password   {oldPassword, newPassword} → 新令牌
 * </pre>
 *
 * <p>为什么单独放这里：首次登录未改密时，权限拦截器会拦掉除「改口令」外的所有接口，
 * 而改口令必须能在只知道令牌的情况下完成（平台账号没有租户名）。</p>
 */
@RestController
@RequestMapping("/api/me")
public class MeController {

    private final AuthService authService;

    public MeController(AuthService authService) {
        this.authService = authService;
    }

    public record PasswordRequest(@NotBlank String oldPassword, @NotBlank String newPassword) {
    }

    @PostMapping("/password")
    public ApiResult<AuthService.LoginResult> changePassword(@RequestBody PasswordRequest req) {
        return ApiResult.ok(authService.changePasswordForCurrentUser(req.oldPassword(), req.newPassword()));
    }
}

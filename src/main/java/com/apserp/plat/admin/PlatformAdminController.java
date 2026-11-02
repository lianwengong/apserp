package com.apserp.plat.admin;

import com.apserp.common.ApiResult;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 平台管理接口：平台管理员的跨租户只读视图。
 *
 * <pre>
 * GET /api/admin/tenants   租户列表（平台管理员）
 * </pre>
 */
@RestController
@RequestMapping("/api/admin")
public class PlatformAdminController {

    private final PlatformAdminService platformAdmin;

    public PlatformAdminController(PlatformAdminService platformAdmin) {
        this.platformAdmin = platformAdmin;
    }

    @GetMapping("/tenants")
    public ApiResult<List<PlatformAdminService.TenantDto>> tenants() {
        return ApiResult.ok(platformAdmin.tenants());
    }
}

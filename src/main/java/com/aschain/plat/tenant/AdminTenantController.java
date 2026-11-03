package com.aschain.plat.tenant;

import com.aschain.common.ApiResult;
import java.util.Map;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 平台管理接口：租户开通与停用/启用。
 *
 * <pre>
 * POST /api/admin/tenants                      开通租户（建租户 + 克隆元数据 + 建管理员）
 * POST /api/admin/tenants/{id}/provision       只补克隆元数据（已有租户行时用）
 * PUT  /api/admin/tenants/{id}/enabled         停用 / 启用
 * </pre>
 *
 * <p>都要求平台登录（平台作用域），租户管理员调用会 403。</p>
 */
@RestController
@RequestMapping("/api/admin/tenants")
public class AdminTenantController {

    private final TenantProvisionService provisionService;
    private final TenantAdminService tenantAdmin;

    public AdminTenantController(TenantProvisionService provisionService,
                                 TenantAdminService tenantAdmin) {
        this.provisionService = provisionService;
        this.tenantAdmin = tenantAdmin;
    }

    public record ProvisionRequest(int templateTenantId) {
    }

    public record EnabledRequest(boolean enabled) {
    }

    @PostMapping("/{tenantId}/provision")
    public ApiResult<Map<String, Long>> provision(@PathVariable int tenantId,
                                                  @RequestBody ProvisionRequest req) {
        return ApiResult.ok(provisionService.provision(req.templateTenantId(), tenantId));
    }

    @PostMapping
    public ApiResult<TenantAdminService.CreateResult> create(
            @RequestBody TenantAdminService.CreateRequest req) {
        return ApiResult.ok(tenantAdmin.create(req));
    }

    @PutMapping("/{tenantId}/enabled")
    public ApiResult<Void> setEnabled(@PathVariable long tenantId,
                                      @RequestBody EnabledRequest req) {
        tenantAdmin.setEnabled(tenantId, req.enabled());
        return ApiResult.ok(null);
    }
}

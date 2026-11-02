package com.aschain.plat.tenant;

import com.aschain.common.ApiResult;
import java.util.Map;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 平台管理接口（需要 adm 声明）。 */
@RestController
@RequestMapping("/api/admin/tenants")
public class AdminTenantController {

    private final TenantProvisionService provisionService;

    public AdminTenantController(TenantProvisionService provisionService) {
        this.provisionService = provisionService;
    }

    public record ProvisionRequest(int templateTenantId) {
    }

    @PostMapping("/{tenantId}/provision")
    public ApiResult<Map<String, Long>> provision(@PathVariable int tenantId,
                                                  @RequestBody ProvisionRequest req) {
        return ApiResult.ok(provisionService.provision(req.templateTenantId(), tenantId));
    }
}

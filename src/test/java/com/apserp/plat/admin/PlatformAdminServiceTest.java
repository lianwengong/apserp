package com.apserp.plat.admin;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.apserp.common.ApiException;
import com.apserp.common.tenant.TenantContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

class PlatformAdminServiceTest {

    @AfterEach
    void clearContext() {
        TenantContext.clear();
    }

    @Test
    void tenants_should_reject_non_platform_admin() {
        TenantContext.clear();
        PlatformAdminService service = new PlatformAdminService(null);

        assertThatThrownBy(service::tenants)
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("平台管理员");
    }
}

package com.apserp.plat.page;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.apserp.common.ApiException;
import com.apserp.common.tenant.TenantContext;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class PageSchemaServiceTest {

    private PageSchemaService service;

    @BeforeEach
    void setUp() {
        TenantContext.set(1L, 1L);
        service = new PageSchemaService(null, new ObjectMapper());
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    @Test
    void save_should_reject_invalid_code() {
        assertThatThrownBy(() -> service.save(new PageSchemaService.SaveRequest(
                null, "bad code!", "标题", "placeholder", "{}", true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("页面编码");
    }

    @Test
    void save_should_reject_invalid_json() {
        assertThatThrownBy(() -> service.save(new PageSchemaService.SaveRequest(
                null, "test.page", "标题", "placeholder", "{not-json", true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("合法 JSON");
    }

    @Test
    void save_should_reject_object_without_object_code() {
        assertThatThrownBy(() -> service.save(new PageSchemaService.SaveRequest(
                null, "test.page", "标题", "object",
                "{\"code\":\"test.page\",\"title\":\"标题\",\"kind\":\"object\"}", true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("objectCode");
    }

    @Test
    void save_should_reject_tabs_with_duplicate_keys() {
        String json = """
                {"code":"test.page","title":"标题","kind":"tabs","tabs":[
                  {"key":"a","label":"A","objectCode":"md.brand"},
                  {"key":"a","label":"B","objectCode":"md.partner"}
                ]}
                """;
        assertThatThrownBy(() -> service.save(new PageSchemaService.SaveRequest(
                null, "test.page", "标题", "tabs", json, true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("重复");
    }

    @Test
    void save_should_reject_mismatched_kind() {
        assertThatThrownBy(() -> service.save(new PageSchemaService.SaveRequest(
                null, "test.page", "标题", "dashboard",
                "{\"code\":\"test.page\",\"title\":\"标题\",\"kind\":\"placeholder\"}", true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("kind");
    }
}

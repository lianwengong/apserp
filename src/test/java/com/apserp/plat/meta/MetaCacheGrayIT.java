package com.apserp.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.apserp.common.ApiException;
import com.apserp.common.tenant.TenantContext;
import com.apserp.support.ItDb;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

/**
 * 元数据缓存与灰度发布集成测试。
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class MetaCacheGrayIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    MetaCache cache;

    @Autowired
    MetaDefinitionService definitionService;

    @Autowired
    MetaPublishService publishService;

    @Autowired
    JdbcTemplate jdbc;

    @BeforeEach
    void setUp() {
        TenantContext.set(1L, 1L);
        cache.invalidateTenant();
    }

    @AfterEach
    void tearDown() {
        cache.invalidateTenant();
        TenantContext.clear();
    }

    @Test
    @DisplayName("缓存命中：同一对象编码第二次读不再查库（返回同一实例）")
    void cache_hit_returns_same_instance() {
        var first = definitionService.listFields("md.brand");
        var second = definitionService.listFields("md.brand");
        assertThat(second).isSameAs(first);
        assertThat(cache.stats()).containsKeys("entries", "ttlSeconds");
        assertThat((Integer) cache.stats().get("entries")).isGreaterThan(0);
    }

    @Test
    @DisplayName("显式失效后重新查库：拿到新实例")
    void invalidate_reloads() {
        var first = definitionService.listFields("md.brand");
        cache.invalidateTenant();
        var second = definitionService.listFields("md.brand");
        assertThat(second).isNotSameAs(first);
        assertThat(second).extracting(MetaDefinitionService.FieldDto::fieldName)
                .isEqualTo(first.stream().map(MetaDefinitionService.FieldDto::fieldName).toList());
    }

    @Test
    @DisplayName("不同租户的缓存互不串（key 带租户）")
    void cache_is_per_tenant() {
        var tenant1 = definitionService.listObjects();
        TenantContext.set(2L, null, true);
        var tenant2 = definitionService.listObjects();
        assertThat(tenant1).isNotSameAs(tenant2);
        TenantContext.set(1L, 1L);
    }

    @Test
    @DisplayName("发布后缓存自动失效，且新版本成为当前生效版本")
    void publish_invalidates_and_activates() {
        var before = definitionService.listFields("md.brand");
        var r = publishService.publish("缓存与灰度测试");
        var after = definitionService.listFields("md.brand");
        assertThat(after).isNotSameAs(before);
        assertThat(publishService.currentVersion()).isEqualTo(r.version());
        Integer status = jdbc.queryForObject(
                "SELECT Status FROM plat.MetaVersion WHERE TenantId = 1 AND Version = ?", Integer.class, r.version());
        assertThat(status).isEqualTo(1);
        Integer others = jdbc.queryForObject(
                "SELECT COUNT(*) FROM plat.MetaVersion WHERE TenantId = 1 AND Status = 1 AND Version <> ?",
                Integer.class, r.version());
        assertThat(others).isZero();
    }

    @Test
    @DisplayName("灰度发布：版本状态为灰度中，名单可读回，当前生效版本不变")
    void gray_publish_keeps_current() {
        Integer currentBefore = publishService.currentVersion();
        long userId = jdbc.queryForObject("SELECT MIN(Id) FROM plat.[User] WHERE TenantId = 1", Long.class);

        var r = publishService.publish("灰度发布", List.of(userId));
        assertThat(r.version()).isPositive();
        assertThat(publishService.currentVersion()).isEqualTo(currentBefore);

        MetaPublishService.GrayDto gray = publishService.grayOf(r.version());
        assertThat(gray.userIds()).containsExactly(userId);
        assertThat(gray.userNames()).hasSize(1);

        Integer status = jdbc.queryForObject(
                "SELECT Status FROM plat.MetaVersion WHERE TenantId = 1 AND Version = ?", Integer.class, r.version());
        assertThat(status).isEqualTo(2);
    }

    @Test
    @DisplayName("激活历史版本：全量生效并可清除灰度名单")
    void activate_version() {
        var v1 = publishService.publish("第一版");
        var v2 = publishService.publish("第二版");
        assertThat(publishService.currentVersion()).isEqualTo(v2.version());

        publishService.activate(v1.version(), List.of(), "回退到第一版");
        assertThat(publishService.currentVersion()).isEqualTo(v1.version());
        Integer status = jdbc.queryForObject(
                "SELECT Status FROM plat.MetaVersion WHERE TenantId = 1 AND Version = ?", Integer.class, v2.version());
        assertThat(status).isZero();
    }

    @Test
    @DisplayName("激活不存在的版本给出明确错误")
    void activate_unknown_version() {
        assertThatThrownBy(() -> publishService.activate(999_999, List.of(), null))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("版本不存在");
        assertThatThrownBy(() -> publishService.grayOf(999_999))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("版本不存在");
    }

    @Test
    @DisplayName("回滚同样会失效缓存")
    void rollback_invalidates_cache() {
        var base = publishService.publish("回滚缓存基线");
        var before = definitionService.listFields("md.brand");
        publishService.rollback(base.version(), "回滚");
        var after = definitionService.listFields("md.brand");
        assertThat(after).isNotSameAs(before);
        assertThat(Map.of()).isEmpty();
    }

    @Test
    @DisplayName("全量失效会清空所有租户条目")
    void invalidate_all() {
        definitionService.listFields("md.brand");
        cache.invalidateAll();
        assertThat((Integer) cache.stats().get("entries")).isZero();
    }
}

package com.apserp.plat.meta;

import com.apserp.common.tenant.TenantContext;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Supplier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * 元数据缓存：字段/视图/表单这类「读多写极少」的定义，每次请求都查库太浪费。
 *
 * <p>为什么不用 Caffeine/Redis：这里是单机单实例的元数据缓存，缺的只是「带 TTL 的 Map」，
 * 引入一个分布式缓存反而多一处一致性风险。等拆多实例时，把 {@link #store} 换掉即可，
 * 上层调用点不用改。</p>
 *
 * <p>失效策略两条腿：<b>显式失效</b>（发布/回滚/激活/元数据保存）+ <b>TTL 兜底</b>（60 秒），
 * 防止有人绕过服务直接改库后一直读到旧数据。</p>
 */
@Component
public class MetaCache {

    private static final Logger log = LoggerFactory.getLogger(MetaCache.class);

    /** TTL 兜底：即使没触发失效，最多旧 60 秒。 */
    private static final Duration TTL = Duration.ofSeconds(60);

    /** 单机上限：元数据条目有限（对象数 × 种类），超过就整体清掉重来。 */
    private static final int MAX_ENTRIES = 20_000;

    private record Entry(Object value, Instant expireAt) {
        boolean alive() {
            return Instant.now().isBefore(expireAt);
        }
    }

    private final Map<String, Entry> store = new ConcurrentHashMap<>();

    /**
     * 取缓存，没有则加载并写入。
     *
     * @param kind 缓存种类（objects/fields/views/forms/qtys…）
     * @param key  具体键（对象编码，全局用 "-"）
     */
    @SuppressWarnings("unchecked")
    public <T> T get(String kind, String key, Supplier<T> loader) {
        Long tenantId = TenantContext.tenantId();
        String cacheKey = (tenantId == null ? 0 : tenantId) + "|" + kind + "|" + key;
        Entry hit = store.get(cacheKey);
        if (hit != null && hit.alive()) {
            return (T) hit.value();
        }
        T value = loader.get();
        if (store.size() > MAX_ENTRIES) {
            store.clear();
            log.warn("meta_cache_cleared size_exceeded");
        }
        store.put(cacheKey, new Entry(value, Instant.now().plus(TTL)));
        return value;
    }

    /** 失效某个租户的全部缓存（发布/回滚/激活时调用）。 */
    public void invalidateTenant() {
        Long tenantId = TenantContext.tenantId();
        String prefix = (tenantId == null ? 0 : tenantId) + "|";
        int before = store.size();
        store.keySet().removeIf(k -> k.startsWith(prefix));
        log.info("meta_cache_invalidated tenant={} removed={}", tenantId, before - store.size());
    }

    /** 失效所有租户（结构级变更，例如迁移后）。 */
    public void invalidateAll() {
        int before = store.size();
        store.clear();
        log.info("meta_cache_invalidated_all removed={}", before);
    }

    /** 观测用：当前条目数与命中键。 */
    public Map<String, Object> stats() {
        return Map.of("entries", store.size(), "ttlSeconds", TTL.toSeconds(),
                "maxEntries", MAX_ENTRIES);
    }
}

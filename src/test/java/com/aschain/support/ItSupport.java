package com.aschain.support;

import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

/**
 * 集成测试基类：统一连「IT 环境变量指向的库」并关闭 Flyway。
 *
 * <p>为什么必须有它：CI 里应用默认数据源是 localhost 的 aschain_dev（容器里不存在），
 * 没有这段动态属性，任何 {@code @SpringBootTest} 都会在上下文启动时报
 * “Login failed for user 'aschain_dev'”。</p>
 *
 * <p>库结构与种子由 CI 的 flyway-migrate 步骤准备，因此测试里关闭 Flyway，
 * 避免每个测试类重复迁移。</p>
 */
public abstract class ItSupport {

    @DynamicPropertySource
    static void itDataSource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }
}

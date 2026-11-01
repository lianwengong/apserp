package com.apserp.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.MSSQLServerContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * 集成测试：用真 SQL Server 容器跑 Flyway + 引擎。
 * 本机没有 Docker 时跳过（@EnabledIfEnvironmentVariable），CI 上必须跑。
 */
@Testcontainers
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "CI", matches = "true")
class MetaQueryIT {

    @Container
    static MSSQLServerContainer<?> SQL = new MSSQLServerContainer<>("mcr.microsoft.com/mssql/server:2022-latest")
            .acceptLicense();

    @DynamicPropertySource
    static void props(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", SQL::getJdbcUrl);
        registry.add("spring.datasource.username", SQL::getUsername);
        registry.add("spring.datasource.password", SQL::getPassword);
    }

    @Test
    void flyway_should_migrate_and_engine_should_query() {
        assertThat(SQL.isRunning()).isTrue();
        // 具体断言在 S1 第二周补充（需先有 seed 数据）
    }
}

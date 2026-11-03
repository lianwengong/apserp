package com.aschain;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * 应用入口。
 *
 * <p>{@code @EnableScheduling}：租户到期扫描（{@code TenantExpiryJob}）等后台任务依赖它；
 * 目前只有每日一次的轻量扫描，没有引入线程池配置。</p>
 */
@SpringBootApplication
@EnableScheduling
public class AsChainApplication {

    public static void main(String[] args) {
        SpringApplication.run(AsChainApplication.class, args);
    }
}

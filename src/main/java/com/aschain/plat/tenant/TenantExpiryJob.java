package com.aschain.plat.tenant;

import com.aschain.common.tenant.TenantContext;
import com.aschain.plat.notify.NotificationService;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 租户到期自动停用。
 *
 * <p>规则：{@code ExpireAt} 已过且仍在启用状态的租户 → 置为停用，并给每个平台账号
 * 发一条站内通知（「到期日 + 租户」都写进内容，便于管理员直接处理）。
 * 只停用、不删除，续期后手工启用即可。</p>
 *
 * <p>定时任务没有请求上下文，必须自己打开平台作用域：否则 RLS 把租户表/用户表
 * 挡成空集，任务会「跑成功但什么都没做」。</p>
 */
@Service
public class TenantExpiryJob {

    private static final Logger log = LoggerFactory.getLogger(TenantExpiryJob.class);

    private final JdbcTemplate jdbc;
    private final NotificationService notificationService;

    public TenantExpiryJob(JdbcTemplate jdbc, NotificationService notificationService) {
        this.jdbc = jdbc;
        this.notificationService = notificationService;
    }

    /** 每天 01:10 扫一次；cron 可通过 app.tenant.expiry-cron 覆盖（测试里不需要触发）。 */
    @Scheduled(cron = "${app.tenant.expiry-cron:0 10 1 * * *}")
    public void scheduledExpire() {
        int expired = expireOverdue();
        if (expired > 0) {
            log.info("tenant_expiry_job expired={}", expired);
        }
    }

    /**
     * 执行一次到期扫描（测试直接调用）。返回本次停用的租户数。
     *
     * <p>平台作用域在方法内临时打开并恢复，避免污染调用方的上下文。</p>
     */
    @Transactional
    public int expireOverdue() {
        boolean previousScope = TenantContext.isPlatformScope();
        Long previousTenant = TenantContext.tenantId();
        Long previousUser = TenantContext.userId();
        boolean previousAdmin = TenantContext.isPlatformAdmin();
        int previousApp = TenantContext.appType();
        TenantContext.set(null, null, false, TenantContext.APP_PLATFORM, true);
        try {
            List<ExpiredTenant> overdue = jdbc.query("""
                    SELECT Id, Code, Name, ExpireAt
                    FROM plat.Tenant
                    WHERE IsDeleted = 0 AND IsEnabled = 1
                      AND ExpireAt IS NOT NULL AND ExpireAt < sysutcdatetime()
                    """,
                    (rs, i) -> new ExpiredTenant(
                            rs.getLong("Id"),
                            rs.getString("Code"),
                            rs.getString("Name"),
                            rs.getObject("ExpireAt", LocalDateTime.class)));
            if (overdue.isEmpty()) {
                return 0;
            }
            List<Long> platformUsers = jdbc.queryForList(
                    "SELECT Id FROM plat.[User] WHERE IsPlatformAccount = 1 AND IsDeleted = 0 AND IsEnabled = 1",
                    Long.class);
            for (ExpiredTenant tenant : overdue) {
                long tenantId = tenant.id();
                String code = tenant.code();
                String name = tenant.name();
                LocalDateTime expireAt = tenant.expireAt();

                jdbc.update("UPDATE plat.Tenant SET IsEnabled = 0, ModifiedAt = sysutcdatetime() "
                        + "WHERE Id = ? AND IsDeleted = 0", tenantId);
                log.info("tenant_expired tenant={} code={} expireAt={}", tenantId, code, expireAt);

                for (Long userId : platformUsers) {
                    Long homeTenant = jdbc.queryForObject(
                            "SELECT TenantId FROM plat.[User] WHERE Id = ?", Long.class, userId);
                    notificationService.record(homeTenant == null ? tenantId : homeTenant, userId,
                            NotificationService.TYPE_WARN,
                            "租户已到期自动停用：" + name,
                            "租户 " + code + "（" + name + "）到期时间 " + expireAt
                                    + "，已自动停用；续期后请在租户管理中重新启用。",
                            "TENANT", tenantId, "/admin/tenants");
                }
            }
            return overdue.size();
        } finally {
            TenantContext.set(previousTenant, previousUser, previousAdmin, previousApp, previousScope);
        }
    }

    private record ExpiredTenant(long id, String code, String name, LocalDateTime expireAt) {
    }
}

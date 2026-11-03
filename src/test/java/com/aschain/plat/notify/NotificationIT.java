package com.aschain.plat.notify;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.aschain.common.ApiException;
import com.aschain.common.security.JwtService;
import com.aschain.common.tenant.TenantContext;
import com.aschain.plat.auth.AuthService;
import com.aschain.plat.tenant.TenantAdminService;
import com.aschain.plat.tenant.TenantExpiryJob;
import com.aschain.support.ItDb;
import io.jsonwebtoken.Claims;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
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
 * 通知中心 + 租户到期自动停用。
 *
 * <p>通知表 {@code plat.Notification} 早就在库里（V2 建表、V14 加 RLS），
 * 这里验证的是「读写按收件人收口」以及「到期扫描确实会停用并通知平台管理员」。</p>
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class NotificationIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    private static final String PASSWORD = "AsChain@2026";

    @Autowired
    NotificationService notificationService;

    @Autowired
    TenantAdminService tenantAdmin;

    @Autowired
    TenantExpiryJob expiryJob;

    @Autowired
    AuthService authService;

    @Autowired
    JwtService jwtService;

    @Autowired
    JdbcTemplate jdbc;

    private long platformUserId;
    private String code;

    @BeforeEach
    void setUp() {
        code = "IT" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("HHmmssSSS"));
        platformContext();
        platformUserId = jdbc.queryForObject(
                "SELECT Id FROM plat.[User] WHERE TenantId = 1 AND UserName = 'admin'", Long.class);
        jdbc.update("DELETE FROM plat.Notification WHERE RecipientId = ?", platformUserId);
    }

    @AfterEach
    void tearDown() {
        platformContext();
        try {
            jdbc.update("DELETE FROM plat.Notification WHERE RecipientId = ?", platformUserId);
            for (Long id : jdbc.queryForList(
                    "SELECT Id FROM plat.Tenant WHERE Code LIKE 'IT%' AND IsDeleted = 0", Long.class)) {
                jdbc.update("UPDATE plat.[User] SET IsEnabled = 0, IsDeleted = 1 WHERE TenantId = ?", id);
                jdbc.update("UPDATE plat.Tenant SET IsEnabled = 0, IsDeleted = 1 WHERE Id = ?", id);
            }
        } finally {
            TenantContext.clear();
        }
    }

    private void platformContext() {
        AuthService.LoginResult login = authService.loginPlatform("admin", PASSWORD);
        Claims claims = jwtService.parse(login.token());
        TenantContext.set(((Number) claims.get(JwtService.CLAIM_TENANT)).longValue(),
                ((Number) claims.get(JwtService.CLAIM_USER)).longValue(),
                true, TenantContext.APP_PLATFORM,
                Boolean.TRUE.equals(claims.get(JwtService.CLAIM_PLATFORM)));
    }

    @Test
    @DisplayName("通知按收件人隔离：写入、未读计数、标记已读")
    void notification_lifecycle() {
        notificationService.record(1L, platformUserId, NotificationService.TYPE_INFO,
                "IT-通知一", "内容一", "TEST", null, null);
        long second = notificationService.record(1L, platformUserId, NotificationService.TYPE_WARN,
                "IT-通知二", "内容二", "TEST", null, "/admin/tenants");

        assertThat(notificationService.unreadCount()).isEqualTo(2);
        List<NotificationService.NotificationDto> list = notificationService.list(10);
        assertThat(list).extracting(NotificationService.NotificationDto::title)
                .contains("IT-通知一", "IT-通知二");
        // 时间倒序：后写的在前
        assertThat(list.get(0).id()).isEqualTo(second);

        notificationService.markRead(second);
        assertThat(notificationService.unreadCount()).isEqualTo(1);
        // 幂等：重复标记不报错
        notificationService.markRead(second);
        assertThat(notificationService.unreadCount()).isEqualTo(1);

        assertThat(notificationService.markAllRead()).isEqualTo(1);
        assertThat(notificationService.unreadCount()).isZero();
        assertThat(notificationService.list(10)).allMatch(NotificationService.NotificationDto::read);
    }

    @Test
    @DisplayName("不能读/改别人的通知")
    void cannot_touch_other_users_notification() {
        long otherUser = createOtherUser();
        long otherNotification = notificationService.record(1L, otherUser,
                NotificationService.TYPE_INFO, "IT-别人的通知", null, null, null, null);

        assertThat(notificationService.list(50))
                .extracting(NotificationService.NotificationDto::id)
                .doesNotContain(otherNotification);
        assertThatThrownBy(() -> notificationService.markRead(otherNotification))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("通知不存在");
    }

    @Test
    @DisplayName("租户到期：扫描后自动停用，并给平台账号发通知")
    void overdue_tenant_is_disabled_and_notified() {
        TenantAdminService.CreateResult created = tenantAdmin.create(
                new TenantAdminService.CreateRequest(code, "到期测试租户", null, null, 1, "tadmin",
                        "Tenant@2026a", null));
        // 人为把到期时间改到昨天
        jdbc.update("UPDATE plat.Tenant SET ExpireAt = DATEADD(day, -1, sysutcdatetime()) WHERE Id = ?",
                created.tenantId());

        int expired = expiryJob.expireOverdue();
        assertThat(expired).isGreaterThanOrEqualTo(1);

        Boolean enabled = jdbc.queryForObject(
                "SELECT IsEnabled FROM plat.Tenant WHERE Id = ?", Boolean.class, created.tenantId());
        assertThat(enabled).isFalse();
        assertThat(notificationService.list(50))
                .anySatisfy(n -> {
                    assertThat(n.title()).contains("到期自动停用");
                    assertThat(n.content()).contains(code);
                    assertThat(n.businessType()).isEqualTo("TENANT");
                });

        // 再次扫描不会重复发通知（租户已停用）
        int again = expiryJob.expireOverdue();
        assertThat(again).isZero();
    }

    private long createOtherUser() {
        com.aschain.common.security.PasswordHasher hasher = new com.aschain.common.security.PasswordHasher();
        String salt = hasher.newSalt();
        String hash = hasher.hash("Other@2026a", salt);
        // 上一次运行可能留下同名用户：先清掉它的通知再删用户（FK_Notification_RecipientId）
        jdbc.update("DELETE n FROM plat.Notification n JOIN plat.[User] u ON u.Id = n.RecipientId "
                + "WHERE u.TenantId = 1 AND u.UserName = 'it_notify_user'");
        jdbc.update("DELETE FROM plat.[User] WHERE TenantId = 1 AND UserName = 'it_notify_user'");
        jdbc.update("""
                INSERT plat.[User] (TenantId, UserName, PasswordHash, PasswordSalt, DisplayName,
                                    UserType, IsEnabled, MustChangePwd, IsDeleted, CreatedAt)
                VALUES (1, ?, ?, ?, N'通知测试用户', 1, 1, 0, 0, sysutcdatetime())
                """, "it_notify_user", hash, salt);
        Long id = jdbc.queryForObject(
                "SELECT Id FROM plat.[User] WHERE UserName = 'it_notify_user' AND TenantId = 1", Long.class);
        return id == null ? 0L : id;
    }
}

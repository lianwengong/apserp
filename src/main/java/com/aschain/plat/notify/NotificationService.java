package com.aschain.plat.notify;

import com.aschain.common.ApiException;
import com.aschain.common.ErrorCode;
import com.aschain.common.tenant.TenantContext;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/**
 * 站内通知：只做「发给某个人的一条消息」，不承担邮件/短信等外部通道。
 *
 * <p>表是既有的 {@code plat.Notification}（V2 就建好了，且已在 RLS 策略里）：
 * {@code RecipientId} 非空，所以这里只支持「发给具体某个人」，没有全员广播；
 * 需要广播时由调用方按收件人逐条展开。</p>
 */
@Service
public class NotificationService {

    /** 通知类型：1 提示 / 2 警告 / 3 错误（与表里的 MsgType 对齐） */
    public static final int TYPE_INFO = 1;
    public static final int TYPE_WARN = 2;
    public static final int TYPE_ERROR = 3;

    private final JdbcTemplate jdbc;

    public NotificationService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public record NotificationDto(long id, String title, String content, int msgType,
                                  String businessType, Long businessId, String linkUrl,
                                  boolean read, LocalDateTime at) {
    }

    /**
     * 写一条通知。{@code tenantId} 显式传入：平台任务给别的租户发通知时，
     * 当前请求可能根本没有那个租户的上下文。
     */
    public long record(long tenantId, long recipientId, int msgType, String title, String content,
                       String businessType, Long businessId, String linkUrl) {
        if (title == null || title.isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "通知标题不能为空");
        }
        jdbc.update("""
                INSERT plat.Notification (TenantId, RecipientId, Title, Content, MsgType,
                                          BusinessType, BusinessId, LinkUrl, IsRead, At)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, sysutcdatetime())
                """, tenantId, recipientId, title.trim(),
                content == null ? null : content.trim(), msgType,
                businessType, businessId, linkUrl);
        Long id = jdbc.queryForObject(
                "SELECT MAX(Id) FROM plat.Notification WHERE TenantId = ? AND RecipientId = ?",
                Long.class, tenantId, recipientId);
        return id == null ? 0L : id;
    }

    /** 当前用户的通知（最近 N 条，按时间倒序）。 */
    public List<NotificationDto> list(int limit) {
        long tenantId = TenantContext.requireTenantId();
        long userId = requireUserId();
        int size = limit < 1 || limit > 200 ? 50 : limit;
        return jdbc.query("""
                SELECT Id, Title, Content, MsgType, BusinessType, BusinessId, LinkUrl, IsRead, At
                FROM plat.Notification
                WHERE TenantId = ? AND RecipientId = ?
                ORDER BY At DESC, Id DESC
                OFFSET 0 ROWS FETCH NEXT ? ROWS ONLY
                """,
                (rs, i) -> new NotificationDto(
                        rs.getLong("Id"),
                        rs.getString("Title"),
                        rs.getString("Content"),
                        rs.getInt("MsgType"),
                        rs.getString("BusinessType"),
                        rs.getObject("BusinessId", Long.class),
                        rs.getString("LinkUrl"),
                        rs.getBoolean("IsRead"),
                        rs.getObject("At", LocalDateTime.class)),
                tenantId, userId, size);
    }

    public int unreadCount() {
        long tenantId = TenantContext.requireTenantId();
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM plat.Notification WHERE TenantId = ? AND RecipientId = ? AND IsRead = 0",
                Integer.class, tenantId, requireUserId());
        return count == null ? 0 : count;
    }

    public void markRead(long id) {
        long tenantId = TenantContext.requireTenantId();
        int updated = jdbc.update("""
                UPDATE plat.Notification SET IsRead = 1, ReadAt = sysutcdatetime()
                WHERE Id = ? AND TenantId = ? AND RecipientId = ? AND IsRead = 0
                """, id, tenantId, requireUserId());
        if (updated == 0) {
            // 可能是已读（幂等）也可能是别人的/不存在：统一按「已处理」返回，不泄露他人通知是否存在
            Integer exists = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM plat.Notification WHERE Id = ? AND TenantId = ? AND RecipientId = ?",
                    Integer.class, id, tenantId, requireUserId());
            if (exists == null || exists == 0) {
                throw new ApiException(ErrorCode.NOT_FOUND, "通知不存在");
            }
        }
    }

    public int markAllRead() {
        long tenantId = TenantContext.requireTenantId();
        return jdbc.update("""
                UPDATE plat.Notification SET IsRead = 1, ReadAt = sysutcdatetime()
                WHERE TenantId = ? AND RecipientId = ? AND IsRead = 0
                """, tenantId, requireUserId());
    }

    private static long requireUserId() {
        Long userId = TenantContext.userId();
        if (userId == null) {
            throw new ApiException(ErrorCode.UNAUTHORIZED, "未登录或登录已失效");
        }
        return userId;
    }
}

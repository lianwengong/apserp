package com.aschain.plat.notify;

import com.aschain.common.ApiResult;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 站内通知：顶栏铃铛与通知抽屉的数据源。
 *
 * <pre>
 * GET  /api/notification?limit=50     当前用户的通知（时间倒序）
 * GET  /api/notification/unread-count 未读数
 * POST /api/notification/{id}/read    标记已读（幂等）
 * POST /api/notification/read-all     全部已读
 * </pre>
 */
@RestController
@RequestMapping("/api/notification")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping
    public ApiResult<List<NotificationService.NotificationDto>> list(
            @RequestParam(defaultValue = "50") int limit) {
        return ApiResult.ok(notificationService.list(limit));
    }

    @GetMapping("/unread-count")
    public ApiResult<Map<String, Integer>> unreadCount() {
        return ApiResult.ok(Map.of("count", notificationService.unreadCount()));
    }

    @PostMapping("/{id}/read")
    public ApiResult<Void> markRead(@PathVariable long id) {
        notificationService.markRead(id);
        return ApiResult.ok(null);
    }

    @PostMapping("/read-all")
    public ApiResult<Map<String, Integer>> markAllRead() {
        return ApiResult.ok(Map.of("updated", notificationService.markAllRead()));
    }
}

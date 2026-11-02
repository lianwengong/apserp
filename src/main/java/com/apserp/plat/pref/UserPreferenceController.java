package com.apserp.plat.pref;

import com.apserp.common.ApiResult;
import java.util.Map;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 用户偏好接口：外观等纯展示设置的跨设备同步。
 *
 * <pre>
 * 全部  GET    /api/preference            → {"appearance":"{...}"}
 * 单个  GET    /api/preference/{key}      → {"value":"{...}"}（没有则 null）
 * 保存  PUT    /api/preference/{key}      body: {"value":"{...}"}
 * 删除  DELETE /api/preference/{key}
 * </pre>
 */
@RestController
@RequestMapping("/api/preference")
public class UserPreferenceController {

    private final UserPreferenceService preferenceService;

    public UserPreferenceController(UserPreferenceService preferenceService) {
        this.preferenceService = preferenceService;
    }

    @GetMapping
    public ApiResult<Map<String, String>> all() {
        return ApiResult.ok(preferenceService.all());
    }

    @GetMapping("/{key}")
    public ApiResult<Map<String, String>> get(@PathVariable String key) {
        String value = preferenceService.get(key);
        return ApiResult.ok(value == null ? Map.of() : Map.of("value", value));
    }

    @PutMapping("/{key}")
    public ApiResult<Void> save(@PathVariable String key, @RequestBody Map<String, String> body) {
        preferenceService.save(key, body == null ? null : body.get("value"));
        return ApiResult.ok(null);
    }

    @DeleteMapping("/{key}")
    public ApiResult<Void> delete(@PathVariable String key) {
        preferenceService.delete(key);
        return ApiResult.ok(null);
    }
}

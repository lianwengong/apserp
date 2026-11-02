package com.aschain.plat.code;

import com.aschain.common.ApiResult;
import com.aschain.common.security.RequiresPermission;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 编号引擎接口。
 *
 * <pre>
 * 运行时取号（任何登录用户）：
 *   GET  /api/runtime/code/preview?code=PO       预览下一个号，不消耗
 *   POST /api/runtime/code/next?code=PO          取号（消耗流水）
 * 管理（DESIGN:module）：
 *   GET  /api/admin/code-rules                   规则列表
 *   POST /api/admin/code-rules                   新增/修改
 *   GET  /api/admin/code-rules/{code}/statistics 当前期间与流水
 * </pre>
 */
@RestController
@RequestMapping("/api")
public class CodeRuleController {

    private final CodeRuleService codeRuleService;

    public CodeRuleController(CodeRuleService codeRuleService) {
        this.codeRuleService = codeRuleService;
    }

    @GetMapping("/runtime/code/preview")
    public ApiResult<Map<String, String>> preview(@RequestParam String code) {
        return ApiResult.ok(Map.of("docNo", codeRuleService.preview(code)));
    }

    @PostMapping("/runtime/code/next")
    public ApiResult<Map<String, String>> next(@RequestParam String code) {
        return ApiResult.ok(Map.of("docNo", codeRuleService.next(code)));
    }

    @GetMapping("/admin/code-rules")
    @RequiresPermission(value = "DESIGN:module", action = "read")
    public ApiResult<List<CodeRuleService.RuleDto>> list() {
        return ApiResult.ok(codeRuleService.list());
    }

    @PostMapping("/admin/code-rules")
    @RequiresPermission(value = "DESIGN:module", action = "write")
    public ApiResult<Map<String, Long>> save(@RequestBody CodeRuleService.RuleSaveRequest body) {
        return ApiResult.ok(Map.of("id", codeRuleService.save(body)));
    }

    @GetMapping("/admin/code-rules/{code}/statistics")
    @RequiresPermission(value = "DESIGN:module", action = "read")
    public ApiResult<Map<String, Object>> statistics(@PathVariable String code) {
        return ApiResult.ok(codeRuleService.statistics(code));
    }
}

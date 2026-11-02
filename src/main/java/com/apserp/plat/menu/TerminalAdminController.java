package com.apserp.plat.menu;

import com.apserp.common.ApiResult;
import com.apserp.common.security.RequiresPermission;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 终端与功能模块接口：终端配置「能用哪些功能模块」，菜单只能在已启用的模块里选。
 *
 * <pre>
 * 概览      GET /api/admin/terminals/overview
 * 终端列表  GET /api/admin/terminals
 * 已启用    GET /api/admin/terminals/{terminalType}/modules
 * 全量+状态 GET /api/admin/terminals/{terminalType}/modules/all
 * 保存      PUT /api/admin/terminals/{terminalType}/modules    body: [模块Id...]
 * </pre>
 */
@RestController
@RequestMapping("/api/admin/terminals")
@RequiresPermission(value = "DESIGN:module", action = "read")
public class TerminalAdminController {

    private final TerminalAdminService terminalAdmin;

    public TerminalAdminController(TerminalAdminService terminalAdmin) {
        this.terminalAdmin = terminalAdmin;
    }

    @GetMapping("/overview")
    public ApiResult<Map<String, Object>> overview() {
        return ApiResult.ok(terminalAdmin.overview());
    }

    @GetMapping
    public ApiResult<List<TerminalAdminService.TerminalDto>> terminals() {
        return ApiResult.ok(terminalAdmin.terminals());
    }

    @GetMapping("/{terminalType}/modules")
    public ApiResult<List<TerminalAdminService.ModuleOption>> modules(@PathVariable int terminalType) {
        return ApiResult.ok(terminalAdmin.enabledModules(terminalType));
    }

    @GetMapping("/{terminalType}/modules/all")
    public ApiResult<List<TerminalAdminService.ModuleOption>> allModules(@PathVariable int terminalType) {
        return ApiResult.ok(terminalAdmin.allModules(terminalType));
    }

    @PutMapping("/{terminalType}/modules")
    @RequiresPermission(value = "DESIGN:module", action = "write")
    public ApiResult<List<TerminalAdminService.ModuleOption>> saveModules(
            @PathVariable int terminalType, @RequestBody(required = false) List<Long> moduleIds) {
        return ApiResult.ok(terminalAdmin.saveModules(terminalType, moduleIds));
    }

    @org.springframework.web.bind.annotation.PostMapping("/{terminalType}/modules/{moduleId}")
    @RequiresPermission(value = "DESIGN:module", action = "write")
    public ApiResult<List<TerminalAdminService.ModuleOption>> enableModule(
            @PathVariable int terminalType, @PathVariable long moduleId) {
        return ApiResult.ok(terminalAdmin.enableModule(terminalType, moduleId));
    }

    @org.springframework.web.bind.annotation.DeleteMapping("/{terminalType}/modules/{moduleId}")
    @RequiresPermission(value = "DESIGN:module", action = "write")
    public ApiResult<List<TerminalAdminService.ModuleOption>> disableModule(
            @PathVariable int terminalType, @PathVariable long moduleId) {
        return ApiResult.ok(terminalAdmin.disableModule(terminalType, moduleId));
    }

    /** 菜单表单用：某终端可选的模块（只要 id/code/name）。 */
    @GetMapping("/{terminalType}/module-options")
    public ApiResult<List<TerminalAdminService.ModuleOption>> moduleOptions(
            @PathVariable int terminalType,
            @RequestParam(required = false) String keyword) {
        List<TerminalAdminService.ModuleOption> list = terminalAdmin.enabledModules(terminalType);
        String key = keyword == null ? "" : keyword.trim().toLowerCase();
        if (key.isEmpty()) {
            return ApiResult.ok(list);
        }
        return ApiResult.ok(list.stream()
                .filter(m -> m.code().toLowerCase().contains(key) || m.name().toLowerCase().contains(key))
                .toList());
    }
}

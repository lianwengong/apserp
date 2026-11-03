package com.aschain.plat.menu;

import com.aschain.common.ApiResult;
import com.aschain.common.security.RequiresPermission;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 系统功能模块管理窗口接口。
 *
 * <pre>
 * 概览    GET    /api/admin/modules/overview
 * 模块树  GET    /api/admin/modules/tree?keyword=
 * 保存    POST   /api/admin/modules                     带 id 即更新
 * 删除    DELETE /api/admin/modules/{id}?force=
 * 功能点  GET    /api/admin/modules/{moduleId}/functions
 *         POST   /api/admin/modules/functions           带 id 即更新
 *         DELETE /api/admin/modules/functions/{id}
 * 动作链  PUT    /api/admin/modules/functions/{id}/actions
 * </pre>
 */
@RestController
@RequestMapping("/api/admin/modules")
@RequiresPermission(value = "DESIGN:module", action = "read")
public class ModuleAdminController {

    private final ModuleAdminService moduleAdmin;

    public ModuleAdminController(ModuleAdminService moduleAdmin) {
        this.moduleAdmin = moduleAdmin;
    }

    @GetMapping("/overview")
    public ApiResult<Map<String, Object>> overview() {
        return ApiResult.ok(moduleAdmin.overview());
    }

    /** 模型关系图：模块 / 功能点 / 菜单 / 终端 / 权限点的实际规模与连接情况。 */
    @GetMapping("/model-map")
    public ApiResult<java.util.Map<String, Object>> modelMap() {
        return ApiResult.ok(moduleAdmin.modelMap());
    }

    @GetMapping("/tree")
    public ApiResult<List<ModuleAdminService.ModuleNode>> tree(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer tenantId) {
        return ApiResult.ok(moduleAdmin.tree(keyword, tenantId));
    }

    /** 租户模块开通/停用：只影响该租户的模块副本与其菜单可见性。 */
    @PostMapping("/tenants/{tenantId}/modules/{code}/toggle")
    @RequiresPermission(value = "DESIGN:module", action = "write")
    public ApiResult<Map<String, Integer>> toggleTenantModule(@PathVariable long tenantId,
                                                              @PathVariable String code,
                                                              @RequestBody ToggleRequest body) {
        int menus = moduleAdmin.setModuleEnabled(tenantId, code, body.enabled());
        return ApiResult.ok(Map.of("menus", menus));
    }

    public record ToggleRequest(boolean enabled) {
    }

    @PostMapping
    @RequiresPermission(value = "DESIGN:module", action = "write")
    public ApiResult<Map<String, Long>> save(@RequestBody ModuleAdminService.ModuleSaveRequest body) {
        return ApiResult.ok(Map.of("id", moduleAdmin.saveModule(body)));
    }

    @DeleteMapping("/{id}")
    @RequiresPermission(value = "DESIGN:module", action = "write")
    public ApiResult<Void> delete(@PathVariable long id,
                                  @RequestParam(defaultValue = "false") boolean force) {
        moduleAdmin.deleteModule(id, force);
        return ApiResult.ok(null);
    }

    @GetMapping("/{moduleId}/functions")
    public ApiResult<List<ModuleAdminService.FunctionDto>> functions(@PathVariable long moduleId) {
        return ApiResult.ok(moduleAdmin.functionsOf(moduleId));
    }

    @PostMapping("/functions")
    @RequiresPermission(value = "DESIGN:module", action = "write")
    public ApiResult<Map<String, Long>> saveFunction(
            @RequestBody ModuleAdminService.FunctionSaveRequest body) {
        return ApiResult.ok(Map.of("id", moduleAdmin.saveFunction(body)));
    }

    @DeleteMapping("/functions/{id}")
    @RequiresPermission(value = "DESIGN:module", action = "write")
    public ApiResult<Void> deleteFunction(@PathVariable long id) {
        moduleAdmin.deleteFunction(id);
        return ApiResult.ok(null);
    }

    @org.springframework.web.bind.annotation.PutMapping("/functions/{id}/actions")
    @RequiresPermission(value = "DESIGN:module", action = "write")
    public ApiResult<List<ModuleAdminService.ActionDto>> saveActions(
            @PathVariable long id,
            @RequestBody(required = false) List<ModuleAdminService.ActionSaveRequest> body) {
        return ApiResult.ok(moduleAdmin.saveActions(id, body));
    }
}

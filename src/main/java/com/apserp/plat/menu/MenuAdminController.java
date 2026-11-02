package com.apserp.plat.menu;

import com.apserp.common.ApiResult;
import com.apserp.common.security.RequiresPermission;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 菜单设置管理窗口接口。
 *
 * <pre>
 * 菜单树  GET    /api/admin/menus/tree?keyword=&amp;moduleId=
 * 选项    GET    /api/admin/menus/options          模块/页面/菜单类型/打开方式/终端
 * 保存    POST   /api/admin/menus                  带 id 即更新；terminals 为终端可见列表
 * 移动    POST   /api/admin/menus/move             拖拽/上移下移
 * 删除    DELETE /api/admin/menus/{id}
 * 终端    GET    /api/admin/menus/{id}/terminals
 *         PUT    /api/admin/menus/{id}/terminals
 * </pre>
 */
@RestController
@RequestMapping("/api/admin/menus")
@RequiresPermission(value = "DESIGN:menu", action = "read")
public class MenuAdminController {

    private final MenuAdminService menuAdmin;

    public MenuAdminController(MenuAdminService menuAdmin) {
        this.menuAdmin = menuAdmin;
    }

    @GetMapping("/tree")
    public ApiResult<List<MenuAdminService.MenuNode>> tree(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Long moduleId) {
        return ApiResult.ok(menuAdmin.tree(keyword, moduleId));
    }

    @GetMapping("/options")
    public ApiResult<Map<String, Object>> options() {
        return ApiResult.ok(menuAdmin.options());
    }

    @PostMapping
    @RequiresPermission(value = "DESIGN:menu", action = "write")
    public ApiResult<Map<String, Long>> save(@RequestBody MenuAdminService.MenuSaveRequest body) {
        return ApiResult.ok(Map.of("id", menuAdmin.save(body)));
    }

    @PostMapping("/move")
    @RequiresPermission(value = "DESIGN:menu", action = "write")
    public ApiResult<Void> move(@RequestBody MenuAdminService.MoveRequest body) {
        menuAdmin.move(body);
        return ApiResult.ok(null);
    }

    @DeleteMapping("/{id}")
    @RequiresPermission(value = "DESIGN:menu", action = "write")
    public ApiResult<Void> delete(@PathVariable long id) {
        menuAdmin.delete(id);
        return ApiResult.ok(null);
    }

    @GetMapping("/{id}/terminals")
    public ApiResult<List<Integer>> terminals(@PathVariable long id) {
        return ApiResult.ok(menuAdmin.terminalsOf(id));
    }

    @PutMapping("/{id}/terminals")
    @RequiresPermission(value = "DESIGN:menu", action = "write")
    public ApiResult<List<Integer>> saveTerminals(@PathVariable long id,
                                                  @RequestBody List<Integer> terminals) {
        menuAdmin.saveTerminals(id, terminals);
        return ApiResult.ok(menuAdmin.terminalsOf(id));
    }
}

package com.apserp.plat.menu;

import com.apserp.common.ApiResult;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 功能模块菜单：前端侧边栏直接渲染这棵树，不再按数据对象拼菜单。
 *
 * <pre>
 * GET /api/menu/tree?terminal=1   终端 1=PC，2=PDA，3=POS，4=移动，5=小程序，6=其他
 * </pre>
 */
@RestController
@RequestMapping("/api/menu")
public class MenuController {

    private final MenuService menuService;

    public MenuController(MenuService menuService) {
        this.menuService = menuService;
    }

    @GetMapping("/tree")
    public ApiResult<List<MenuService.MenuNode>> tree(
            @RequestParam(defaultValue = "1") int terminal) {
        return ApiResult.ok(menuService.tree(terminal));
    }
}

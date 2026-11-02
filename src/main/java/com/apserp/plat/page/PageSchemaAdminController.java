package com.apserp.plat.page;

import com.apserp.common.ApiResult;
import com.apserp.common.security.RequiresPermission;
import com.apserp.plat.page.PageSchemaService.PageSchemaDto;
import com.apserp.plat.page.PageSchemaService.SaveRequest;
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
 * 平台管理：页面编排（PageSchema）CRUD。
 *
 * <pre>
 * 列表  GET    /api/admin/page-schemas?keyword=
 * 单条  GET    /api/admin/page-schemas/{id}
 * 保存  POST   /api/admin/page-schemas         带 id 即更新，编码不可改
 * 删除  DELETE /api/admin/page-schemas/{id}    软删
 * </pre>
 */
@RestController
@RequestMapping("/api/admin/page-schemas")
@RequiresPermission(value = "DESIGN:publish", action = "read")
public class PageSchemaAdminController {

    private final PageSchemaService pages;

    public PageSchemaAdminController(PageSchemaService pages) {
        this.pages = pages;
    }

    @GetMapping
    public ApiResult<List<PageSchemaDto>> list(@RequestParam(required = false) String keyword) {
        return ApiResult.ok(pages.list(keyword));
    }

    @GetMapping("/{id}")
    public ApiResult<PageSchemaDto> get(@PathVariable long id) {
        return ApiResult.ok(pages.get(id));
    }

    @PostMapping
    @RequiresPermission(value = "DESIGN:publish", action = "write")
    public ApiResult<Map<String, Long>> save(@RequestBody SaveRequest body) {
        return ApiResult.ok(Map.of("id", pages.save(body)));
    }

    @DeleteMapping("/{id}")
    @RequiresPermission(value = "DESIGN:publish", action = "write")
    public ApiResult<Void> delete(@PathVariable long id) {
        pages.delete(id);
        return ApiResult.ok(null);
    }
}

package com.apserp.plat.page;

import com.apserp.common.ApiResult;
import com.apserp.plat.page.PageSchemaService.PageSchemaDto;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

/**
 * 运行时页面定义读取。
 *
 * <p>返回 {@code data: null} 表示该租户没有远程定义，前端回退本地 PageSchema；
 * 不用 404 是为了避免每次进入页面都在控制台留下无意义的红色错误。</p>
 */
@RestController
public class PageSchemaController {

    private final PageSchemaService pages;

    public PageSchemaController(PageSchemaService pages) {
        this.pages = pages;
    }

    @GetMapping("/api/page-schema/{code}")
    public ApiResult<PageSchemaDto> get(@PathVariable String code) {
        return ApiResult.ok(pages.findEnabled(code).orElse(null));
    }
}

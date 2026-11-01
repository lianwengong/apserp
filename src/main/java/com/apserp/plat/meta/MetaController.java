package com.apserp.plat.meta;

import com.apserp.common.ApiResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** 通用元数据查询入口：前端所有列表页都走这一个接口。 */
@RestController
@RequestMapping("/api/meta")
public class MetaController {

    private final MetaQueryService service;

    public MetaController(MetaQueryService service) {
        this.service = service;
    }

    @GetMapping("/{objectCode}")
    public ApiResult<MetaQueryService.PageResult> list(
            @PathVariable String objectCode,
            @RequestParam(required = false) String filters,
            @RequestParam(required = false) String sort,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "50") int size) {
        return ApiResult.ok(service.query(objectCode, filters, sort, page, size));
    }
}

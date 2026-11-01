package com.apserp.plat.meta;

import com.apserp.common.ApiResult;
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
 * 元数据接口：前端渲染一个页面所需的全部配置都从这里取。
 *
 * <pre>
 * GET  /api/meta/objects                     数据对象列表
 * GET  /api/meta/objects/{code}              单个数据对象
 * GET  /api/meta/objects/{code}/fields       字段定义
 * GET  /api/meta/objects/{code}/views        列表视图（含列）
 * GET  /api/meta/objects/{code}/forms        表单布局（含字段）
 * GET  /api/meta/{objectCode}                数据查询（分页）
 * POST /api/meta/{objectCode}                保存（新增/修改）
 * </pre>
 */
@RestController
@RequestMapping("/api/meta")
public class MetaController {

    private final MetaQueryService queryService;
    private final MetaDefinitionService definitionService;
    private final MetaSaveService saveService;

    public MetaController(MetaQueryService queryService,
                          MetaDefinitionService definitionService,
                          MetaSaveService saveService) {
        this.queryService = queryService;
        this.definitionService = definitionService;
        this.saveService = saveService;
    }

    // ------------------------------------------------------------ 定义

    @GetMapping("/objects")
    public ApiResult<List<MetaDefinitionService.DataObjectDto>> objects() {
        return ApiResult.ok(definitionService.listObjects());
    }

    @GetMapping("/objects/{code}")
    public ApiResult<MetaDefinitionService.DataObjectDto> object(@PathVariable String code) {
        return ApiResult.ok(definitionService.getObject(code));
    }

    @GetMapping("/objects/{code}/fields")
    public ApiResult<List<MetaDefinitionService.FieldDto>> fields(@PathVariable String code) {
        return ApiResult.ok(definitionService.listFields(code));
    }

    @GetMapping("/objects/{code}/views")
    public ApiResult<List<MetaDefinitionService.ListViewDto>> views(@PathVariable String code) {
        return ApiResult.ok(definitionService.listViews(code));
    }

    @GetMapping("/objects/{code}/forms")
    public ApiResult<List<MetaDefinitionService.FormLayoutDto>> forms(@PathVariable String code) {
        return ApiResult.ok(definitionService.listFormLayouts(code));
    }

    // ------------------------------------------------------------ 数据

    @GetMapping("/{objectCode}")
    public ApiResult<MetaQueryService.PageResult> list(
            @PathVariable String objectCode,
            @RequestParam(required = false) String filters,
            @RequestParam(required = false) String sort,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "50") int size) {
        return ApiResult.ok(queryService.query(objectCode, filters, sort, page, size));
    }

    @PostMapping("/{objectCode}")
    public ApiResult<Map<String, Long>> save(@PathVariable String objectCode,
                                             @RequestBody String json) {
        long id = saveService.save(objectCode, json);
        return ApiResult.ok(Map.of("id", id));
    }
}

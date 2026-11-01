package com.apserp.plat.meta;

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
 * 设计器接口：规则、按钮动作、审批流、发布回滚、权限矩阵。
 *
 * <p>所有写接口都要求对应设计器权限点（平台管理员直通）；读接口要求同名 read 权限。</p>
 *
 * <pre>
 * 概览      GET  /api/design/overview
 * 规则      GET  /api/design/rules
 *           POST /api/design/rules                 新增/更新（带 id 即更新）
 *           DELETE /api/design/rules/{code}
 *           POST /api/design/rules/validate         表达式即时校验
 *           POST /api/design/rules/test             规则测试台
 * 绑定      GET  /api/design/rules/bindings?objectCode=
 *           POST /api/design/rules/bindings
 *           DELETE /api/design/rules/bindings/{id}
 * 按钮      GET  /api/design/buttons?objectCode=
 *           POST /api/design/buttons
 *           DELETE /api/design/buttons/{code}
 * 审批      GET  /api/design/approvals
 *           POST /api/design/approvals
 *           POST /api/design/approvals/{code}/publish
 *           GET  /api/design/approvals/dictionaries
 *           GET  /api/design/approvals/users
 * 发布      POST /api/design/publish
 *           GET  /api/design/versions
 *           GET  /api/design/versions/{version}
 *           POST /api/design/versions/{version}/rollback
 *           GET  /api/design/versions/{version}/diff
 * 权限      GET  /api/design/permissions/roles
 *           GET  /api/design/permissions/resources?keyword=
 *           GET  /api/design/permissions/roles/{roleId}/matrix
 *           PUT  /api/design/permissions/roles/{roleId}/matrix
 *           GET  /api/design/permissions/fields?roleId=&amp;objectCode=
 *           PUT  /api/design/permissions/fields
 *           GET  /api/design/permissions/functions
 * </pre>
 */
@RestController
@RequestMapping("/api/design")
public class DesignerController {

    private final RuleService ruleService;
    private final ActionService actionService;
    private final ApprovalService approvalService;
    private final MetaPublishService publishService;
    private final PermissionDesignService permissionDesign;

    public DesignerController(RuleService ruleService, ActionService actionService,
                              ApprovalService approvalService, MetaPublishService publishService,
                              PermissionDesignService permissionDesign) {
        this.ruleService = ruleService;
        this.actionService = actionService;
        this.approvalService = approvalService;
        this.publishService = publishService;
        this.permissionDesign = permissionDesign;
    }

    // ---------------------------------------------------------------- 概览

    @GetMapping("/overview")
    @RequiresPermission(value = "DESIGN:publish", action = "read")
    public ApiResult<Map<String, Object>> overview() {
        return ApiResult.ok(permissionDesign.overview());
    }

    // ---------------------------------------------------------------- 规则

    @GetMapping("/rules")
    @RequiresPermission(value = "DESIGN:rule", action = "read")
    public ApiResult<List<RuleService.RuleDto>> rules() {
        return ApiResult.ok(ruleService.listRules());
    }

    @PostMapping("/rules")
    @RequiresPermission(value = "DESIGN:rule", action = "write")
    public ApiResult<Map<String, Long>> saveRule(@RequestBody RuleSaveBody body) {
        long id = ruleService.saveRule(body.id(), new RuleService.RuleSaveRequest(
                body.code(), body.name(), body.ruleType(), body.expression(), body.errorMessage(),
                body.severity() <= 0 ? 2 : body.severity(), body.enabled(), body.remark()));
        return ApiResult.ok(Map.of("id", id));
    }

    public record RuleSaveBody(Long id, String code, String name, Integer ruleType, String expression,
                               String errorMessage, Integer severity, boolean enabled, String remark) {

    }

    @DeleteMapping("/rules/{code}")
    @RequiresPermission(value = "DESIGN:rule", action = "write")
    public ApiResult<Void> deleteRule(@PathVariable String code) {
        ruleService.deleteRule(code);
        return ApiResult.ok(null);
    }

    @PostMapping("/rules/validate")
    @RequiresPermission(value = "DESIGN:rule", action = "read")
    public ApiResult<Map<String, Object>> validateRule(@RequestBody Map<String, String> body) {
        return ApiResult.ok(ruleService.validateExpression(body.getOrDefault("expression", "")));
    }

    @PostMapping("/rules/test")
    @RequiresPermission(value = "DESIGN:rule", action = "read")
    public ApiResult<List<Map<String, Object>>> testRule(@RequestBody RuleTestBody body) {
        return ApiResult.ok(ruleService.test(body.objectCode(), body.triggerEvent() <= 0 ? 1 : body.triggerEvent(),
                body.data()));
    }

    public record RuleTestBody(String objectCode, Integer triggerEvent, Map<String, Object> data) {

    }

    @GetMapping("/rules/bindings")
    @RequiresPermission(value = "DESIGN:rule", action = "read")
    public ApiResult<List<RuleService.RuleBindingDto>> bindings(@RequestParam(required = false) String objectCode) {
        return ApiResult.ok(ruleService.listBindings(objectCode));
    }

    @PostMapping("/rules/bindings")
    @RequiresPermission(value = "DESIGN:rule", action = "write")
    public ApiResult<Map<String, Long>> bind(@RequestBody RuleService.BindingSaveRequest body) {
        return ApiResult.ok(Map.of("id", ruleService.bind(body)));
    }

    @DeleteMapping("/rules/bindings/{id}")
    @RequiresPermission(value = "DESIGN:rule", action = "write")
    public ApiResult<Void> unbind(@PathVariable long id) {
        ruleService.unbind(id);
        return ApiResult.ok(null);
    }

    // ---------------------------------------------------------------- 按钮

    @GetMapping("/buttons")
    @RequiresPermission(value = "DESIGN:action", action = "read")
    public ApiResult<List<ActionService.ButtonDto>> buttons(@RequestParam(required = false) String objectCode) {
        return ApiResult.ok(actionService.listButtons(objectCode));
    }

    @PostMapping("/buttons")
    @RequiresPermission(value = "DESIGN:action", action = "write")
    public ApiResult<Map<String, Long>> saveButton(@RequestBody ActionService.ButtonSaveRequest body) {
        return ApiResult.ok(Map.of("id", actionService.saveButton(body.id(), body)));
    }

    @DeleteMapping("/buttons/{code}")
    @RequiresPermission(value = "DESIGN:action", action = "write")
    public ApiResult<Void> deleteButton(@PathVariable String code) {
        actionService.deleteButton(code);
        return ApiResult.ok(null);
    }

    @GetMapping("/buttons/functions")
    @RequiresPermission(value = "DESIGN:action", action = "read")
    public ApiResult<List<Map<String, Object>>> functions(@RequestParam String objectCode) {
        return ApiResult.ok(actionService.functionsOf(objectCode));
    }

    // ---------------------------------------------------------------- 审批

    @GetMapping("/approvals")
    @RequiresPermission(value = "DESIGN:approval", action = "read")
    public ApiResult<List<ApprovalService.DefDto>> approvals() {
        return ApiResult.ok(approvalService.listDefs());
    }

    @PostMapping("/approvals")
    @RequiresPermission(value = "DESIGN:approval", action = "write")
    public ApiResult<Map<String, Long>> saveApproval(@RequestBody ApprovalService.DefSaveRequest body) {
        return ApiResult.ok(Map.of("id", approvalService.saveDef(body.id(), body)));
    }

    @PostMapping("/approvals/{code}/publish")
    @RequiresPermission(value = "DESIGN:approval", action = "write")
    public ApiResult<Void> publishApproval(@PathVariable String code) {
        approvalService.publish(code);
        return ApiResult.ok(null);
    }

    @GetMapping("/approvals/dictionaries")
    @RequiresPermission(value = "DESIGN:approval", action = "read")
    public ApiResult<Map<String, Object>> approvalDict() {
        return ApiResult.ok(approvalService.dictionaries());
    }

    @GetMapping("/approvals/users")
    @RequiresPermission(value = "DESIGN:approval", action = "read")
    public ApiResult<List<Map<String, Object>>> users() {
        return ApiResult.ok(approvalService.users());
    }

    // ---------------------------------------------------------------- 发布

    @PostMapping("/publish")
    @RequiresPermission(value = "DESIGN:publish", action = "write")
    public ApiResult<MetaPublishService.PublishResult> publish(@RequestBody Map<String, String> body) {
        return ApiResult.ok(publishService.publish(body.getOrDefault("remark", "")));
    }

    @GetMapping("/versions")
    @RequiresPermission(value = "DESIGN:publish", action = "read")
    public ApiResult<List<MetaPublishService.VersionDto>> versions() {
        return ApiResult.ok(publishService.versions());
    }

    @GetMapping("/versions/{version}")
    @RequiresPermission(value = "DESIGN:publish", action = "read")
    public ApiResult<Map<String, Object>> version(@PathVariable int version) {
        return ApiResult.ok(publishService.payload(version));
    }

    @PostMapping("/versions/{version}/rollback")
    @RequiresPermission(value = "DESIGN:publish", action = "write")
    public ApiResult<MetaPublishService.PublishResult> rollback(@PathVariable int version,
                                                               @RequestBody(required = false) Map<String, String> body) {
        String remark = body == null ? null : body.get("remark");
        return ApiResult.ok(publishService.rollback(version, remark));
    }

    @GetMapping("/versions/{version}/diff")
    @RequiresPermission(value = "DESIGN:publish", action = "read")
    public ApiResult<MetaPublishService.DiffResult> diff(@PathVariable int version) {
        return ApiResult.ok(publishService.diffAgainstCurrent(version));
    }

    // ---------------------------------------------------------------- 权限

    @GetMapping("/permissions/roles")
    @RequiresPermission(value = "DESIGN:publish", action = "read")
    public ApiResult<List<PermissionDesignService.RoleDto>> roles() {
        return ApiResult.ok(permissionDesign.listRoles());
    }

    @GetMapping("/permissions/resources")
    @RequiresPermission(value = "DESIGN:publish", action = "read")
    public ApiResult<List<PermissionDesignService.ResourceDto>> resources(
            @RequestParam(required = false) String keyword) {
        return ApiResult.ok(permissionDesign.listResources(keyword));
    }

    @GetMapping("/permissions/roles/{roleId}/matrix")
    @RequiresPermission(value = "DESIGN:publish", action = "read")
    public ApiResult<PermissionDesignService.RoleMatrix> matrix(@PathVariable long roleId) {
        return ApiResult.ok(permissionDesign.getMatrix(roleId));
    }

    @PutMapping("/permissions/roles/{roleId}/matrix")
    @RequiresPermission(value = "DESIGN:publish", action = "write")
    public ApiResult<Map<String, Integer>> saveMatrix(@PathVariable long roleId,
                                                      @RequestBody Map<String, List<String>> body) {
        int n = permissionDesign.saveMatrix(roleId, body.getOrDefault("resourceKeys", List.of()));
        return ApiResult.ok(Map.of("granted", n));
    }

    @GetMapping("/permissions/fields")
    @RequiresPermission(value = "DESIGN:publish", action = "read")
    public ApiResult<PermissionDesignService.FieldMatrix> fields(@RequestParam long roleId,
                                                                 @RequestParam String objectCode) {
        return ApiResult.ok(permissionDesign.fieldMatrix(roleId, objectCode));
    }

    @PutMapping("/permissions/fields")
    @RequiresPermission(value = "DESIGN:publish", action = "write")
    public ApiResult<Map<String, Integer>> saveFields(@RequestBody FieldMatrixBody body) {
        int n = permissionDesign.saveFieldMatrix(body.roleId(), body.objectCode(), body.access());
        return ApiResult.ok(Map.of("saved", n));
    }

    public record FieldMatrixBody(long roleId, String objectCode, Map<String, Integer> access) {

    }

    @GetMapping("/permissions/functions")
    @RequiresPermission(value = "DESIGN:publish", action = "read")
    public ApiResult<List<Map<String, Object>>> functionTree() {
        return ApiResult.ok(permissionDesign.functionTree());
    }
}

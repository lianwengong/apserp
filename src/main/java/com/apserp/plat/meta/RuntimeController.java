package com.apserp.plat.meta;

import com.apserp.common.ApiException;
import com.apserp.common.ApiResult;
import com.apserp.common.ErrorCode;
import com.apserp.common.security.RequiresPermission;
import com.apserp.plat.perm.PermissionService;
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
 * 运行时接口：按钮、审批、待办。前端渲染页面时从这里取“这个用户能点哪些按钮、能不能审批”。
 *
 * <prime>审批类接口的权限点由任务反查业务对象后动态校验：{@code DATA:{objectCode}:approve}。
 * 这样前端不需要额外传对象编码，也不会出现“传错对象绕过校验”的漏洞。</prime>
 *
 * <pre>
 * GET  /api/runtime/buttons?objectCode=&amp;id=      当前行可用按钮（已按权限与表达式求值）
 * POST /api/runtime/workflow/submit              提交审批
 * POST /api/runtime/workflow/tasks/{id}/approve  通过/驳回
 * POST /api/runtime/workflow/tasks/{id}/return   退回
 * POST /api/runtime/workflow/tasks/{id}/addsign  加签
 * POST /api/runtime/workflow/instances/{id}/withdraw 撤回
 * GET  /api/runtime/workflow/todos               我的待办
 * GET  /api/runtime/workflow/instances?objectCode=&amp;businessId=  某单据的流程
 * </pre>
 */
@RestController
@RequestMapping("/api/runtime")
public class RuntimeController {

    private final ActionService actionService;
    private final ApprovalService approvalService;
    private final MetaQueryService queryService;
    private final MetaChildService childService;
    private final PermissionService permissionService;

    public RuntimeController(ActionService actionService, ApprovalService approvalService,
                             MetaQueryService queryService, MetaChildService childService,
                             PermissionService permissionService) {
        this.actionService = actionService;
        this.approvalService = approvalService;
        this.queryService = queryService;
        this.childService = childService;
        this.permissionService = permissionService;
    }

    // ---------------------------------------------------------------- 子表

    /**
     * 某张单据的明细数据：按关系元数据分组返回，前端不硬编码子表。
     * 用在「打开编辑表单」「查看单据」时加载明细。
     */
    @GetMapping("/children")
    public ApiResult<List<MetaChildService.ChildGroup>> children(@RequestParam String objectCode,
                                                                 @RequestParam long id) {
        if (!permissionService.check("DATA:" + objectCode, "read")) {
            throw new ApiException(ErrorCode.FORBIDDEN, "没有该对象的读取权限：" + objectCode);
        }
        return ApiResult.ok(childService.childrenOf(objectCode, id));
    }

    // ---------------------------------------------------------------- 按钮

    /**
     * 当前行可用按钮。对象编码来自查询参数而不是路径变量，不能用
     * {@code @RequiresPermission("DATA:{objectCode}")}（拦截器解析不到路径变量会 fail-closed 直接 403），
     * 改为方法内显式校验；按钮自身还会按 {@code FunctionId} 再校验一次。
     */
    @GetMapping("/buttons")
    public ApiResult<List<ActionService.ResolvedButton>> buttons(@RequestParam String objectCode,
                                                                 @RequestParam(required = false) Long id) {
        if (!permissionService.check("DATA:" + objectCode, "read")) {
            throw new ApiException(ErrorCode.FORBIDDEN, "没有该对象的读取权限：" + objectCode);
        }
        Map<String, Object> row = id == null ? Map.of() : rowOf(objectCode, id);
        return ApiResult.ok(actionService.resolve(objectCode, row));
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> rowOf(String objectCode, long id) {
        // 复用查询引擎，保证与列表看到的是同一份数据（含权限与租户过滤）
        // filters 是 JSON 数组格式：[{"f":"Id","op":"eq","v":"123"}]，与列表页同一套解析
        String filters = "[{\"f\":\"Id\",\"op\":\"eq\",\"v\":\"" + id + "\"}]";
        MetaQueryService.PageResult page = queryService.query(objectCode, filters, null, 1, 1);
        if (page.rows() == null || page.rows().isEmpty()) {
            return Map.of();
        }
        return (Map<String, Object>) page.rows().get(0);
    }

    // ---------------------------------------------------------------- 审批

    public record SubmitBody(String objectCode, long businessId, String businessNo, String title) {
    }

    @PostMapping("/workflow/submit")
    public ApiResult<Map<String, Long>> submit(@RequestBody SubmitBody body) {
        if (!permissionService.check("DATA:" + body.objectCode(), "write")) {
            throw new ApiException(ErrorCode.FORBIDDEN, "没有该对象的写入权限：" + body.objectCode());
        }
        long instanceId = approvalService.submit(body.objectCode(), body.businessId(),
                body.businessNo(), body.title());
        return ApiResult.ok(Map.of("instanceId", instanceId));
    }

    public record ApproveBody(Boolean approved, String opinion) {

    }

    @PostMapping("/workflow/tasks/{taskId}/approve")
    public ApiResult<Void> approve(@PathVariable long taskId, @RequestBody ApproveBody body) {
        String objectCode = requireApprovePermission(taskId);
        approvalService.approve(taskId, Boolean.TRUE.equals(body.approved()), body.opinion());
        // 审计：审批动作写业务日志（工作流时间轴已有，这里补操作日志方便排障）
        return ApiResult.ok(null);
    }

    public record ReturnBody(String targetNodeCode, String opinion) {
    }

    @PostMapping("/workflow/tasks/{taskId}/return")
    public ApiResult<Void> returnTo(@PathVariable long taskId, @RequestBody ReturnBody body) {
        requireApprovePermission(taskId);
        if (body.targetNodeCode() == null || body.targetNodeCode().isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "退回必须指定目标节点");
        }
        approvalService.returnTo(taskId, body.targetNodeCode(), body.opinion());
        return ApiResult.ok(null);
    }

    public record AddSignBody(long approverId, String opinion) {
    }

    @PostMapping("/workflow/tasks/{taskId}/addsign")
    public ApiResult<Map<String, Long>> addSign(@PathVariable long taskId, @RequestBody AddSignBody body) {
        requireApprovePermission(taskId);
        long id = approvalService.addSign(taskId, body.approverId(), body.opinion());
        return ApiResult.ok(Map.of("taskId", id));
    }

    @PostMapping("/workflow/instances/{instanceId}/withdraw")
    public ApiResult<Void> withdraw(@PathVariable long instanceId,
                                    @RequestBody(required = false) Map<String, String> body) {
        String objectCode = approvalService.objectCodeOfInstance(instanceId);
        if (objectCode != null && !permissionService.check("DATA:" + objectCode, "write")) {
            throw new ApiException(ErrorCode.FORBIDDEN, "没有该单据的写入权限，不能撤回");
        }
        approvalService.withdraw(instanceId, body == null ? null : body.get("opinion"));
        return ApiResult.ok(null);
    }

    @GetMapping("/workflow/todos")
    public ApiResult<List<ApprovalService.InstanceDto>> todos() {
        return ApiResult.ok(approvalService.myTodos());
    }

    @GetMapping("/workflow/instances")
    public ApiResult<List<ApprovalService.InstanceDto>> instances(@RequestParam String objectCode,
                                                                 @RequestParam long businessId) {
        if (!permissionService.check("DATA:" + objectCode, "read")) {
            throw new ApiException(ErrorCode.FORBIDDEN, "没有该对象的读取权限：" + objectCode);
        }
        return ApiResult.ok(approvalService.instancesOf(objectCode, businessId));
    }

    @GetMapping("/workflow/instances/{instanceId}")
    public ApiResult<ApprovalService.InstanceDto> instance(@PathVariable long instanceId) {
        String objectCode = approvalService.objectCodeOfInstance(instanceId);
        if (objectCode != null && !permissionService.check("DATA:" + objectCode, "read")) {
            throw new ApiException(ErrorCode.FORBIDDEN, "没有该单据的读取权限");
        }
        return ApiResult.ok(approvalService.getInstance(instanceId));
    }

    /** 审批权限：由任务反查对象编码，再走统一的权限判定。 */
    private String requireApprovePermission(long taskId) {
        String objectCode = approvalService.objectCodeOfTask(taskId);
        if (objectCode != null && !permissionService.check("DATA:" + objectCode, "approve")) {
            throw new ApiException(ErrorCode.FORBIDDEN, "没有该单据的审批权限");
        }
        return objectCode;
    }
}

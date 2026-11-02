package com.apserp.plat.meta;

import com.apserp.common.ApiException;
import com.apserp.common.ApiResult;
import com.apserp.common.ErrorCode;
import com.apserp.common.security.RequiresPermission;
import com.apserp.plat.perm.PermissionService;
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
    private final ActionExecutor actionExecutor;
    private final MetaOverlay metaOverlay;
    private final DocStatusService docStatusService;
    private final AttachmentService attachmentService;
    private final MetaPublishService publishService;
    private final PermissionService permissionService;

    public RuntimeController(ActionService actionService, ApprovalService approvalService,
                             MetaQueryService queryService, MetaChildService childService,
                             ActionExecutor actionExecutor, MetaOverlay metaOverlay,
                             MetaPublishService publishService, DocStatusService docStatusService,
                             AttachmentService attachmentService, PermissionService permissionService) {
        this.actionService = actionService;
        this.approvalService = approvalService;
        this.queryService = queryService;
        this.childService = childService;
        this.actionExecutor = actionExecutor;
        this.metaOverlay = metaOverlay;
        this.publishService = publishService;
        this.docStatusService = docStatusService;
        this.attachmentService = attachmentService;
        this.permissionService = permissionService;
    }

    // ---------------------------------------------------------------- 抄送 / 超时 / 代理

    /** 抄送给我的流程（未读在前）。 */
    @GetMapping("/workflow/ccs")
    public ApiResult<List<ApprovalService.InstanceDto>> ccs() {
        return ApiResult.ok(approvalService.myCcs());
    }

    @GetMapping("/workflow/ccs/unread")
    public ApiResult<Map<String, Integer>> unreadCc() {
        return ApiResult.ok(Map.of("count", approvalService.unreadCcCount()));
    }

    @PostMapping("/workflow/instances/{id}/cc-read")
    public ApiResult<Void> markCcRead(@PathVariable long id) {
        approvalService.markCcRead(id);
        return ApiResult.ok(null);
    }

    /** 超时未处理的流程（管理员/审批人视角）。 */
    @GetMapping("/workflow/overdue")
    public ApiResult<List<ApprovalService.InstanceDto>> overdue() {
        return ApiResult.ok(approvalService.overdueTasks());
    }

    @PostMapping("/workflow/tasks/{id}/remind")
    public ApiResult<Map<String, Integer>> remind(@PathVariable long id,
                                                  @RequestBody(required = false) Map<String, String> body) {
        String opinion = body == null ? null : body.get("opinion");
        return ApiResult.ok(Map.of("reminded", approvalService.remind(id, opinion)));
    }

    @GetMapping("/workflow/delegates")
    public ApiResult<List<ApprovalService.DelegateDto>> delegates() {
        return ApiResult.ok(approvalService.listDelegates());
    }

    @PostMapping("/workflow/delegates")
    public ApiResult<Map<String, Long>> saveDelegate(@RequestBody DelegateBody body) {
        long id = approvalService.saveDelegate(new ApprovalService.DelegateSaveRequest(
                body.id(), body.userId(), body.delegateToId(), body.startAt(), body.endAt(),
                body.enabled(), body.remark()));
        return ApiResult.ok(Map.of("id", id));
    }

    public record DelegateBody(Long id, long userId, long delegateToId,
                               java.time.LocalDateTime startAt, java.time.LocalDateTime endAt,
                               boolean enabled, String remark) {
    }

    @DeleteMapping("/workflow/delegates/{id}")
    public ApiResult<Void> deleteDelegate(@PathVariable long id) {
        approvalService.deleteDelegate(id);
        return ApiResult.ok(null);
    }

    // ---------------------------------------------------------------- 动作执行

    /**
     * 执行按钮上配置的动作链（内置/导航/命令/脚本）。
     *
     * <p>前端不再自己实现动作语义：点按钮 → 调这个接口 → 按返回的 kind 跳转/下载/刷新。</p>
     */
    @PostMapping("/action/execute")
    public ApiResult<ActionExecutor.ExecuteResult> execute(@RequestBody ActionExecutor.ExecuteRequest body) {
        return ApiResult.ok(actionExecutor.execute(body));
    }

    /** 已注册的服务端命令（脚本动作白名单，设计器下拉用）。 */
    @GetMapping("/action/commands")
    public ApiResult<List<String>> commands() {
        return ApiResult.ok(actionExecutor.availableCommands());
    }

    /**
     * CSV 导出：列取默认列表视图，UTF-8 BOM，最多 5000 行。
     * 直接返回文件流，不走 ApiResult（否则前端要先解析 JSON 再 blob）。
     */
    @GetMapping("/export")
    public org.springframework.http.ResponseEntity<byte[]> export(
            @RequestParam String objectCode,
            @RequestParam(required = false) String filters,
            @RequestParam(required = false) String sort,
            @RequestParam(required = false, defaultValue = "5000") int maxRows) {
        String csv = actionExecutor.exportCsv(objectCode, filters, sort, maxRows);
        String fileName = objectCode.replace('.', '_') + "-"
                + java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                + ".csv";
        return org.springframework.http.ResponseEntity.ok()
                .header("Content-Type", "text/csv; charset=UTF-8")
                .header("Content-Disposition", "attachment; filename=\"" + fileName + "\"")
                .body(csv.getBytes(java.nio.charset.StandardCharsets.UTF_8));
    }

    // ---------------------------------------------------------------- 附件

    /** 某单据的附件列表。 */
    @GetMapping("/attachments")
    public ApiResult<List<AttachmentService.AttachmentDto>> attachments(@RequestParam String objectCode,
                                                                      @RequestParam long businessId) {
        requireRead(objectCode);
        return ApiResult.ok(attachmentService.list(objectCode, businessId));
    }

    @PostMapping("/attachments")
    public ApiResult<AttachmentService.AttachmentDto> uploadAttachment(
            @RequestParam String objectCode,
            @RequestParam long businessId,
            @RequestParam("file") org.springframework.web.multipart.MultipartFile file) {
        requireWrite(objectCode);
        return ApiResult.ok(attachmentService.upload(objectCode, businessId, file));
    }

    @GetMapping("/attachments/{id}/download")
    public org.springframework.http.ResponseEntity<org.springframework.core.io.Resource> downloadAttachment(
            @PathVariable long id) {
        AttachmentService.AttachmentDto dto = attachmentService.get(id);
        requireRead(dto.objectCode());
        AttachmentService.Download download = attachmentService.download(id);
        String encoded = java.net.URLEncoder.encode(download.fileName(),
                java.nio.charset.StandardCharsets.UTF_8).replace("+", "%20");
        return org.springframework.http.ResponseEntity.ok()
                .header("Content-Disposition",
                        "attachment; filename=\"file\"; filename*=UTF-8''" + encoded)
                .body(download.resource());
    }

    @DeleteMapping("/attachments/{id}")
    public ApiResult<Void> deleteAttachment(@PathVariable long id) {
        AttachmentService.AttachmentDto dto = attachmentService.get(id);
        requireWrite(dto.objectCode());
        attachmentService.delete(id);
        return ApiResult.ok(null);
    }

    private void requireRead(String objectCode) {
        if (!permissionService.check("DATA:" + objectCode, "read")) {
            throw new ApiException(ErrorCode.FORBIDDEN, "没有该对象的读取权限：" + objectCode);
        }
    }

    private void requireWrite(String objectCode) {
        if (!permissionService.check("DATA:" + objectCode, "write")) {
            throw new ApiException(ErrorCode.FORBIDDEN, "没有该对象的写入权限：" + objectCode);
        }
    }

    // ---------------------------------------------------------------- 状态机

    /** 某条单据当前状态与可用动作（前端据此置灰按钮）。 */
    @GetMapping("/doc-status")
    public ApiResult<DocStatusService.StatusCapability> docStatus(@RequestParam String objectCode,
                                                                 @RequestParam long id) {
        if (!permissionService.check("DATA:" + objectCode, "read")) {
            throw new ApiException(ErrorCode.FORBIDDEN, "没有该对象的读取权限：" + objectCode);
        }
        return ApiResult.ok(docStatusService.capabilityOf(objectCode, id));
    }

    /** 状态定义（列表页渲染状态标签用）。 */
    @GetMapping("/doc-status/define")
    public ApiResult<List<DocStatusService.StatusDto>> docStatusDefine(@RequestParam String objectCode) {
        return ApiResult.ok(docStatusService.statusesOf(objectCode));
    }

    // ---------------------------------------------------------------- 元数据版本

    /**
     * 当前登录用户正在使用的元数据版本：灰度用户返回灰度版本号并标记 gray=true。
     * 前端据此在顶栏显示「灰度中」提示，避免验收时误以为改错了。
     */
    @GetMapping("/meta-version")
    public ApiResult<Map<String, Object>> metaVersion() {
        var gray = metaOverlay.current();
        if (gray != null) {
            return ApiResult.ok(Map.of("version", gray.version(), "gray", true));
        }
        Integer current = publishService.currentVersion();
        return ApiResult.ok(Map.of("version", current == null ? 0 : current, "gray", false));
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

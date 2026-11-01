/* ============================================================
   规则/按钮/审批/发布 四类引擎的演示配置与结构补强
   1) 审批流补「流转去向」与快照列（表已存在，缺的是流转所需字段）
   2) 演示规则 3 条 + 绑定
   3) 演示按钮 4 个（含可见/可用表达式、确认文案、流程）
   4) 演示审批流 1 个（含条件分支与或签/会签）
   5) 设计器权限点
   幂等：全部 IF NOT EXISTS / IF COL_LENGTH IS NULL。
   注意：ALTER TABLE 用 sp_executesql 执行，避免同批次引用新列导致编译失败。
   ============================================================ */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

/* ---------- 1. 审批流结构补强 ---------- */
IF COL_LENGTH('plat.WorkflowNode', 'NextNodeCode') IS NULL
    EXEC sp_executesql N'ALTER TABLE plat.WorkflowNode ADD NextNodeCode varchar(20) NULL';
IF COL_LENGTH('plat.WorkflowNode', 'RejectNodeCode') IS NULL
    EXEC sp_executesql N'ALTER TABLE plat.WorkflowNode ADD RejectNodeCode varchar(20) NULL';
IF COL_LENGTH('plat.WorkflowInstance', 'CurrentNodeCode') IS NULL
    EXEC sp_executesql N'ALTER TABLE plat.WorkflowInstance ADD CurrentNodeCode varchar(20) NULL';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_WfTask_Instance' AND object_id = OBJECT_ID('plat.WorkflowTask'))
    CREATE INDEX IX_WfTask_Instance ON plat.WorkflowTask(InstanceId, ApproveStatus);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_WfInst_Business' AND object_id = OBJECT_ID('plat.WorkflowInstance'))
    CREATE INDEX IX_WfInst_Business ON plat.WorkflowInstance(DataObjectCode, BusinessId);
GO

/* ---------- 2. 演示规则 ---------- */
IF NOT EXISTS (SELECT 1 FROM plat.BizRule WHERE TenantId = 1 AND Code = 'R-CODE-REQUIRED')
    INSERT plat.BizRule (TenantId, Code, Name, RuleType, Expression, ErrorMessage, Severity, IsEnabled, CreatedAt)
    VALUES (1, 'R-CODE-REQUIRED', N'编码必填且长度≤32', 1,
            N'ctx.Code != null && ctx.Code.length() <= 32', N'编码不能为空且不超过 32 位', 2, 1, sysutcdatetime());

IF NOT EXISTS (SELECT 1 FROM plat.BizRule WHERE TenantId = 1 AND Code = 'R-SORT-RANGE')
    INSERT plat.BizRule (TenantId, Code, Name, RuleType, Expression, ErrorMessage, Severity, IsEnabled, CreatedAt)
    VALUES (1, 'R-SORT-RANGE', N'排序值 0-999', 1,
            N'ctx.Sort == null || (ctx.Sort >= 0 && ctx.Sort <= 999)', N'排序值必须在 0-999 之间', 2, 1, sysutcdatetime());

IF NOT EXISTS (SELECT 1 FROM plat.BizRule WHERE TenantId = 1 AND Code = 'R-NAME-LEN')
    INSERT plat.BizRule (TenantId, Code, Name, RuleType, Expression, ErrorMessage, Severity, IsEnabled, CreatedAt)
    VALUES (1, 'R-NAME-LEN', N'名称不超过 50 字（警告）', 1,
            N'ctx.Name == null || ctx.Name.length() <= 50', N'名称超过 50 字建议缩短', 1, 1, sysutcdatetime());
GO

DECLARE @brandId bigint = (SELECT TOP 1 Id FROM plat.DataObject WHERE TenantId = 1 AND Code = 'md.brand');
IF @brandId IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM plat.RuleBinding WHERE RuleId = (SELECT Id FROM plat.BizRule WHERE TenantId=1 AND Code='R-CODE-REQUIRED') AND DataObjectId = @brandId)
        INSERT plat.RuleBinding (RuleId, DataObjectId, FieldName, TriggerEvent, Sort, IsEnabled)
        VALUES ((SELECT Id FROM plat.BizRule WHERE TenantId=1 AND Code='R-CODE-REQUIRED'), @brandId, NULL, 1, 10, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.RuleBinding WHERE RuleId = (SELECT Id FROM plat.BizRule WHERE TenantId=1 AND Code='R-SORT-RANGE') AND DataObjectId = @brandId)
        INSERT plat.RuleBinding (RuleId, DataObjectId, FieldName, TriggerEvent, Sort, IsEnabled)
        VALUES ((SELECT Id FROM plat.BizRule WHERE TenantId=1 AND Code='R-SORT-RANGE'), @brandId, 'Sort', 1, 20, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.RuleBinding WHERE RuleId = (SELECT Id FROM plat.BizRule WHERE TenantId=1 AND Code='R-NAME-LEN') AND DataObjectId = @brandId)
        INSERT plat.RuleBinding (RuleId, DataObjectId, FieldName, TriggerEvent, Sort, IsEnabled)
        VALUES ((SELECT Id FROM plat.BizRule WHERE TenantId=1 AND Code='R-NAME-LEN'), @brandId, 'Name', 1, 30, 1);
END
GO

/* ---------- 3. 演示按钮 ---------- */
IF NOT EXISTS (SELECT 1 FROM plat.Button WHERE TenantId = 1 AND Code = 'BTN-BRAND-EDIT')
BEGIN
    INSERT plat.Button (TenantId, Code, Name, Text, Icon, ButtonType, FunctionId, Sort, IsVisible, IsEnabledExpr, Style, CreatedAt)
    VALUES (1, 'BTN-BRAND-EDIT', N'编辑', N'编辑', 'Edit', 2,
            (SELECT TOP 1 Id FROM plat.ModuleFunction WHERE TenantId = 1 AND Code = 'md.brand'),
            10, 1, N'ctx.IsEnabled == null || ctx.IsEnabled == true', 'primary', sysutcdatetime());
    DECLARE @b1 bigint = SCOPE_IDENTITY();
    INSERT plat.ButtonAction (ButtonId, Seq, ActionType, BuiltinCode, ConfirmText, IsEnabled)
    VALUES (@b1, 1, 1, 'OPEN_FORM', N'打开编辑表单', 1);
END

IF NOT EXISTS (SELECT 1 FROM plat.Button WHERE TenantId = 1 AND Code = 'BTN-BRAND-DELETE')
BEGIN
    INSERT plat.Button (TenantId, Code, Name, Text, Icon, ButtonType, FunctionId, Sort, IsVisible, VisibleExpr, Style, CreatedAt)
    VALUES (1, 'BTN-BRAND-DELETE', N'删除', N'删除', 'Delete', 1,
            (SELECT TOP 1 Id FROM plat.ModuleFunction WHERE TenantId = 1 AND Code = 'md.brand'),
            20, 1, N'ctx.IsEnabled == true', 'danger', sysutcdatetime());
    DECLARE @b2 bigint = SCOPE_IDENTITY();
    INSERT plat.ButtonAction (ButtonId, Seq, ActionType, BuiltinCode, ConfirmText, SuccessMessage, IsEnabled)
    VALUES (@b2, 1, 1, 'DELETE', N'确认删除该品牌？删除后不可恢复。', N'已删除', 1);
END

IF NOT EXISTS (SELECT 1 FROM plat.Button WHERE TenantId = 1 AND Code = 'BTN-BRAND-SUBMIT')
BEGIN
    INSERT plat.Button (TenantId, Code, Name, Text, Icon, ButtonType, FunctionId, Sort, IsVisible, Style, CreatedAt)
    VALUES (1, 'BTN-BRAND-SUBMIT', N'提交审批', N'提交审批', 'Promotion', 3,
            (SELECT TOP 1 Id FROM plat.ModuleFunction WHERE TenantId = 1 AND Code = 'md.brand'),
            30, 1, 'warning', sysutcdatetime());
    DECLARE @b3 bigint = SCOPE_IDENTITY();
    INSERT plat.ButtonAction (ButtonId, Seq, ActionType, BuiltinCode, ConfirmText, SuccessMessage, NeedWorkflow, IsEnabled)
    VALUES (@b3, 1, 1, 'SUBMIT', N'提交后将进入审批流程，确认提交？', N'已提交', 1, 1);
END

IF NOT EXISTS (SELECT 1 FROM plat.Button WHERE TenantId = 1 AND Code = 'BTN-BRAND-EXPORT')
BEGIN
    INSERT plat.Button (TenantId, Code, Name, Text, Icon, ButtonType, FunctionId, Sort, IsVisible, Style, CreatedAt)
    VALUES (1, 'BTN-BRAND-EXPORT', N'导出', N'导出', 'Download', 4,
            (SELECT TOP 1 Id FROM plat.ModuleFunction WHERE TenantId = 1 AND Code = 'md.brand'),
            40, 1, '', sysutcdatetime());
    DECLARE @b4 bigint = SCOPE_IDENTITY();
    INSERT plat.ButtonAction (ButtonId, Seq, ActionType, BuiltinCode, SuccessMessage, IsEnabled)
    VALUES (@b4, 1, 1, 'EXPORT', N'导出任务已提交', 1);
END
GO

/* ---------- 4. 演示审批流：品牌启用申请 ---------- */
IF NOT EXISTS (SELECT 1 FROM plat.WorkflowDef WHERE TenantId = 1 AND Code = 'WF-BRAND-ENABLE')
BEGIN
    DECLARE @defId bigint;
    INSERT plat.WorkflowDef (TenantId, Code, Name, DataObjectId, Version, ConditionExpr, Status, PublishedAt, IsDefault, CreatedAt)
    VALUES (1, 'WF-BRAND-ENABLE', N'品牌启用审批',
            (SELECT TOP 1 Id FROM plat.DataObject WHERE TenantId=1 AND Code='md.brand'),
            1, N'ctx.IsEnabled == true', 1, sysutcdatetime(), 1, sysutcdatetime());
    SET @defId = SCOPE_IDENTITY();

    INSERT plat.WorkflowNode (WorkflowDefId, Code, Name, NodeType, Sort, ApproveMode, RejectMode, ConditionExpr, AllowAddSign, NextNodeCode, RejectNodeCode)
    VALUES (@defId, 'N1', N'部门审批', 2, 10, 1, 1, N'ctx.Sort != null && ctx.Sort >= 100', 1, 'N2', NULL),
           (@defId, 'N2', N'财务会签', 2, 20, 2, 1, N'ctx.Sort != null && ctx.Sort < 100', 1, NULL, NULL);

    INSERT plat.WorkflowNodeApprover (WorkflowNodeId, ApproverType, ApproverId, Sort)
    SELECT Id, 1, 1, 10 FROM plat.WorkflowNode WHERE WorkflowDefId = @defId AND Code = 'N1';
    INSERT plat.WorkflowNodeApprover (WorkflowNodeId, ApproverType, ApproverId, Sort)
    SELECT Id, 1, 1, 10 FROM plat.WorkflowNode WHERE WorkflowDefId = @defId AND Code = 'N2';
END
GO

/* ---------- 5. 设计器权限点 ---------- */
DECLARE @p TABLE (k varchar(60), nm nvarchar(100));
INSERT @p (k, nm) VALUES
    ('DESIGN:rule', N'设计器：规则'), ('DESIGN:action', N'设计器：按钮动作'),
    ('DESIGN:approval', N'设计器：审批流'), ('DESIGN:publish', N'设计器：发布回滚'),
    ('DESIGN:page', N'设计器：页面');
INSERT plat.Permission (TenantId, ResourceKey, ResourceType, Name, IsEnabled)
SELECT 1, p.k, 1, p.nm, 1
FROM @p p
WHERE NOT EXISTS (SELECT 1 FROM plat.Permission x WHERE x.TenantId = 1 AND x.ResourceKey = p.k);
GO

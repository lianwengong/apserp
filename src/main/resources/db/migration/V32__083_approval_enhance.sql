/* =====================================================================
   V32 · 审批增强：抄送 / 超时 / 代理
   ---------------------------------------------------------------------
   1) plat.WorkflowNodeCc        节点抄送人（定义期配置）
   2) plat.WorkflowInstanceCc    实例抄送（提交时快照，读状态可跟踪）
   3) plat.WorkflowDelegate      审批代理（请假期间把待办转给人）
   4) WorkflowNode.TimeoutHours  节点超时小时数
   5) WorkflowTask.DueAt         任务到期时间（提交时按节点超时算出）
   全部幂等；新增表补 RLS 过滤谓词。
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

/* ---------------------------------------------------------------- 1. 节点抄送人 */
IF OBJECT_ID('plat.WorkflowNodeCc', 'U') IS NULL
BEGIN
    CREATE TABLE [plat].[WorkflowNodeCc] (
        [Id] bigint IDENTITY(1,1) NOT NULL,
        [WorkflowNodeId] bigint NOT NULL,
        [UserId] bigint NOT NULL,
        [Sort] int NOT NULL CONSTRAINT [DF_WorkflowNodeCc_Sort] DEFAULT (10),
        CONSTRAINT [PK_WorkflowNodeCc] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_WorkflowNodeCc_Node] FOREIGN KEY ([WorkflowNodeId]) REFERENCES [plat].[WorkflowNode] ([Id]),
        CONSTRAINT [FK_WorkflowNodeCc_User] FOREIGN KEY ([UserId]) REFERENCES [plat].[User] ([Id])
    );
    CREATE UNIQUE INDEX [UQ_WorkflowNodeCc_Node_User]
        ON [plat].[WorkflowNodeCc] ([WorkflowNodeId], [UserId]);
    EXEC sp_addextendedproperty N'MS_Description', N'审批节点抄送人（只读，不进待办）',
        N'SCHEMA', N'plat', N'TABLE', N'WorkflowNodeCc';
END
GO

/* ---------------------------------------------------------------- 2. 实例抄送 */
IF OBJECT_ID('plat.WorkflowInstanceCc', 'U') IS NULL
BEGIN
    CREATE TABLE [plat].[WorkflowInstanceCc] (
        [Id] bigint IDENTITY(1,1) NOT NULL,
        [TenantId] int NOT NULL CONSTRAINT [DF_WorkflowInstanceCc_TenantId] DEFAULT (1),
        [InstanceId] bigint NOT NULL,
        [NodeCode] varchar(50) NULL,
        [UserId] bigint NOT NULL,
        [IsRead] bit NOT NULL CONSTRAINT [DF_WorkflowInstanceCc_IsRead] DEFAULT (0),
        [ReadAt] datetime2(3) NULL,
        [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_WorkflowInstanceCc_CreatedAt] DEFAULT (sysutcdatetime()),
        CONSTRAINT [PK_WorkflowInstanceCc] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_WorkflowInstanceCc_Instance] FOREIGN KEY ([InstanceId]) REFERENCES [plat].[WorkflowInstance] ([Id]),
        CONSTRAINT [FK_WorkflowInstanceCc_User] FOREIGN KEY ([UserId]) REFERENCES [plat].[User] ([Id])
    );
    CREATE UNIQUE INDEX [UQ_WorkflowInstanceCc_Instance_User]
        ON [plat].[WorkflowInstanceCc] ([InstanceId], [UserId]);
    CREATE INDEX [IX_WorkflowInstanceCc_User] ON [plat].[WorkflowInstanceCc] ([TenantId], [UserId], [IsRead]);
    EXEC sp_addextendedproperty N'MS_Description', N'审批实例抄送（提交时快照）',
        N'SCHEMA', N'plat', N'TABLE', N'WorkflowInstanceCc';
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.security_predicates WHERE target_object_id = OBJECT_ID('plat.WorkflowInstanceCc'))
    ALTER SECURITY POLICY plat.TenantPolicy
        ADD FILTER PREDICATE plat.fn_TenantFilter(TenantId) ON [plat].[WorkflowInstanceCc];
GO

/* ---------------------------------------------------------------- 3. 审批代理 */
IF OBJECT_ID('plat.WorkflowDelegate', 'U') IS NULL
BEGIN
    CREATE TABLE [plat].[WorkflowDelegate] (
        [Id] bigint IDENTITY(1,1) NOT NULL,
        [TenantId] int NOT NULL CONSTRAINT [DF_WorkflowDelegate_TenantId] DEFAULT (1),
        [UserId] bigint NOT NULL,
        [DelegateToId] bigint NOT NULL,
        [StartAt] datetime2(3) NULL,
        [EndAt] datetime2(3) NULL,
        [IsEnabled] bit NOT NULL CONSTRAINT [DF_WorkflowDelegate_IsEnabled] DEFAULT (1),
        [Remark] nvarchar(200) NULL,
        [RowVersion] rowversion NOT NULL,
        [IsDeleted] bit NOT NULL CONSTRAINT [DF_WorkflowDelegate_IsDeleted] DEFAULT (0),
        [CreatedBy] bigint NULL,
        [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_WorkflowDelegate_CreatedAt] DEFAULT (sysutcdatetime()),
        [ModifiedBy] bigint NULL,
        [ModifiedAt] datetime2(3) NULL,
        CONSTRAINT [PK_WorkflowDelegate] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_WorkflowDelegate_User] FOREIGN KEY ([UserId]) REFERENCES [plat].[User] ([Id]),
        CONSTRAINT [FK_WorkflowDelegate_Target] FOREIGN KEY ([DelegateToId]) REFERENCES [plat].[User] ([Id])
    );
    CREATE UNIQUE INDEX [UQ_WorkflowDelegate_User]
        ON [plat].[WorkflowDelegate] ([TenantId], [UserId]) WHERE [IsDeleted] = 0;
    EXEC sp_addextendedproperty N'MS_Description', N'审批代理（UserId 的待办转给 DelegateToId）',
        N'SCHEMA', N'plat', N'TABLE', N'WorkflowDelegate';
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.security_predicates WHERE target_object_id = OBJECT_ID('plat.WorkflowDelegate'))
    ALTER SECURITY POLICY plat.TenantPolicy
        ADD FILTER PREDICATE plat.fn_TenantFilter(TenantId) ON [plat].[WorkflowDelegate];
GO

/* ---------------------------------------------------------------- 4/5. 超时字段 */
IF COL_LENGTH('plat.WorkflowNode', 'TimeoutHours') IS NULL
    ALTER TABLE plat.WorkflowNode ADD [TimeoutHours] int NULL;
GO
IF COL_LENGTH('plat.WorkflowTask', 'DueAt') IS NULL
    ALTER TABLE plat.WorkflowTask ADD [DueAt] datetime2(3) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_WfTask_Due' AND object_id = OBJECT_ID('plat.WorkflowTask'))
    CREATE INDEX [IX_WfTask_Due] ON plat.WorkflowTask ([ApproveStatus], [DueAt]);
GO

/* ---------------------------------------------------------------- 演示：给品牌启用流程 N1 配 24 小时超时 */
UPDATE plat.WorkflowNode SET TimeoutHours = 24
WHERE TimeoutHours IS NULL
  AND WorkflowDefId IN (SELECT Id FROM plat.WorkflowDef WHERE TenantId = 1 AND Code = 'WF-BRAND-ENABLE')
  AND Code = 'N1';
GO

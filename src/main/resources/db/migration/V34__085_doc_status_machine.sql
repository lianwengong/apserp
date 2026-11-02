/* =====================================================================
   V34 · 单据状态机
   ---------------------------------------------------------------------
   背景：DataObject.StatusField 一直是元数据里的空字段，引擎从没用过；
        单据可以随便改、随便删、重复提交审批。
   做法：
     1) plat.DocStatus      每个状态能否编辑/删除/提交、是否终态
     2) plat.DocTransition  允许的流转（动作码 → 目标状态）
     3) md.Brand 增加 Status 列并接上 StatusField，作为演示与集成测试的载体
   约定：
     - 对象没配 StatusField，或没配任何状态行 → 引擎不拦截（向后兼容）
     - 审批通过/驳回通过动作码 APPROVE / REJECT 触发流转
   幂等。
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

/* ---------------------------------------------------------------- 1. 状态定义 */
IF OBJECT_ID('plat.DocStatus', 'U') IS NULL
BEGIN
    CREATE TABLE [plat].[DocStatus] (
        [Id] bigint IDENTITY(1,1) NOT NULL,
        [TenantId] int NOT NULL CONSTRAINT [DF_DocStatus_TenantId] DEFAULT (1),
        [DataObjectId] bigint NOT NULL,
        [StatusValue] tinyint NOT NULL,
        [StatusName] nvarchar(50) NOT NULL,
        [Sort] int NOT NULL CONSTRAINT [DF_DocStatus_Sort] DEFAULT (10),
        [CanEdit] bit NOT NULL CONSTRAINT [DF_DocStatus_CanEdit] DEFAULT (1),
        [CanDelete] bit NOT NULL CONSTRAINT [DF_DocStatus_CanDelete] DEFAULT (1),
        [CanSubmit] bit NOT NULL CONSTRAINT [DF_DocStatus_CanSubmit] DEFAULT (0),
        [IsFinal] bit NOT NULL CONSTRAINT [DF_DocStatus_IsFinal] DEFAULT (0),
        [ColorType] varchar(20) NULL,
        [IsEnabled] bit NOT NULL CONSTRAINT [DF_DocStatus_IsEnabled] DEFAULT (1),
        [Remark] nvarchar(500) NULL,
        [RowVersion] rowversion NOT NULL,
        [IsDeleted] bit NOT NULL CONSTRAINT [DF_DocStatus_IsDeleted] DEFAULT (0),
        [CreatedBy] bigint NULL,
        [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_DocStatus_CreatedAt] DEFAULT (sysutcdatetime()),
        [ModifiedBy] bigint NULL,
        [ModifiedAt] datetime2(3) NULL,
        CONSTRAINT [PK_DocStatus] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_DocStatus_Object] FOREIGN KEY ([DataObjectId]) REFERENCES [plat].[DataObject] ([Id])
    );
    CREATE UNIQUE INDEX [UQ_DocStatus_Object_Value]
        ON [plat].[DocStatus] ([TenantId], [DataObjectId], [StatusValue]) WHERE [IsDeleted] = 0;
    EXEC sp_addextendedproperty N'MS_Description', N'单据状态定义（能否编辑/删除/提交）',
        N'SCHEMA', N'plat', N'TABLE', N'DocStatus';
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.security_predicates WHERE target_object_id = OBJECT_ID('plat.DocStatus'))
    ALTER SECURITY POLICY plat.TenantPolicy
        ADD FILTER PREDICATE plat.fn_TenantFilter(TenantId) ON [plat].[DocStatus];
GO

/* ---------------------------------------------------------------- 2. 允许的流转 */
IF OBJECT_ID('plat.DocTransition', 'U') IS NULL
BEGIN
    CREATE TABLE [plat].[DocTransition] (
        [Id] bigint IDENTITY(1,1) NOT NULL,
        [TenantId] int NOT NULL CONSTRAINT [DF_DocTransition_TenantId] DEFAULT (1),
        [DataObjectId] bigint NOT NULL,
        [FromStatus] tinyint NOT NULL,
        [ToStatus] tinyint NOT NULL,
        [ActionCode] varchar(30) NOT NULL,
        [ActionName] nvarchar(50) NULL,
        [Sort] int NOT NULL CONSTRAINT [DF_DocTransition_Sort] DEFAULT (10),
        [IsEnabled] bit NOT NULL CONSTRAINT [DF_DocTransition_IsEnabled] DEFAULT (1),
        [Remark] nvarchar(500) NULL,
        [RowVersion] rowversion NOT NULL,
        [IsDeleted] bit NOT NULL CONSTRAINT [DF_DocTransition_IsDeleted] DEFAULT (0),
        [CreatedBy] bigint NULL,
        [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_DocTransition_CreatedAt] DEFAULT (sysutcdatetime()),
        [ModifiedBy] bigint NULL,
        [ModifiedAt] datetime2(3) NULL,
        CONSTRAINT [PK_DocTransition] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_DocTransition_Object] FOREIGN KEY ([DataObjectId]) REFERENCES [plat].[DataObject] ([Id])
    );
    CREATE UNIQUE INDEX [UQ_DocTransition_Action]
        ON [plat].[DocTransition] ([TenantId], [DataObjectId], [FromStatus], [ActionCode]) WHERE [IsDeleted] = 0;
    EXEC sp_addextendedproperty N'MS_Description', N'单据状态流转（动作码 → 目标状态）',
        N'SCHEMA', N'plat', N'TABLE', N'DocTransition';
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.security_predicates WHERE target_object_id = OBJECT_ID('plat.DocTransition'))
    ALTER SECURITY POLICY plat.TenantPolicy
        ADD FILTER PREDICATE plat.fn_TenantFilter(TenantId) ON [plat].[DocTransition];
GO

/* ---------------------------------------------------------------- 3. 演示：品牌状态 */
IF COL_LENGTH('md.Brand', 'Status') IS NULL
    ALTER TABLE md.Brand ADD [Status] tinyint NOT NULL
        CONSTRAINT [DF_Brand_Status] DEFAULT (0);
GO
UPDATE plat.DataObject SET StatusField = 'Status'
WHERE TenantId = 1 AND Code = 'md.brand' AND (StatusField IS NULL OR StatusField = '');
GO
IF NOT EXISTS (SELECT 1 FROM plat.DataObjectField f JOIN plat.DataObject o ON o.Id = f.DataObjectId
               WHERE o.TenantId = 1 AND o.Code = 'md.brand' AND f.FieldName = 'Status')
    INSERT plat.DataObjectField (DataObjectId, FieldName, DisplayName, DataType, MaxLength,
                                 IsNullable, IsPrimaryKey, IsIdentity, IsRequired, IsVisible, Sort)
    SELECT Id, 'Status', N'状态', 'tinyint', NULL, 0, 0, 0, 0, 1, 15
    FROM plat.DataObject WHERE TenantId = 1 AND Code = 'md.brand';
GO

DECLARE @brand bigint = (SELECT Id FROM plat.DataObject WHERE TenantId = 1 AND Code = 'md.brand');
IF @brand IS NOT NULL AND NOT EXISTS (SELECT 1 FROM plat.DocStatus WHERE TenantId = 1 AND DataObjectId = @brand)
BEGIN
    INSERT plat.DocStatus (TenantId, DataObjectId, StatusValue, StatusName, Sort,
                           CanEdit, CanDelete, CanSubmit, IsFinal, ColorType, IsEnabled, IsDeleted, CreatedAt)
    VALUES (1, @brand, 0, N'草稿',   10, 1, 1, 1, 0, 'info',    1, 0, sysutcdatetime()),
           (1, @brand, 1, N'审批中', 20, 0, 0, 0, 0, 'warning', 1, 0, sysutcdatetime()),
           (1, @brand, 2, N'已审核', 30, 0, 0, 0, 1, 'success', 1, 0, sysutcdatetime()),
           (1, @brand, 3, N'已驳回', 40, 1, 1, 1, 0, 'danger',  1, 0, sysutcdatetime());

    INSERT plat.DocTransition (TenantId, DataObjectId, FromStatus, ToStatus, ActionCode, ActionName,
                               Sort, IsEnabled, IsDeleted, CreatedAt)
    VALUES (1, @brand, 0, 1, 'SUBMIT',  N'提交审批', 10, 1, 0, sysutcdatetime()),
           (1, @brand, 3, 1, 'SUBMIT',  N'重新提交', 20, 1, 0, sysutcdatetime()),
           (1, @brand, 1, 2, 'APPROVE', N'审批通过', 30, 1, 0, sysutcdatetime()),
           (1, @brand, 1, 3, 'REJECT',  N'审批驳回', 40, 1, 0, sysutcdatetime()),
           (1, @brand, 1, 0, 'WITHDRAW', N'撤回',    50, 1, 0, sysutcdatetime());
END
GO

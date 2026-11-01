/* =====================================================================
   进销存管理系统 V3 · 表结构 · fin 架构（24 张表）
   数据库：APSErpV3   生成器：db/emit.py（请勿手改，改规格文件后重新生成）
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE TABLE [fin].[AccountSubject] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_AccountSubject_TenantId] DEFAULT (1),
    [ParentId] bigint NULL,
    [Code] varchar(30) NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    [Level] tinyint NOT NULL CONSTRAINT [DF_AccountSubject_Level] DEFAULT (1),
    [SubjectType] tinyint NOT NULL CONSTRAINT [DF_AccountSubject_SubjectType] DEFAULT (1) CONSTRAINT [CK_AccountSubject_SubjectType] CHECK (SubjectType BETWEEN 1 AND 5),
    [Direction] tinyint NOT NULL CONSTRAINT [DF_AccountSubject_Direction] DEFAULT (1),
    [IsLeaf] bit NOT NULL CONSTRAINT [DF_AccountSubject_IsLeaf] DEFAULT (1),
    [NeedCustomer] bit NOT NULL CONSTRAINT [DF_AccountSubject_NeedCustomer] DEFAULT (0),
    [NeedSupplier] bit NOT NULL CONSTRAINT [DF_AccountSubject_NeedSupplier] DEFAULT (0),
    [NeedDept] bit NOT NULL CONSTRAINT [DF_AccountSubject_NeedDept] DEFAULT (0),
    [NeedEmployee] bit NOT NULL CONSTRAINT [DF_AccountSubject_NeedEmployee] DEFAULT (0),
    [NeedProduct] bit NOT NULL CONSTRAINT [DF_AccountSubject_NeedProduct] DEFAULT (0),
    [NeedProject] bit NOT NULL CONSTRAINT [DF_AccountSubject_NeedProject] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_AccountSubject_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_AccountSubject_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_AccountSubject_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_AccountSubject] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_AccountSubject_TenantId_Code] ON [fin].[AccountSubject] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_AccountSubject_TenantId_ParentId] ON [fin].[AccountSubject] ([TenantId], [ParentId]);
GO
CREATE INDEX [IX_AccountSubject_ParentId] ON [fin].[AccountSubject] ([ParentId]);
GO
CREATE INDEX [IX_AccountSubject_CreatedBy] ON [fin].[AccountSubject] ([CreatedBy]);
GO
CREATE INDEX [IX_AccountSubject_ModifiedBy] ON [fin].[AccountSubject] ([ModifiedBy]);
GO
CREATE INDEX [IX_AccountSubject_DeletedBy] ON [fin].[AccountSubject] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'会计科目', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'上级科目', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'ParentId';
EXEC sp_addextendedproperty N'MS_Description', N'科目编码', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'科目名称', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1资产 2负债 3权益 4成本 5损益)', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'SubjectType';
EXEC sp_addextendedproperty N'MS_Description', N'余额方向(1借 2贷)', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'Direction';
EXEC sp_addextendedproperty N'MS_Description', N'末级(可记账)', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'IsLeaf';
EXEC sp_addextendedproperty N'MS_Description', N'往来核算-客户', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'NeedCustomer';
EXEC sp_addextendedproperty N'MS_Description', N'往来核算-供应商', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'NeedSupplier';
EXEC sp_addextendedproperty N'MS_Description', N'部门核算', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'NeedDept';
EXEC sp_addextendedproperty N'MS_Description', N'个人核算', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'NeedEmployee';
EXEC sp_addextendedproperty N'MS_Description', N'商品核算', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'NeedProduct';
EXEC sp_addextendedproperty N'MS_Description', N'项目核算', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'NeedProject';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'AccountSubject', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [fin].[AccountingPeriod] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_AccountingPeriod_TenantId] DEFAULT (1),
    [Period] varchar(10) NOT NULL,
    [Year] smallint NOT NULL,
    [Month] tinyint NOT NULL,
    [StartDate] date NOT NULL,
    [EndDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_AccountingPeriod_Status] DEFAULT (0),
    [ClosedAt] datetime2(3) NULL,
    [ClosedBy] bigint NULL,
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_AccountingPeriod_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_AccountingPeriod_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_AccountingPeriod] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_AccountingPeriod_TenantId_Period] ON [fin].[AccountingPeriod] ([TenantId], [Period]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_AccountingPeriod_CreatedBy] ON [fin].[AccountingPeriod] ([CreatedBy]);
GO
CREATE INDEX [IX_AccountingPeriod_ModifiedBy] ON [fin].[AccountingPeriod] ([ModifiedBy]);
GO
CREATE INDEX [IX_AccountingPeriod_DeletedBy] ON [fin].[AccountingPeriod] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'会计期间', N'SCHEMA', N'fin', N'TABLE', N'AccountingPeriod';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'AccountingPeriod', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'期间(2026-01)', N'SCHEMA', N'fin', N'TABLE', N'AccountingPeriod', N'COLUMN', N'Period';
EXEC sp_addextendedproperty N'MS_Description', N'0未开启 1已开启 2已结账 3已年结', N'SCHEMA', N'fin', N'TABLE', N'AccountingPeriod', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'fin', N'TABLE', N'AccountingPeriod', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'fin', N'TABLE', N'AccountingPeriod', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'fin', N'TABLE', N'AccountingPeriod', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'fin', N'TABLE', N'AccountingPeriod', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'AccountingPeriod', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'fin', N'TABLE', N'AccountingPeriod', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'AccountingPeriod', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'fin', N'TABLE', N'AccountingPeriod', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'AccountingPeriod', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [fin].[Voucher] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Voucher_TenantId] DEFAULT (1),
    [VoucherNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Period] varchar(10) NOT NULL,
    [VoucherType] tinyint NOT NULL CONSTRAINT [DF_Voucher_VoucherType] DEFAULT (1),
    [SourceType] varchar(40) NULL,
    [SourceId] bigint NULL,
    [SourceNo] varchar(40) NULL,
    [TotalDebit] decimal(19,4) NOT NULL CONSTRAINT [DF_Voucher_TotalDebit] DEFAULT (0),
    [TotalCredit] decimal(19,4) NOT NULL CONSTRAINT [DF_Voucher_TotalCredit] DEFAULT (0),
    [Status] tinyint NOT NULL CONSTRAINT [DF_Voucher_Status] DEFAULT (0),
    [IsAuto] bit NOT NULL CONSTRAINT [DF_Voucher_IsAuto] DEFAULT (1),
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    [PostedAt] datetime2(3) NULL,
    [Remark] nvarchar(500) NULL,
    [OrgId] int NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Voucher_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Voucher_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [CK_Voucher_1] CHECK (TotalDebit >= 0),
    CONSTRAINT [PK_Voucher] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Voucher_TenantId_Period_VoucherNo] ON [fin].[Voucher] ([TenantId], [Period], [VoucherNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Voucher_Period_Status] ON [fin].[Voucher] ([Period], [Status]);
GO
CREATE INDEX [IX_Voucher_SourceType_SourceId] ON [fin].[Voucher] ([SourceType], [SourceId]);
GO
CREATE INDEX [IX_Voucher_OrgId] ON [fin].[Voucher] ([OrgId]);
GO
CREATE INDEX [IX_Voucher_CreatedBy] ON [fin].[Voucher] ([CreatedBy]);
GO
CREATE INDEX [IX_Voucher_ModifiedBy] ON [fin].[Voucher] ([ModifiedBy]);
GO
CREATE INDEX [IX_Voucher_DeletedBy] ON [fin].[Voucher] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'记账凭证', N'SCHEMA', N'fin', N'TABLE', N'Voucher';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'凭证号', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'VoucherNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'会计期间', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'Period';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1记账 2转字 3收字 4付字)', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'VoucherType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'来源单号', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'SourceNo';
EXEC sp_addextendedproperty N'MS_Description', N'借方合计', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'TotalDebit';
EXEC sp_addextendedproperty N'MS_Description', N'贷方合计', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'TotalCredit';
EXEC sp_addextendedproperty N'MS_Description', N'0待审 1已审 2已过账 9作废', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'自动生成', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'IsAuto';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'Voucher', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [fin].[VoucherEntry] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [VoucherId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SubjectId] bigint NOT NULL,
    [SubjectCode] varchar(30) NULL,
    [Summary] nvarchar(200) NULL,
    [Debit] decimal(19,4) NOT NULL CONSTRAINT [DF_VoucherEntry_Debit] DEFAULT (0),
    [Credit] decimal(19,4) NOT NULL CONSTRAINT [DF_VoucherEntry_Credit] DEFAULT (0),
    [CustomerId] bigint NULL,
    [SupplierId] bigint NULL,
    [DeptId] bigint NULL,
    [EmployeeId] bigint NULL,
    [SkuId] bigint NULL,
    [ProjectCode] varchar(40) NULL,
    [Qty] decimal(19,6) NULL,
    [SourceDetailId] bigint NULL,
    CONSTRAINT [CK_VoucherEntry_1] CHECK ((Debit > 0 AND Credit = 0) OR (Credit > 0 AND Debit = 0) OR (Debit = 0 AND Credit = 0)),
    CONSTRAINT [PK_VoucherEntry] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_VoucherEntry_VoucherId_LineNo] ON [fin].[VoucherEntry] ([VoucherId], [LineNo]);
GO
CREATE INDEX [IX_VoucherEntry_SubjectId] ON [fin].[VoucherEntry] ([SubjectId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'凭证分录', N'SCHEMA', N'fin', N'TABLE', N'VoucherEntry';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'VoucherEntry', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'科目', N'SCHEMA', N'fin', N'TABLE', N'VoucherEntry', N'COLUMN', N'SubjectId';
EXEC sp_addextendedproperty N'MS_Description', N'科目编码快照', N'SCHEMA', N'fin', N'TABLE', N'VoucherEntry', N'COLUMN', N'SubjectCode';
EXEC sp_addextendedproperty N'MS_Description', N'摘要', N'SCHEMA', N'fin', N'TABLE', N'VoucherEntry', N'COLUMN', N'Summary';
EXEC sp_addextendedproperty N'MS_Description', N'借方', N'SCHEMA', N'fin', N'TABLE', N'VoucherEntry', N'COLUMN', N'Debit';
EXEC sp_addextendedproperty N'MS_Description', N'贷方', N'SCHEMA', N'fin', N'TABLE', N'VoucherEntry', N'COLUMN', N'Credit';
EXEC sp_addextendedproperty N'MS_Description', N'客户', N'SCHEMA', N'fin', N'TABLE', N'VoucherEntry', N'COLUMN', N'CustomerId';
EXEC sp_addextendedproperty N'MS_Description', N'供应商', N'SCHEMA', N'fin', N'TABLE', N'VoucherEntry', N'COLUMN', N'SupplierId';
EXEC sp_addextendedproperty N'MS_Description', N'部门', N'SCHEMA', N'fin', N'TABLE', N'VoucherEntry', N'COLUMN', N'DeptId';
EXEC sp_addextendedproperty N'MS_Description', N'个人', N'SCHEMA', N'fin', N'TABLE', N'VoucherEntry', N'COLUMN', N'EmployeeId';
EXEC sp_addextendedproperty N'MS_Description', N'商品', N'SCHEMA', N'fin', N'TABLE', N'VoucherEntry', N'COLUMN', N'SkuId';
EXEC sp_addextendedproperty N'MS_Description', N'项目', N'SCHEMA', N'fin', N'TABLE', N'VoucherEntry', N'COLUMN', N'ProjectCode';
EXEC sp_addextendedproperty N'MS_Description', N'数量', N'SCHEMA', N'fin', N'TABLE', N'VoucherEntry', N'COLUMN', N'Qty';
EXEC sp_addextendedproperty N'MS_Description', N'来源明细', N'SCHEMA', N'fin', N'TABLE', N'VoucherEntry', N'COLUMN', N'SourceDetailId';
GO
CREATE TABLE [fin].[VoucherTemplate] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_VoucherTemplate_TenantId] DEFAULT (1),
    [Code] varchar(50) NOT NULL,
    [Name] nvarchar(100) NULL,
    [BizType] varchar(50) NOT NULL,
    [CondJson] nvarchar(max) NULL,
    [LinesJson] nvarchar(max) NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_VoucherTemplate_IsEnabled] DEFAULT (1),
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_VoucherTemplate_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_VoucherTemplate_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_VoucherTemplate] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_VoucherTemplate_TenantId_Code] ON [fin].[VoucherTemplate] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_VoucherTemplate_OrgId] ON [fin].[VoucherTemplate] ([OrgId]);
GO
CREATE INDEX [IX_VoucherTemplate_CreatedBy] ON [fin].[VoucherTemplate] ([CreatedBy]);
GO
CREATE INDEX [IX_VoucherTemplate_ModifiedBy] ON [fin].[VoucherTemplate] ([ModifiedBy]);
GO
CREATE INDEX [IX_VoucherTemplate_DeletedBy] ON [fin].[VoucherTemplate] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'凭证模板（自动记账规则）', N'SCHEMA', N'fin', N'TABLE', N'VoucherTemplate';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'VoucherTemplate', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'模板名称', N'SCHEMA', N'fin', N'TABLE', N'VoucherTemplate', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'业务类型(销售出库/采购入库/收款...)', N'SCHEMA', N'fin', N'TABLE', N'VoucherTemplate', N'COLUMN', N'BizType';
EXEC sp_addextendedproperty N'MS_Description', N'适用条件', N'SCHEMA', N'fin', N'TABLE', N'VoucherTemplate', N'COLUMN', N'CondJson';
EXEC sp_addextendedproperty N'MS_Description', N'借贷方科目与取数规则', N'SCHEMA', N'fin', N'TABLE', N'VoucherTemplate', N'COLUMN', N'LinesJson';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'fin', N'TABLE', N'VoucherTemplate', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'fin', N'TABLE', N'VoucherTemplate', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'fin', N'TABLE', N'VoucherTemplate', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'fin', N'TABLE', N'VoucherTemplate', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'fin', N'TABLE', N'VoucherTemplate', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'VoucherTemplate', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'fin', N'TABLE', N'VoucherTemplate', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'VoucherTemplate', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'fin', N'TABLE', N'VoucherTemplate', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'VoucherTemplate', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [fin].[ArInvoice] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_ArInvoice_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_ArInvoice_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_ArInvoice_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_ArInvoice_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [SourceNo] varchar(40) NULL,
    [DueDate] date NULL,
    [Amount] decimal(19,4) NOT NULL,
    [ReceivedAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_ArInvoice_ReceivedAmount] DEFAULT (0),
    [BalanceAmount] AS (Amount - ReceivedAmount),
    [SettleStatus] tinyint NOT NULL CONSTRAINT [DF_ArInvoice_SettleStatus] DEFAULT (0),
    [IsInvoiced] bit NOT NULL CONSTRAINT [DF_ArInvoice_IsInvoiced] DEFAULT (0),
    CONSTRAINT [PK_ArInvoice] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ArInvoice_TenantId_DocNo] ON [fin].[ArInvoice] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_ArInvoice_PartnerId_SettleStatus] ON [fin].[ArInvoice] ([PartnerId], [SettleStatus]);
GO
CREATE INDEX [IX_ArInvoice_DueDate] ON [fin].[ArInvoice] ([DueDate]);
GO
CREATE INDEX [IX_ArInvoice_OrgId] ON [fin].[ArInvoice] ([OrgId]);
GO
CREATE INDEX [IX_ArInvoice_CreatedBy] ON [fin].[ArInvoice] ([CreatedBy]);
GO
CREATE INDEX [IX_ArInvoice_ModifiedBy] ON [fin].[ArInvoice] ([ModifiedBy]);
GO
CREATE INDEX [IX_ArInvoice_DeletedBy] ON [fin].[ArInvoice] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'应收单', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'客户', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'到期日', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'DueDate';
EXEC sp_addextendedproperty N'MS_Description', N'应收金额', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'Amount';
EXEC sp_addextendedproperty N'MS_Description', N'已收', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'ReceivedAmount';
EXEC sp_addextendedproperty N'MS_Description', N'未收余额', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'BalanceAmount';
EXEC sp_addextendedproperty N'MS_Description', N'0未收 1部分 2已收 3已核销', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'SettleStatus';
EXEC sp_addextendedproperty N'MS_Description', N'已开票', N'SCHEMA', N'fin', N'TABLE', N'ArInvoice', N'COLUMN', N'IsInvoiced';
GO
CREATE TABLE [fin].[ArReceipt] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_ArReceipt_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_ArReceipt_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_ArReceipt_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_ArReceipt_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [PayMethod] tinyint NOT NULL CONSTRAINT [DF_ArReceipt_PayMethod] DEFAULT (1) CONSTRAINT [CK_ArReceipt_PayMethod] CHECK (PayMethod BETWEEN 1 AND 6),
    [BankAccountId] bigint NULL,
    [Amount] decimal(19,4) NOT NULL,
    [AllocatedAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_ArReceipt_AllocatedAmount] DEFAULT (0),
    [UnallocatedAmount] AS (Amount - AllocatedAmount),
    [TradeNo] varchar(64) NULL,
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    CONSTRAINT [PK_ArReceipt] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ArReceipt_TenantId_DocNo] ON [fin].[ArReceipt] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_ArReceipt_PartnerId_Status] ON [fin].[ArReceipt] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_ArReceipt_OrgId] ON [fin].[ArReceipt] ([OrgId]);
GO
CREATE INDEX [IX_ArReceipt_CreatedBy] ON [fin].[ArReceipt] ([CreatedBy]);
GO
CREATE INDEX [IX_ArReceipt_ModifiedBy] ON [fin].[ArReceipt] ([ModifiedBy]);
GO
CREATE INDEX [IX_ArReceipt_DeletedBy] ON [fin].[ArReceipt] ([DeletedBy]);
GO
CREATE INDEX [IX_ArReceipt_BankAccountId] ON [fin].[ArReceipt] ([BankAccountId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'收款单', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'客户', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'方式(1现金 2银行转账 3微信 4支付宝 5承兑 6预存抵扣)', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'PayMethod';
EXEC sp_addextendedproperty N'MS_Description', N'收款账户', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'BankAccountId';
EXEC sp_addextendedproperty N'MS_Description', N'收款金额', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'Amount';
EXEC sp_addextendedproperty N'MS_Description', N'已核销', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'AllocatedAmount';
EXEC sp_addextendedproperty N'MS_Description', N'未核销', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'UnallocatedAmount';
EXEC sp_addextendedproperty N'MS_Description', N'交易号', N'SCHEMA', N'fin', N'TABLE', N'ArReceipt', N'COLUMN', N'TradeNo';
GO
CREATE TABLE [fin].[ArReceiptLine] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [ReceiptId] bigint NOT NULL,
    [ArInvoiceId] bigint NOT NULL,
    [Amount] decimal(19,4) NOT NULL,
    [DiscountAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_ArReceiptLine_DiscountAmount] DEFAULT (0),
    CONSTRAINT [PK_ArReceiptLine] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ArReceiptLine_ReceiptId_ArInvoiceId] ON [fin].[ArReceiptLine] ([ReceiptId], [ArInvoiceId]);
GO
CREATE INDEX [IX_ArReceiptLine_ArInvoiceId] ON [fin].[ArReceiptLine] ([ArInvoiceId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'收款核销明细', N'SCHEMA', N'fin', N'TABLE', N'ArReceiptLine';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'ArReceiptLine', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'应收单', N'SCHEMA', N'fin', N'TABLE', N'ArReceiptLine', N'COLUMN', N'ArInvoiceId';
EXEC sp_addextendedproperty N'MS_Description', N'核销金额', N'SCHEMA', N'fin', N'TABLE', N'ArReceiptLine', N'COLUMN', N'Amount';
EXEC sp_addextendedproperty N'MS_Description', N'折让', N'SCHEMA', N'fin', N'TABLE', N'ArReceiptLine', N'COLUMN', N'DiscountAmount';
GO
CREATE TABLE [fin].[ApInvoice] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_ApInvoice_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_ApInvoice_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_ApInvoice_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_ApInvoice_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [SourceNo] varchar(40) NULL,
    [DueDate] date NULL,
    [Amount] decimal(19,4) NOT NULL,
    [PaidAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_ApInvoice_PaidAmount] DEFAULT (0),
    [BalanceAmount] AS (Amount - PaidAmount),
    [SettleStatus] tinyint NOT NULL CONSTRAINT [DF_ApInvoice_SettleStatus] DEFAULT (0),
    [IsInvoiced] bit NOT NULL CONSTRAINT [DF_ApInvoice_IsInvoiced] DEFAULT (0),
    CONSTRAINT [PK_ApInvoice] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ApInvoice_TenantId_DocNo] ON [fin].[ApInvoice] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_ApInvoice_PartnerId_SettleStatus] ON [fin].[ApInvoice] ([PartnerId], [SettleStatus]);
GO
CREATE INDEX [IX_ApInvoice_DueDate] ON [fin].[ApInvoice] ([DueDate]);
GO
CREATE INDEX [IX_ApInvoice_OrgId] ON [fin].[ApInvoice] ([OrgId]);
GO
CREATE INDEX [IX_ApInvoice_CreatedBy] ON [fin].[ApInvoice] ([CreatedBy]);
GO
CREATE INDEX [IX_ApInvoice_ModifiedBy] ON [fin].[ApInvoice] ([ModifiedBy]);
GO
CREATE INDEX [IX_ApInvoice_DeletedBy] ON [fin].[ApInvoice] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'应付单', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'供应商', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'到期日', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'DueDate';
EXEC sp_addextendedproperty N'MS_Description', N'未付余额', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'BalanceAmount';
EXEC sp_addextendedproperty N'MS_Description', N'0未付 1部分 2已付 3已核销', N'SCHEMA', N'fin', N'TABLE', N'ApInvoice', N'COLUMN', N'SettleStatus';
GO
CREATE TABLE [fin].[ApPayment] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_ApPayment_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_ApPayment_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_ApPayment_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_ApPayment_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [PayMethod] tinyint NOT NULL CONSTRAINT [DF_ApPayment_PayMethod] DEFAULT (2),
    [BankAccountId] bigint NULL,
    [Amount] decimal(19,4) NOT NULL,
    [AllocatedAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_ApPayment_AllocatedAmount] DEFAULT (0),
    [UnallocatedAmount] AS (Amount - AllocatedAmount),
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    CONSTRAINT [PK_ApPayment] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ApPayment_TenantId_DocNo] ON [fin].[ApPayment] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_ApPayment_PartnerId_Status] ON [fin].[ApPayment] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_ApPayment_OrgId] ON [fin].[ApPayment] ([OrgId]);
GO
CREATE INDEX [IX_ApPayment_CreatedBy] ON [fin].[ApPayment] ([CreatedBy]);
GO
CREATE INDEX [IX_ApPayment_ModifiedBy] ON [fin].[ApPayment] ([ModifiedBy]);
GO
CREATE INDEX [IX_ApPayment_DeletedBy] ON [fin].[ApPayment] ([DeletedBy]);
GO
CREATE INDEX [IX_ApPayment_BankAccountId] ON [fin].[ApPayment] ([BankAccountId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'付款单', N'SCHEMA', N'fin', N'TABLE', N'ApPayment';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'供应商', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'付款账户', N'SCHEMA', N'fin', N'TABLE', N'ApPayment', N'COLUMN', N'BankAccountId';
GO
CREATE TABLE [fin].[ApPaymentLine] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [PaymentId] bigint NOT NULL,
    [ApInvoiceId] bigint NOT NULL,
    [Amount] decimal(19,4) NOT NULL,
    CONSTRAINT [PK_ApPaymentLine] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ApPaymentLine_PaymentId_ApInvoiceId] ON [fin].[ApPaymentLine] ([PaymentId], [ApInvoiceId]);
GO
CREATE INDEX [IX_ApPaymentLine_ApInvoiceId] ON [fin].[ApPaymentLine] ([ApInvoiceId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'付款核销明细', N'SCHEMA', N'fin', N'TABLE', N'ApPaymentLine';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'ApPaymentLine', N'COLUMN', N'Id';
GO
CREATE TABLE [fin].[BankAccount] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_BankAccount_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(100) NULL,
    [AccountType] tinyint NOT NULL CONSTRAINT [DF_BankAccount_AccountType] DEFAULT (1) CONSTRAINT [CK_BankAccount_AccountType] CHECK (AccountType BETWEEN 1 AND 6),
    [BankName] nvarchar(100) NULL,
    [AccountNo] varchar(50) NULL,
    [CurrencyCode] varchar(3) NOT NULL CONSTRAINT [DF_BankAccount_CurrencyCode] DEFAULT ('CNY'),
    [Balance] decimal(19,4) NOT NULL CONSTRAINT [DF_BankAccount_Balance] DEFAULT (0),
    [GlSubjectCode] varchar(30) NULL,
    [StoreId] bigint NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_BankAccount_IsEnabled] DEFAULT (1),
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_BankAccount_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_BankAccount_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_BankAccount] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_BankAccount_TenantId_Code] ON [fin].[BankAccount] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_BankAccount_OrgId] ON [fin].[BankAccount] ([OrgId]);
GO
CREATE INDEX [IX_BankAccount_CreatedBy] ON [fin].[BankAccount] ([CreatedBy]);
GO
CREATE INDEX [IX_BankAccount_ModifiedBy] ON [fin].[BankAccount] ([ModifiedBy]);
GO
CREATE INDEX [IX_BankAccount_DeletedBy] ON [fin].[BankAccount] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'资金账户', N'SCHEMA', N'fin', N'TABLE', N'BankAccount';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'账户名称', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1现金 2银行 3微信 4支付宝 5承兑 6预存)', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'AccountType';
EXEC sp_addextendedproperty N'MS_Description', N'账号', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'AccountNo';
EXEC sp_addextendedproperty N'MS_Description', N'账面余额', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'Balance';
EXEC sp_addextendedproperty N'MS_Description', N'对应科目', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'GlSubjectCode';
EXEC sp_addextendedproperty N'MS_Description', N'绑定门店', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'StoreId';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'BankAccount', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [fin].[FundTransaction] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_FundTransaction_TenantId] DEFAULT (1),
    [AccountId] bigint NOT NULL,
    [Direction] tinyint NOT NULL,
    [TxnType] tinyint NOT NULL CONSTRAINT [DF_FundTransaction_TxnType] DEFAULT (1),
    [Amount] decimal(19,4) NOT NULL,
    [BalanceAfter] decimal(19,4) NOT NULL,
    [SourceType] varchar(40) NULL,
    [SourceId] bigint NULL,
    [SourceNo] varchar(40) NULL,
    [PartnerId] bigint NULL,
    [BizDate] date NOT NULL,
    [At] datetime2(3) NOT NULL CONSTRAINT [DF_FundTransaction_At] DEFAULT (sysutcdatetime()),
    [OperatorId] bigint NULL,
    CONSTRAINT [PK_FundTransaction] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_FundTransaction_AccountId_BizDate] ON [fin].[FundTransaction] ([AccountId], [BizDate]);
GO
CREATE INDEX [IX_FundTransaction_SourceType_SourceId] ON [fin].[FundTransaction] ([SourceType], [SourceId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'资金流水', N'SCHEMA', N'fin', N'TABLE', N'FundTransaction';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'FundTransaction', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'方向(1收 2付)', N'SCHEMA', N'fin', N'TABLE', N'FundTransaction', N'COLUMN', N'Direction';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1销售收款 2采购付款 3费用 4转账 5备用金 6其他)', N'SCHEMA', N'fin', N'TABLE', N'FundTransaction', N'COLUMN', N'TxnType';
EXEC sp_addextendedproperty N'MS_Description', N'往来单位', N'SCHEMA', N'fin', N'TABLE', N'FundTransaction', N'COLUMN', N'PartnerId';
GO
CREATE TABLE [fin].[BankStatement] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_BankStatement_TenantId] DEFAULT (1),
    [AccountId] bigint NOT NULL,
    [TxnDate] date NOT NULL,
    [Amount] decimal(19,4) NOT NULL,
    [Balance] decimal(19,4) NULL,
    [CounterParty] nvarchar(200) NULL,
    [Summary] nvarchar(300) NULL,
    [TxnNo] varchar(64) NULL,
    [MatchStatus] tinyint NOT NULL CONSTRAINT [DF_BankStatement_MatchStatus] DEFAULT (0),
    [MatchedSourceType] varchar(40) NULL,
    [MatchedSourceId] bigint NULL,
    CONSTRAINT [PK_BankStatement] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_BankStatement_AccountId_TxnNo] ON [fin].[BankStatement] ([AccountId], [TxnNo]);
GO
CREATE INDEX [IX_BankStatement_AccountId_MatchStatus] ON [fin].[BankStatement] ([AccountId], [MatchStatus]);
GO
CREATE INDEX [IX_BankStatement_TxnDate] ON [fin].[BankStatement] ([TxnDate]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'银行流水（对账）', N'SCHEMA', N'fin', N'TABLE', N'BankStatement';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'BankStatement', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'交易日期', N'SCHEMA', N'fin', N'TABLE', N'BankStatement', N'COLUMN', N'TxnDate';
EXEC sp_addextendedproperty N'MS_Description', N'金额(正收负付)', N'SCHEMA', N'fin', N'TABLE', N'BankStatement', N'COLUMN', N'Amount';
EXEC sp_addextendedproperty N'MS_Description', N'余额', N'SCHEMA', N'fin', N'TABLE', N'BankStatement', N'COLUMN', N'Balance';
EXEC sp_addextendedproperty N'MS_Description', N'对方户名', N'SCHEMA', N'fin', N'TABLE', N'BankStatement', N'COLUMN', N'CounterParty';
EXEC sp_addextendedproperty N'MS_Description', N'摘要', N'SCHEMA', N'fin', N'TABLE', N'BankStatement', N'COLUMN', N'Summary';
EXEC sp_addextendedproperty N'MS_Description', N'银行流水号', N'SCHEMA', N'fin', N'TABLE', N'BankStatement', N'COLUMN', N'TxnNo';
EXEC sp_addextendedproperty N'MS_Description', N'0未匹配 1已匹配 2手工匹配 3忽略', N'SCHEMA', N'fin', N'TABLE', N'BankStatement', N'COLUMN', N'MatchStatus';
GO
CREATE TABLE [fin].[OutputInvoice] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_OutputInvoice_TenantId] DEFAULT (1),
    [InvoiceNo] varchar(40) NOT NULL,
    [InvoiceCode] varchar(20) NULL,
    [InvoiceType] tinyint NOT NULL CONSTRAINT [DF_OutputInvoice_InvoiceType] DEFAULT (1),
    [PartnerId] bigint NOT NULL,
    [InvoiceDate] date NOT NULL,
    [Amount] decimal(19,4) NOT NULL,
    [NetAmount] decimal(19,4) NULL,
    [TaxAmount] decimal(19,4) NULL,
    [TaxRate] decimal(9,4) NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_OutputInvoice_Status] DEFAULT (1),
    [RedInvoiceNo] varchar(40) NULL,
    [DeliveryStatus] tinyint NOT NULL CONSTRAINT [DF_OutputInvoice_DeliveryStatus] DEFAULT (0),
    CONSTRAINT [PK_OutputInvoice] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_OutputInvoice_TenantId_InvoiceNo] ON [fin].[OutputInvoice] ([TenantId], [InvoiceNo]);
GO
CREATE INDEX [IX_OutputInvoice_PartnerId_InvoiceDate] ON [fin].[OutputInvoice] ([PartnerId], [InvoiceDate]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'销项发票', N'SCHEMA', N'fin', N'TABLE', N'OutputInvoice';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'OutputInvoice', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'发票号', N'SCHEMA', N'fin', N'TABLE', N'OutputInvoice', N'COLUMN', N'InvoiceNo';
EXEC sp_addextendedproperty N'MS_Description', N'发票代码', N'SCHEMA', N'fin', N'TABLE', N'OutputInvoice', N'COLUMN', N'InvoiceCode';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1专票 2普票 3电子普票 4电子专票)', N'SCHEMA', N'fin', N'TABLE', N'OutputInvoice', N'COLUMN', N'InvoiceType';
EXEC sp_addextendedproperty N'MS_Description', N'客户', N'SCHEMA', N'fin', N'TABLE', N'OutputInvoice', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'价税合计', N'SCHEMA', N'fin', N'TABLE', N'OutputInvoice', N'COLUMN', N'Amount';
EXEC sp_addextendedproperty N'MS_Description', N'不含税', N'SCHEMA', N'fin', N'TABLE', N'OutputInvoice', N'COLUMN', N'NetAmount';
EXEC sp_addextendedproperty N'MS_Description', N'税额', N'SCHEMA', N'fin', N'TABLE', N'OutputInvoice', N'COLUMN', N'TaxAmount';
EXEC sp_addextendedproperty N'MS_Description', N'1正常 2已红冲 3作废', N'SCHEMA', N'fin', N'TABLE', N'OutputInvoice', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'红冲发票号', N'SCHEMA', N'fin', N'TABLE', N'OutputInvoice', N'COLUMN', N'RedInvoiceNo';
EXEC sp_addextendedproperty N'MS_Description', N'交付(0未交付 1已推送 2已下载)', N'SCHEMA', N'fin', N'TABLE', N'OutputInvoice', N'COLUMN', N'DeliveryStatus';
GO
CREATE TABLE [fin].[InputInvoice] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_InputInvoice_TenantId] DEFAULT (1),
    [InvoiceNo] varchar(40) NOT NULL,
    [InvoiceCode] varchar(20) NULL,
    [InvoiceType] tinyint NOT NULL CONSTRAINT [DF_InputInvoice_InvoiceType] DEFAULT (1),
    [PartnerId] bigint NULL,
    [InvoiceDate] date NOT NULL,
    [Amount] decimal(19,4) NOT NULL,
    [NetAmount] decimal(19,4) NULL,
    [TaxAmount] decimal(19,4) NULL,
    [TaxRate] decimal(9,4) NULL,
    [VerifyStatus] tinyint NOT NULL CONSTRAINT [DF_InputInvoice_VerifyStatus] DEFAULT (0),
    [Status] tinyint NOT NULL CONSTRAINT [DF_InputInvoice_Status] DEFAULT (1),
    CONSTRAINT [PK_InputInvoice] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_InputInvoice_TenantId_InvoiceNo] ON [fin].[InputInvoice] ([TenantId], [InvoiceNo]);
GO
CREATE INDEX [IX_InputInvoice_PartnerId_InvoiceDate] ON [fin].[InputInvoice] ([PartnerId], [InvoiceDate]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'进项发票', N'SCHEMA', N'fin', N'TABLE', N'InputInvoice';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'InputInvoice', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'供应商', N'SCHEMA', N'fin', N'TABLE', N'InputInvoice', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'认证(0未认证 1已认证 2不可抵扣)', N'SCHEMA', N'fin', N'TABLE', N'InputInvoice', N'COLUMN', N'VerifyStatus';
GO
CREATE TABLE [fin].[InvoiceMatch] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [InvoiceType] tinyint NOT NULL CONSTRAINT [DF_InvoiceMatch_InvoiceType] DEFAULT (1),
    [InvoiceId] bigint NOT NULL,
    [SourceType] varchar(40) NULL,
    [SourceId] bigint NOT NULL,
    [Amount] decimal(19,4) NOT NULL,
    CONSTRAINT [PK_InvoiceMatch] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_InvoiceMatch_InvoiceType_InvoiceId] ON [fin].[InvoiceMatch] ([InvoiceType], [InvoiceId]);
GO
CREATE INDEX [IX_InvoiceMatch_SourceType_SourceId] ON [fin].[InvoiceMatch] ([SourceType], [SourceId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'发票与单据核销', N'SCHEMA', N'fin', N'TABLE', N'InvoiceMatch';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'InvoiceMatch', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'1销项 2进项', N'SCHEMA', N'fin', N'TABLE', N'InvoiceMatch', N'COLUMN', N'InvoiceType';
EXEC sp_addextendedproperty N'MS_Description', N'单据类型(应收/应付/入库/出库)', N'SCHEMA', N'fin', N'TABLE', N'InvoiceMatch', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'核销金额', N'SCHEMA', N'fin', N'TABLE', N'InvoiceMatch', N'COLUMN', N'Amount';
GO
CREATE TABLE [fin].[ExpenseClaim] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_ExpenseClaim_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_ExpenseClaim_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_ExpenseClaim_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_ExpenseClaim_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [EmployeeId] bigint NULL,
    [DeptId] int NULL,
    [ExpenseType] tinyint NOT NULL CONSTRAINT [DF_ExpenseClaim_ExpenseType] DEFAULT (1),
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_ExpenseClaim_TotalAmount] DEFAULT (0),
    [AdvanceAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_ExpenseClaim_AdvanceAmount] DEFAULT (0),
    [PayableAmount] AS (TotalAmount - AdvanceAmount),
    [PayStatus] tinyint NOT NULL CONSTRAINT [DF_ExpenseClaim_PayStatus] DEFAULT (0),
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    CONSTRAINT [PK_ExpenseClaim] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ExpenseClaim_TenantId_DocNo] ON [fin].[ExpenseClaim] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_ExpenseClaim_EmployeeId_Status] ON [fin].[ExpenseClaim] ([EmployeeId], [Status]);
GO
CREATE INDEX [IX_ExpenseClaim_OrgId] ON [fin].[ExpenseClaim] ([OrgId]);
GO
CREATE INDEX [IX_ExpenseClaim_CreatedBy] ON [fin].[ExpenseClaim] ([CreatedBy]);
GO
CREATE INDEX [IX_ExpenseClaim_ModifiedBy] ON [fin].[ExpenseClaim] ([ModifiedBy]);
GO
CREATE INDEX [IX_ExpenseClaim_DeletedBy] ON [fin].[ExpenseClaim] ([DeletedBy]);
GO
CREATE INDEX [IX_ExpenseClaim_DeptId] ON [fin].[ExpenseClaim] ([DeptId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'费用报销单', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'报销人', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'EmployeeId';
EXEC sp_addextendedproperty N'MS_Description', N'部门', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'DeptId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1差旅 2办公 3招待 4运费 5促销 6其他)', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'ExpenseType';
EXEC sp_addextendedproperty N'MS_Description', N'冲抵借款', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'AdvanceAmount';
EXEC sp_addextendedproperty N'MS_Description', N'应付金额', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'PayableAmount';
EXEC sp_addextendedproperty N'MS_Description', N'0未付 1已付', N'SCHEMA', N'fin', N'TABLE', N'ExpenseClaim', N'COLUMN', N'PayStatus';
GO
CREATE TABLE [fin].[ExpenseItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [ClaimId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [ExpenseDate] date NULL,
    [SubjectCode] varchar(30) NULL,
    [Amount] decimal(19,4) NOT NULL,
    [TaxAmount] decimal(19,4) NULL,
    [InvoiceCount] int NULL,
    [AttachmentJson] nvarchar(max) NULL,
    [Description] nvarchar(300) NULL,
    CONSTRAINT [PK_ExpenseItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_ExpenseItem_ClaimId] ON [fin].[ExpenseItem] ([ClaimId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'报销明细', N'SCHEMA', N'fin', N'TABLE', N'ExpenseItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'ExpenseItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'fin', N'TABLE', N'ExpenseItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'fin', N'TABLE', N'ExpenseItem', N'COLUMN', N'ClaimId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'fin', N'TABLE', N'ExpenseItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'费用日期', N'SCHEMA', N'fin', N'TABLE', N'ExpenseItem', N'COLUMN', N'ExpenseDate';
EXEC sp_addextendedproperty N'MS_Description', N'费用科目', N'SCHEMA', N'fin', N'TABLE', N'ExpenseItem', N'COLUMN', N'SubjectCode';
EXEC sp_addextendedproperty N'MS_Description', N'税额', N'SCHEMA', N'fin', N'TABLE', N'ExpenseItem', N'COLUMN', N'TaxAmount';
EXEC sp_addextendedproperty N'MS_Description', N'发票张数', N'SCHEMA', N'fin', N'TABLE', N'ExpenseItem', N'COLUMN', N'InvoiceCount';
EXEC sp_addextendedproperty N'MS_Description', N'发票影像', N'SCHEMA', N'fin', N'TABLE', N'ExpenseItem', N'COLUMN', N'AttachmentJson';
GO
CREATE TABLE [fin].[Budget] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Budget_TenantId] DEFAULT (1),
    [Code] varchar(40) NOT NULL,
    [Name] nvarchar(100) NULL,
    [BudgetType] tinyint NOT NULL CONSTRAINT [DF_Budget_BudgetType] DEFAULT (1) CONSTRAINT [CK_Budget_BudgetType] CHECK (BudgetType BETWEEN 1 AND 5),
    [Year] smallint NOT NULL,
    [Version] int NOT NULL CONSTRAINT [DF_Budget_Version] DEFAULT (1),
    [Status] tinyint NOT NULL CONSTRAINT [DF_Budget_Status] DEFAULT (0),
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_Budget_TotalAmount] DEFAULT (0),
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    [PublishedAt] datetime2(3) NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Budget_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Budget_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Budget] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Budget_TenantId_Code_Version] ON [fin].[Budget] ([TenantId], [Code], [Version]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Budget_OrgId] ON [fin].[Budget] ([OrgId]);
GO
CREATE INDEX [IX_Budget_CreatedBy] ON [fin].[Budget] ([CreatedBy]);
GO
CREATE INDEX [IX_Budget_ModifiedBy] ON [fin].[Budget] ([ModifiedBy]);
GO
CREATE INDEX [IX_Budget_DeletedBy] ON [fin].[Budget] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'预算', N'SCHEMA', N'fin', N'TABLE', N'Budget';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'Budget', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1收入 2成本 3费用 4采购 5资金)', N'SCHEMA', N'fin', N'TABLE', N'Budget', N'COLUMN', N'BudgetType';
EXEC sp_addextendedproperty N'MS_Description', N'0编制中 1已审批 2已下达 3已关闭', N'SCHEMA', N'fin', N'TABLE', N'Budget', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'fin', N'TABLE', N'Budget', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'fin', N'TABLE', N'Budget', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'fin', N'TABLE', N'Budget', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'fin', N'TABLE', N'Budget', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'fin', N'TABLE', N'Budget', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'fin', N'TABLE', N'Budget', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'Budget', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'fin', N'TABLE', N'Budget', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'Budget', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'fin', N'TABLE', N'Budget', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'Budget', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [fin].[BudgetItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [BudgetId] bigint NOT NULL,
    [OrgId] int NULL,
    [SubjectCode] varchar(30) NULL,
    [Period] varchar(10) NULL,
    [BudgetAmount] decimal(19,4) NOT NULL,
    [UsedAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_BudgetItem_UsedAmount] DEFAULT (0),
    [OccupiedAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_BudgetItem_OccupiedAmount] DEFAULT (0),
    [AvailableAmount] AS (BudgetAmount - UsedAmount - OccupiedAmount),
    [ControlMode] tinyint NOT NULL CONSTRAINT [DF_BudgetItem_ControlMode] DEFAULT (2),
    CONSTRAINT [PK_BudgetItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_BudgetItem_BudgetId_Period] ON [fin].[BudgetItem] ([BudgetId], [Period]);
GO
CREATE INDEX [IX_BudgetItem_OrgId] ON [fin].[BudgetItem] ([OrgId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'预算明细', N'SCHEMA', N'fin', N'TABLE', N'BudgetItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'BudgetItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'责任部门', N'SCHEMA', N'fin', N'TABLE', N'BudgetItem', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'科目/费用项', N'SCHEMA', N'fin', N'TABLE', N'BudgetItem', N'COLUMN', N'SubjectCode';
EXEC sp_addextendedproperty N'MS_Description', N'期间(空=全年)', N'SCHEMA', N'fin', N'TABLE', N'BudgetItem', N'COLUMN', N'Period';
EXEC sp_addextendedproperty N'MS_Description', N'预算额', N'SCHEMA', N'fin', N'TABLE', N'BudgetItem', N'COLUMN', N'BudgetAmount';
EXEC sp_addextendedproperty N'MS_Description', N'已用', N'SCHEMA', N'fin', N'TABLE', N'BudgetItem', N'COLUMN', N'UsedAmount';
EXEC sp_addextendedproperty N'MS_Description', N'占用(在途)', N'SCHEMA', N'fin', N'TABLE', N'BudgetItem', N'COLUMN', N'OccupiedAmount';
EXEC sp_addextendedproperty N'MS_Description', N'可用', N'SCHEMA', N'fin', N'TABLE', N'BudgetItem', N'COLUMN', N'AvailableAmount';
EXEC sp_addextendedproperty N'MS_Description', N'控制(1拦截 2预警 3不控)', N'SCHEMA', N'fin', N'TABLE', N'BudgetItem', N'COLUMN', N'ControlMode';
GO
CREATE TABLE [fin].[CostCalculation] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_CostCalculation_TenantId] DEFAULT (1),
    [Period] varchar(10) NOT NULL,
    [CalcNo] varchar(40) NOT NULL,
    [Method] tinyint NOT NULL CONSTRAINT [DF_CostCalculation_Method] DEFAULT (1) CONSTRAINT [CK_CostCalculation_Method] CHECK (Method BETWEEN 1 AND 3),
    [Status] tinyint NOT NULL CONSTRAINT [DF_CostCalculation_Status] DEFAULT (0),
    [BeginAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_CostCalculation_BeginAmount] DEFAULT (0),
    [InAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_CostCalculation_InAmount] DEFAULT (0),
    [OutAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_CostCalculation_OutAmount] DEFAULT (0),
    [EndAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_CostCalculation_EndAmount] DEFAULT (0),
    [DiffAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_CostCalculation_DiffAmount] DEFAULT (0),
    [CalculatedAt] datetime2(3) NULL,
    [PostedAt] datetime2(3) NULL,
    [OperatorId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_CostCalculation_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_CostCalculation_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_CostCalculation] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_CostCalculation_TenantId_Period_CalcNo] ON [fin].[CostCalculation] ([TenantId], [Period], [CalcNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_CostCalculation_OrgId] ON [fin].[CostCalculation] ([OrgId]);
GO
CREATE INDEX [IX_CostCalculation_CreatedBy] ON [fin].[CostCalculation] ([CreatedBy]);
GO
CREATE INDEX [IX_CostCalculation_ModifiedBy] ON [fin].[CostCalculation] ([ModifiedBy]);
GO
CREATE INDEX [IX_CostCalculation_DeletedBy] ON [fin].[CostCalculation] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'成本计算单', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'期间', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'Period';
EXEC sp_addextendedproperty N'MS_Description', N'方法(1移动加权 2先进先出 3批次个别计价)', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'Method';
EXEC sp_addextendedproperty N'MS_Description', N'0计算中 1已计算 2已结转 3已反结转', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'期初金额', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'BeginAmount';
EXEC sp_addextendedproperty N'MS_Description', N'入库金额', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'InAmount';
EXEC sp_addextendedproperty N'MS_Description', N'出库金额', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'OutAmount';
EXEC sp_addextendedproperty N'MS_Description', N'期末金额', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'EndAmount';
EXEC sp_addextendedproperty N'MS_Description', N'差异调整', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'DiffAmount';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'CostCalculation', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [fin].[CostDetail] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [CalcId] bigint NOT NULL,
    [SkuId] bigint NOT NULL,
    [WarehouseId] bigint NULL,
    [BeginQty] decimal(19,6) NOT NULL CONSTRAINT [DF_CostDetail_BeginQty] DEFAULT (0),
    [BeginAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_CostDetail_BeginAmount] DEFAULT (0),
    [InQty] decimal(19,6) NOT NULL CONSTRAINT [DF_CostDetail_InQty] DEFAULT (0),
    [InAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_CostDetail_InAmount] DEFAULT (0),
    [OutQty] decimal(19,6) NOT NULL CONSTRAINT [DF_CostDetail_OutQty] DEFAULT (0),
    [OutAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_CostDetail_OutAmount] DEFAULT (0),
    [EndQty] decimal(19,6) NOT NULL CONSTRAINT [DF_CostDetail_EndQty] DEFAULT (0),
    [EndAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_CostDetail_EndAmount] DEFAULT (0),
    [UnitCost] decimal(19,6) NOT NULL CONSTRAINT [DF_CostDetail_UnitCost] DEFAULT (0),
    CONSTRAINT [PK_CostDetail] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_CostDetail_CalcId_SkuId_WarehouseId] ON [fin].[CostDetail] ([CalcId], [SkuId], [WarehouseId]);
GO
CREATE INDEX [IX_CostDetail_SkuId] ON [fin].[CostDetail] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'成本计算明细', N'SCHEMA', N'fin', N'TABLE', N'CostDetail';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'CostDetail', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'仓库', N'SCHEMA', N'fin', N'TABLE', N'CostDetail', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'结存单价', N'SCHEMA', N'fin', N'TABLE', N'CostDetail', N'COLUMN', N'UnitCost';
GO
CREATE TABLE [fin].[FixedAsset] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_FixedAsset_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(100) NULL,
    [CategoryCode] varchar(30) NULL,
    [DeptId] int NULL,
    [OriginalValue] decimal(19,4) NOT NULL,
    [SalvageRate] decimal(9,4) NULL,
    [UsefulMonths] int NOT NULL,
    [DepreciatedMonths] int NOT NULL CONSTRAINT [DF_FixedAsset_DepreciatedMonths] DEFAULT (0),
    [AccumDepreciation] decimal(19,4) NOT NULL CONSTRAINT [DF_FixedAsset_AccumDepreciation] DEFAULT (0),
    [NetValue] AS (OriginalValue - AccumDepreciation),
    [StartDate] date NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_FixedAsset_Status] DEFAULT (1),
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_FixedAsset_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_FixedAsset_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_FixedAsset] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_FixedAsset_TenantId_Code] ON [fin].[FixedAsset] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_FixedAsset_DeptId] ON [fin].[FixedAsset] ([DeptId]);
GO
CREATE INDEX [IX_FixedAsset_OrgId] ON [fin].[FixedAsset] ([OrgId]);
GO
CREATE INDEX [IX_FixedAsset_CreatedBy] ON [fin].[FixedAsset] ([CreatedBy]);
GO
CREATE INDEX [IX_FixedAsset_ModifiedBy] ON [fin].[FixedAsset] ([ModifiedBy]);
GO
CREATE INDEX [IX_FixedAsset_DeletedBy] ON [fin].[FixedAsset] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'固定资产', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'资产类别', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'CategoryCode';
EXEC sp_addextendedproperty N'MS_Description', N'使用部门', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'DeptId';
EXEC sp_addextendedproperty N'MS_Description', N'原值', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'OriginalValue';
EXEC sp_addextendedproperty N'MS_Description', N'残值率%', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'SalvageRate';
EXEC sp_addextendedproperty N'MS_Description', N'使用月数', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'UsefulMonths';
EXEC sp_addextendedproperty N'MS_Description', N'已折旧月数', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'DepreciatedMonths';
EXEC sp_addextendedproperty N'MS_Description', N'累计折旧', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'AccumDepreciation';
EXEC sp_addextendedproperty N'MS_Description', N'净值', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'NetValue';
EXEC sp_addextendedproperty N'MS_Description', N'开始使用', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'StartDate';
EXEC sp_addextendedproperty N'MS_Description', N'1在用 2闲置 3处置', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'fin', N'TABLE', N'FixedAsset', N'COLUMN', N'DeletedAt';
GO
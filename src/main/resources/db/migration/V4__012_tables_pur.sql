/* =====================================================================
   进销存管理系统 V3 · 表结构 · pur 架构（23 张表）
   数据库：APSErpV3   生成器：db/emit.py（请勿手改，改规格文件后重新生成）
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE TABLE [pur].[Requisition] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Requisition_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_Requisition_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Requisition_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Requisition_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [ReqType] tinyint NOT NULL CONSTRAINT [DF_Requisition_ReqType] DEFAULT (1) CONSTRAINT [CK_Requisition_ReqType] CHECK (ReqType BETWEEN 1 AND 5),
    [ApplicantId] bigint NULL,
    [DeptId] int NULL,
    [ExpectedDate] date NULL,
    [WarehouseId] bigint NULL,
    [BudgetAmount] decimal(19,4) NULL,
    CONSTRAINT [PK_Requisition] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Requisition_TenantId_DocNo] ON [pur].[Requisition] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Requisition_Status_BizDate] ON [pur].[Requisition] ([Status], [BizDate]);
GO
CREATE INDEX [IX_Requisition_OrgId] ON [pur].[Requisition] ([OrgId]);
GO
CREATE INDEX [IX_Requisition_CreatedBy] ON [pur].[Requisition] ([CreatedBy]);
GO
CREATE INDEX [IX_Requisition_ModifiedBy] ON [pur].[Requisition] ([ModifiedBy]);
GO
CREATE INDEX [IX_Requisition_DeletedBy] ON [pur].[Requisition] ([DeletedBy]);
GO
CREATE INDEX [IX_Requisition_ApplicantId] ON [pur].[Requisition] ([ApplicantId]);
GO
CREATE INDEX [IX_Requisition_DeptId] ON [pur].[Requisition] ([DeptId]);
GO
CREATE INDEX [IX_Requisition_WarehouseId] ON [pur].[Requisition] ([WarehouseId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'请购单', N'SCHEMA', N'pur', N'TABLE', N'Requisition';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'请购来源(1手工 2补货建议 3门店要货 4缺货登记 5销售订单)', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'ReqType';
EXEC sp_addextendedproperty N'MS_Description', N'申请人', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'ApplicantId';
EXEC sp_addextendedproperty N'MS_Description', N'申请部门', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'DeptId';
EXEC sp_addextendedproperty N'MS_Description', N'期望到货', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'ExpectedDate';
EXEC sp_addextendedproperty N'MS_Description', N'收货仓', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'预算金额', N'SCHEMA', N'pur', N'TABLE', N'Requisition', N'COLUMN', N'BudgetAmount';
GO
CREATE TABLE [pur].[RequisitionItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [RequisitionId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [UnitId] bigint NOT NULL,
    [Qty] decimal(19,6) NOT NULL,
    [SuggestQty] decimal(19,6) NULL,
    [RefPrice] decimal(19,6) NULL,
    [NeedDate] date NULL,
    [LinkedOrderQty] decimal(19,6) NOT NULL CONSTRAINT [DF_RequisitionItem_LinkedOrderQty] DEFAULT (0),
    [Reason] nvarchar(200) NULL,
    CONSTRAINT [PK_RequisitionItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_RequisitionItem_RequisitionId_LineNo] ON [pur].[RequisitionItem] ([RequisitionId], [LineNo]);
GO
CREATE INDEX [IX_RequisitionItem_SkuId] ON [pur].[RequisitionItem] ([SkuId]);
GO
CREATE INDEX [IX_RequisitionItem_UnitId] ON [pur].[RequisitionItem] ([UnitId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'请购明细', N'SCHEMA', N'pur', N'TABLE', N'RequisitionItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'RequisitionItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'pur', N'TABLE', N'RequisitionItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'pur', N'TABLE', N'RequisitionItem', N'COLUMN', N'RequisitionId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'pur', N'TABLE', N'RequisitionItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'请购数量', N'SCHEMA', N'pur', N'TABLE', N'RequisitionItem', N'COLUMN', N'Qty';
EXEC sp_addextendedproperty N'MS_Description', N'系统建议量', N'SCHEMA', N'pur', N'TABLE', N'RequisitionItem', N'COLUMN', N'SuggestQty';
EXEC sp_addextendedproperty N'MS_Description', N'参考价', N'SCHEMA', N'pur', N'TABLE', N'RequisitionItem', N'COLUMN', N'RefPrice';
EXEC sp_addextendedproperty N'MS_Description', N'需求日期', N'SCHEMA', N'pur', N'TABLE', N'RequisitionItem', N'COLUMN', N'NeedDate';
EXEC sp_addextendedproperty N'MS_Description', N'已转订单数量', N'SCHEMA', N'pur', N'TABLE', N'RequisitionItem', N'COLUMN', N'LinkedOrderQty';
EXEC sp_addextendedproperty N'MS_Description', N'请购理由', N'SCHEMA', N'pur', N'TABLE', N'RequisitionItem', N'COLUMN', N'Reason';
GO
CREATE TABLE [pur].[RFQ] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_RFQ_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_RFQ_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_RFQ_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_RFQ_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [RFQType] tinyint NOT NULL CONSTRAINT [DF_RFQ_RFQType] DEFAULT (1),
    [Deadline] datetime2(3) NULL,
    [BuyerId] bigint NULL,
    CONSTRAINT [PK_RFQ] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_RFQ_TenantId_DocNo] ON [pur].[RFQ] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_RFQ_OrgId] ON [pur].[RFQ] ([OrgId]);
GO
CREATE INDEX [IX_RFQ_CreatedBy] ON [pur].[RFQ] ([CreatedBy]);
GO
CREATE INDEX [IX_RFQ_ModifiedBy] ON [pur].[RFQ] ([ModifiedBy]);
GO
CREATE INDEX [IX_RFQ_DeletedBy] ON [pur].[RFQ] ([DeletedBy]);
GO
CREATE INDEX [IX_RFQ_BuyerId] ON [pur].[RFQ] ([BuyerId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'询价单', N'SCHEMA', N'pur', N'TABLE', N'RFQ';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1公开询价 2定向询价)', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'RFQType';
EXEC sp_addextendedproperty N'MS_Description', N'报价截止', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'Deadline';
EXEC sp_addextendedproperty N'MS_Description', N'采购员', N'SCHEMA', N'pur', N'TABLE', N'RFQ', N'COLUMN', N'BuyerId';
GO
CREATE TABLE [pur].[RFQItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [RFQId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [Qty] decimal(19,6) NOT NULL,
    [UnitId] bigint NULL,
    [TargetPrice] decimal(19,6) NULL,
    CONSTRAINT [PK_RFQItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_RFQItem_RFQId] ON [pur].[RFQItem] ([RFQId]);
GO
CREATE INDEX [IX_RFQItem_SkuId] ON [pur].[RFQItem] ([SkuId]);
GO
CREATE INDEX [IX_RFQItem_UnitId] ON [pur].[RFQItem] ([UnitId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'询价明细', N'SCHEMA', N'pur', N'TABLE', N'RFQItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'RFQItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'pur', N'TABLE', N'RFQItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'pur', N'TABLE', N'RFQItem', N'COLUMN', N'RFQId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'pur', N'TABLE', N'RFQItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'询价数量', N'SCHEMA', N'pur', N'TABLE', N'RFQItem', N'COLUMN', N'Qty';
EXEC sp_addextendedproperty N'MS_Description', N'单位', N'SCHEMA', N'pur', N'TABLE', N'RFQItem', N'COLUMN', N'UnitId';
EXEC sp_addextendedproperty N'MS_Description', N'目标价', N'SCHEMA', N'pur', N'TABLE', N'RFQItem', N'COLUMN', N'TargetPrice';
GO
CREATE TABLE [pur].[Quote] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Quote_TenantId] DEFAULT (1),
    [RFQId] bigint NULL,
    [PartnerId] bigint NOT NULL,
    [QuoteNo] varchar(40) NULL,
    [QuoteDate] date NOT NULL,
    [ValidTo] date NULL,
    [TaxRate] decimal(9,4) NULL,
    [Freight] decimal(19,4) NULL,
    [PaymentTerm] nvarchar(100) NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_Quote_Status] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Quote_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Quote_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Quote] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_Quote_RFQId] ON [pur].[Quote] ([RFQId]);
GO
CREATE INDEX [IX_Quote_PartnerId_Status] ON [pur].[Quote] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_Quote_CreatedBy] ON [pur].[Quote] ([CreatedBy]);
GO
CREATE INDEX [IX_Quote_ModifiedBy] ON [pur].[Quote] ([ModifiedBy]);
GO
CREATE INDEX [IX_Quote_DeletedBy] ON [pur].[Quote] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'供应商报价', N'SCHEMA', N'pur', N'TABLE', N'Quote';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'询价单', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'RFQId';
EXEC sp_addextendedproperty N'MS_Description', N'供应商', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'报价单号', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'QuoteNo';
EXEC sp_addextendedproperty N'MS_Description', N'报价日期', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'QuoteDate';
EXEC sp_addextendedproperty N'MS_Description', N'有效期至', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'ValidTo';
EXEC sp_addextendedproperty N'MS_Description', N'税率', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'TaxRate';
EXEC sp_addextendedproperty N'MS_Description', N'运费', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'Freight';
EXEC sp_addextendedproperty N'MS_Description', N'付款条件', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'PaymentTerm';
EXEC sp_addextendedproperty N'MS_Description', N'1报价中 2已报价 3中标 4未中标', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'Quote', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [pur].[QuoteItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [QuoteId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [UnitId] bigint NULL,
    [Qty] decimal(19,6) NULL,
    [Price] decimal(19,6) NOT NULL,
    [LeadDays] int NULL,
    [Score] decimal(9,4) NULL,
    CONSTRAINT [PK_QuoteItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_QuoteItem_QuoteId] ON [pur].[QuoteItem] ([QuoteId]);
GO
CREATE INDEX [IX_QuoteItem_SkuId] ON [pur].[QuoteItem] ([SkuId]);
GO
CREATE INDEX [IX_QuoteItem_UnitId] ON [pur].[QuoteItem] ([UnitId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'报价明细', N'SCHEMA', N'pur', N'TABLE', N'QuoteItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'QuoteItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'pur', N'TABLE', N'QuoteItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'pur', N'TABLE', N'QuoteItem', N'COLUMN', N'QuoteId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'pur', N'TABLE', N'QuoteItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'单位', N'SCHEMA', N'pur', N'TABLE', N'QuoteItem', N'COLUMN', N'UnitId';
EXEC sp_addextendedproperty N'MS_Description', N'可供数量', N'SCHEMA', N'pur', N'TABLE', N'QuoteItem', N'COLUMN', N'Qty';
EXEC sp_addextendedproperty N'MS_Description', N'报价单价', N'SCHEMA', N'pur', N'TABLE', N'QuoteItem', N'COLUMN', N'Price';
EXEC sp_addextendedproperty N'MS_Description', N'交货天数', N'SCHEMA', N'pur', N'TABLE', N'QuoteItem', N'COLUMN', N'LeadDays';
EXEC sp_addextendedproperty N'MS_Description', N'综合评分', N'SCHEMA', N'pur', N'TABLE', N'QuoteItem', N'COLUMN', N'Score';
GO
CREATE TABLE [pur].[PurchaseContract] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_PurchaseContract_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_PurchaseContract_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_PurchaseContract_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_PurchaseContract_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [ContractType] tinyint NOT NULL CONSTRAINT [DF_PurchaseContract_ContractType] DEFAULT (1),
    [StartDate] date NULL,
    [EndDate] date NULL,
    [TotalAmount] decimal(19,4) NULL,
    [TotalQty] decimal(19,6) NULL,
    [PaymentTerm] nvarchar(200) NULL,
    [AutoRenew] bit NOT NULL CONSTRAINT [DF_PurchaseContract_AutoRenew] DEFAULT (0),
    CONSTRAINT [PK_PurchaseContract] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PurchaseContract_TenantId_DocNo] ON [pur].[PurchaseContract] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_PurchaseContract_PartnerId_Status] ON [pur].[PurchaseContract] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_PurchaseContract_OrgId] ON [pur].[PurchaseContract] ([OrgId]);
GO
CREATE INDEX [IX_PurchaseContract_CreatedBy] ON [pur].[PurchaseContract] ([CreatedBy]);
GO
CREATE INDEX [IX_PurchaseContract_ModifiedBy] ON [pur].[PurchaseContract] ([ModifiedBy]);
GO
CREATE INDEX [IX_PurchaseContract_DeletedBy] ON [pur].[PurchaseContract] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'采购合同/框架协议', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'供应商', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1单次 2年度框架 3配额协议)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'ContractType';
EXEC sp_addextendedproperty N'MS_Description', N'开始', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'StartDate';
EXEC sp_addextendedproperty N'MS_Description', N'结束', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'EndDate';
EXEC sp_addextendedproperty N'MS_Description', N'合同金额', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'TotalAmount';
EXEC sp_addextendedproperty N'MS_Description', N'合同数量', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'TotalQty';
EXEC sp_addextendedproperty N'MS_Description', N'付款条款', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'PaymentTerm';
EXEC sp_addextendedproperty N'MS_Description', N'到期提醒续签', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContract', N'COLUMN', N'AutoRenew';
GO
CREATE TABLE [pur].[PurchaseContractItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [ContractId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [UnitId] bigint NULL,
    [Qty] decimal(19,6) NULL,
    [Price] decimal(19,6) NULL,
    [QuotaRate] decimal(9,4) NULL,
    [UsedQty] decimal(19,6) NOT NULL CONSTRAINT [DF_PurchaseContractItem_UsedQty] DEFAULT (0),
    CONSTRAINT [PK_PurchaseContractItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_PurchaseContractItem_ContractId] ON [pur].[PurchaseContractItem] ([ContractId]);
GO
CREATE INDEX [IX_PurchaseContractItem_SkuId] ON [pur].[PurchaseContractItem] ([SkuId]);
GO
CREATE INDEX [IX_PurchaseContractItem_UnitId] ON [pur].[PurchaseContractItem] ([UnitId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'合同明细', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContractItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContractItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContractItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContractItem', N'COLUMN', N'ContractId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContractItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'单位', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContractItem', N'COLUMN', N'UnitId';
EXEC sp_addextendedproperty N'MS_Description', N'协议数量', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContractItem', N'COLUMN', N'Qty';
EXEC sp_addextendedproperty N'MS_Description', N'协议价', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContractItem', N'COLUMN', N'Price';
EXEC sp_addextendedproperty N'MS_Description', N'配额比例%', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContractItem', N'COLUMN', N'QuotaRate';
EXEC sp_addextendedproperty N'MS_Description', N'已执行数量', N'SCHEMA', N'pur', N'TABLE', N'PurchaseContractItem', N'COLUMN', N'UsedQty';
GO
CREATE TABLE [pur].[PurchaseOrder] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_PurchaseOrder_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_PurchaseOrder_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_PurchaseOrder_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_PurchaseOrder_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [BuyerId] bigint NULL,
    [ExpectedDate] date NULL,
    [WarehouseId] bigint NULL,
    [ContractId] bigint NULL,
    [CurrencyCode] varchar(3) NOT NULL CONSTRAINT [DF_PurchaseOrder_CurrencyCode] DEFAULT ('CNY'),
    [ExchangeRate] decimal(19,6) NOT NULL CONSTRAINT [DF_PurchaseOrder_ExchangeRate] DEFAULT (1),
    [NetAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PurchaseOrder_NetAmount] DEFAULT (0),
    [TaxAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PurchaseOrder_TaxAmount] DEFAULT (0),
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PurchaseOrder_TotalAmount] DEFAULT (0),
    [DiscountAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PurchaseOrder_DiscountAmount] DEFAULT (0),
    [ReceivedAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PurchaseOrder_ReceivedAmount] DEFAULT (0),
    [InvoicedAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PurchaseOrder_InvoicedAmount] DEFAULT (0),
    [PaidAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PurchaseOrder_PaidAmount] DEFAULT (0),
    [DeliveryType] tinyint NOT NULL CONSTRAINT [DF_PurchaseOrder_DeliveryType] DEFAULT (1) CONSTRAINT [CK_PurchaseOrder_DeliveryType] CHECK (DeliveryType BETWEEN 1 AND 3),
    [SupplierConfirmAt] datetime2(3) NULL,
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    CONSTRAINT [PK_PurchaseOrder] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PurchaseOrder_TenantId_DocNo] ON [pur].[PurchaseOrder] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_PurchaseOrder_PartnerId_Status] ON [pur].[PurchaseOrder] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_PurchaseOrder_Status_BizDate] ON [pur].[PurchaseOrder] ([Status], [BizDate]);
GO
CREATE INDEX [IX_PurchaseOrder_ExpectedDate] ON [pur].[PurchaseOrder] ([ExpectedDate]);
GO
CREATE INDEX [IX_PurchaseOrder_OrgId] ON [pur].[PurchaseOrder] ([OrgId]);
GO
CREATE INDEX [IX_PurchaseOrder_CreatedBy] ON [pur].[PurchaseOrder] ([CreatedBy]);
GO
CREATE INDEX [IX_PurchaseOrder_ModifiedBy] ON [pur].[PurchaseOrder] ([ModifiedBy]);
GO
CREATE INDEX [IX_PurchaseOrder_DeletedBy] ON [pur].[PurchaseOrder] ([DeletedBy]);
GO
CREATE INDEX [IX_PurchaseOrder_BuyerId] ON [pur].[PurchaseOrder] ([BuyerId]);
GO
CREATE INDEX [IX_PurchaseOrder_WarehouseId] ON [pur].[PurchaseOrder] ([WarehouseId]);
GO
CREATE INDEX [IX_PurchaseOrder_ContractId] ON [pur].[PurchaseOrder] ([ContractId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'采购订单', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'供应商', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'采购员', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'BuyerId';
EXEC sp_addextendedproperty N'MS_Description', N'预计到货', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'ExpectedDate';
EXEC sp_addextendedproperty N'MS_Description', N'收货仓', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'关联合同', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'ContractId';
EXEC sp_addextendedproperty N'MS_Description', N'汇率', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'ExchangeRate';
EXEC sp_addextendedproperty N'MS_Description', N'不含税金额', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'NetAmount';
EXEC sp_addextendedproperty N'MS_Description', N'税额', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'TaxAmount';
EXEC sp_addextendedproperty N'MS_Description', N'价税合计', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'TotalAmount';
EXEC sp_addextendedproperty N'MS_Description', N'优惠金额', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'DiscountAmount';
EXEC sp_addextendedproperty N'MS_Description', N'已入库金额', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'ReceivedAmount';
EXEC sp_addextendedproperty N'MS_Description', N'已开票金额', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'InvoicedAmount';
EXEC sp_addextendedproperty N'MS_Description', N'已付款金额', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'PaidAmount';
EXEC sp_addextendedproperty N'MS_Description', N'交货方式(1送货到仓 2直发客户 3自提)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'DeliveryType';
EXEC sp_addextendedproperty N'MS_Description', N'供应商确认时间', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'SupplierConfirmAt';
EXEC sp_addextendedproperty N'MS_Description', N'审核人', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'ApprovedBy';
EXEC sp_addextendedproperty N'MS_Description', N'审核时间', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrder', N'COLUMN', N'ApprovedAt';
GO
CREATE TABLE [pur].[PurchaseOrderItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [OrderId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [UnitId] bigint NOT NULL,
    [ConvertRate] decimal(19,6) NOT NULL CONSTRAINT [DF_PurchaseOrderItem_ConvertRate] DEFAULT (1),
    [Qty] decimal(19,6) NOT NULL,
    [BaseQty] decimal(19,6) NOT NULL,
    [Price] decimal(19,6) NOT NULL,
    [TaxRate] decimal(9,4) NOT NULL CONSTRAINT [DF_PurchaseOrderItem_TaxRate] DEFAULT (13),
    [NetAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PurchaseOrderItem_NetAmount] DEFAULT (0),
    [TaxAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PurchaseOrderItem_TaxAmount] DEFAULT (0),
    [Amount] decimal(19,4) NOT NULL CONSTRAINT [DF_PurchaseOrderItem_Amount] DEFAULT (0),
    [Discount] decimal(9,4) NOT NULL CONSTRAINT [DF_PurchaseOrderItem_Discount] DEFAULT (0),
    [ReceivedQty] decimal(19,6) NOT NULL CONSTRAINT [DF_PurchaseOrderItem_ReceivedQty] DEFAULT (0),
    [BatchNo] varchar(50) NULL,
    [NeedDate] date NULL,
    CONSTRAINT [PK_PurchaseOrderItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PurchaseOrderItem_OrderId_LineNo] ON [pur].[PurchaseOrderItem] ([OrderId], [LineNo]);
GO
CREATE INDEX [IX_PurchaseOrderItem_SkuId] ON [pur].[PurchaseOrderItem] ([SkuId]);
GO
CREATE INDEX [IX_PurchaseOrderItem_UnitId] ON [pur].[PurchaseOrderItem] ([UnitId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'采购订单明细', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrderItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrderItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrderItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrderItem', N'COLUMN', N'OrderId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrderItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'换算率', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrderItem', N'COLUMN', N'ConvertRate';
EXEC sp_addextendedproperty N'MS_Description', N'订单数量', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrderItem', N'COLUMN', N'Qty';
EXEC sp_addextendedproperty N'MS_Description', N'基本数量', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrderItem', N'COLUMN', N'BaseQty';
EXEC sp_addextendedproperty N'MS_Description', N'含税单价', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrderItem', N'COLUMN', N'Price';
EXEC sp_addextendedproperty N'MS_Description', N'价税合计', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrderItem', N'COLUMN', N'Amount';
EXEC sp_addextendedproperty N'MS_Description', N'已入库数量', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrderItem', N'COLUMN', N'ReceivedQty';
EXEC sp_addextendedproperty N'MS_Description', N'批次要求', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrderItem', N'COLUMN', N'BatchNo';
EXEC sp_addextendedproperty N'MS_Description', N'需求日期', N'SCHEMA', N'pur', N'TABLE', N'PurchaseOrderItem', N'COLUMN', N'NeedDate';
GO
CREATE TABLE [pur].[ArrivalAppointment] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_ArrivalAppointment_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_ArrivalAppointment_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_ArrivalAppointment_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_ArrivalAppointment_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [OrderId] bigint NULL,
    [WarehouseId] bigint NULL,
    [PlanArriveAt] datetime2(3) NULL,
    [VehicleNo] varchar(20) NULL,
    [DriverPhone] varchar(30) NULL,
    [DockNo] varchar(20) NULL,
    CONSTRAINT [PK_ArrivalAppointment] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ArrivalAppointment_TenantId_DocNo] ON [pur].[ArrivalAppointment] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_ArrivalAppointment_PlanArriveAt] ON [pur].[ArrivalAppointment] ([PlanArriveAt]);
GO
CREATE INDEX [IX_ArrivalAppointment_OrgId] ON [pur].[ArrivalAppointment] ([OrgId]);
GO
CREATE INDEX [IX_ArrivalAppointment_CreatedBy] ON [pur].[ArrivalAppointment] ([CreatedBy]);
GO
CREATE INDEX [IX_ArrivalAppointment_ModifiedBy] ON [pur].[ArrivalAppointment] ([ModifiedBy]);
GO
CREATE INDEX [IX_ArrivalAppointment_DeletedBy] ON [pur].[ArrivalAppointment] ([DeletedBy]);
GO
CREATE INDEX [IX_ArrivalAppointment_PartnerId] ON [pur].[ArrivalAppointment] ([PartnerId]);
GO
CREATE INDEX [IX_ArrivalAppointment_OrderId] ON [pur].[ArrivalAppointment] ([OrderId]);
GO
CREATE INDEX [IX_ArrivalAppointment_WarehouseId] ON [pur].[ArrivalAppointment] ([WarehouseId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'到货预约', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'供应商', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'采购订单', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'OrderId';
EXEC sp_addextendedproperty N'MS_Description', N'仓库', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'预约到货时间', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'PlanArriveAt';
EXEC sp_addextendedproperty N'MS_Description', N'车号', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'VehicleNo';
EXEC sp_addextendedproperty N'MS_Description', N'司机电话', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'DriverPhone';
EXEC sp_addextendedproperty N'MS_Description', N'月台', N'SCHEMA', N'pur', N'TABLE', N'ArrivalAppointment', N'COLUMN', N'DockNo';
GO
CREATE TABLE [pur].[Receipt] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Receipt_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_Receipt_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Receipt_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Receipt_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [OrderId] bigint NULL,
    [WarehouseId] bigint NOT NULL,
    [ReceiptType] tinyint NOT NULL CONSTRAINT [DF_Receipt_ReceiptType] DEFAULT (1),
    [NetAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_Receipt_NetAmount] DEFAULT (0),
    [TaxAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_Receipt_TaxAmount] DEFAULT (0),
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_Receipt_TotalAmount] DEFAULT (0),
    [FeeAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_Receipt_FeeAmount] DEFAULT (0),
    [IsInvoiced] bit NOT NULL CONSTRAINT [DF_Receipt_IsInvoiced] DEFAULT (0),
    [IsSettled] bit NOT NULL CONSTRAINT [DF_Receipt_IsSettled] DEFAULT (0),
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    [StockedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Receipt] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Receipt_TenantId_DocNo] ON [pur].[Receipt] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Receipt_PartnerId_Status] ON [pur].[Receipt] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_Receipt_Status_BizDate] ON [pur].[Receipt] ([Status], [BizDate]);
GO
CREATE INDEX [IX_Receipt_OrgId] ON [pur].[Receipt] ([OrgId]);
GO
CREATE INDEX [IX_Receipt_CreatedBy] ON [pur].[Receipt] ([CreatedBy]);
GO
CREATE INDEX [IX_Receipt_ModifiedBy] ON [pur].[Receipt] ([ModifiedBy]);
GO
CREATE INDEX [IX_Receipt_DeletedBy] ON [pur].[Receipt] ([DeletedBy]);
GO
CREATE INDEX [IX_Receipt_OrderId] ON [pur].[Receipt] ([OrderId]);
GO
CREATE INDEX [IX_Receipt_WarehouseId] ON [pur].[Receipt] ([WarehouseId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'采购入库单', N'SCHEMA', N'pur', N'TABLE', N'Receipt';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'供应商', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'采购订单', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'OrderId';
EXEC sp_addextendedproperty N'MS_Description', N'仓库', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1正常入库 2越库直发 3赠品 4其他)', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'ReceiptType';
EXEC sp_addextendedproperty N'MS_Description', N'采购费用合计', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'FeeAmount';
EXEC sp_addextendedproperty N'MS_Description', N'已开票', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'IsInvoiced';
EXEC sp_addextendedproperty N'MS_Description', N'已结算', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'IsSettled';
EXEC sp_addextendedproperty N'MS_Description', N'审核人', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'ApprovedBy';
EXEC sp_addextendedproperty N'MS_Description', N'过账时间', N'SCHEMA', N'pur', N'TABLE', N'Receipt', N'COLUMN', N'StockedAt';
GO
CREATE TABLE [pur].[ReceiptItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [ReceiptId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [OrderItemId] bigint NULL,
    [SkuId] bigint NOT NULL,
    [UnitId] bigint NOT NULL,
    [Qty] decimal(19,6) NOT NULL,
    [OrderQty] decimal(19,6) NULL,
    [DiffQty] decimal(19,6) NULL,
    [Price] decimal(19,6) NOT NULL,
    [TaxRate] decimal(9,4) NOT NULL CONSTRAINT [DF_ReceiptItem_TaxRate] DEFAULT (13),
    [NetAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_ReceiptItem_NetAmount] DEFAULT (0),
    [TaxAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_ReceiptItem_TaxAmount] DEFAULT (0),
    [Amount] decimal(19,4) NOT NULL CONSTRAINT [DF_ReceiptItem_Amount] DEFAULT (0),
    [BatchNo] varchar(50) NULL,
    [ProduceDate] date NULL,
    [ExpireDate] date NULL,
    [QualityStatus] tinyint NOT NULL CONSTRAINT [DF_ReceiptItem_QualityStatus] DEFAULT (1),
    [WarehouseLocationId] bigint NULL,
    CONSTRAINT [PK_ReceiptItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ReceiptItem_ReceiptId_LineNo] ON [pur].[ReceiptItem] ([ReceiptId], [LineNo]);
GO
CREATE INDEX [IX_ReceiptItem_SkuId] ON [pur].[ReceiptItem] ([SkuId]);
GO
CREATE INDEX [IX_ReceiptItem_BatchNo] ON [pur].[ReceiptItem] ([BatchNo]);
GO
CREATE INDEX [IX_ReceiptItem_OrderItemId] ON [pur].[ReceiptItem] ([OrderItemId]);
GO
CREATE INDEX [IX_ReceiptItem_UnitId] ON [pur].[ReceiptItem] ([UnitId]);
GO
CREATE INDEX [IX_ReceiptItem_WarehouseLocationId] ON [pur].[ReceiptItem] ([WarehouseLocationId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'采购入库明细', N'SCHEMA', N'pur', N'TABLE', N'ReceiptItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'ReceiptItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'pur', N'TABLE', N'ReceiptItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'pur', N'TABLE', N'ReceiptItem', N'COLUMN', N'ReceiptId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'pur', N'TABLE', N'ReceiptItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'订单行', N'SCHEMA', N'pur', N'TABLE', N'ReceiptItem', N'COLUMN', N'OrderItemId';
EXEC sp_addextendedproperty N'MS_Description', N'实收数量', N'SCHEMA', N'pur', N'TABLE', N'ReceiptItem', N'COLUMN', N'Qty';
EXEC sp_addextendedproperty N'MS_Description', N'订单数量', N'SCHEMA', N'pur', N'TABLE', N'ReceiptItem', N'COLUMN', N'OrderQty';
EXEC sp_addextendedproperty N'MS_Description', N'差异数量', N'SCHEMA', N'pur', N'TABLE', N'ReceiptItem', N'COLUMN', N'DiffQty';
EXEC sp_addextendedproperty N'MS_Description', N'批号', N'SCHEMA', N'pur', N'TABLE', N'ReceiptItem', N'COLUMN', N'BatchNo';
EXEC sp_addextendedproperty N'MS_Description', N'生产日期', N'SCHEMA', N'pur', N'TABLE', N'ReceiptItem', N'COLUMN', N'ProduceDate';
EXEC sp_addextendedproperty N'MS_Description', N'到期日', N'SCHEMA', N'pur', N'TABLE', N'ReceiptItem', N'COLUMN', N'ExpireDate';
EXEC sp_addextendedproperty N'MS_Description', N'质检(1合格 2让步接收 3不合格退货 4待检)', N'SCHEMA', N'pur', N'TABLE', N'ReceiptItem', N'COLUMN', N'QualityStatus';
EXEC sp_addextendedproperty N'MS_Description', N'上架货位', N'SCHEMA', N'pur', N'TABLE', N'ReceiptItem', N'COLUMN', N'WarehouseLocationId';
GO
CREATE TABLE [pur].[PurchaseReturn] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_PurchaseReturn_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_PurchaseReturn_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_PurchaseReturn_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_PurchaseReturn_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [ReceiptId] bigint NULL,
    [WarehouseId] bigint NOT NULL,
    [ReturnReason] tinyint NOT NULL CONSTRAINT [DF_PurchaseReturn_ReturnReason] DEFAULT (1),
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PurchaseReturn_TotalAmount] DEFAULT (0),
    [ClaimAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PurchaseReturn_ClaimAmount] DEFAULT (0),
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    CONSTRAINT [PK_PurchaseReturn] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PurchaseReturn_TenantId_DocNo] ON [pur].[PurchaseReturn] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_PurchaseReturn_PartnerId_Status] ON [pur].[PurchaseReturn] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_PurchaseReturn_OrgId] ON [pur].[PurchaseReturn] ([OrgId]);
GO
CREATE INDEX [IX_PurchaseReturn_CreatedBy] ON [pur].[PurchaseReturn] ([CreatedBy]);
GO
CREATE INDEX [IX_PurchaseReturn_ModifiedBy] ON [pur].[PurchaseReturn] ([ModifiedBy]);
GO
CREATE INDEX [IX_PurchaseReturn_DeletedBy] ON [pur].[PurchaseReturn] ([DeletedBy]);
GO
CREATE INDEX [IX_PurchaseReturn_ReceiptId] ON [pur].[PurchaseReturn] ([ReceiptId]);
GO
CREATE INDEX [IX_PurchaseReturn_WarehouseId] ON [pur].[PurchaseReturn] ([WarehouseId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'采购退货单', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'供应商', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'原入库单', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'ReceiptId';
EXEC sp_addextendedproperty N'MS_Description', N'原因(1质量 2临期 3多订 4错发 5其他)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'ReturnReason';
EXEC sp_addextendedproperty N'MS_Description', N'索赔金额', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturn', N'COLUMN', N'ClaimAmount';
GO
CREATE TABLE [pur].[PurchaseReturnItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [ReturnId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [UnitId] bigint NOT NULL,
    [Qty] decimal(19,6) NOT NULL,
    [Price] decimal(19,6) NOT NULL,
    [Amount] decimal(19,4) NOT NULL CONSTRAINT [DF_PurchaseReturnItem_Amount] DEFAULT (0),
    [BatchNo] varchar(50) NULL,
    CONSTRAINT [PK_PurchaseReturnItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PurchaseReturnItem_ReturnId_LineNo] ON [pur].[PurchaseReturnItem] ([ReturnId], [LineNo]);
GO
CREATE INDEX [IX_PurchaseReturnItem_SkuId] ON [pur].[PurchaseReturnItem] ([SkuId]);
GO
CREATE INDEX [IX_PurchaseReturnItem_UnitId] ON [pur].[PurchaseReturnItem] ([UnitId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'采购退货明细', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturnItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturnItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturnItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturnItem', N'COLUMN', N'ReturnId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'pur', N'TABLE', N'PurchaseReturnItem', N'COLUMN', N'LineNo';
GO
CREATE TABLE [pur].[PurchaseExpense] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_PurchaseExpense_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_PurchaseExpense_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_PurchaseExpense_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_PurchaseExpense_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NULL,
    [ExpenseType] tinyint NOT NULL CONSTRAINT [DF_PurchaseExpense_ExpenseType] DEFAULT (1) CONSTRAINT [CK_PurchaseExpense_ExpenseType] CHECK (ExpenseType BETWEEN 1 AND 5),
    [ReceiptId] bigint NULL,
    [Amount] decimal(19,4) NOT NULL CONSTRAINT [DF_PurchaseExpense_Amount] DEFAULT (0),
    [TaxRate] decimal(9,4) NOT NULL CONSTRAINT [DF_PurchaseExpense_TaxRate] DEFAULT (9),
    [AllocMethod] tinyint NOT NULL CONSTRAINT [DF_PurchaseExpense_AllocMethod] DEFAULT (1) CONSTRAINT [CK_PurchaseExpense_AllocMethod] CHECK (AllocMethod BETWEEN 1 AND 4),
    [IsAllocated] bit NOT NULL CONSTRAINT [DF_PurchaseExpense_IsAllocated] DEFAULT (0),
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    CONSTRAINT [PK_PurchaseExpense] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PurchaseExpense_TenantId_DocNo] ON [pur].[PurchaseExpense] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_PurchaseExpense_OrgId] ON [pur].[PurchaseExpense] ([OrgId]);
GO
CREATE INDEX [IX_PurchaseExpense_CreatedBy] ON [pur].[PurchaseExpense] ([CreatedBy]);
GO
CREATE INDEX [IX_PurchaseExpense_ModifiedBy] ON [pur].[PurchaseExpense] ([ModifiedBy]);
GO
CREATE INDEX [IX_PurchaseExpense_DeletedBy] ON [pur].[PurchaseExpense] ([DeletedBy]);
GO
CREATE INDEX [IX_PurchaseExpense_PartnerId] ON [pur].[PurchaseExpense] ([PartnerId]);
GO
CREATE INDEX [IX_PurchaseExpense_ReceiptId] ON [pur].[PurchaseExpense] ([ReceiptId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'采购费用单', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'供应商(空=第三方)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1运费 2装卸 3关税 4保险 5杂费)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'ExpenseType';
EXEC sp_addextendedproperty N'MS_Description', N'关联入库单', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'ReceiptId';
EXEC sp_addextendedproperty N'MS_Description', N'费用金额', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'Amount';
EXEC sp_addextendedproperty N'MS_Description', N'分摊方式(1按金额 2按数量 3按重量 4不分摊)', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'AllocMethod';
EXEC sp_addextendedproperty N'MS_Description', N'已分摊', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpense', N'COLUMN', N'IsAllocated';
GO
CREATE TABLE [pur].[PurchaseExpenseAllocation] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [ExpenseId] bigint NOT NULL,
    [ReceiptItemId] bigint NULL,
    [SkuId] bigint NULL,
    [BaseAmount] decimal(19,4) NULL,
    [AllocRate] decimal(9,4) NULL,
    [AllocAmount] decimal(19,4) NOT NULL,
    [CostImpact] decimal(19,6) NULL,
    CONSTRAINT [PK_PurchaseExpenseAllocation] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_PurchaseExpenseAllocation_ExpenseId] ON [pur].[PurchaseExpenseAllocation] ([ExpenseId]);
GO
CREATE INDEX [IX_PurchaseExpenseAllocation_ReceiptItemId] ON [pur].[PurchaseExpenseAllocation] ([ReceiptItemId]);
GO
CREATE INDEX [IX_PurchaseExpenseAllocation_SkuId] ON [pur].[PurchaseExpenseAllocation] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'采购费用分摊明细', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpenseAllocation';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpenseAllocation', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'入库行', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpenseAllocation', N'COLUMN', N'ReceiptItemId';
EXEC sp_addextendedproperty N'MS_Description', N'商品', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpenseAllocation', N'COLUMN', N'SkuId';
EXEC sp_addextendedproperty N'MS_Description', N'分摊基数', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpenseAllocation', N'COLUMN', N'BaseAmount';
EXEC sp_addextendedproperty N'MS_Description', N'分摊比例', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpenseAllocation', N'COLUMN', N'AllocRate';
EXEC sp_addextendedproperty N'MS_Description', N'分摊金额', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpenseAllocation', N'COLUMN', N'AllocAmount';
EXEC sp_addextendedproperty N'MS_Description', N'单位成本影响', N'SCHEMA', N'pur', N'TABLE', N'PurchaseExpenseAllocation', N'COLUMN', N'CostImpact';
GO
CREATE TABLE [pur].[SupplierStatement] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_SupplierStatement_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_SupplierStatement_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_SupplierStatement_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_SupplierStatement_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [PeriodFrom] date NOT NULL,
    [PeriodTo] date NOT NULL,
    [ReceiptAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SupplierStatement_ReceiptAmount] DEFAULT (0),
    [ReturnAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SupplierStatement_ReturnAmount] DEFAULT (0),
    [ExpenseAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SupplierStatement_ExpenseAmount] DEFAULT (0),
    [PaidAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SupplierStatement_PaidAmount] DEFAULT (0),
    [BalanceAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SupplierStatement_BalanceAmount] DEFAULT (0),
    [ConfirmStatus] tinyint NOT NULL CONSTRAINT [DF_SupplierStatement_ConfirmStatus] DEFAULT (0),
    [ConfirmedAt] datetime2(3) NULL,
    [ConfirmedBy] nvarchar(50) NULL,
    CONSTRAINT [PK_SupplierStatement] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_SupplierStatement_TenantId_DocNo] ON [pur].[SupplierStatement] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_SupplierStatement_PartnerId_ConfirmStatus] ON [pur].[SupplierStatement] ([PartnerId], [ConfirmStatus]);
GO
CREATE INDEX [IX_SupplierStatement_OrgId] ON [pur].[SupplierStatement] ([OrgId]);
GO
CREATE INDEX [IX_SupplierStatement_CreatedBy] ON [pur].[SupplierStatement] ([CreatedBy]);
GO
CREATE INDEX [IX_SupplierStatement_ModifiedBy] ON [pur].[SupplierStatement] ([ModifiedBy]);
GO
CREATE INDEX [IX_SupplierStatement_DeletedBy] ON [pur].[SupplierStatement] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'供应商对账单', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'供应商', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'期间起', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'PeriodFrom';
EXEC sp_addextendedproperty N'MS_Description', N'期间止', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'PeriodTo';
EXEC sp_addextendedproperty N'MS_Description', N'入库金额', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'ReceiptAmount';
EXEC sp_addextendedproperty N'MS_Description', N'退货金额', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'ReturnAmount';
EXEC sp_addextendedproperty N'MS_Description', N'费用金额', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'ExpenseAmount';
EXEC sp_addextendedproperty N'MS_Description', N'已付金额', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'PaidAmount';
EXEC sp_addextendedproperty N'MS_Description', N'应付余额', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'BalanceAmount';
EXEC sp_addextendedproperty N'MS_Description', N'0待确认 1已确认 2有异议', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'ConfirmStatus';
EXEC sp_addextendedproperty N'MS_Description', N'确认人', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatement', N'COLUMN', N'ConfirmedBy';
GO
CREATE TABLE [pur].[SupplierStatementItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [StatementId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [SourceNo] varchar(40) NULL,
    [BizDate] date NULL,
    [Amount] decimal(19,4) NOT NULL,
    [Direction] tinyint NOT NULL CONSTRAINT [DF_SupplierStatementItem_Direction] DEFAULT (1),
    [IsConfirmed] bit NOT NULL CONSTRAINT [DF_SupplierStatementItem_IsConfirmed] DEFAULT (0),
    CONSTRAINT [PK_SupplierStatementItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_SupplierStatementItem_StatementId] ON [pur].[SupplierStatementItem] ([StatementId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'对账单明细', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatementItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatementItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatementItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatementItem', N'COLUMN', N'StatementId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatementItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'来源类型(入库/退货/费用/付款/期初)', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatementItem', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源Id', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatementItem', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'来源单号', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatementItem', N'COLUMN', N'SourceNo';
EXEC sp_addextendedproperty N'MS_Description', N'日期', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatementItem', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'金额', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatementItem', N'COLUMN', N'Amount';
EXEC sp_addextendedproperty N'MS_Description', N'方向(1增加应付 2减少应付)', N'SCHEMA', N'pur', N'TABLE', N'SupplierStatementItem', N'COLUMN', N'Direction';
GO
CREATE TABLE [pur].[SupplierQualificationAudit] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_SupplierQualificationAudit_TenantId] DEFAULT (1),
    [PartnerId] bigint NOT NULL,
    [ApplyType] tinyint NOT NULL CONSTRAINT [DF_SupplierQualificationAudit_ApplyType] DEFAULT (1),
    [Score] decimal(9,4) NULL,
    [EvalJson] nvarchar(max) NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_SupplierQualificationAudit_Status] DEFAULT (0),
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    [ValidUntil] date NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_SupplierQualificationAudit_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_SupplierQualificationAudit_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_SupplierQualificationAudit] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_SupplierQualificationAudit_PartnerId_Status] ON [pur].[SupplierQualificationAudit] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_SupplierQualificationAudit_CreatedBy] ON [pur].[SupplierQualificationAudit] ([CreatedBy]);
GO
CREATE INDEX [IX_SupplierQualificationAudit_ModifiedBy] ON [pur].[SupplierQualificationAudit] ([ModifiedBy]);
GO
CREATE INDEX [IX_SupplierQualificationAudit_DeletedBy] ON [pur].[SupplierQualificationAudit] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'供应商准入审核', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'供应商', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1新准入 2扩品类 3重新评估)', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'ApplyType';
EXEC sp_addextendedproperty N'MS_Description', N'评估得分', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'Score';
EXEC sp_addextendedproperty N'MS_Description', N'评估项得分明细', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'EvalJson';
EXEC sp_addextendedproperty N'MS_Description', N'0待审 1通过 2驳回', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'资格有效期', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'ValidUntil';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'SupplierQualificationAudit', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [pur].[SupplierPerformance] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_SupplierPerformance_TenantId] DEFAULT (1),
    [PartnerId] bigint NOT NULL,
    [Period] varchar(10) NOT NULL,
    [QualityScore] decimal(9,4) NULL,
    [DeliveryScore] decimal(9,4) NULL,
    [PriceScore] decimal(9,4) NULL,
    [ServiceScore] decimal(9,4) NULL,
    [TotalScore] decimal(9,4) NULL,
    [Grade] char(1) NULL,
    [OnTimeRate] decimal(9,4) NULL,
    [QualifiedRate] decimal(9,4) NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_SupplierPerformance_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_SupplierPerformance_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_SupplierPerformance] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_SupplierPerformance_TenantId_PartnerId_Period] ON [pur].[SupplierPerformance] ([TenantId], [PartnerId], [Period]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_SupplierPerformance_PartnerId] ON [pur].[SupplierPerformance] ([PartnerId]);
GO
CREATE INDEX [IX_SupplierPerformance_CreatedBy] ON [pur].[SupplierPerformance] ([CreatedBy]);
GO
CREATE INDEX [IX_SupplierPerformance_ModifiedBy] ON [pur].[SupplierPerformance] ([ModifiedBy]);
GO
CREATE INDEX [IX_SupplierPerformance_DeletedBy] ON [pur].[SupplierPerformance] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'供应商绩效评分', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'期间(2026-01)', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'Period';
EXEC sp_addextendedproperty N'MS_Description', N'质量分', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'QualityScore';
EXEC sp_addextendedproperty N'MS_Description', N'交期分', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'DeliveryScore';
EXEC sp_addextendedproperty N'MS_Description', N'价格分', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'PriceScore';
EXEC sp_addextendedproperty N'MS_Description', N'服务分', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'ServiceScore';
EXEC sp_addextendedproperty N'MS_Description', N'总分', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'TotalScore';
EXEC sp_addextendedproperty N'MS_Description', N'等级(A/B/C/D)', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'Grade';
EXEC sp_addextendedproperty N'MS_Description', N'准时交货率', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'OnTimeRate';
EXEC sp_addextendedproperty N'MS_Description', N'合格率', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'QualifiedRate';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'SupplierPerformance', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [pur].[SupplierAsn] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_SupplierAsn_TenantId] DEFAULT (1),
    [AsnNo] varchar(40) NOT NULL,
    [PartnerId] bigint NOT NULL,
    [OrderId] bigint NULL,
    [WarehouseId] bigint NULL,
    [ExpectedArriveAt] datetime2(3) NULL,
    [CartonCount] int NULL,
    [PalletCount] int NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_SupplierAsn_Status] DEFAULT (0),
    [ReceiptId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_SupplierAsn_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_SupplierAsn_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_SupplierAsn] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_SupplierAsn_TenantId_AsnNo] ON [pur].[SupplierAsn] ([TenantId], [AsnNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_SupplierAsn_PartnerId_Status] ON [pur].[SupplierAsn] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_SupplierAsn_OrderId] ON [pur].[SupplierAsn] ([OrderId]);
GO
CREATE INDEX [IX_SupplierAsn_WarehouseId] ON [pur].[SupplierAsn] ([WarehouseId]);
GO
CREATE INDEX [IX_SupplierAsn_ReceiptId] ON [pur].[SupplierAsn] ([ReceiptId]);
GO
CREATE INDEX [IX_SupplierAsn_OrgId] ON [pur].[SupplierAsn] ([OrgId]);
GO
CREATE INDEX [IX_SupplierAsn_CreatedBy] ON [pur].[SupplierAsn] ([CreatedBy]);
GO
CREATE INDEX [IX_SupplierAsn_ModifiedBy] ON [pur].[SupplierAsn] ([ModifiedBy]);
GO
CREATE INDEX [IX_SupplierAsn_DeletedBy] ON [pur].[SupplierAsn] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'供应商送货通知(ASN)', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'ASN号', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'AsnNo';
EXEC sp_addextendedproperty N'MS_Description', N'供应商', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'采购订单', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'OrderId';
EXEC sp_addextendedproperty N'MS_Description', N'收货仓', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'预计到达', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'ExpectedArriveAt';
EXEC sp_addextendedproperty N'MS_Description', N'箱数', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'CartonCount';
EXEC sp_addextendedproperty N'MS_Description', N'托盘数', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'PalletCount';
EXEC sp_addextendedproperty N'MS_Description', N'0待收货 1部分收货 2已收货 3取消', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'转入库单', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'ReceiptId';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsn', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [pur].[SupplierAsnItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [AsnId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [OrderItemId] bigint NULL,
    [SkuId] bigint NOT NULL,
    [Qty] decimal(19,6) NOT NULL,
    [ReceivedQty] decimal(19,6) NOT NULL CONSTRAINT [DF_SupplierAsnItem_ReceivedQty] DEFAULT (0),
    [BatchNo] varchar(50) NULL,
    [ExpireDate] date NULL,
    CONSTRAINT [PK_SupplierAsnItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_SupplierAsnItem_AsnId] ON [pur].[SupplierAsnItem] ([AsnId]);
GO
CREATE INDEX [IX_SupplierAsnItem_OrderItemId] ON [pur].[SupplierAsnItem] ([OrderItemId]);
GO
CREATE INDEX [IX_SupplierAsnItem_SkuId] ON [pur].[SupplierAsnItem] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'ASN 明细', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsnItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsnItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsnItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsnItem', N'COLUMN', N'AsnId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsnItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'订单行', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsnItem', N'COLUMN', N'OrderItemId';
EXEC sp_addextendedproperty N'MS_Description', N'发货数量', N'SCHEMA', N'pur', N'TABLE', N'SupplierAsnItem', N'COLUMN', N'Qty';
GO
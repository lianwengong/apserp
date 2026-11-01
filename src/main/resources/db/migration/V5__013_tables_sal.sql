/* =====================================================================
   进销存管理系统 V3 · 表结构 · sal 架构（21 张表）
   数据库：APSErpV3   生成器：db/emit.py（请勿手改，改规格文件后重新生成）
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE TABLE [sal].[Quotation] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Quotation_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_Quotation_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Quotation_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Quotation_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [SalesmanId] bigint NULL,
    [ValidTo] date NULL,
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_Quotation_TotalAmount] DEFAULT (0),
    [PriceSource] varchar(30) NULL,
    [ConvertedOrderId] bigint NULL,
    CONSTRAINT [PK_Quotation] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Quotation_TenantId_DocNo] ON [sal].[Quotation] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Quotation_PartnerId_Status] ON [sal].[Quotation] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_Quotation_OrgId] ON [sal].[Quotation] ([OrgId]);
GO
CREATE INDEX [IX_Quotation_CreatedBy] ON [sal].[Quotation] ([CreatedBy]);
GO
CREATE INDEX [IX_Quotation_ModifiedBy] ON [sal].[Quotation] ([ModifiedBy]);
GO
CREATE INDEX [IX_Quotation_DeletedBy] ON [sal].[Quotation] ([DeletedBy]);
GO
CREATE INDEX [IX_Quotation_SalesmanId] ON [sal].[Quotation] ([SalesmanId]);
GO
CREATE INDEX [IX_Quotation_ConvertedOrderId] ON [sal].[Quotation] ([ConvertedOrderId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'销售报价单', N'SCHEMA', N'sal', N'TABLE', N'Quotation';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'客户', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'业务员', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'SalesmanId';
EXEC sp_addextendedproperty N'MS_Description', N'有效期至', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'ValidTo';
EXEC sp_addextendedproperty N'MS_Description', N'取价来源', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'PriceSource';
EXEC sp_addextendedproperty N'MS_Description', N'已转订单', N'SCHEMA', N'sal', N'TABLE', N'Quotation', N'COLUMN', N'ConvertedOrderId';
GO
CREATE TABLE [sal].[QuotationItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [QuotationId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [UnitId] bigint NOT NULL,
    [Qty] decimal(19,6) NOT NULL,
    [Price] decimal(19,6) NOT NULL,
    [TaxRate] decimal(9,4) NOT NULL CONSTRAINT [DF_QuotationItem_TaxRate] DEFAULT (13),
    [Amount] decimal(19,4) NOT NULL CONSTRAINT [DF_QuotationItem_Amount] DEFAULT (0),
    [MinQty] decimal(19,6) NULL,
    CONSTRAINT [PK_QuotationItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_QuotationItem_QuotationId_LineNo] ON [sal].[QuotationItem] ([QuotationId], [LineNo]);
GO
CREATE INDEX [IX_QuotationItem_SkuId] ON [sal].[QuotationItem] ([SkuId]);
GO
CREATE INDEX [IX_QuotationItem_UnitId] ON [sal].[QuotationItem] ([UnitId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'报价明细', N'SCHEMA', N'sal', N'TABLE', N'QuotationItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'QuotationItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'sal', N'TABLE', N'QuotationItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'sal', N'TABLE', N'QuotationItem', N'COLUMN', N'QuotationId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'sal', N'TABLE', N'QuotationItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'报价单价', N'SCHEMA', N'sal', N'TABLE', N'QuotationItem', N'COLUMN', N'Price';
EXEC sp_addextendedproperty N'MS_Description', N'阶梯起订', N'SCHEMA', N'sal', N'TABLE', N'QuotationItem', N'COLUMN', N'MinQty';
GO
CREATE TABLE [sal].[SalesContract] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_SalesContract_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_SalesContract_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_SalesContract_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_SalesContract_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [ContractType] tinyint NOT NULL CONSTRAINT [DF_SalesContract_ContractType] DEFAULT (1),
    [StartDate] date NULL,
    [EndDate] date NULL,
    [TotalAmount] decimal(19,4) NULL,
    [PaymentTerm] nvarchar(200) NULL,
    [RebateTerms] nvarchar(500) NULL,
    [ExecutedAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesContract_ExecutedAmount] DEFAULT (0),
    [ReceivedAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesContract_ReceivedAmount] DEFAULT (0),
    CONSTRAINT [PK_SalesContract] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_SalesContract_TenantId_DocNo] ON [sal].[SalesContract] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_SalesContract_PartnerId_Status] ON [sal].[SalesContract] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_SalesContract_OrgId] ON [sal].[SalesContract] ([OrgId]);
GO
CREATE INDEX [IX_SalesContract_CreatedBy] ON [sal].[SalesContract] ([CreatedBy]);
GO
CREATE INDEX [IX_SalesContract_ModifiedBy] ON [sal].[SalesContract] ([ModifiedBy]);
GO
CREATE INDEX [IX_SalesContract_DeletedBy] ON [sal].[SalesContract] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'销售合同', N'SCHEMA', N'sal', N'TABLE', N'SalesContract';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'客户', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1单次 2年度 3项目)', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'ContractType';
EXEC sp_addextendedproperty N'MS_Description', N'合同金额', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'TotalAmount';
EXEC sp_addextendedproperty N'MS_Description', N'账期与条款', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'PaymentTerm';
EXEC sp_addextendedproperty N'MS_Description', N'返利条款', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'RebateTerms';
EXEC sp_addextendedproperty N'MS_Description', N'已执行金额', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'ExecutedAmount';
EXEC sp_addextendedproperty N'MS_Description', N'已回款', N'SCHEMA', N'sal', N'TABLE', N'SalesContract', N'COLUMN', N'ReceivedAmount';
GO
CREATE TABLE [sal].[SalesContractItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [ContractId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [Qty] decimal(19,6) NULL,
    [Price] decimal(19,6) NULL,
    [ExecutedQty] decimal(19,6) NOT NULL CONSTRAINT [DF_SalesContractItem_ExecutedQty] DEFAULT (0),
    CONSTRAINT [PK_SalesContractItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_SalesContractItem_ContractId] ON [sal].[SalesContractItem] ([ContractId]);
GO
CREATE INDEX [IX_SalesContractItem_SkuId] ON [sal].[SalesContractItem] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'销售合同明细', N'SCHEMA', N'sal', N'TABLE', N'SalesContractItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'SalesContractItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'sal', N'TABLE', N'SalesContractItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'sal', N'TABLE', N'SalesContractItem', N'COLUMN', N'ContractId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'sal', N'TABLE', N'SalesContractItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'合同数量', N'SCHEMA', N'sal', N'TABLE', N'SalesContractItem', N'COLUMN', N'Qty';
EXEC sp_addextendedproperty N'MS_Description', N'合同价', N'SCHEMA', N'sal', N'TABLE', N'SalesContractItem', N'COLUMN', N'Price';
GO
CREATE TABLE [sal].[SalesOrder] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_SalesOrder_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_SalesOrder_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_SalesOrder_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_SalesOrder_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [SalesmanId] bigint NULL,
    [OrderType] tinyint NOT NULL CONSTRAINT [DF_SalesOrder_OrderType] DEFAULT (1) CONSTRAINT [CK_SalesOrder_OrderType] CHECK (OrderType BETWEEN 1 AND 5),
    [ContractId] bigint NULL,
    [WarehouseId] bigint NULL,
    [DeliveryDate] date NULL,
    [AddressId] bigint NULL,
    [PriceTypeId] bigint NULL,
    [NetAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesOrder_NetAmount] DEFAULT (0),
    [TaxAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesOrder_TaxAmount] DEFAULT (0),
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesOrder_TotalAmount] DEFAULT (0),
    [DiscountAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesOrder_DiscountAmount] DEFAULT (0),
    [FreightAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesOrder_FreightAmount] DEFAULT (0),
    [PaidAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesOrder_PaidAmount] DEFAULT (0),
    [ShippedAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesOrder_ShippedAmount] DEFAULT (0),
    [CreditUsed] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesOrder_CreditUsed] DEFAULT (0),
    [SettleType] tinyint NOT NULL CONSTRAINT [DF_SalesOrder_SettleType] DEFAULT (1) CONSTRAINT [CK_SalesOrder_SettleType] CHECK (SettleType BETWEEN 1 AND 4),
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    CONSTRAINT [PK_SalesOrder] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_SalesOrder_TenantId_DocNo] ON [sal].[SalesOrder] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_SalesOrder_PartnerId_Status] ON [sal].[SalesOrder] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_SalesOrder_Status_BizDate] ON [sal].[SalesOrder] ([Status], [BizDate]);
GO
CREATE INDEX [IX_SalesOrder_SalesmanId_BizDate] ON [sal].[SalesOrder] ([SalesmanId], [BizDate]);
GO
CREATE INDEX [IX_SalesOrder_OrgId] ON [sal].[SalesOrder] ([OrgId]);
GO
CREATE INDEX [IX_SalesOrder_CreatedBy] ON [sal].[SalesOrder] ([CreatedBy]);
GO
CREATE INDEX [IX_SalesOrder_ModifiedBy] ON [sal].[SalesOrder] ([ModifiedBy]);
GO
CREATE INDEX [IX_SalesOrder_DeletedBy] ON [sal].[SalesOrder] ([DeletedBy]);
GO
CREATE INDEX [IX_SalesOrder_ContractId] ON [sal].[SalesOrder] ([ContractId]);
GO
CREATE INDEX [IX_SalesOrder_WarehouseId] ON [sal].[SalesOrder] ([WarehouseId]);
GO
CREATE INDEX [IX_SalesOrder_AddressId] ON [sal].[SalesOrder] ([AddressId]);
GO
CREATE INDEX [IX_SalesOrder_PriceTypeId] ON [sal].[SalesOrder] ([PriceTypeId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'销售订单', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'客户', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'业务员', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'SalesmanId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1普通批发 2团购 3项目 4补货 5代客下单)', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'OrderType';
EXEC sp_addextendedproperty N'MS_Description', N'合同', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'ContractId';
EXEC sp_addextendedproperty N'MS_Description', N'发货仓', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'要求到货日', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'DeliveryDate';
EXEC sp_addextendedproperty N'MS_Description', N'收货地址', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'AddressId';
EXEC sp_addextendedproperty N'MS_Description', N'应用价格类型', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'PriceTypeId';
EXEC sp_addextendedproperty N'MS_Description', N'运费', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'FreightAmount';
EXEC sp_addextendedproperty N'MS_Description', N'已收金额', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'PaidAmount';
EXEC sp_addextendedproperty N'MS_Description', N'已发金额', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'ShippedAmount';
EXEC sp_addextendedproperty N'MS_Description', N'本次占用信用', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'CreditUsed';
EXEC sp_addextendedproperty N'MS_Description', N'结算(1现结 2账期 3预存 4货到付款)', N'SCHEMA', N'sal', N'TABLE', N'SalesOrder', N'COLUMN', N'SettleType';
GO
CREATE TABLE [sal].[SalesOrderItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [OrderId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [UnitId] bigint NOT NULL,
    [ConvertRate] decimal(19,6) NOT NULL CONSTRAINT [DF_SalesOrderItem_ConvertRate] DEFAULT (1),
    [Qty] decimal(19,6) NOT NULL,
    [BaseQty] decimal(19,6) NOT NULL,
    [Price] decimal(19,6) NOT NULL,
    [StandardPrice] decimal(19,6) NULL,
    [PriceSource] varchar(30) NULL,
    [Discount] decimal(9,4) NOT NULL CONSTRAINT [DF_SalesOrderItem_Discount] DEFAULT (0),
    [TaxRate] decimal(9,4) NOT NULL CONSTRAINT [DF_SalesOrderItem_TaxRate] DEFAULT (13),
    [NetAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesOrderItem_NetAmount] DEFAULT (0),
    [TaxAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesOrderItem_TaxAmount] DEFAULT (0),
    [Amount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesOrderItem_Amount] DEFAULT (0),
    [IsGift] bit NOT NULL CONSTRAINT [DF_SalesOrderItem_IsGift] DEFAULT (0),
    [PromotionId] bigint NULL,
    [ShippedQty] decimal(19,6) NOT NULL CONSTRAINT [DF_SalesOrderItem_ShippedQty] DEFAULT (0),
    [Remark] nvarchar(200) NULL,
    CONSTRAINT [PK_SalesOrderItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_SalesOrderItem_OrderId_LineNo] ON [sal].[SalesOrderItem] ([OrderId], [LineNo]);
GO
CREATE INDEX [IX_SalesOrderItem_SkuId] ON [sal].[SalesOrderItem] ([SkuId]);
GO
CREATE INDEX [IX_SalesOrderItem_UnitId] ON [sal].[SalesOrderItem] ([UnitId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'销售订单明细', N'SCHEMA', N'sal', N'TABLE', N'SalesOrderItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'SalesOrderItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'sal', N'TABLE', N'SalesOrderItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'sal', N'TABLE', N'SalesOrderItem', N'COLUMN', N'OrderId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'sal', N'TABLE', N'SalesOrderItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'成交单价', N'SCHEMA', N'sal', N'TABLE', N'SalesOrderItem', N'COLUMN', N'Price';
EXEC sp_addextendedproperty N'MS_Description', N'标准价(用于折扣分析)', N'SCHEMA', N'sal', N'TABLE', N'SalesOrderItem', N'COLUMN', N'StandardPrice';
EXEC sp_addextendedproperty N'MS_Description', N'取价来源(协议/等级/促销/手工)', N'SCHEMA', N'sal', N'TABLE', N'SalesOrderItem', N'COLUMN', N'PriceSource';
EXEC sp_addextendedproperty N'MS_Description', N'折扣%', N'SCHEMA', N'sal', N'TABLE', N'SalesOrderItem', N'COLUMN', N'Discount';
EXEC sp_addextendedproperty N'MS_Description', N'赠品行', N'SCHEMA', N'sal', N'TABLE', N'SalesOrderItem', N'COLUMN', N'IsGift';
EXEC sp_addextendedproperty N'MS_Description', N'来源促销', N'SCHEMA', N'sal', N'TABLE', N'SalesOrderItem', N'COLUMN', N'PromotionId';
EXEC sp_addextendedproperty N'MS_Description', N'已出库数量', N'SCHEMA', N'sal', N'TABLE', N'SalesOrderItem', N'COLUMN', N'ShippedQty';
GO
CREATE TABLE [sal].[Shipment] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Shipment_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_Shipment_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Shipment_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Shipment_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [OrderId] bigint NULL,
    [WarehouseId] bigint NOT NULL,
    [ShipType] tinyint NOT NULL CONSTRAINT [DF_Shipment_ShipType] DEFAULT (1),
    [DeliveryMethod] tinyint NOT NULL CONSTRAINT [DF_Shipment_DeliveryMethod] DEFAULT (1),
    [CarrierId] bigint NULL,
    [VehicleId] bigint NULL,
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_Shipment_TotalAmount] DEFAULT (0),
    [CostAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_Shipment_CostAmount] DEFAULT (0),
    [StockedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Shipment] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Shipment_TenantId_DocNo] ON [sal].[Shipment] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Shipment_PartnerId_Status] ON [sal].[Shipment] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_Shipment_OrderId] ON [sal].[Shipment] ([OrderId]);
GO
CREATE INDEX [IX_Shipment_OrgId] ON [sal].[Shipment] ([OrgId]);
GO
CREATE INDEX [IX_Shipment_CreatedBy] ON [sal].[Shipment] ([CreatedBy]);
GO
CREATE INDEX [IX_Shipment_ModifiedBy] ON [sal].[Shipment] ([ModifiedBy]);
GO
CREATE INDEX [IX_Shipment_DeletedBy] ON [sal].[Shipment] ([DeletedBy]);
GO
CREATE INDEX [IX_Shipment_WarehouseId] ON [sal].[Shipment] ([WarehouseId]);
GO
CREATE INDEX [IX_Shipment_CarrierId] ON [sal].[Shipment] ([CarrierId]);
GO
CREATE INDEX [IX_Shipment_VehicleId] ON [sal].[Shipment] ([VehicleId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'销售出库单', N'SCHEMA', N'sal', N'TABLE', N'Shipment';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'客户', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'销售订单', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'OrderId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1仓出 2门店直发 3供应商直发 4越库)', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'ShipType';
EXEC sp_addextendedproperty N'MS_Description', N'配送(1自有车 2承运商 3快递 4客户自提)', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'DeliveryMethod';
EXEC sp_addextendedproperty N'MS_Description', N'承运商', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'CarrierId';
EXEC sp_addextendedproperty N'MS_Description', N'车辆', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'VehicleId';
EXEC sp_addextendedproperty N'MS_Description', N'成本金额', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'CostAmount';
EXEC sp_addextendedproperty N'MS_Description', N'扣减库存时间', N'SCHEMA', N'sal', N'TABLE', N'Shipment', N'COLUMN', N'StockedAt';
GO
CREATE TABLE [sal].[ShipmentItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [ShipmentId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [OrderItemId] bigint NULL,
    [SkuId] bigint NOT NULL,
    [UnitId] bigint NOT NULL,
    [Qty] decimal(19,6) NOT NULL,
    [BaseQty] decimal(19,6) NOT NULL,
    [Price] decimal(19,6) NOT NULL,
    [Amount] decimal(19,4) NOT NULL CONSTRAINT [DF_ShipmentItem_Amount] DEFAULT (0),
    [CostPrice] decimal(19,6) NULL,
    [CostAmount] decimal(19,4) NULL,
    [BatchId] bigint NULL,
    [WarehouseLocationId] bigint NULL,
    CONSTRAINT [PK_ShipmentItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ShipmentItem_ShipmentId_LineNo] ON [sal].[ShipmentItem] ([ShipmentId], [LineNo]);
GO
CREATE INDEX [IX_ShipmentItem_SkuId] ON [sal].[ShipmentItem] ([SkuId]);
GO
CREATE INDEX [IX_ShipmentItem_OrderItemId] ON [sal].[ShipmentItem] ([OrderItemId]);
GO
CREATE INDEX [IX_ShipmentItem_UnitId] ON [sal].[ShipmentItem] ([UnitId]);
GO
CREATE INDEX [IX_ShipmentItem_WarehouseLocationId] ON [sal].[ShipmentItem] ([WarehouseLocationId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'销售出库明细', N'SCHEMA', N'sal', N'TABLE', N'ShipmentItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'ShipmentItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'sal', N'TABLE', N'ShipmentItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'sal', N'TABLE', N'ShipmentItem', N'COLUMN', N'ShipmentId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'sal', N'TABLE', N'ShipmentItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'订单行', N'SCHEMA', N'sal', N'TABLE', N'ShipmentItem', N'COLUMN', N'OrderItemId';
EXEC sp_addextendedproperty N'MS_Description', N'成本单价', N'SCHEMA', N'sal', N'TABLE', N'ShipmentItem', N'COLUMN', N'CostPrice';
EXEC sp_addextendedproperty N'MS_Description', N'成本金额', N'SCHEMA', N'sal', N'TABLE', N'ShipmentItem', N'COLUMN', N'CostAmount';
EXEC sp_addextendedproperty N'MS_Description', N'批次', N'SCHEMA', N'sal', N'TABLE', N'ShipmentItem', N'COLUMN', N'BatchId';
EXEC sp_addextendedproperty N'MS_Description', N'货位', N'SCHEMA', N'sal', N'TABLE', N'ShipmentItem', N'COLUMN', N'WarehouseLocationId';
GO
CREATE TABLE [sal].[SalesReturn] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_SalesReturn_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_SalesReturn_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_SalesReturn_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_SalesReturn_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [ShipmentId] bigint NULL,
    [WarehouseId] bigint NULL,
    [ReturnReason] tinyint NOT NULL CONSTRAINT [DF_SalesReturn_ReturnReason] DEFAULT (1),
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesReturn_TotalAmount] DEFAULT (0),
    [RefundAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesReturn_RefundAmount] DEFAULT (0),
    [QualityStatus] tinyint NOT NULL CONSTRAINT [DF_SalesReturn_QualityStatus] DEFAULT (1),
    CONSTRAINT [PK_SalesReturn] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_SalesReturn_TenantId_DocNo] ON [sal].[SalesReturn] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_SalesReturn_PartnerId_Status] ON [sal].[SalesReturn] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_SalesReturn_OrgId] ON [sal].[SalesReturn] ([OrgId]);
GO
CREATE INDEX [IX_SalesReturn_CreatedBy] ON [sal].[SalesReturn] ([CreatedBy]);
GO
CREATE INDEX [IX_SalesReturn_ModifiedBy] ON [sal].[SalesReturn] ([ModifiedBy]);
GO
CREATE INDEX [IX_SalesReturn_DeletedBy] ON [sal].[SalesReturn] ([DeletedBy]);
GO
CREATE INDEX [IX_SalesReturn_ShipmentId] ON [sal].[SalesReturn] ([ShipmentId]);
GO
CREATE INDEX [IX_SalesReturn_WarehouseId] ON [sal].[SalesReturn] ([WarehouseId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'销售退货单', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'客户', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'原出库单', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'ShipmentId';
EXEC sp_addextendedproperty N'MS_Description', N'退回仓', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'原因(1质量问题 2错发 3滞销 4临期 5客户取消)', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'ReturnReason';
EXEC sp_addextendedproperty N'MS_Description', N'处理(1可二次销售 2残次 3报废)', N'SCHEMA', N'sal', N'TABLE', N'SalesReturn', N'COLUMN', N'QualityStatus';
GO
CREATE TABLE [sal].[SalesReturnItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [ReturnId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [Qty] decimal(19,6) NOT NULL,
    [Price] decimal(19,6) NOT NULL,
    [Amount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesReturnItem_Amount] DEFAULT (0),
    [BatchNo] varchar(50) NULL,
    CONSTRAINT [PK_SalesReturnItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_SalesReturnItem_ReturnId_LineNo] ON [sal].[SalesReturnItem] ([ReturnId], [LineNo]);
GO
CREATE INDEX [IX_SalesReturnItem_SkuId] ON [sal].[SalesReturnItem] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'销售退货明细', N'SCHEMA', N'sal', N'TABLE', N'SalesReturnItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'SalesReturnItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'sal', N'TABLE', N'SalesReturnItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'sal', N'TABLE', N'SalesReturnItem', N'COLUMN', N'ReturnId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'sal', N'TABLE', N'SalesReturnItem', N'COLUMN', N'LineNo';
GO
CREATE TABLE [sal].[SalesExpense] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_SalesExpense_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_SalesExpense_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_SalesExpense_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_SalesExpense_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NULL,
    [OrderId] bigint NULL,
    [ExpenseType] tinyint NOT NULL CONSTRAINT [DF_SalesExpense_ExpenseType] DEFAULT (1),
    [Amount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesExpense_Amount] DEFAULT (0),
    [BearType] tinyint NOT NULL CONSTRAINT [DF_SalesExpense_BearType] DEFAULT (1),
    [SalesmanId] bigint NULL,
    CONSTRAINT [PK_SalesExpense] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_SalesExpense_TenantId_DocNo] ON [sal].[SalesExpense] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_SalesExpense_OrgId] ON [sal].[SalesExpense] ([OrgId]);
GO
CREATE INDEX [IX_SalesExpense_CreatedBy] ON [sal].[SalesExpense] ([CreatedBy]);
GO
CREATE INDEX [IX_SalesExpense_ModifiedBy] ON [sal].[SalesExpense] ([ModifiedBy]);
GO
CREATE INDEX [IX_SalesExpense_DeletedBy] ON [sal].[SalesExpense] ([DeletedBy]);
GO
CREATE INDEX [IX_SalesExpense_PartnerId] ON [sal].[SalesExpense] ([PartnerId]);
GO
CREATE INDEX [IX_SalesExpense_OrderId] ON [sal].[SalesExpense] ([OrderId]);
GO
CREATE INDEX [IX_SalesExpense_SalesmanId] ON [sal].[SalesExpense] ([SalesmanId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'销售费用单', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'客户', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'订单', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'OrderId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1运费 2装卸 3陈列 4促销 5返点 6其他)', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'ExpenseType';
EXEC sp_addextendedproperty N'MS_Description', N'承担方(1我方 2客户 3供应商)', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'BearType';
EXEC sp_addextendedproperty N'MS_Description', N'归属业务员', N'SCHEMA', N'sal', N'TABLE', N'SalesExpense', N'COLUMN', N'SalesmanId';
GO
CREATE TABLE [sal].[CustomerStatement] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_CustomerStatement_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_CustomerStatement_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_CustomerStatement_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_CustomerStatement_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [PeriodFrom] date NOT NULL,
    [PeriodTo] date NOT NULL,
    [BeginBalance] decimal(19,4) NOT NULL CONSTRAINT [DF_CustomerStatement_BeginBalance] DEFAULT (0),
    [SaleAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_CustomerStatement_SaleAmount] DEFAULT (0),
    [ReturnAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_CustomerStatement_ReturnAmount] DEFAULT (0),
    [ReceiptAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_CustomerStatement_ReceiptAmount] DEFAULT (0),
    [EndBalance] decimal(19,4) NOT NULL CONSTRAINT [DF_CustomerStatement_EndBalance] DEFAULT (0),
    [ConfirmStatus] tinyint NOT NULL CONSTRAINT [DF_CustomerStatement_ConfirmStatus] DEFAULT (0),
    [ConfirmedAt] datetime2(3) NULL,
    [ConfirmedBy] nvarchar(50) NULL,
    CONSTRAINT [PK_CustomerStatement] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_CustomerStatement_TenantId_DocNo] ON [sal].[CustomerStatement] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_CustomerStatement_PartnerId_ConfirmStatus] ON [sal].[CustomerStatement] ([PartnerId], [ConfirmStatus]);
GO
CREATE INDEX [IX_CustomerStatement_OrgId] ON [sal].[CustomerStatement] ([OrgId]);
GO
CREATE INDEX [IX_CustomerStatement_CreatedBy] ON [sal].[CustomerStatement] ([CreatedBy]);
GO
CREATE INDEX [IX_CustomerStatement_ModifiedBy] ON [sal].[CustomerStatement] ([ModifiedBy]);
GO
CREATE INDEX [IX_CustomerStatement_DeletedBy] ON [sal].[CustomerStatement] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'客户对账单', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'客户', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'期初应收', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'BeginBalance';
EXEC sp_addextendedproperty N'MS_Description', N'本期销售', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'SaleAmount';
EXEC sp_addextendedproperty N'MS_Description', N'本期退货', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'ReturnAmount';
EXEC sp_addextendedproperty N'MS_Description', N'本期收款', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'ReceiptAmount';
EXEC sp_addextendedproperty N'MS_Description', N'期末应收', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'EndBalance';
EXEC sp_addextendedproperty N'MS_Description', N'0待确认 1已确认 2有异议', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatement', N'COLUMN', N'ConfirmStatus';
GO
CREATE TABLE [sal].[CustomerStatementItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [StatementId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [SourceNo] varchar(40) NULL,
    [BizDate] date NULL,
    [Amount] decimal(19,4) NOT NULL,
    [Direction] tinyint NOT NULL CONSTRAINT [DF_CustomerStatementItem_Direction] DEFAULT (1),
    [IsConfirmed] bit NOT NULL CONSTRAINT [DF_CustomerStatementItem_IsConfirmed] DEFAULT (0),
    CONSTRAINT [PK_CustomerStatementItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_CustomerStatementItem_StatementId] ON [sal].[CustomerStatementItem] ([StatementId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'客户对账单明细', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatementItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatementItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatementItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatementItem', N'COLUMN', N'StatementId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatementItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'来源(销售/退货/收款/期初)', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatementItem', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'1增加应收 2减少应收', N'SCHEMA', N'sal', N'TABLE', N'CustomerStatementItem', N'COLUMN', N'Direction';
GO
CREATE TABLE [sal].[RebatePolicy] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_RebatePolicy_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(100) NULL,
    [PolicyType] tinyint NOT NULL CONSTRAINT [DF_RebatePolicy_PolicyType] DEFAULT (1) CONSTRAINT [CK_RebatePolicy_PolicyType] CHECK (PolicyType BETWEEN 1 AND 4),
    [ScopeType] tinyint NOT NULL CONSTRAINT [DF_RebatePolicy_ScopeType] DEFAULT (1),
    [ScopeIds] nvarchar(max) NULL,
    [CalcBase] tinyint NOT NULL CONSTRAINT [DF_RebatePolicy_CalcBase] DEFAULT (1),
    [LadderJson] nvarchar(max) NULL,
    [Period] varchar(20) NULL,
    [StartDate] date NULL,
    [EndDate] date NULL,
    [SettleMode] tinyint NOT NULL CONSTRAINT [DF_RebatePolicy_SettleMode] DEFAULT (1),
    [Status] tinyint NOT NULL CONSTRAINT [DF_RebatePolicy_Status] DEFAULT (1),
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_RebatePolicy_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_RebatePolicy_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_RebatePolicy] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_RebatePolicy_TenantId_Code] ON [sal].[RebatePolicy] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_RebatePolicy_OrgId] ON [sal].[RebatePolicy] ([OrgId]);
GO
CREATE INDEX [IX_RebatePolicy_CreatedBy] ON [sal].[RebatePolicy] ([CreatedBy]);
GO
CREATE INDEX [IX_RebatePolicy_ModifiedBy] ON [sal].[RebatePolicy] ([ModifiedBy]);
GO
CREATE INDEX [IX_RebatePolicy_DeletedBy] ON [sal].[RebatePolicy] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'返利政策', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'政策名称', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1阶梯返利 2年度返利 3专销返利 4费用返还)', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'PolicyType';
EXEC sp_addextendedproperty N'MS_Description', N'范围(1全部客户 2等级 3指定客户 4渠道)', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'ScopeType';
EXEC sp_addextendedproperty N'MS_Description', N'范围明细', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'ScopeIds';
EXEC sp_addextendedproperty N'MS_Description', N'计算口径(1销售额 2回款额 3毛利 4数量)', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'CalcBase';
EXEC sp_addextendedproperty N'MS_Description', N'阶梯规则[{min,max,rate/amount}]', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'LadderJson';
EXEC sp_addextendedproperty N'MS_Description', N'结算周期(年度/季度/月度)', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'Period';
EXEC sp_addextendedproperty N'MS_Description', N'返还方式(1抵扣货款 2现金 3转预存)', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'SettleMode';
EXEC sp_addextendedproperty N'MS_Description', N'0草稿 1生效 2停用', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'RebatePolicy', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [sal].[RebateSettlement] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_RebateSettlement_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_RebateSettlement_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_RebateSettlement_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_RebateSettlement_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [PolicyId] bigint NULL,
    [Period] varchar(20) NULL,
    [BaseAmount] decimal(19,4) NULL,
    [RebateRate] decimal(9,4) NULL,
    [RebateAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_RebateSettlement_RebateAmount] DEFAULT (0),
    [SettledAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_RebateSettlement_SettledAmount] DEFAULT (0),
    CONSTRAINT [PK_RebateSettlement] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_RebateSettlement_TenantId_DocNo] ON [sal].[RebateSettlement] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_RebateSettlement_PartnerId_Status] ON [sal].[RebateSettlement] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_RebateSettlement_OrgId] ON [sal].[RebateSettlement] ([OrgId]);
GO
CREATE INDEX [IX_RebateSettlement_CreatedBy] ON [sal].[RebateSettlement] ([CreatedBy]);
GO
CREATE INDEX [IX_RebateSettlement_ModifiedBy] ON [sal].[RebateSettlement] ([ModifiedBy]);
GO
CREATE INDEX [IX_RebateSettlement_DeletedBy] ON [sal].[RebateSettlement] ([DeletedBy]);
GO
CREATE INDEX [IX_RebateSettlement_PolicyId] ON [sal].[RebateSettlement] ([PolicyId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'返利结算单', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'客户', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'政策', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'PolicyId';
EXEC sp_addextendedproperty N'MS_Description', N'期间', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'Period';
EXEC sp_addextendedproperty N'MS_Description', N'计算基数', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'BaseAmount';
EXEC sp_addextendedproperty N'MS_Description', N'返利率%', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'RebateRate';
EXEC sp_addextendedproperty N'MS_Description', N'返利金额', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'RebateAmount';
EXEC sp_addextendedproperty N'MS_Description', N'已结算金额', N'SCHEMA', N'sal', N'TABLE', N'RebateSettlement', N'COLUMN', N'SettledAmount';
GO
CREATE TABLE [sal].[ChannelPolicy] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_ChannelPolicy_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(100) NULL,
    [PolicyType] tinyint NOT NULL CONSTRAINT [DF_ChannelPolicy_PolicyType] DEFAULT (1) CONSTRAINT [CK_ChannelPolicy_PolicyType] CHECK (PolicyType BETWEEN 1 AND 5),
    [PartnerId] bigint NULL,
    [Content] nvarchar(max) NULL,
    [StartDate] date NULL,
    [EndDate] date NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_ChannelPolicy_Status] DEFAULT (1),
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_ChannelPolicy_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_ChannelPolicy_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_ChannelPolicy] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ChannelPolicy_TenantId_Code] ON [sal].[ChannelPolicy] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_ChannelPolicy_PartnerId] ON [sal].[ChannelPolicy] ([PartnerId]);
GO
CREATE INDEX [IX_ChannelPolicy_OrgId] ON [sal].[ChannelPolicy] ([OrgId]);
GO
CREATE INDEX [IX_ChannelPolicy_CreatedBy] ON [sal].[ChannelPolicy] ([CreatedBy]);
GO
CREATE INDEX [IX_ChannelPolicy_ModifiedBy] ON [sal].[ChannelPolicy] ([ModifiedBy]);
GO
CREATE INDEX [IX_ChannelPolicy_DeletedBy] ON [sal].[ChannelPolicy] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'渠道政策', N'SCHEMA', N'sal', N'TABLE', N'ChannelPolicy';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'ChannelPolicy', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1区域保护 2价格保护 3退换货 4陈列 5任务奖励)', N'SCHEMA', N'sal', N'TABLE', N'ChannelPolicy', N'COLUMN', N'PolicyType';
EXEC sp_addextendedproperty N'MS_Description', N'适用客户(空=全部)', N'SCHEMA', N'sal', N'TABLE', N'ChannelPolicy', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'政策内容', N'SCHEMA', N'sal', N'TABLE', N'ChannelPolicy', N'COLUMN', N'Content';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'sal', N'TABLE', N'ChannelPolicy', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'sal', N'TABLE', N'ChannelPolicy', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'sal', N'TABLE', N'ChannelPolicy', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'sal', N'TABLE', N'ChannelPolicy', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'sal', N'TABLE', N'ChannelPolicy', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'sal', N'TABLE', N'ChannelPolicy', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'ChannelPolicy', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'sal', N'TABLE', N'ChannelPolicy', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'ChannelPolicy', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'sal', N'TABLE', N'ChannelPolicy', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'ChannelPolicy', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [sal].[ChannelExpense] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_ChannelExpense_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_ChannelExpense_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_ChannelExpense_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_ChannelExpense_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [PartnerId] bigint NOT NULL,
    [ExpenseType] tinyint NOT NULL CONSTRAINT [DF_ChannelExpense_ExpenseType] DEFAULT (1),
    [ApplyAmount] decimal(19,4) NOT NULL,
    [ApproveAmount] decimal(19,4) NULL,
    [EvidenceType] tinyint NOT NULL CONSTRAINT [DF_ChannelExpense_EvidenceType] DEFAULT (1),
    [EvidenceJson] nvarchar(max) NULL,
    [DeductAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_ChannelExpense_DeductAmount] DEFAULT (0),
    CONSTRAINT [PK_ChannelExpense] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ChannelExpense_TenantId_DocNo] ON [sal].[ChannelExpense] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_ChannelExpense_PartnerId_Status] ON [sal].[ChannelExpense] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_ChannelExpense_OrgId] ON [sal].[ChannelExpense] ([OrgId]);
GO
CREATE INDEX [IX_ChannelExpense_CreatedBy] ON [sal].[ChannelExpense] ([CreatedBy]);
GO
CREATE INDEX [IX_ChannelExpense_ModifiedBy] ON [sal].[ChannelExpense] ([ModifiedBy]);
GO
CREATE INDEX [IX_ChannelExpense_DeletedBy] ON [sal].[ChannelExpense] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'渠道费用核销', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'客户/经销商', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1陈列费 2促销费 3进场费 4返点 5广告费)', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'ExpenseType';
EXEC sp_addextendedproperty N'MS_Description', N'申请金额', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'ApplyAmount';
EXEC sp_addextendedproperty N'MS_Description', N'核准金额', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'ApproveAmount';
EXEC sp_addextendedproperty N'MS_Description', N'凭证(1照片 2销量 3发票)', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'EvidenceType';
EXEC sp_addextendedproperty N'MS_Description', N'核销凭证明细', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'EvidenceJson';
EXEC sp_addextendedproperty N'MS_Description', N'抵减应付金额', N'SCHEMA', N'sal', N'TABLE', N'ChannelExpense', N'COLUMN', N'DeductAmount';
GO
CREATE TABLE [sal].[SellOutReport] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_SellOutReport_TenantId] DEFAULT (1),
    [PartnerId] bigint NOT NULL,
    [Period] varchar(10) NOT NULL,
    [ReportType] tinyint NOT NULL CONSTRAINT [DF_SellOutReport_ReportType] DEFAULT (1),
    [SubmitAt] datetime2(3) NOT NULL CONSTRAINT [DF_SellOutReport_SubmitAt] DEFAULT (sysutcdatetime()),
    [SubmitBy] bigint NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_SellOutReport_Status] DEFAULT (0),
    [TotalQty] decimal(19,6) NULL,
    [TotalAmount] decimal(19,4) NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_SellOutReport_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_SellOutReport_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_SellOutReport] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_SellOutReport_TenantId_PartnerId_Period_ReportType] ON [sal].[SellOutReport] ([TenantId], [PartnerId], [Period], [ReportType]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_SellOutReport_PartnerId] ON [sal].[SellOutReport] ([PartnerId]);
GO
CREATE INDEX [IX_SellOutReport_CreatedBy] ON [sal].[SellOutReport] ([CreatedBy]);
GO
CREATE INDEX [IX_SellOutReport_ModifiedBy] ON [sal].[SellOutReport] ([ModifiedBy]);
GO
CREATE INDEX [IX_SellOutReport_DeletedBy] ON [sal].[SellOutReport] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'经销商动销上报', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'经销商', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'期间', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'Period';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1销量 2库存 3终端门店)', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'ReportType';
EXEC sp_addextendedproperty N'MS_Description', N'提交人', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'SubmitBy';
EXEC sp_addextendedproperty N'MS_Description', N'0待审 1已确认 2退回', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'上报总数量', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'TotalQty';
EXEC sp_addextendedproperty N'MS_Description', N'上报总金额', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'TotalAmount';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SellOutReport', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [sal].[SellOutReportItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [ReportId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [Qty] decimal(19,6) NULL,
    [Amount] decimal(19,4) NULL,
    [EndStockQty] decimal(19,6) NULL,
    [TerminalCount] int NULL,
    CONSTRAINT [PK_SellOutReportItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_SellOutReportItem_ReportId] ON [sal].[SellOutReportItem] ([ReportId]);
GO
CREATE INDEX [IX_SellOutReportItem_SkuId] ON [sal].[SellOutReportItem] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'动销上报明细', N'SCHEMA', N'sal', N'TABLE', N'SellOutReportItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'SellOutReportItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'sal', N'TABLE', N'SellOutReportItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'sal', N'TABLE', N'SellOutReportItem', N'COLUMN', N'ReportId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'sal', N'TABLE', N'SellOutReportItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'销量', N'SCHEMA', N'sal', N'TABLE', N'SellOutReportItem', N'COLUMN', N'Qty';
EXEC sp_addextendedproperty N'MS_Description', N'金额', N'SCHEMA', N'sal', N'TABLE', N'SellOutReportItem', N'COLUMN', N'Amount';
EXEC sp_addextendedproperty N'MS_Description', N'期末库存', N'SCHEMA', N'sal', N'TABLE', N'SellOutReportItem', N'COLUMN', N'EndStockQty';
EXEC sp_addextendedproperty N'MS_Description', N'覆盖终端数', N'SCHEMA', N'sal', N'TABLE', N'SellOutReportItem', N'COLUMN', N'TerminalCount';
GO
CREATE TABLE [sal].[SalesTarget] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_SalesTarget_TenantId] DEFAULT (1),
    [Period] varchar(10) NOT NULL,
    [TargetLevel] tinyint NOT NULL CONSTRAINT [DF_SalesTarget_TargetLevel] DEFAULT (1),
    [TargetId] bigint NULL,
    [TargetName] nvarchar(100) NULL,
    [TargetAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesTarget_TargetAmount] DEFAULT (0),
    [TargetQty] decimal(19,6) NULL,
    [AchievedAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesTarget_AchievedAmount] DEFAULT (0),
    [Status] tinyint NOT NULL CONSTRAINT [DF_SalesTarget_Status] DEFAULT (1),
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_SalesTarget_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_SalesTarget_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_SalesTarget] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_SalesTarget_TenantId_Period_TargetLevel_TargetId] ON [sal].[SalesTarget] ([TenantId], [Period], [TargetLevel], [TargetId]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_SalesTarget_OrgId] ON [sal].[SalesTarget] ([OrgId]);
GO
CREATE INDEX [IX_SalesTarget_CreatedBy] ON [sal].[SalesTarget] ([CreatedBy]);
GO
CREATE INDEX [IX_SalesTarget_ModifiedBy] ON [sal].[SalesTarget] ([ModifiedBy]);
GO
CREATE INDEX [IX_SalesTarget_DeletedBy] ON [sal].[SalesTarget] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'销售目标', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'期间(2026-01)', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'Period';
EXEC sp_addextendedproperty N'MS_Description', N'层级(1公司 2区域 3业务员 4客户 5商品)', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'TargetLevel';
EXEC sp_addextendedproperty N'MS_Description', N'目标对象Id', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'TargetId';
EXEC sp_addextendedproperty N'MS_Description', N'目标名称', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'TargetName';
EXEC sp_addextendedproperty N'MS_Description', N'目标金额', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'TargetAmount';
EXEC sp_addextendedproperty N'MS_Description', N'目标数量', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'TargetQty';
EXEC sp_addextendedproperty N'MS_Description', N'已完成', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'AchievedAmount';
EXEC sp_addextendedproperty N'MS_Description', N'0草稿 1已下达', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'SalesTarget', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [sal].[VisitRecord] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_VisitRecord_TenantId] DEFAULT (1),
    [PartnerId] bigint NOT NULL,
    [SalesmanId] bigint NOT NULL,
    [VisitType] tinyint NOT NULL CONSTRAINT [DF_VisitRecord_VisitType] DEFAULT (1),
    [CheckInAt] datetime2(3) NULL,
    [Latitude] decimal(10,6) NULL,
    [Longitude] decimal(10,6) NULL,
    [Address] nvarchar(200) NULL,
    [PhotoJson] nvarchar(max) NULL,
    [CompetitorJson] nvarchar(max) NULL,
    [Note] nvarchar(500) NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_VisitRecord_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_VisitRecord_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_VisitRecord] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_VisitRecord_PartnerId_CheckInAt] ON [sal].[VisitRecord] ([PartnerId], [CheckInAt]);
GO
CREATE INDEX [IX_VisitRecord_SalesmanId_CheckInAt] ON [sal].[VisitRecord] ([SalesmanId], [CheckInAt]);
GO
CREATE INDEX [IX_VisitRecord_OrgId] ON [sal].[VisitRecord] ([OrgId]);
GO
CREATE INDEX [IX_VisitRecord_CreatedBy] ON [sal].[VisitRecord] ([CreatedBy]);
GO
CREATE INDEX [IX_VisitRecord_ModifiedBy] ON [sal].[VisitRecord] ([ModifiedBy]);
GO
CREATE INDEX [IX_VisitRecord_DeletedBy] ON [sal].[VisitRecord] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'拜访与巡店记录', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'客户', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'业务员', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'SalesmanId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1拜访 2巡店 3抄单 4收款)', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'VisitType';
EXEC sp_addextendedproperty N'MS_Description', N'签到时间', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'CheckInAt';
EXEC sp_addextendedproperty N'MS_Description', N'照片附件', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'PhotoJson';
EXEC sp_addextendedproperty N'MS_Description', N'竞品与陈列采集', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'CompetitorJson';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'sal', N'TABLE', N'VisitRecord', N'COLUMN', N'DeletedAt';
GO
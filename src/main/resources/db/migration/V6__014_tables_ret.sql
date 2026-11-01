/* =====================================================================
   进销存管理系统 V3 · 表结构 · ret 架构（9 张表）
   数据库：APSErpV3   生成器：db/emit.py（请勿手改，改规格文件后重新生成）
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE TABLE [ret].[Shift] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Shift_TenantId] DEFAULT (1),
    [ShiftNo] varchar(40) NOT NULL,
    [StoreId] bigint NOT NULL,
    [PosTerminalId] int NULL,
    [CashierId] bigint NOT NULL,
    [StartAt] datetime2(3) NOT NULL,
    [EndAt] datetime2(3) NULL,
    [BeginCash] decimal(19,4) NOT NULL CONSTRAINT [DF_Shift_BeginCash] DEFAULT (0),
    [SaleAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_Shift_SaleAmount] DEFAULT (0),
    [ReturnAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_Shift_ReturnAmount] DEFAULT (0),
    [CashAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_Shift_CashAmount] DEFAULT (0),
    [ActualCash] decimal(19,4) NULL,
    [DiffCash] decimal(19,4) NULL,
    [PayDetailJson] nvarchar(max) NULL,
    [VoidCount] int NOT NULL CONSTRAINT [DF_Shift_VoidCount] DEFAULT (0),
    [Status] tinyint NOT NULL CONSTRAINT [DF_Shift_Status] DEFAULT (0),
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Shift_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Shift_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Shift] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Shift_TenantId_ShiftNo] ON [ret].[Shift] ([TenantId], [ShiftNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Shift_StoreId_StartAt] ON [ret].[Shift] ([StoreId], [StartAt]);
GO
CREATE INDEX [IX_Shift_PosTerminalId] ON [ret].[Shift] ([PosTerminalId]);
GO
CREATE INDEX [IX_Shift_CashierId] ON [ret].[Shift] ([CashierId]);
GO
CREATE INDEX [IX_Shift_OrgId] ON [ret].[Shift] ([OrgId]);
GO
CREATE INDEX [IX_Shift_CreatedBy] ON [ret].[Shift] ([CreatedBy]);
GO
CREATE INDEX [IX_Shift_ModifiedBy] ON [ret].[Shift] ([ModifiedBy]);
GO
CREATE INDEX [IX_Shift_DeletedBy] ON [ret].[Shift] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'收银交班', N'SCHEMA', N'ret', N'TABLE', N'Shift';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'班次号', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'ShiftNo';
EXEC sp_addextendedproperty N'MS_Description', N'POS机', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'PosTerminalId';
EXEC sp_addextendedproperty N'MS_Description', N'收银员', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'CashierId';
EXEC sp_addextendedproperty N'MS_Description', N'开班时间', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'StartAt';
EXEC sp_addextendedproperty N'MS_Description', N'交班时间', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'EndAt';
EXEC sp_addextendedproperty N'MS_Description', N'备用金', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'BeginCash';
EXEC sp_addextendedproperty N'MS_Description', N'销售金额', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'SaleAmount';
EXEC sp_addextendedproperty N'MS_Description', N'退货金额', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'ReturnAmount';
EXEC sp_addextendedproperty N'MS_Description', N'现金应收', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'CashAmount';
EXEC sp_addextendedproperty N'MS_Description', N'实点现金', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'ActualCash';
EXEC sp_addextendedproperty N'MS_Description', N'长短款', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'DiffCash';
EXEC sp_addextendedproperty N'MS_Description', N'各支付方式金额', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'PayDetailJson';
EXEC sp_addextendedproperty N'MS_Description', N'作废单数', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'VoidCount';
EXEC sp_addextendedproperty N'MS_Description', N'0进行中 1已交班 2已审核', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'ret', N'TABLE', N'Shift', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [ret].[PosSale] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_PosSale_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_PosSale_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_PosSale_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_PosSale_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [StoreId] bigint NOT NULL,
    [PosTerminalId] bigint NULL,
    [ShiftId] bigint NULL,
    [MemberId] bigint NULL,
    [SaleType] tinyint NOT NULL CONSTRAINT [DF_PosSale_SaleType] DEFAULT (1),
    [NetAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PosSale_NetAmount] DEFAULT (0),
    [TaxAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PosSale_TaxAmount] DEFAULT (0),
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PosSale_TotalAmount] DEFAULT (0),
    [DiscountAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PosSale_DiscountAmount] DEFAULT (0),
    [PaidAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PosSale_PaidAmount] DEFAULT (0),
    [ChangeAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PosSale_ChangeAmount] DEFAULT (0),
    [CostAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PosSale_CostAmount] DEFAULT (0),
    [PromotionJson] nvarchar(max) NULL,
    [IsOffline] bit NOT NULL CONSTRAINT [DF_PosSale_IsOffline] DEFAULT (0),
    [ClientNo] varchar(50) NOT NULL CONSTRAINT [DF_PosSale_ClientNo] DEFAULT (''),
    [CashierId] bigint NULL,
    CONSTRAINT [PK_PosSale] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PosSale_TenantId_DocNo] ON [ret].[PosSale] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE UNIQUE INDEX [UQ_PosSale_TenantId_PosTerminalId_ClientNo] ON [ret].[PosSale] ([TenantId], [PosTerminalId], [ClientNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_PosSale_StoreId_BizDate] ON [ret].[PosSale] ([StoreId], [BizDate]);
GO
CREATE INDEX [IX_PosSale_Status] ON [ret].[PosSale] ([Status]);
GO
CREATE INDEX [IX_PosSale_OrgId] ON [ret].[PosSale] ([OrgId]);
GO
CREATE INDEX [IX_PosSale_CreatedBy] ON [ret].[PosSale] ([CreatedBy]);
GO
CREATE INDEX [IX_PosSale_ModifiedBy] ON [ret].[PosSale] ([ModifiedBy]);
GO
CREATE INDEX [IX_PosSale_DeletedBy] ON [ret].[PosSale] ([DeletedBy]);
GO
CREATE INDEX [IX_PosSale_ShiftId] ON [ret].[PosSale] ([ShiftId]);
GO
CREATE INDEX [IX_PosSale_MemberId] ON [ret].[PosSale] ([MemberId]);
GO
CREATE INDEX [IX_PosSale_CashierId] ON [ret].[PosSale] ([CashierId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'零售销售单', N'SCHEMA', N'ret', N'TABLE', N'PosSale';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'POS机', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'PosTerminalId';
EXEC sp_addextendedproperty N'MS_Description', N'班次', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'ShiftId';
EXEC sp_addextendedproperty N'MS_Description', N'会员', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'MemberId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1零售 2批发开单 3团购 4自助)', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'SaleType';
EXEC sp_addextendedproperty N'MS_Description', N'应收', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'TotalAmount';
EXEC sp_addextendedproperty N'MS_Description', N'让利', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'DiscountAmount';
EXEC sp_addextendedproperty N'MS_Description', N'实收', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'PaidAmount';
EXEC sp_addextendedproperty N'MS_Description', N'找零', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'ChangeAmount';
EXEC sp_addextendedproperty N'MS_Description', N'执行的促销与券', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'PromotionJson';
EXEC sp_addextendedproperty N'MS_Description', N'离线补传', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'IsOffline';
EXEC sp_addextendedproperty N'MS_Description', N'端上唯一号(离线去重)', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'ClientNo';
EXEC sp_addextendedproperty N'MS_Description', N'收银员', N'SCHEMA', N'ret', N'TABLE', N'PosSale', N'COLUMN', N'CashierId';
GO
CREATE TABLE [ret].[PosSaleItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [SaleId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [Barcode] varchar(50) NULL,
    [UnitId] bigint NULL,
    [Qty] decimal(19,6) NOT NULL,
    [BaseQty] decimal(19,6) NOT NULL,
    [Price] decimal(19,6) NOT NULL,
    [ActualPrice] decimal(19,6) NOT NULL,
    [DiscountAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PosSaleItem_DiscountAmount] DEFAULT (0),
    [Amount] decimal(19,4) NOT NULL CONSTRAINT [DF_PosSaleItem_Amount] DEFAULT (0),
    [CostPrice] decimal(19,6) NULL,
    [CostAmount] decimal(19,4) NULL,
    [PromotionId] bigint NULL,
    [IsGift] bit NOT NULL CONSTRAINT [DF_PosSaleItem_IsGift] DEFAULT (0),
    [WeighQty] decimal(19,6) NULL,
    CONSTRAINT [PK_PosSaleItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PosSaleItem_SaleId_LineNo] ON [ret].[PosSaleItem] ([SaleId], [LineNo]);
GO
CREATE INDEX [IX_PosSaleItem_SkuId] ON [ret].[PosSaleItem] ([SkuId]);
GO
CREATE INDEX [IX_PosSaleItem_UnitId] ON [ret].[PosSaleItem] ([UnitId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'零售明细', N'SCHEMA', N'ret', N'TABLE', N'PosSaleItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'ret', N'TABLE', N'PosSaleItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'ret', N'TABLE', N'PosSaleItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'ret', N'TABLE', N'PosSaleItem', N'COLUMN', N'SaleId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'ret', N'TABLE', N'PosSaleItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'扫码条码', N'SCHEMA', N'ret', N'TABLE', N'PosSaleItem', N'COLUMN', N'Barcode';
EXEC sp_addextendedproperty N'MS_Description', N'标准价', N'SCHEMA', N'ret', N'TABLE', N'PosSaleItem', N'COLUMN', N'Price';
EXEC sp_addextendedproperty N'MS_Description', N'成交价', N'SCHEMA', N'ret', N'TABLE', N'PosSaleItem', N'COLUMN', N'ActualPrice';
EXEC sp_addextendedproperty N'MS_Description', N'称重数量', N'SCHEMA', N'ret', N'TABLE', N'PosSaleItem', N'COLUMN', N'WeighQty';
GO
CREATE TABLE [ret].[PosPayment] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [SaleId] bigint NOT NULL,
    [PayMethod] tinyint NOT NULL CONSTRAINT [DF_PosPayment_PayMethod] DEFAULT (1) CONSTRAINT [CK_PosPayment_PayMethod] CHECK (PayMethod BETWEEN 1 AND 9),
    [Amount] decimal(19,4) NOT NULL,
    [TradeNo] varchar(64) NULL,
    [PayStatus] tinyint NOT NULL CONSTRAINT [DF_PosPayment_PayStatus] DEFAULT (1),
    [PaidAt] datetime2(3) NULL,
    CONSTRAINT [PK_PosPayment] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_PosPayment_SaleId] ON [ret].[PosPayment] ([SaleId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'零售支付明细', N'SCHEMA', N'ret', N'TABLE', N'PosPayment';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'ret', N'TABLE', N'PosPayment', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'方式(1现金 2银行卡 3微信 4支付宝 5会员储值 6券 7积分 8挂账 9其他)', N'SCHEMA', N'ret', N'TABLE', N'PosPayment', N'COLUMN', N'PayMethod';
EXEC sp_addextendedproperty N'MS_Description', N'支付金额', N'SCHEMA', N'ret', N'TABLE', N'PosPayment', N'COLUMN', N'Amount';
EXEC sp_addextendedproperty N'MS_Description', N'第三方交易号', N'SCHEMA', N'ret', N'TABLE', N'PosPayment', N'COLUMN', N'TradeNo';
EXEC sp_addextendedproperty N'MS_Description', N'1成功 2已退 3失败', N'SCHEMA', N'ret', N'TABLE', N'PosPayment', N'COLUMN', N'PayStatus';
EXEC sp_addextendedproperty N'MS_Description', N'支付时间', N'SCHEMA', N'ret', N'TABLE', N'PosPayment', N'COLUMN', N'PaidAt';
GO
CREATE TABLE [ret].[PosReturn] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_PosReturn_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_PosReturn_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_PosReturn_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_PosReturn_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [StoreId] bigint NOT NULL,
    [OriginalSaleId] bigint NULL,
    [ShiftId] bigint NULL,
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PosReturn_TotalAmount] DEFAULT (0),
    [RefundAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_PosReturn_RefundAmount] DEFAULT (0),
    [ReturnReason] tinyint NOT NULL CONSTRAINT [DF_PosReturn_ReturnReason] DEFAULT (1),
    [CashierId] bigint NULL,
    [ApprovedBy] bigint NULL,
    CONSTRAINT [PK_PosReturn] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PosReturn_TenantId_DocNo] ON [ret].[PosReturn] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_PosReturn_OriginalSaleId] ON [ret].[PosReturn] ([OriginalSaleId]);
GO
CREATE INDEX [IX_PosReturn_OrgId] ON [ret].[PosReturn] ([OrgId]);
GO
CREATE INDEX [IX_PosReturn_CreatedBy] ON [ret].[PosReturn] ([CreatedBy]);
GO
CREATE INDEX [IX_PosReturn_ModifiedBy] ON [ret].[PosReturn] ([ModifiedBy]);
GO
CREATE INDEX [IX_PosReturn_DeletedBy] ON [ret].[PosReturn] ([DeletedBy]);
GO
CREATE INDEX [IX_PosReturn_StoreId] ON [ret].[PosReturn] ([StoreId]);
GO
CREATE INDEX [IX_PosReturn_ShiftId] ON [ret].[PosReturn] ([ShiftId]);
GO
CREATE INDEX [IX_PosReturn_CashierId] ON [ret].[PosReturn] ([CashierId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'零售退货单', N'SCHEMA', N'ret', N'TABLE', N'PosReturn';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'原销售单', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'OriginalSaleId';
EXEC sp_addextendedproperty N'MS_Description', N'班次', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'ShiftId';
EXEC sp_addextendedproperty N'MS_Description', N'原因(1质量问题 2不想要 3错扫 4其他)', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'ReturnReason';
EXEC sp_addextendedproperty N'MS_Description', N'收银员', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'CashierId';
EXEC sp_addextendedproperty N'MS_Description', N'授权人(改价/退货需授权)', N'SCHEMA', N'ret', N'TABLE', N'PosReturn', N'COLUMN', N'ApprovedBy';
GO
CREATE TABLE [ret].[PosReturnItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [ReturnId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SaleItemId] bigint NULL,
    [SkuId] bigint NOT NULL,
    [Qty] decimal(19,6) NOT NULL,
    [Price] decimal(19,6) NOT NULL,
    [Amount] decimal(19,4) NOT NULL,
    [QualityStatus] tinyint NOT NULL CONSTRAINT [DF_PosReturnItem_QualityStatus] DEFAULT (1),
    CONSTRAINT [PK_PosReturnItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PosReturnItem_ReturnId_LineNo] ON [ret].[PosReturnItem] ([ReturnId], [LineNo]);
GO
CREATE INDEX [IX_PosReturnItem_SaleItemId] ON [ret].[PosReturnItem] ([SaleItemId]);
GO
CREATE INDEX [IX_PosReturnItem_SkuId] ON [ret].[PosReturnItem] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'零售退货明细', N'SCHEMA', N'ret', N'TABLE', N'PosReturnItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'ret', N'TABLE', N'PosReturnItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'ret', N'TABLE', N'PosReturnItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'ret', N'TABLE', N'PosReturnItem', N'COLUMN', N'ReturnId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'ret', N'TABLE', N'PosReturnItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'原销售行', N'SCHEMA', N'ret', N'TABLE', N'PosReturnItem', N'COLUMN', N'SaleItemId';
EXEC sp_addextendedproperty N'MS_Description', N'1可售 2残次 3报废', N'SCHEMA', N'ret', N'TABLE', N'PosReturnItem', N'COLUMN', N'QualityStatus';
GO
CREATE TABLE [ret].[DayClose] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_DayClose_TenantId] DEFAULT (1),
    [StoreId] bigint NOT NULL,
    [BizDate] date NOT NULL,
    [SaleAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_DayClose_SaleAmount] DEFAULT (0),
    [ReturnAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_DayClose_ReturnAmount] DEFAULT (0),
    [NetAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_DayClose_NetAmount] DEFAULT (0),
    [CashAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_DayClose_CashAmount] DEFAULT (0),
    [NonCashAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_DayClose_NonCashAmount] DEFAULT (0),
    [TurnoverAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_DayClose_TurnoverAmount] DEFAULT (0),
    [CustomerCount] int NOT NULL CONSTRAINT [DF_DayClose_CustomerCount] DEFAULT (0),
    [ItemCount] decimal(19,6) NOT NULL CONSTRAINT [DF_DayClose_ItemCount] DEFAULT (0),
    [Status] tinyint NOT NULL CONSTRAINT [DF_DayClose_Status] DEFAULT (0),
    [ClosedBy] bigint NULL,
    [ClosedAt] datetime2(3) NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_DayClose_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_DayClose_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_DayClose] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_DayClose_TenantId_StoreId_BizDate] ON [ret].[DayClose] ([TenantId], [StoreId], [BizDate]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_DayClose_StoreId] ON [ret].[DayClose] ([StoreId]);
GO
CREATE INDEX [IX_DayClose_OrgId] ON [ret].[DayClose] ([OrgId]);
GO
CREATE INDEX [IX_DayClose_CreatedBy] ON [ret].[DayClose] ([CreatedBy]);
GO
CREATE INDEX [IX_DayClose_ModifiedBy] ON [ret].[DayClose] ([ModifiedBy]);
GO
CREATE INDEX [IX_DayClose_DeletedBy] ON [ret].[DayClose] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'门店日结', N'SCHEMA', N'ret', N'TABLE', N'DayClose';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'营业日', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'营业净额', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'NetAmount';
EXEC sp_addextendedproperty N'MS_Description', N'营业款上缴', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'TurnoverAmount';
EXEC sp_addextendedproperty N'MS_Description', N'客单数', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'CustomerCount';
EXEC sp_addextendedproperty N'MS_Description', N'销售件数', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'ItemCount';
EXEC sp_addextendedproperty N'MS_Description', N'0待结 1已日结 2已上缴 3已入账', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'ret', N'TABLE', N'DayClose', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [ret].[StoreRequisition] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_StoreRequisition_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_StoreRequisition_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_StoreRequisition_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_StoreRequisition_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [StoreId] bigint NOT NULL,
    [WarehouseId] bigint NULL,
    [ReqType] tinyint NOT NULL CONSTRAINT [DF_StoreRequisition_ReqType] DEFAULT (1),
    [WantDate] date NULL,
    [TotalQty] decimal(19,6) NOT NULL CONSTRAINT [DF_StoreRequisition_TotalQty] DEFAULT (0),
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_StoreRequisition_TotalAmount] DEFAULT (0),
    [TransferId] bigint NULL,
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    CONSTRAINT [PK_StoreRequisition] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_StoreRequisition_TenantId_DocNo] ON [ret].[StoreRequisition] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_StoreRequisition_StoreId_Status] ON [ret].[StoreRequisition] ([StoreId], [Status]);
GO
CREATE INDEX [IX_StoreRequisition_OrgId] ON [ret].[StoreRequisition] ([OrgId]);
GO
CREATE INDEX [IX_StoreRequisition_CreatedBy] ON [ret].[StoreRequisition] ([CreatedBy]);
GO
CREATE INDEX [IX_StoreRequisition_ModifiedBy] ON [ret].[StoreRequisition] ([ModifiedBy]);
GO
CREATE INDEX [IX_StoreRequisition_DeletedBy] ON [ret].[StoreRequisition] ([DeletedBy]);
GO
CREATE INDEX [IX_StoreRequisition_WarehouseId] ON [ret].[StoreRequisition] ([WarehouseId]);
GO
CREATE INDEX [IX_StoreRequisition_TransferId] ON [ret].[StoreRequisition] ([TransferId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'门店要货单', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'发货仓', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1要货 2紧急补货 3退货)', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'ReqType';
EXEC sp_addextendedproperty N'MS_Description', N'期望到货', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'WantDate';
EXEC sp_addextendedproperty N'MS_Description', N'转调拨单', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisition', N'COLUMN', N'TransferId';
GO
CREATE TABLE [ret].[StoreRequisitionItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [RequisitionId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [Qty] decimal(19,6) NOT NULL,
    [SuggestQty] decimal(19,6) NULL,
    [ApprovedQty] decimal(19,6) NULL,
    [Price] decimal(19,6) NULL,
    CONSTRAINT [PK_StoreRequisitionItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_StoreRequisitionItem_RequisitionId_LineNo] ON [ret].[StoreRequisitionItem] ([RequisitionId], [LineNo]);
GO
CREATE INDEX [IX_StoreRequisitionItem_SkuId] ON [ret].[StoreRequisitionItem] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'门店要货明细', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisitionItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisitionItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisitionItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisitionItem', N'COLUMN', N'RequisitionId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisitionItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'要货数量', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisitionItem', N'COLUMN', N'Qty';
EXEC sp_addextendedproperty N'MS_Description', N'系统建议(基于上下限)', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisitionItem', N'COLUMN', N'SuggestQty';
EXEC sp_addextendedproperty N'MS_Description', N'核准数量', N'SCHEMA', N'ret', N'TABLE', N'StoreRequisitionItem', N'COLUMN', N'ApprovedQty';
GO
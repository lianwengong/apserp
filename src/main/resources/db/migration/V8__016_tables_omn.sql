/* =====================================================================
   进销存管理系统 V3 · 表结构 · omn 架构（9 张表）
   数据库：APSErpV3   生成器：db/emit.py（请勿手改，改规格文件后重新生成）
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE TABLE [omn].[Channel] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Channel_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(50) NOT NULL,
    [ChannelType] tinyint NOT NULL CONSTRAINT [DF_Channel_ChannelType] DEFAULT (1) CONSTRAINT [CK_Channel_ChannelType] CHECK (ChannelType BETWEEN 1 AND 6),
    [ShopId] varchar(60) NULL,
    [EndpointId] bigint NULL,
    [WarehouseId] bigint NULL,
    [PriceTypeId] bigint NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Channel_IsEnabled] DEFAULT (1),
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Channel_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Channel_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Channel] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Channel_TenantId_Code] ON [omn].[Channel] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Channel_EndpointId] ON [omn].[Channel] ([EndpointId]);
GO
CREATE INDEX [IX_Channel_WarehouseId] ON [omn].[Channel] ([WarehouseId]);
GO
CREATE INDEX [IX_Channel_PriceTypeId] ON [omn].[Channel] ([PriceTypeId]);
GO
CREATE INDEX [IX_Channel_OrgId] ON [omn].[Channel] ([OrgId]);
GO
CREATE INDEX [IX_Channel_CreatedBy] ON [omn].[Channel] ([CreatedBy]);
GO
CREATE INDEX [IX_Channel_ModifiedBy] ON [omn].[Channel] ([ModifiedBy]);
GO
CREATE INDEX [IX_Channel_DeletedBy] ON [omn].[Channel] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'销售渠道', N'SCHEMA', N'omn', N'TABLE', N'Channel';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'渠道编码', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'渠道名称', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1线下批发 2线下零售 3线上批发B2B 4线上零售B2C 5平台电商 6团购)', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'ChannelType';
EXEC sp_addextendedproperty N'MS_Description', N'平台店铺Id', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'ShopId';
EXEC sp_addextendedproperty N'MS_Description', N'集成端点', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'EndpointId';
EXEC sp_addextendedproperty N'MS_Description', N'默认发货仓', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'默认价格类型', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'PriceTypeId';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'omn', N'TABLE', N'Channel', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [omn].[OnlineOrder] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_OnlineOrder_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_OnlineOrder_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_OnlineOrder_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_OnlineOrder_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [OrderNo] varchar(50) NOT NULL,
    [ChannelId] bigint NOT NULL,
    [PlatformOrderNo] varchar(64) NULL,
    [OrderType] tinyint NOT NULL CONSTRAINT [DF_OnlineOrder_OrderType] DEFAULT (1),
    [PartnerId] bigint NULL,
    [MemberId] bigint NULL,
    [ReceiverName] nvarchar(50) NULL,
    [ReceiverPhone] varchar(30) NULL,
    [ReceiverAddress] nvarchar(300) NULL,
    [RegionId] bigint NULL,
    [WarehouseId] bigint NULL,
    [StoreId] bigint NULL,
    [NetAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_OnlineOrder_NetAmount] DEFAULT (0),
    [TaxAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_OnlineOrder_TaxAmount] DEFAULT (0),
    [FreightAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_OnlineOrder_FreightAmount] DEFAULT (0),
    [DiscountAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_OnlineOrder_DiscountAmount] DEFAULT (0),
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_OnlineOrder_TotalAmount] DEFAULT (0),
    [PaidAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_OnlineOrder_PaidAmount] DEFAULT (0),
    [PayStatus] tinyint NOT NULL CONSTRAINT [DF_OnlineOrder_PayStatus] DEFAULT (0),
    [OrderStatus] tinyint NOT NULL CONSTRAINT [DF_OnlineOrder_OrderStatus] DEFAULT (0) CONSTRAINT [CK_OnlineOrder_OrderStatus] CHECK (OrderStatus BETWEEN 0 AND 7),
    [DeliveryType] tinyint NOT NULL CONSTRAINT [DF_OnlineOrder_DeliveryType] DEFAULT (1),
    [ExpressCompany] nvarchar(50) NULL,
    [ExpressNo] varchar(50) NULL,
    [BuyerRemark] nvarchar(500) NULL,
    [SellerRemark] nvarchar(500) NULL,
    [AutoAuditAt] datetime2(3) NULL,
    [PayAt] datetime2(3) NULL,
    [ShipAt] datetime2(3) NULL,
    [SignAt] datetime2(3) NULL,
    [FinishAt] datetime2(3) NULL,
    [SourceOrderId] bigint NULL,
    CONSTRAINT [PK_OnlineOrder] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_OnlineOrder_TenantId_OrderNo] ON [omn].[OnlineOrder] ([TenantId], [OrderNo]) WHERE [IsDeleted] = 0;
GO
CREATE UNIQUE INDEX [UQ_OnlineOrder_TenantId_ChannelId_PlatformOrderNo] ON [omn].[OnlineOrder] ([TenantId], [ChannelId], [PlatformOrderNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_OnlineOrder_TenantId_OrderStatus] ON [omn].[OnlineOrder] ([TenantId], [OrderStatus]);
GO
CREATE INDEX [IX_OnlineOrder_BizDate] ON [omn].[OnlineOrder] ([BizDate]);
GO
CREATE INDEX [IX_OnlineOrder_MemberId] ON [omn].[OnlineOrder] ([MemberId]);
GO
CREATE INDEX [IX_OnlineOrder_CreatedBy] ON [omn].[OnlineOrder] ([CreatedBy]);
GO
CREATE INDEX [IX_OnlineOrder_ModifiedBy] ON [omn].[OnlineOrder] ([ModifiedBy]);
GO
CREATE INDEX [IX_OnlineOrder_DeletedBy] ON [omn].[OnlineOrder] ([DeletedBy]);
GO
CREATE INDEX [IX_OnlineOrder_ChannelId] ON [omn].[OnlineOrder] ([ChannelId]);
GO
CREATE INDEX [IX_OnlineOrder_PartnerId] ON [omn].[OnlineOrder] ([PartnerId]);
GO
CREATE INDEX [IX_OnlineOrder_RegionId] ON [omn].[OnlineOrder] ([RegionId]);
GO
CREATE INDEX [IX_OnlineOrder_WarehouseId] ON [omn].[OnlineOrder] ([WarehouseId]);
GO
CREATE INDEX [IX_OnlineOrder_StoreId] ON [omn].[OnlineOrder] ([StoreId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'线上订单（全渠道订单池）', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'订单号', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'OrderNo';
EXEC sp_addextendedproperty N'MS_Description', N'渠道', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'ChannelId';
EXEC sp_addextendedproperty N'MS_Description', N'平台订单号', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'PlatformOrderNo';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1B2B订货 2B2C零售 3平台 4自提)', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'OrderType';
EXEC sp_addextendedproperty N'MS_Description', N'客户(批发)', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'会员(零售)', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'MemberId';
EXEC sp_addextendedproperty N'MS_Description', N'收货人', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'ReceiverName';
EXEC sp_addextendedproperty N'MS_Description', N'区域', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'RegionId';
EXEC sp_addextendedproperty N'MS_Description', N'发货仓', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'自提门店', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'StoreId';
EXEC sp_addextendedproperty N'MS_Description', N'0未付 1部分 2已付 3已退', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'PayStatus';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0待审 1已审 2待发 3已发 4已签 5已完成 6已取消 7售后中)', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'OrderStatus';
EXEC sp_addextendedproperty N'MS_Description', N'(1快递 2配送 3自提 4即时)', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'DeliveryType';
EXEC sp_addextendedproperty N'MS_Description', N'买家留言', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'BuyerRemark';
EXEC sp_addextendedproperty N'MS_Description', N'商家备注', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'SellerRemark';
EXEC sp_addextendedproperty N'MS_Description', N'自动审单时间', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'AutoAuditAt';
EXEC sp_addextendedproperty N'MS_Description', N'下游销售单', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrder', N'COLUMN', N'SourceOrderId';
GO
CREATE TABLE [omn].[OnlineOrderItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [OrderId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [PlatformSkuId] varchar(64) NULL,
    [Title] nvarchar(300) NULL,
    [Qty] decimal(19,6) NOT NULL,
    [Price] decimal(19,6) NOT NULL,
    [Amount] decimal(19,4) NOT NULL,
    [DiscountAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_OnlineOrderItem_DiscountAmount] DEFAULT (0),
    [CostPrice] decimal(19,6) NULL,
    [IsGift] bit NOT NULL CONSTRAINT [DF_OnlineOrderItem_IsGift] DEFAULT (0),
    [BatchId] bigint NULL,
    [Remark] nvarchar(200) NULL,
    CONSTRAINT [PK_OnlineOrderItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_OnlineOrderItem_OrderId_LineNo] ON [omn].[OnlineOrderItem] ([OrderId], [LineNo]);
GO
CREATE INDEX [IX_OnlineOrderItem_SkuId] ON [omn].[OnlineOrderItem] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'线上订单明细', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrderItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrderItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrderItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrderItem', N'COLUMN', N'OrderId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrderItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'平台商品Id', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrderItem', N'COLUMN', N'PlatformSkuId';
EXEC sp_addextendedproperty N'MS_Description', N'下单时商品名快照', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrderItem', N'COLUMN', N'Title';
GO
CREATE TABLE [omn].[OnlineOrderPayment] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [OrderId] bigint NOT NULL,
    [PayMethod] tinyint NOT NULL CONSTRAINT [DF_OnlineOrderPayment_PayMethod] DEFAULT (1),
    [Amount] decimal(19,4) NOT NULL,
    [TradeNo] varchar(64) NULL,
    [PayStatus] tinyint NOT NULL CONSTRAINT [DF_OnlineOrderPayment_PayStatus] DEFAULT (0),
    [PaidAt] datetime2(3) NULL,
    [RefundAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_OnlineOrderPayment_RefundAmount] DEFAULT (0),
    CONSTRAINT [PK_OnlineOrderPayment] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_OnlineOrderPayment_OrderId] ON [omn].[OnlineOrderPayment] ([OrderId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'线上支付记录', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrderPayment';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrderPayment', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'(1微信 2支付宝 3网银 4余额 5账期 6货到付款)', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrderPayment', N'COLUMN', N'PayMethod';
EXEC sp_addextendedproperty N'MS_Description', N'第三方交易号', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrderPayment', N'COLUMN', N'TradeNo';
EXEC sp_addextendedproperty N'MS_Description', N'0待支付 1成功 2关闭 3已退', N'SCHEMA', N'omn', N'TABLE', N'OnlineOrderPayment', N'COLUMN', N'PayStatus';
GO
CREATE TABLE [omn].[AfterSale] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_AfterSale_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_AfterSale_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_AfterSale_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_AfterSale_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [AfterSaleNo] varchar(50) NOT NULL,
    [OrderId] bigint NULL,
    [SaleOrderId] bigint NULL,
    [ApplyType] tinyint NOT NULL CONSTRAINT [DF_AfterSale_ApplyType] DEFAULT (1),
    [Reason] nvarchar(200) NULL,
    [ApplyAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_AfterSale_ApplyAmount] DEFAULT (0),
    [RefundAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_AfterSale_RefundAmount] DEFAULT (0),
    [WorkStatus] tinyint NOT NULL CONSTRAINT [DF_AfterSale_WorkStatus] DEFAULT (0) CONSTRAINT [CK_AfterSale_WorkStatus] CHECK (WorkStatus BETWEEN 0 AND 6),
    [AssigneeId] bigint NULL,
    [SlaDueAt] datetime2(3) NULL,
    [FinishedAt] datetime2(3) NULL,
    CONSTRAINT [PK_AfterSale] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_AfterSale_TenantId_AfterSaleNo] ON [omn].[AfterSale] ([TenantId], [AfterSaleNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_AfterSale_OrderId] ON [omn].[AfterSale] ([OrderId]);
GO
CREATE INDEX [IX_AfterSale_WorkStatus] ON [omn].[AfterSale] ([WorkStatus]);
GO
CREATE INDEX [IX_AfterSale_CreatedBy] ON [omn].[AfterSale] ([CreatedBy]);
GO
CREATE INDEX [IX_AfterSale_ModifiedBy] ON [omn].[AfterSale] ([ModifiedBy]);
GO
CREATE INDEX [IX_AfterSale_DeletedBy] ON [omn].[AfterSale] ([DeletedBy]);
GO
CREATE INDEX [IX_AfterSale_AssigneeId] ON [omn].[AfterSale] ([AssigneeId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'售后工单', N'SCHEMA', N'omn', N'TABLE', N'AfterSale';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'原订单', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'OrderId';
EXEC sp_addextendedproperty N'MS_Description', N'销售单', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'SaleOrderId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1仅退款 2退货退款 3换货 4补发)', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'ApplyType';
EXEC sp_addextendedproperty N'MS_Description', N'售后原因', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'Reason';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0待审 1已同意 2待收货 3已收 4退款中 5完成 6拒绝)', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'WorkStatus';
EXEC sp_addextendedproperty N'MS_Description', N'处理人', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'AssigneeId';
EXEC sp_addextendedproperty N'MS_Description', N'处理时限', N'SCHEMA', N'omn', N'TABLE', N'AfterSale', N'COLUMN', N'SlaDueAt';
GO
CREATE TABLE [omn].[AfterSaleItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [AfterSaleId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [OrderItemId] bigint NULL,
    [SkuId] bigint NOT NULL,
    [Qty] decimal(19,6) NOT NULL,
    [Amount] decimal(19,4) NOT NULL,
    [QualityStatus] tinyint NOT NULL CONSTRAINT [DF_AfterSaleItem_QualityStatus] DEFAULT (1),
    CONSTRAINT [PK_AfterSaleItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_AfterSaleItem_AfterSaleId] ON [omn].[AfterSaleItem] ([AfterSaleId]);
GO
CREATE INDEX [IX_AfterSaleItem_OrderItemId] ON [omn].[AfterSaleItem] ([OrderItemId]);
GO
CREATE INDEX [IX_AfterSaleItem_SkuId] ON [omn].[AfterSaleItem] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'售后明细', N'SCHEMA', N'omn', N'TABLE', N'AfterSaleItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'omn', N'TABLE', N'AfterSaleItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'omn', N'TABLE', N'AfterSaleItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'omn', N'TABLE', N'AfterSaleItem', N'COLUMN', N'AfterSaleId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'omn', N'TABLE', N'AfterSaleItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'原订单行', N'SCHEMA', N'omn', N'TABLE', N'AfterSaleItem', N'COLUMN', N'OrderItemId';
EXEC sp_addextendedproperty N'MS_Description', N'1可售 2残次 3报废', N'SCHEMA', N'omn', N'TABLE', N'AfterSaleItem', N'COLUMN', N'QualityStatus';
GO
CREATE TABLE [omn].[ShopConfig] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_ShopConfig_TenantId] DEFAULT (1),
    [Code] varchar(40) NOT NULL,
    [ShopType] tinyint NOT NULL CONSTRAINT [DF_ShopConfig_ShopType] DEFAULT (1),
    [Name] nvarchar(100) NULL,
    [Domain] varchar(100) NULL,
    [AppId] varchar(60) NULL,
    [ThemeJson] nvarchar(max) NULL,
    [PriceMode] tinyint NOT NULL CONSTRAINT [DF_ShopConfig_PriceMode] DEFAULT (1),
    [StockShow] tinyint NOT NULL CONSTRAINT [DF_ShopConfig_StockShow] DEFAULT (1),
    [Status] tinyint NOT NULL CONSTRAINT [DF_ShopConfig_Status] DEFAULT (1),
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_ShopConfig_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_ShopConfig_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_ShopConfig] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ShopConfig_TenantId_Code] ON [omn].[ShopConfig] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_ShopConfig_OrgId] ON [omn].[ShopConfig] ([OrgId]);
GO
CREATE INDEX [IX_ShopConfig_CreatedBy] ON [omn].[ShopConfig] ([CreatedBy]);
GO
CREATE INDEX [IX_ShopConfig_ModifiedBy] ON [omn].[ShopConfig] ([ModifiedBy]);
GO
CREATE INDEX [IX_ShopConfig_DeletedBy] ON [omn].[ShopConfig] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'商城配置（B2B/B2C）', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1B2B订货 2B2C微商城)', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'ShopType';
EXEC sp_addextendedproperty N'MS_Description', N'独立域名', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'Domain';
EXEC sp_addextendedproperty N'MS_Description', N'小程序AppId', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'AppId';
EXEC sp_addextendedproperty N'MS_Description', N'装修配置(首页组件)', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'ThemeJson';
EXEC sp_addextendedproperty N'MS_Description', N'价格展示(1分级 2统一 3隐藏)', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'PriceMode';
EXEC sp_addextendedproperty N'MS_Description', N'库存展示(1准确 2区间 3仅有无)', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'StockShow';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'omn', N'TABLE', N'ShopConfig', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [omn].[ShopProduct] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_ShopProduct_TenantId] DEFAULT (1),
    [ShopConfigId] bigint NOT NULL,
    [SkuId] bigint NOT NULL,
    [Price] decimal(19,6) NULL,
    [MinQty] decimal(19,6) NOT NULL CONSTRAINT [DF_ShopProduct_MinQty] DEFAULT (1),
    [QtyStep] decimal(19,6) NOT NULL CONSTRAINT [DF_ShopProduct_QtyStep] DEFAULT (1),
    [MaxQty] decimal(19,6) NULL,
    [IsOnSale] bit NOT NULL CONSTRAINT [DF_ShopProduct_IsOnSale] DEFAULT (1),
    [Sort] int NOT NULL CONSTRAINT [DF_ShopProduct_Sort] DEFAULT (0),
    [VisibleLevels] varchar(100) NULL,
    [Title] nvarchar(200) NULL,
    [SubTitle] nvarchar(300) NULL,
    [ImagesJson] nvarchar(max) NULL,
    CONSTRAINT [PK_ShopProduct] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ShopProduct_ShopConfigId_SkuId] ON [omn].[ShopProduct] ([ShopConfigId], [SkuId]);
GO
CREATE INDEX [IX_ShopProduct_SkuId] ON [omn].[ShopProduct] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'商城商品', N'SCHEMA', N'omn', N'TABLE', N'ShopProduct';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'omn', N'TABLE', N'ShopProduct', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'商城价', N'SCHEMA', N'omn', N'TABLE', N'ShopProduct', N'COLUMN', N'Price';
EXEC sp_addextendedproperty N'MS_Description', N'起订量', N'SCHEMA', N'omn', N'TABLE', N'ShopProduct', N'COLUMN', N'MinQty';
EXEC sp_addextendedproperty N'MS_Description', N'订货基数', N'SCHEMA', N'omn', N'TABLE', N'ShopProduct', N'COLUMN', N'QtyStep';
EXEC sp_addextendedproperty N'MS_Description', N'限购', N'SCHEMA', N'omn', N'TABLE', N'ShopProduct', N'COLUMN', N'MaxQty';
EXEC sp_addextendedproperty N'MS_Description', N'可见客户等级', N'SCHEMA', N'omn', N'TABLE', N'ShopProduct', N'COLUMN', N'VisibleLevels';
GO
CREATE TABLE [omn].[PlatformGoodsMapping] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_PlatformGoodsMapping_TenantId] DEFAULT (1),
    [ChannelId] bigint NOT NULL,
    [SkuId] bigint NOT NULL,
    [PlatformItemId] varchar(64) NOT NULL,
    [PlatformSkuId] varchar(64) NULL,
    [PlatformTitle] nvarchar(300) NULL,
    [SyncStock] bit NOT NULL CONSTRAINT [DF_PlatformGoodsMapping_SyncStock] DEFAULT (1),
    [SyncPrice] bit NOT NULL CONSTRAINT [DF_PlatformGoodsMapping_SyncPrice] DEFAULT (1),
    [LastSyncAt] datetime2(3) NULL,
    CONSTRAINT [PK_PlatformGoodsMapping] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PlatformGoodsMapping_TenantId_ChannelId_PlatformItemId_PlatformSkuId] ON [omn].[PlatformGoodsMapping] ([TenantId], [ChannelId], [PlatformItemId], [PlatformSkuId]);
GO
CREATE INDEX [IX_PlatformGoodsMapping_ChannelId] ON [omn].[PlatformGoodsMapping] ([ChannelId]);
GO
CREATE INDEX [IX_PlatformGoodsMapping_SkuId] ON [omn].[PlatformGoodsMapping] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'平台商品映射', N'SCHEMA', N'omn', N'TABLE', N'PlatformGoodsMapping';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'omn', N'TABLE', N'PlatformGoodsMapping', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'平台商品Id', N'SCHEMA', N'omn', N'TABLE', N'PlatformGoodsMapping', N'COLUMN', N'PlatformItemId';
EXEC sp_addextendedproperty N'MS_Description', N'平台规格Id', N'SCHEMA', N'omn', N'TABLE', N'PlatformGoodsMapping', N'COLUMN', N'PlatformSkuId';
GO
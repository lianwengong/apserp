/* =====================================================================
   进销存管理系统 V3 · 表结构 · inv 架构（17 张表）
   数据库：APSErpV3   生成器：db/emit.py（请勿手改，改规格文件后重新生成）
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE TABLE [inv].[Stock] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Stock_TenantId] DEFAULT (1),
    [WarehouseId] bigint NOT NULL,
    [LocationId] bigint NOT NULL CONSTRAINT [DF_Stock_LocationId] DEFAULT (0),
    [SkuId] bigint NOT NULL,
    [BatchId] bigint NOT NULL CONSTRAINT [DF_Stock_BatchId] DEFAULT (0),
    [StockStatus] tinyint NOT NULL CONSTRAINT [DF_Stock_StockStatus] DEFAULT (1) CONSTRAINT [CK_Stock_StockStatus] CHECK (StockStatus BETWEEN 1 AND 5),
    [OwnerType] tinyint NOT NULL CONSTRAINT [DF_Stock_OwnerType] DEFAULT (1),
    [OwnerPartnerId] bigint NOT NULL CONSTRAINT [DF_Stock_OwnerPartnerId] DEFAULT (0),
    [Qty] decimal(19,6) NOT NULL CONSTRAINT [DF_Stock_Qty] DEFAULT (0),
    [ReservedQty] decimal(19,6) NOT NULL CONSTRAINT [DF_Stock_ReservedQty] DEFAULT (0),
    [FrozenQty] decimal(19,6) NOT NULL CONSTRAINT [DF_Stock_FrozenQty] DEFAULT (0),
    [InTransitQty] decimal(19,6) NOT NULL CONSTRAINT [DF_Stock_InTransitQty] DEFAULT (0),
    [AvailableQty] AS (Qty - ReservedQty - FrozenQty) PERSISTED,
    [CostPrice] decimal(19,6) NOT NULL CONSTRAINT [DF_Stock_CostPrice] DEFAULT (0),
    [CostAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_Stock_CostAmount] DEFAULT (0),
    [LastInAt] datetime2(3) NULL,
    [LastOutAt] datetime2(3) NULL,
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_Stock] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Stock_TenantId_WarehouseId_LocationId_SkuId_BatchId_StockStatus_OwnerType_OwnerPartnerId] ON [inv].[Stock] ([TenantId], [WarehouseId], [LocationId], [SkuId], [BatchId], [StockStatus], [OwnerType], [OwnerPartnerId]);
GO
CREATE INDEX [IX_Stock_TenantId_SkuId_WarehouseId] ON [inv].[Stock] ([TenantId], [SkuId], [WarehouseId]);
GO
CREATE INDEX [IX_Stock_TenantId_WarehouseId] ON [inv].[Stock] ([TenantId], [WarehouseId]);
GO
CREATE INDEX [IX_Stock_WarehouseId] ON [inv].[Stock] ([WarehouseId]);
GO
CREATE INDEX [IX_Stock_LocationId] ON [inv].[Stock] ([LocationId]);
GO
CREATE INDEX [IX_Stock_SkuId] ON [inv].[Stock] ([SkuId]);
GO
CREATE INDEX [IX_Stock_BatchId] ON [inv].[Stock] ([BatchId]);
GO
CREATE INDEX [IX_Stock_OwnerPartnerId] ON [inv].[Stock] ([OwnerPartnerId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'库存台账（唯一属主）', N'SCHEMA', N'inv', N'TABLE', N'Stock';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'仓库', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'货位(0=未指定)', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'LocationId';
EXEC sp_addextendedproperty N'MS_Description', N'SKU', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'SkuId';
EXEC sp_addextendedproperty N'MS_Description', N'批次(0=无批次)', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'BatchId';
EXEC sp_addextendedproperty N'MS_Description', N'状态(1良品 2待检 3残次 4报废 5冻结)', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'StockStatus';
EXEC sp_addextendedproperty N'MS_Description', N'所有权(1自有 2供应商寄售 3客户寄售)', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'OwnerType';
EXEC sp_addextendedproperty N'MS_Description', N'货主(0=自有)', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'OwnerPartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'现存量(基本单位)', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'Qty';
EXEC sp_addextendedproperty N'MS_Description', N'占用(订单/拣货锁定)', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'ReservedQty';
EXEC sp_addextendedproperty N'MS_Description', N'冻结(质量/盘点)', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'FrozenQty';
EXEC sp_addextendedproperty N'MS_Description', N'在途(调拨)', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'InTransitQty';
EXEC sp_addextendedproperty N'MS_Description', N'可用量(计算列,唯一口径)', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'AvailableQty';
EXEC sp_addextendedproperty N'MS_Description', N'结存单价', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'CostPrice';
EXEC sp_addextendedproperty N'MS_Description', N'结存金额', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'CostAmount';
EXEC sp_addextendedproperty N'MS_Description', N'最近入库', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'LastInAt';
EXEC sp_addextendedproperty N'MS_Description', N'最近出库', N'SCHEMA', N'inv', N'TABLE', N'Stock', N'COLUMN', N'LastOutAt';
GO
CREATE TABLE [inv].[StockLedger] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_StockLedger_TenantId] DEFAULT (1),
    [WarehouseId] bigint NOT NULL,
    [LocationId] bigint NULL,
    [SkuId] bigint NOT NULL,
    [BatchId] bigint NULL,
    [StockStatus] tinyint NOT NULL CONSTRAINT [DF_StockLedger_StockStatus] DEFAULT (1),
    [Direction] tinyint NOT NULL,
    [BizType] varchar(30) NOT NULL,
    [SourceType] varchar(40) NULL,
    [SourceId] bigint NULL,
    [SourceNo] varchar(40) NULL,
    [Qty] decimal(19,6) NOT NULL,
    [UnitCost] decimal(19,6) NULL,
    [Amount] decimal(19,4) NULL,
    [BalanceQty] decimal(19,6) NULL,
    [BalanceAmount] decimal(19,4) NULL,
    [BizDate] date NOT NULL,
    [At] datetime2(3) NOT NULL CONSTRAINT [DF_StockLedger_At] DEFAULT (sysutcdatetime()),
    [OperatorId] bigint NULL,
    CONSTRAINT [PK_StockLedger] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_StockLedger_TenantId_SkuId_BizDate] ON [inv].[StockLedger] ([TenantId], [SkuId], [BizDate]);
GO
CREATE INDEX [IX_StockLedger_SourceType_SourceId] ON [inv].[StockLedger] ([SourceType], [SourceId]);
GO
CREATE INDEX [IX_StockLedger_WarehouseId_BizDate] ON [inv].[StockLedger] ([WarehouseId], [BizDate]);
GO
CREATE INDEX [IX_StockLedger_LocationId] ON [inv].[StockLedger] ([LocationId]);
GO
CREATE INDEX [IX_StockLedger_SkuId] ON [inv].[StockLedger] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'库存流水（收发存）', N'SCHEMA', N'inv', N'TABLE', N'StockLedger';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'StockLedger', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'批次', N'SCHEMA', N'inv', N'TABLE', N'StockLedger', N'COLUMN', N'BatchId';
EXEC sp_addextendedproperty N'MS_Description', N'方向(1入 2出)', N'SCHEMA', N'inv', N'TABLE', N'StockLedger', N'COLUMN', N'Direction';
EXEC sp_addextendedproperty N'MS_Description', N'业务类型(采购入库/销售出库/调拨/盘盈亏/报损/调整)', N'SCHEMA', N'inv', N'TABLE', N'StockLedger', N'COLUMN', N'BizType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'inv', N'TABLE', N'StockLedger', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'inv', N'TABLE', N'StockLedger', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'来源单号', N'SCHEMA', N'inv', N'TABLE', N'StockLedger', N'COLUMN', N'SourceNo';
EXEC sp_addextendedproperty N'MS_Description', N'数量', N'SCHEMA', N'inv', N'TABLE', N'StockLedger', N'COLUMN', N'Qty';
EXEC sp_addextendedproperty N'MS_Description', N'单位成本', N'SCHEMA', N'inv', N'TABLE', N'StockLedger', N'COLUMN', N'UnitCost';
EXEC sp_addextendedproperty N'MS_Description', N'金额', N'SCHEMA', N'inv', N'TABLE', N'StockLedger', N'COLUMN', N'Amount';
EXEC sp_addextendedproperty N'MS_Description', N'结存数量', N'SCHEMA', N'inv', N'TABLE', N'StockLedger', N'COLUMN', N'BalanceQty';
EXEC sp_addextendedproperty N'MS_Description', N'结存金额', N'SCHEMA', N'inv', N'TABLE', N'StockLedger', N'COLUMN', N'BalanceAmount';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'inv', N'TABLE', N'StockLedger', N'COLUMN', N'BizDate';
GO
CREATE TABLE [inv].[StockReservation] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_StockReservation_TenantId] DEFAULT (1),
    [StockId] bigint NULL,
    [SkuId] bigint NOT NULL,
    [WarehouseId] bigint NOT NULL,
    [SourceType] varchar(40) NOT NULL,
    [SourceId] bigint NOT NULL,
    [Qty] decimal(19,6) NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_StockReservation_Status] DEFAULT (0),
    [ExpireAt] datetime2(3) NULL,
    CONSTRAINT [PK_StockReservation] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_StockReservation_SourceType_SourceId] ON [inv].[StockReservation] ([SourceType], [SourceId]);
GO
CREATE INDEX [IX_StockReservation_SkuId_Status] ON [inv].[StockReservation] ([SkuId], [Status]);
GO
CREATE INDEX [IX_StockReservation_StockId] ON [inv].[StockReservation] ([StockId]);
GO
CREATE INDEX [IX_StockReservation_WarehouseId] ON [inv].[StockReservation] ([WarehouseId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'库存占用', N'SCHEMA', N'inv', N'TABLE', N'StockReservation';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'StockReservation', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'台账行', N'SCHEMA', N'inv', N'TABLE', N'StockReservation', N'COLUMN', N'StockId';
EXEC sp_addextendedproperty N'MS_Description', N'占用来源(销售订单/拣货任务/调拨)', N'SCHEMA', N'inv', N'TABLE', N'StockReservation', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'占用数量', N'SCHEMA', N'inv', N'TABLE', N'StockReservation', N'COLUMN', N'Qty';
EXEC sp_addextendedproperty N'MS_Description', N'0占用中 1已释放 2已转出库', N'SCHEMA', N'inv', N'TABLE', N'StockReservation', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'自动释放时间', N'SCHEMA', N'inv', N'TABLE', N'StockReservation', N'COLUMN', N'ExpireAt';
GO
CREATE TABLE [inv].[Batch] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Batch_TenantId] DEFAULT (1),
    [BatchNo] varchar(50) NOT NULL,
    [SkuId] bigint NOT NULL,
    [ProduceDate] date NULL,
    [ExpireDate] date NULL,
    [SupplierId] bigint NULL,
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [CostPrice] decimal(19,6) NULL,
    [QcStatus] tinyint NOT NULL CONSTRAINT [DF_Batch_QcStatus] DEFAULT (1),
    [Remark] nvarchar(200) NULL,
    CONSTRAINT [PK_Batch] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Batch_TenantId_SkuId_BatchNo] ON [inv].[Batch] ([TenantId], [SkuId], [BatchNo]);
GO
CREATE INDEX [IX_Batch_ExpireDate] ON [inv].[Batch] ([ExpireDate]);
GO
CREATE INDEX [IX_Batch_SkuId] ON [inv].[Batch] ([SkuId]);
GO
CREATE INDEX [IX_Batch_SupplierId] ON [inv].[Batch] ([SupplierId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'批次', N'SCHEMA', N'inv', N'TABLE', N'Batch';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'Batch', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'批号', N'SCHEMA', N'inv', N'TABLE', N'Batch', N'COLUMN', N'BatchNo';
EXEC sp_addextendedproperty N'MS_Description', N'生产日期', N'SCHEMA', N'inv', N'TABLE', N'Batch', N'COLUMN', N'ProduceDate';
EXEC sp_addextendedproperty N'MS_Description', N'到期日', N'SCHEMA', N'inv', N'TABLE', N'Batch', N'COLUMN', N'ExpireDate';
EXEC sp_addextendedproperty N'MS_Description', N'来源供应商', N'SCHEMA', N'inv', N'TABLE', N'Batch', N'COLUMN', N'SupplierId';
EXEC sp_addextendedproperty N'MS_Description', N'来源(采购入库/调拨/期初)', N'SCHEMA', N'inv', N'TABLE', N'Batch', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'批次成本', N'SCHEMA', N'inv', N'TABLE', N'Batch', N'COLUMN', N'CostPrice';
EXEC sp_addextendedproperty N'MS_Description', N'1合格 2待检 3不合格', N'SCHEMA', N'inv', N'TABLE', N'Batch', N'COLUMN', N'QcStatus';
GO
CREATE TABLE [inv].[SerialNumber] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_SerialNumber_TenantId] DEFAULT (1),
    [SkuId] bigint NOT NULL,
    [SerialNo] varchar(80) NOT NULL,
    [BatchId] bigint NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_SerialNumber_Status] DEFAULT (1),
    [InSourceType] varchar(30) NULL,
    [InSourceId] bigint NULL,
    [InAt] datetime2(3) NULL,
    [OutSourceType] varchar(30) NULL,
    [OutSourceId] bigint NULL,
    [OutAt] datetime2(3) NULL,
    [CustomerId] bigint NULL,
    CONSTRAINT [PK_SerialNumber] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_SerialNumber_TenantId_SerialNo] ON [inv].[SerialNumber] ([TenantId], [SerialNo]);
GO
CREATE INDEX [IX_SerialNumber_SkuId_Status] ON [inv].[SerialNumber] ([SkuId], [Status]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'序列号', N'SCHEMA', N'inv', N'TABLE', N'SerialNumber';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'SerialNumber', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'批次', N'SCHEMA', N'inv', N'TABLE', N'SerialNumber', N'COLUMN', N'BatchId';
EXEC sp_addextendedproperty N'MS_Description', N'1在库 2已出库 3已退 4锁定', N'SCHEMA', N'inv', N'TABLE', N'SerialNumber', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'销售客户', N'SCHEMA', N'inv', N'TABLE', N'SerialNumber', N'COLUMN', N'CustomerId';
GO
CREATE TABLE [inv].[TransferOrder] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_TransferOrder_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_TransferOrder_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_TransferOrder_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_TransferOrder_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [FromWarehouseId] bigint NOT NULL,
    [ToWarehouseId] bigint NOT NULL,
    [TransferType] tinyint NOT NULL CONSTRAINT [DF_TransferOrder_TransferType] DEFAULT (1),
    [StoreId] bigint NULL,
    [TotalQty] decimal(19,6) NOT NULL CONSTRAINT [DF_TransferOrder_TotalQty] DEFAULT (0),
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_TransferOrder_TotalAmount] DEFAULT (0),
    [FeeAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_TransferOrder_FeeAmount] DEFAULT (0),
    [OutAt] datetime2(3) NULL,
    [InAt] datetime2(3) NULL,
    CONSTRAINT [PK_TransferOrder] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_TransferOrder_TenantId_DocNo] ON [inv].[TransferOrder] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_TransferOrder_Status_BizDate] ON [inv].[TransferOrder] ([Status], [BizDate]);
GO
CREATE INDEX [IX_TransferOrder_OrgId] ON [inv].[TransferOrder] ([OrgId]);
GO
CREATE INDEX [IX_TransferOrder_CreatedBy] ON [inv].[TransferOrder] ([CreatedBy]);
GO
CREATE INDEX [IX_TransferOrder_ModifiedBy] ON [inv].[TransferOrder] ([ModifiedBy]);
GO
CREATE INDEX [IX_TransferOrder_DeletedBy] ON [inv].[TransferOrder] ([DeletedBy]);
GO
CREATE INDEX [IX_TransferOrder_FromWarehouseId] ON [inv].[TransferOrder] ([FromWarehouseId]);
GO
CREATE INDEX [IX_TransferOrder_ToWarehouseId] ON [inv].[TransferOrder] ([ToWarehouseId]);
GO
CREATE INDEX [IX_TransferOrder_StoreId] ON [inv].[TransferOrder] ([StoreId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'库存调拨单', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'调出仓', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'FromWarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'调入仓', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'ToWarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1仓间调拨 2门店配货 3门店间 4退货调拨)', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'TransferType';
EXEC sp_addextendedproperty N'MS_Description', N'门店', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'StoreId';
EXEC sp_addextendedproperty N'MS_Description', N'调拨费用', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'FeeAmount';
EXEC sp_addextendedproperty N'MS_Description', N'出库时间', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'OutAt';
EXEC sp_addextendedproperty N'MS_Description', N'入库时间', N'SCHEMA', N'inv', N'TABLE', N'TransferOrder', N'COLUMN', N'InAt';
GO
CREATE TABLE [inv].[TransferOrderItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [TransferId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [UnitId] bigint NULL,
    [Qty] decimal(19,6) NOT NULL,
    [OutQty] decimal(19,6) NOT NULL CONSTRAINT [DF_TransferOrderItem_OutQty] DEFAULT (0),
    [InQty] decimal(19,6) NOT NULL CONSTRAINT [DF_TransferOrderItem_InQty] DEFAULT (0),
    [CostPrice] decimal(19,6) NULL,
    [Amount] decimal(19,4) NULL,
    [FromLocationId] bigint NULL,
    [ToLocationId] bigint NULL,
    [BatchId] bigint NULL,
    CONSTRAINT [PK_TransferOrderItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_TransferOrderItem_TransferId_LineNo] ON [inv].[TransferOrderItem] ([TransferId], [LineNo]);
GO
CREATE INDEX [IX_TransferOrderItem_SkuId] ON [inv].[TransferOrderItem] ([SkuId]);
GO
CREATE INDEX [IX_TransferOrderItem_UnitId] ON [inv].[TransferOrderItem] ([UnitId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'调拨明细', N'SCHEMA', N'inv', N'TABLE', N'TransferOrderItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'TransferOrderItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'inv', N'TABLE', N'TransferOrderItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'inv', N'TABLE', N'TransferOrderItem', N'COLUMN', N'TransferId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'inv', N'TABLE', N'TransferOrderItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'实际出库', N'SCHEMA', N'inv', N'TABLE', N'TransferOrderItem', N'COLUMN', N'OutQty';
EXEC sp_addextendedproperty N'MS_Description', N'实际入库', N'SCHEMA', N'inv', N'TABLE', N'TransferOrderItem', N'COLUMN', N'InQty';
EXEC sp_addextendedproperty N'MS_Description', N'调出货位', N'SCHEMA', N'inv', N'TABLE', N'TransferOrderItem', N'COLUMN', N'FromLocationId';
EXEC sp_addextendedproperty N'MS_Description', N'调入货位', N'SCHEMA', N'inv', N'TABLE', N'TransferOrderItem', N'COLUMN', N'ToLocationId';
EXEC sp_addextendedproperty N'MS_Description', N'批次', N'SCHEMA', N'inv', N'TABLE', N'TransferOrderItem', N'COLUMN', N'BatchId';
GO
CREATE TABLE [inv].[StockDocument] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_StockDocument_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_StockDocument_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_StockDocument_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_StockDocument_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [DocCategory] tinyint NOT NULL CONSTRAINT [DF_StockDocument_DocCategory] DEFAULT (1) CONSTRAINT [CK_StockDocument_DocCategory] CHECK (DocCategory BETWEEN 1 AND 6),
    [WarehouseId] bigint NOT NULL,
    [PartnerId] bigint NULL,
    [ReasonType] tinyint NULL,
    [TotalQty] decimal(19,6) NOT NULL CONSTRAINT [DF_StockDocument_TotalQty] DEFAULT (0),
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_StockDocument_TotalAmount] DEFAULT (0),
    [PostedAt] datetime2(3) NULL,
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    CONSTRAINT [PK_StockDocument] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_StockDocument_TenantId_DocNo] ON [inv].[StockDocument] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_StockDocument_DocCategory_Status] ON [inv].[StockDocument] ([DocCategory], [Status]);
GO
CREATE INDEX [IX_StockDocument_OrgId] ON [inv].[StockDocument] ([OrgId]);
GO
CREATE INDEX [IX_StockDocument_CreatedBy] ON [inv].[StockDocument] ([CreatedBy]);
GO
CREATE INDEX [IX_StockDocument_ModifiedBy] ON [inv].[StockDocument] ([ModifiedBy]);
GO
CREATE INDEX [IX_StockDocument_DeletedBy] ON [inv].[StockDocument] ([DeletedBy]);
GO
CREATE INDEX [IX_StockDocument_WarehouseId] ON [inv].[StockDocument] ([WarehouseId]);
GO
CREATE INDEX [IX_StockDocument_PartnerId] ON [inv].[StockDocument] ([PartnerId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'库存内部单据（报损/调整/借出/寄售）', N'SCHEMA', N'inv', N'TABLE', N'StockDocument';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'类别(1报损 2调整 3借出 4借入 5寄售 6其他出入库)', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'DocCategory';
EXEC sp_addextendedproperty N'MS_Description', N'往来单位(借出/寄售)', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'原因类型', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'ReasonType';
EXEC sp_addextendedproperty N'MS_Description', N'过账时间', N'SCHEMA', N'inv', N'TABLE', N'StockDocument', N'COLUMN', N'PostedAt';
GO
CREATE TABLE [inv].[StockDocumentItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [DocumentId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [Qty] decimal(19,6) NOT NULL,
    [CostPrice] decimal(19,6) NULL,
    [Amount] decimal(19,4) NULL,
    [BatchId] bigint NULL,
    [LocationId] bigint NULL,
    [StockStatus] tinyint NULL,
    [Reason] nvarchar(200) NULL,
    CONSTRAINT [PK_StockDocumentItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_StockDocumentItem_DocumentId_LineNo] ON [inv].[StockDocumentItem] ([DocumentId], [LineNo]);
GO
CREATE INDEX [IX_StockDocumentItem_SkuId] ON [inv].[StockDocumentItem] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'内部单据明细', N'SCHEMA', N'inv', N'TABLE', N'StockDocumentItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'StockDocumentItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'inv', N'TABLE', N'StockDocumentItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'inv', N'TABLE', N'StockDocumentItem', N'COLUMN', N'DocumentId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'inv', N'TABLE', N'StockDocumentItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'货位', N'SCHEMA', N'inv', N'TABLE', N'StockDocumentItem', N'COLUMN', N'LocationId';
EXEC sp_addextendedproperty N'MS_Description', N'库存状态', N'SCHEMA', N'inv', N'TABLE', N'StockDocumentItem', N'COLUMN', N'StockStatus';
GO
CREATE TABLE [inv].[CountPlan] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_CountPlan_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_CountPlan_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_CountPlan_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_CountPlan_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [WarehouseId] bigint NOT NULL,
    [CountType] tinyint NOT NULL CONSTRAINT [DF_CountPlan_CountType] DEFAULT (1),
    [ZoneId] bigint NULL,
    [CategoryId] bigint NULL,
    [IsBlind] bit NOT NULL CONSTRAINT [DF_CountPlan_IsBlind] DEFAULT (1),
    [FreezeStock] bit NOT NULL CONSTRAINT [DF_CountPlan_FreezeStock] DEFAULT (1),
    [BeginAt] datetime2(3) NULL,
    [EndAt] datetime2(3) NULL,
    [PostedAt] datetime2(3) NULL,
    CONSTRAINT [PK_CountPlan] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_CountPlan_TenantId_DocNo] ON [inv].[CountPlan] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_CountPlan_OrgId] ON [inv].[CountPlan] ([OrgId]);
GO
CREATE INDEX [IX_CountPlan_CreatedBy] ON [inv].[CountPlan] ([CreatedBy]);
GO
CREATE INDEX [IX_CountPlan_ModifiedBy] ON [inv].[CountPlan] ([ModifiedBy]);
GO
CREATE INDEX [IX_CountPlan_DeletedBy] ON [inv].[CountPlan] ([DeletedBy]);
GO
CREATE INDEX [IX_CountPlan_WarehouseId] ON [inv].[CountPlan] ([WarehouseId]);
GO
CREATE INDEX [IX_CountPlan_ZoneId] ON [inv].[CountPlan] ([ZoneId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'盘点计划', N'SCHEMA', N'inv', N'TABLE', N'CountPlan';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1全盘 2循环盘点 3抽盘 4动碰盘点)', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'CountType';
EXEC sp_addextendedproperty N'MS_Description', N'库区', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'ZoneId';
EXEC sp_addextendedproperty N'MS_Description', N'品类范围', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'CategoryId';
EXEC sp_addextendedproperty N'MS_Description', N'盲盘(不显示账面)', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'IsBlind';
EXEC sp_addextendedproperty N'MS_Description', N'冻结库存', N'SCHEMA', N'inv', N'TABLE', N'CountPlan', N'COLUMN', N'FreezeStock';
GO
CREATE TABLE [inv].[CountTask] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_CountTask_TenantId] DEFAULT (1),
    [PlanId] bigint NOT NULL,
    [TaskNo] varchar(40) NOT NULL,
    [WarehouseId] bigint NOT NULL,
    [ZoneId] bigint NULL,
    [LocationId] bigint NULL,
    [AssigneeId] bigint NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_CountTask_Status] DEFAULT (0),
    [BeginAt] datetime2(3) NULL,
    [EndAt] datetime2(3) NULL,
    CONSTRAINT [PK_CountTask] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_CountTask_TenantId_TaskNo] ON [inv].[CountTask] ([TenantId], [TaskNo]);
GO
CREATE INDEX [IX_CountTask_PlanId_Status] ON [inv].[CountTask] ([PlanId], [Status]);
GO
CREATE INDEX [IX_CountTask_AssigneeId] ON [inv].[CountTask] ([AssigneeId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'盘点任务', N'SCHEMA', N'inv', N'TABLE', N'CountTask';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'CountTask', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'库区', N'SCHEMA', N'inv', N'TABLE', N'CountTask', N'COLUMN', N'ZoneId';
EXEC sp_addextendedproperty N'MS_Description', N'货位', N'SCHEMA', N'inv', N'TABLE', N'CountTask', N'COLUMN', N'LocationId';
EXEC sp_addextendedproperty N'MS_Description', N'盘点人', N'SCHEMA', N'inv', N'TABLE', N'CountTask', N'COLUMN', N'AssigneeId';
EXEC sp_addextendedproperty N'MS_Description', N'0待盘 1盘点中 2已完成 3已复核', N'SCHEMA', N'inv', N'TABLE', N'CountTask', N'COLUMN', N'Status';
GO
CREATE TABLE [inv].[CountItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TaskId] bigint NOT NULL,
    [SkuId] bigint NOT NULL,
    [BatchId] bigint NULL,
    [LocationId] bigint NULL,
    [BookQty] decimal(19,6) NULL,
    [CountQty] decimal(19,6) NULL,
    [DiffQty] AS (CountQty - BookQty),
    [CostPrice] decimal(19,6) NULL,
    [DiffAmount] decimal(19,4) NULL,
    [IsRecount] bit NOT NULL CONSTRAINT [DF_CountItem_IsRecount] DEFAULT (0),
    [Remark] nvarchar(200) NULL,
    CONSTRAINT [PK_CountItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_CountItem_TaskId] ON [inv].[CountItem] ([TaskId]);
GO
CREATE INDEX [IX_CountItem_SkuId] ON [inv].[CountItem] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'盘点明细', N'SCHEMA', N'inv', N'TABLE', N'CountItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'CountItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'批次', N'SCHEMA', N'inv', N'TABLE', N'CountItem', N'COLUMN', N'BatchId';
EXEC sp_addextendedproperty N'MS_Description', N'货位', N'SCHEMA', N'inv', N'TABLE', N'CountItem', N'COLUMN', N'LocationId';
EXEC sp_addextendedproperty N'MS_Description', N'账面数量', N'SCHEMA', N'inv', N'TABLE', N'CountItem', N'COLUMN', N'BookQty';
EXEC sp_addextendedproperty N'MS_Description', N'实盘数量', N'SCHEMA', N'inv', N'TABLE', N'CountItem', N'COLUMN', N'CountQty';
EXEC sp_addextendedproperty N'MS_Description', N'差异', N'SCHEMA', N'inv', N'TABLE', N'CountItem', N'COLUMN', N'DiffQty';
EXEC sp_addextendedproperty N'MS_Description', N'差异金额', N'SCHEMA', N'inv', N'TABLE', N'CountItem', N'COLUMN', N'DiffAmount';
EXEC sp_addextendedproperty N'MS_Description', N'已复盘', N'SCHEMA', N'inv', N'TABLE', N'CountItem', N'COLUMN', N'IsRecount';
GO
CREATE TABLE [inv].[Wave] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Wave_TenantId] DEFAULT (1),
    [WaveNo] varchar(40) NOT NULL,
    [WarehouseId] bigint NOT NULL,
    [WaveType] tinyint NOT NULL CONSTRAINT [DF_Wave_WaveType] DEFAULT (1),
    [RouteId] bigint NULL,
    [OrderCount] int NOT NULL CONSTRAINT [DF_Wave_OrderCount] DEFAULT (0),
    [ItemCount] int NOT NULL CONSTRAINT [DF_Wave_ItemCount] DEFAULT (0),
    [Status] tinyint NOT NULL CONSTRAINT [DF_Wave_Status] DEFAULT (0),
    [AssigneeId] bigint NULL,
    [BeginAt] datetime2(3) NULL,
    [EndAt] datetime2(3) NULL,
    CONSTRAINT [PK_Wave] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Wave_TenantId_WaveNo] ON [inv].[Wave] ([TenantId], [WaveNo]);
GO
CREATE INDEX [IX_Wave_Status] ON [inv].[Wave] ([Status]);
GO
CREATE INDEX [IX_Wave_WarehouseId] ON [inv].[Wave] ([WarehouseId]);
GO
CREATE INDEX [IX_Wave_RouteId] ON [inv].[Wave] ([RouteId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'波次', N'SCHEMA', N'inv', N'TABLE', N'Wave';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'Wave', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1按线路 2按时效 3按客户 4按承运商)', N'SCHEMA', N'inv', N'TABLE', N'Wave', N'COLUMN', N'WaveType';
EXEC sp_addextendedproperty N'MS_Description', N'线路', N'SCHEMA', N'inv', N'TABLE', N'Wave', N'COLUMN', N'RouteId';
EXEC sp_addextendedproperty N'MS_Description', N'0待分配 1拣货中 2已拣完 3已复核 4已发运', N'SCHEMA', N'inv', N'TABLE', N'Wave', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'拣货员', N'SCHEMA', N'inv', N'TABLE', N'Wave', N'COLUMN', N'AssigneeId';
GO
CREATE TABLE [inv].[PickTask] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_PickTask_TenantId] DEFAULT (1),
    [TaskNo] varchar(40) NOT NULL,
    [WaveId] bigint NULL,
    [SourceType] varchar(40) NULL,
    [SourceId] bigint NULL,
    [SourceNo] varchar(40) NULL,
    [WarehouseId] bigint NOT NULL,
    [PickType] tinyint NOT NULL CONSTRAINT [DF_PickTask_PickType] DEFAULT (1),
    [AssigneeId] bigint NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_PickTask_Status] DEFAULT (0),
    [BeginAt] datetime2(3) NULL,
    [EndAt] datetime2(3) NULL,
    CONSTRAINT [PK_PickTask] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PickTask_TenantId_TaskNo] ON [inv].[PickTask] ([TenantId], [TaskNo]);
GO
CREATE INDEX [IX_PickTask_WaveId_Status] ON [inv].[PickTask] ([WaveId], [Status]);
GO
CREATE INDEX [IX_PickTask_SourceType_SourceId] ON [inv].[PickTask] ([SourceType], [SourceId]);
GO
CREATE INDEX [IX_PickTask_AssigneeId] ON [inv].[PickTask] ([AssigneeId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'拣货任务', N'SCHEMA', N'inv', N'TABLE', N'PickTask';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'PickTask', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'波次', N'SCHEMA', N'inv', N'TABLE', N'PickTask', N'COLUMN', N'WaveId';
EXEC sp_addextendedproperty N'MS_Description', N'来源(销售出库/调拨/其他)', N'SCHEMA', N'inv', N'TABLE', N'PickTask', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'方式(1摘果 2播种 3边拣边分)', N'SCHEMA', N'inv', N'TABLE', N'PickTask', N'COLUMN', N'PickType';
EXEC sp_addextendedproperty N'MS_Description', N'拣货员', N'SCHEMA', N'inv', N'TABLE', N'PickTask', N'COLUMN', N'AssigneeId';
EXEC sp_addextendedproperty N'MS_Description', N'0待拣 1拣货中 2已拣 3短拣 4已复核', N'SCHEMA', N'inv', N'TABLE', N'PickTask', N'COLUMN', N'Status';
GO
CREATE TABLE [inv].[PickTaskItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TaskId] bigint NOT NULL,
    [SkuId] bigint NOT NULL,
    [LocationId] bigint NULL,
    [BatchId] bigint NULL,
    [PlanQty] decimal(19,6) NOT NULL,
    [PickedQty] decimal(19,6) NOT NULL CONSTRAINT [DF_PickTaskItem_PickedQty] DEFAULT (0),
    [ShortQty] AS (PlanQty - PickedQty),
    [SortPath] int NULL,
    CONSTRAINT [PK_PickTaskItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_PickTaskItem_TaskId] ON [inv].[PickTaskItem] ([TaskId]);
GO
CREATE INDEX [IX_PickTaskItem_SkuId] ON [inv].[PickTaskItem] ([SkuId]);
GO
CREATE INDEX [IX_PickTaskItem_LocationId] ON [inv].[PickTaskItem] ([LocationId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'拣货明细', N'SCHEMA', N'inv', N'TABLE', N'PickTaskItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'PickTaskItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'货位', N'SCHEMA', N'inv', N'TABLE', N'PickTaskItem', N'COLUMN', N'LocationId';
EXEC sp_addextendedproperty N'MS_Description', N'批次', N'SCHEMA', N'inv', N'TABLE', N'PickTaskItem', N'COLUMN', N'BatchId';
EXEC sp_addextendedproperty N'MS_Description', N'应拣', N'SCHEMA', N'inv', N'TABLE', N'PickTaskItem', N'COLUMN', N'PlanQty';
EXEC sp_addextendedproperty N'MS_Description', N'已拣', N'SCHEMA', N'inv', N'TABLE', N'PickTaskItem', N'COLUMN', N'PickedQty';
EXEC sp_addextendedproperty N'MS_Description', N'短拣', N'SCHEMA', N'inv', N'TABLE', N'PickTaskItem', N'COLUMN', N'ShortQty';
EXEC sp_addextendedproperty N'MS_Description', N'拣货路径序号', N'SCHEMA', N'inv', N'TABLE', N'PickTaskItem', N'COLUMN', N'SortPath';
GO
CREATE TABLE [inv].[MoveTask] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_MoveTask_TenantId] DEFAULT (1),
    [TaskNo] varchar(40) NOT NULL,
    [TaskType] tinyint NOT NULL CONSTRAINT [DF_MoveTask_TaskType] DEFAULT (1),
    [WarehouseId] bigint NOT NULL,
    [SkuId] bigint NOT NULL,
    [FromLocationId] bigint NULL,
    [ToLocationId] bigint NULL,
    [Qty] decimal(19,6) NOT NULL,
    [BatchId] bigint NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_MoveTask_Status] DEFAULT (0),
    [AssigneeId] bigint NULL,
    [FinishedAt] datetime2(3) NULL,
    CONSTRAINT [PK_MoveTask] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_MoveTask_TenantId_TaskNo] ON [inv].[MoveTask] ([TenantId], [TaskNo]);
GO
CREATE INDEX [IX_MoveTask_SkuId] ON [inv].[MoveTask] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'库内移位/补货任务', N'SCHEMA', N'inv', N'TABLE', N'MoveTask';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'MoveTask', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1移位 2补货 3冻结 4解冻)', N'SCHEMA', N'inv', N'TABLE', N'MoveTask', N'COLUMN', N'TaskType';
EXEC sp_addextendedproperty N'MS_Description', N'源货位', N'SCHEMA', N'inv', N'TABLE', N'MoveTask', N'COLUMN', N'FromLocationId';
EXEC sp_addextendedproperty N'MS_Description', N'目标货位', N'SCHEMA', N'inv', N'TABLE', N'MoveTask', N'COLUMN', N'ToLocationId';
EXEC sp_addextendedproperty N'MS_Description', N'0待执行 1已完成 2已取消', N'SCHEMA', N'inv', N'TABLE', N'MoveTask', N'COLUMN', N'Status';
GO
CREATE TABLE [inv].[StockAlert] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_StockAlert_TenantId] DEFAULT (1),
    [AlertType] tinyint NOT NULL CONSTRAINT [DF_StockAlert_AlertType] DEFAULT (1) CONSTRAINT [CK_StockAlert_AlertType] CHECK (AlertType BETWEEN 1 AND 6),
    [WarehouseId] bigint NULL,
    [SkuId] bigint NOT NULL,
    [BatchId] bigint NULL,
    [CurrentQty] decimal(19,6) NULL,
    [ThresholdQty] decimal(19,6) NULL,
    [Level] tinyint NOT NULL CONSTRAINT [DF_StockAlert_Level] DEFAULT (1),
    [Status] tinyint NOT NULL CONSTRAINT [DF_StockAlert_Status] DEFAULT (0),
    [HandledBy] bigint NULL,
    [HandledAt] datetime2(3) NULL,
    [HandleNote] nvarchar(300) NULL,
    [At] datetime2(3) NOT NULL CONSTRAINT [DF_StockAlert_At] DEFAULT (sysutcdatetime()),
    CONSTRAINT [PK_StockAlert] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_StockAlert_TenantId_Status_Level] ON [inv].[StockAlert] ([TenantId], [Status], [Level]);
GO
CREATE INDEX [IX_StockAlert_SkuId] ON [inv].[StockAlert] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'库存预警', N'SCHEMA', N'inv', N'TABLE', N'StockAlert';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'inv', N'TABLE', N'StockAlert', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1低于下限 2高于上限 3临期 4已过期 5呆滞 6断货)', N'SCHEMA', N'inv', N'TABLE', N'StockAlert', N'COLUMN', N'AlertType';
EXEC sp_addextendedproperty N'MS_Description', N'仓库', N'SCHEMA', N'inv', N'TABLE', N'StockAlert', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'批次(效期预警)', N'SCHEMA', N'inv', N'TABLE', N'StockAlert', N'COLUMN', N'BatchId';
EXEC sp_addextendedproperty N'MS_Description', N'当前数量', N'SCHEMA', N'inv', N'TABLE', N'StockAlert', N'COLUMN', N'CurrentQty';
EXEC sp_addextendedproperty N'MS_Description', N'阈值', N'SCHEMA', N'inv', N'TABLE', N'StockAlert', N'COLUMN', N'ThresholdQty';
EXEC sp_addextendedproperty N'MS_Description', N'级别(1提示 2警告 3严重)', N'SCHEMA', N'inv', N'TABLE', N'StockAlert', N'COLUMN', N'Level';
EXEC sp_addextendedproperty N'MS_Description', N'0未处理 1已处理 2已忽略', N'SCHEMA', N'inv', N'TABLE', N'StockAlert', N'COLUMN', N'Status';
GO
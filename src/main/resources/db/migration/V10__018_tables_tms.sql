/* =====================================================================
   进销存管理系统 V3 · 表结构 · tms 架构（9 张表）
   数据库：APSErpV3   生成器：db/emit.py（请勿手改，改规格文件后重新生成）
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE TABLE [tms].[DeliveryTask] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_DeliveryTask_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_DeliveryTask_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_DeliveryTask_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_DeliveryTask_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [TaskNo] varchar(40) NOT NULL,
    [WarehouseId] bigint NULL,
    [RouteId] bigint NULL,
    [RegionId] bigint NULL,
    [PartnerId] bigint NULL,
    [AddressId] bigint NULL,
    [PlanDate] date NOT NULL,
    [TimeWindow] varchar(30) NULL,
    [TotalQty] decimal(19,6) NOT NULL CONSTRAINT [DF_DeliveryTask_TotalQty] DEFAULT (0),
    [TotalVolume] decimal(19,6) NULL,
    [TotalWeight] decimal(19,6) NULL,
    [FreightAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_DeliveryTask_FreightAmount] DEFAULT (0),
    [DispatchId] bigint NULL,
    CONSTRAINT [PK_DeliveryTask] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_DeliveryTask_TenantId_TaskNo] ON [tms].[DeliveryTask] ([TenantId], [TaskNo]) WHERE [IsDeleted] = 0;
GO
CREATE UNIQUE INDEX [UQ_DeliveryTask_TenantId_DocNo] ON [tms].[DeliveryTask] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_DeliveryTask_PlanDate_Status] ON [tms].[DeliveryTask] ([PlanDate], [Status]);
GO
CREATE INDEX [IX_DeliveryTask_PartnerId] ON [tms].[DeliveryTask] ([PartnerId]);
GO
CREATE INDEX [IX_DeliveryTask_OrgId] ON [tms].[DeliveryTask] ([OrgId]);
GO
CREATE INDEX [IX_DeliveryTask_CreatedBy] ON [tms].[DeliveryTask] ([CreatedBy]);
GO
CREATE INDEX [IX_DeliveryTask_ModifiedBy] ON [tms].[DeliveryTask] ([ModifiedBy]);
GO
CREATE INDEX [IX_DeliveryTask_DeletedBy] ON [tms].[DeliveryTask] ([DeletedBy]);
GO
CREATE INDEX [IX_DeliveryTask_WarehouseId] ON [tms].[DeliveryTask] ([WarehouseId]);
GO
CREATE INDEX [IX_DeliveryTask_RouteId] ON [tms].[DeliveryTask] ([RouteId]);
GO
CREATE INDEX [IX_DeliveryTask_RegionId] ON [tms].[DeliveryTask] ([RegionId]);
GO
CREATE INDEX [IX_DeliveryTask_AddressId] ON [tms].[DeliveryTask] ([AddressId]);
GO
CREATE INDEX [IX_DeliveryTask_DispatchId] ON [tms].[DeliveryTask] ([DispatchId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'配送任务', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'发货仓', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'线路', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'RouteId';
EXEC sp_addextendedproperty N'MS_Description', N'区域', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'RegionId';
EXEC sp_addextendedproperty N'MS_Description', N'收货客户', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'收货地址', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'AddressId';
EXEC sp_addextendedproperty N'MS_Description', N'计划配送日', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'PlanDate';
EXEC sp_addextendedproperty N'MS_Description', N'时间窗', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'TimeWindow';
EXEC sp_addextendedproperty N'MS_Description', N'总体积', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'TotalVolume';
EXEC sp_addextendedproperty N'MS_Description', N'总重量', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'TotalWeight';
EXEC sp_addextendedproperty N'MS_Description', N'应收运费', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'FreightAmount';
EXEC sp_addextendedproperty N'MS_Description', N'派车单', N'SCHEMA', N'tms', N'TABLE', N'DeliveryTask', N'COLUMN', N'DispatchId';
GO
CREATE TABLE [tms].[DispatchOrder] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_DispatchOrder_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_DispatchOrder_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_DispatchOrder_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_DispatchOrder_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [VehicleId] bigint NOT NULL,
    [DriverId] bigint NOT NULL,
    [CarrierId] bigint NULL,
    [PlanDate] date NOT NULL,
    [TaskCount] int NOT NULL CONSTRAINT [DF_DispatchOrder_TaskCount] DEFAULT (0),
    [LoadRate] decimal(9,4) NULL,
    [TotalFreight] decimal(19,4) NOT NULL CONSTRAINT [DF_DispatchOrder_TotalFreight] DEFAULT (0),
    [LeaveAt] datetime2(3) NULL,
    [BackAt] datetime2(3) NULL,
    CONSTRAINT [PK_DispatchOrder] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_DispatchOrder_TenantId_DocNo] ON [tms].[DispatchOrder] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_DispatchOrder_PlanDate_Status] ON [tms].[DispatchOrder] ([PlanDate], [Status]);
GO
CREATE INDEX [IX_DispatchOrder_OrgId] ON [tms].[DispatchOrder] ([OrgId]);
GO
CREATE INDEX [IX_DispatchOrder_CreatedBy] ON [tms].[DispatchOrder] ([CreatedBy]);
GO
CREATE INDEX [IX_DispatchOrder_ModifiedBy] ON [tms].[DispatchOrder] ([ModifiedBy]);
GO
CREATE INDEX [IX_DispatchOrder_DeletedBy] ON [tms].[DispatchOrder] ([DeletedBy]);
GO
CREATE INDEX [IX_DispatchOrder_VehicleId] ON [tms].[DispatchOrder] ([VehicleId]);
GO
CREATE INDEX [IX_DispatchOrder_DriverId] ON [tms].[DispatchOrder] ([DriverId]);
GO
CREATE INDEX [IX_DispatchOrder_CarrierId] ON [tms].[DispatchOrder] ([CarrierId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'派车单', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'车辆', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'VehicleId';
EXEC sp_addextendedproperty N'MS_Description', N'司机', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'DriverId';
EXEC sp_addextendedproperty N'MS_Description', N'承运商', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'CarrierId';
EXEC sp_addextendedproperty N'MS_Description', N'任务数', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'TaskCount';
EXEC sp_addextendedproperty N'MS_Description', N'装载率%', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'LoadRate';
EXEC sp_addextendedproperty N'MS_Description', N'本车运费合计', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'TotalFreight';
EXEC sp_addextendedproperty N'MS_Description', N'发车时间', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'LeaveAt';
EXEC sp_addextendedproperty N'MS_Description', N'回场时间', N'SCHEMA', N'tms', N'TABLE', N'DispatchOrder', N'COLUMN', N'BackAt';
GO
CREATE TABLE [tms].[LoadDetail] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [DispatchId] bigint NOT NULL,
    [DeliveryTaskId] bigint NOT NULL,
    [PackageCount] int NULL,
    [Weight] decimal(19,6) NULL,
    [Volume] decimal(19,6) NULL,
    [ScannedAt] datetime2(3) NULL,
    [ScannedBy] bigint NULL,
    CONSTRAINT [PK_LoadDetail] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_LoadDetail_DispatchId] ON [tms].[LoadDetail] ([DispatchId]);
GO
CREATE INDEX [IX_LoadDetail_DeliveryTaskId] ON [tms].[LoadDetail] ([DeliveryTaskId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'装车明细', N'SCHEMA', N'tms', N'TABLE', N'LoadDetail';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'tms', N'TABLE', N'LoadDetail', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'件数', N'SCHEMA', N'tms', N'TABLE', N'LoadDetail', N'COLUMN', N'PackageCount';
EXEC sp_addextendedproperty N'MS_Description', N'扫码装车时间', N'SCHEMA', N'tms', N'TABLE', N'LoadDetail', N'COLUMN', N'ScannedAt';
GO
CREATE TABLE [tms].[TripLog] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [DeliveryTaskId] bigint NOT NULL,
    [DispatchId] bigint NULL,
    [NodeType] tinyint NOT NULL CONSTRAINT [DF_TripLog_NodeType] DEFAULT (1) CONSTRAINT [CK_TripLog_NodeType] CHECK (NodeType BETWEEN 1 AND 5),
    [Latitude] decimal(10,6) NULL,
    [Longitude] decimal(10,6) NULL,
    [Address] nvarchar(200) NULL,
    [ReportedBy] bigint NULL,
    [At] datetime2(3) NOT NULL CONSTRAINT [DF_TripLog_At] DEFAULT (sysutcdatetime()),
    [Note] nvarchar(300) NULL,
    CONSTRAINT [PK_TripLog] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_TripLog_DeliveryTaskId_At] ON [tms].[TripLog] ([DeliveryTaskId], [At]);
GO
CREATE INDEX [IX_TripLog_DispatchId] ON [tms].[TripLog] ([DispatchId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'在途节点', N'SCHEMA', N'tms', N'TABLE', N'TripLog';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'tms', N'TABLE', N'TripLog', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'派车单', N'SCHEMA', N'tms', N'TABLE', N'TripLog', N'COLUMN', N'DispatchId';
EXEC sp_addextendedproperty N'MS_Description', N'节点(1发车 2到店 3离店 4异常 5回场)', N'SCHEMA', N'tms', N'TABLE', N'TripLog', N'COLUMN', N'NodeType';
EXEC sp_addextendedproperty N'MS_Description', N'上报人(司机)', N'SCHEMA', N'tms', N'TABLE', N'TripLog', N'COLUMN', N'ReportedBy';
GO
CREATE TABLE [tms].[Signature] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [DeliveryTaskId] bigint NOT NULL,
    [SignedBy] nvarchar(50) NULL,
    [SignType] tinyint NOT NULL CONSTRAINT [DF_Signature_SignType] DEFAULT (1),
    [SignedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Signature_SignedAt] DEFAULT (sysutcdatetime()),
    [Result] tinyint NOT NULL CONSTRAINT [DF_Signature_Result] DEFAULT (1),
    [RejectReason] nvarchar(300) NULL,
    [AttachmentJson] nvarchar(max) NULL,
    [CodAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_Signature_CodAmount] DEFAULT (0),
    [CodCollected] bit NOT NULL CONSTRAINT [DF_Signature_CodCollected] DEFAULT (0),
    CONSTRAINT [PK_Signature] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_Signature_DeliveryTaskId] ON [tms].[Signature] ([DeliveryTaskId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'签收', N'SCHEMA', N'tms', N'TABLE', N'Signature';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'tms', N'TABLE', N'Signature', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'签收人', N'SCHEMA', N'tms', N'TABLE', N'Signature', N'COLUMN', N'SignedBy';
EXEC sp_addextendedproperty N'MS_Description', N'方式(1手写 2拍照 3电子签名 4验证码)', N'SCHEMA', N'tms', N'TABLE', N'Signature', N'COLUMN', N'SignType';
EXEC sp_addextendedproperty N'MS_Description', N'结果(1正常签收 2部分签收 3拒收)', N'SCHEMA', N'tms', N'TABLE', N'Signature', N'COLUMN', N'Result';
EXEC sp_addextendedproperty N'MS_Description', N'签收照片', N'SCHEMA', N'tms', N'TABLE', N'Signature', N'COLUMN', N'AttachmentJson';
EXEC sp_addextendedproperty N'MS_Description', N'代收货款', N'SCHEMA', N'tms', N'TABLE', N'Signature', N'COLUMN', N'CodAmount';
GO
CREATE TABLE [tms].[ReturnReceipt] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [DeliveryTaskId] bigint NOT NULL,
    [ReceiptNo] varchar(40) NULL,
    [AttachmentId] bigint NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_ReturnReceipt_Status] DEFAULT (0),
    [ReturnedAt] datetime2(3) NULL,
    [ReceivedBy] bigint NULL,
    CONSTRAINT [PK_ReturnReceipt] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_ReturnReceipt_DeliveryTaskId] ON [tms].[ReturnReceipt] ([DeliveryTaskId]);
GO
CREATE INDEX [IX_ReturnReceipt_AttachmentId] ON [tms].[ReturnReceipt] ([AttachmentId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'回单', N'SCHEMA', N'tms', N'TABLE', N'ReturnReceipt';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'tms', N'TABLE', N'ReturnReceipt', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'回单号', N'SCHEMA', N'tms', N'TABLE', N'ReturnReceipt', N'COLUMN', N'ReceiptNo';
EXEC sp_addextendedproperty N'MS_Description', N'回单影像', N'SCHEMA', N'tms', N'TABLE', N'ReturnReceipt', N'COLUMN', N'AttachmentId';
EXEC sp_addextendedproperty N'MS_Description', N'0待回 1已回 2已审核 3缺回', N'SCHEMA', N'tms', N'TABLE', N'ReturnReceipt', N'COLUMN', N'Status';
GO
CREATE TABLE [tms].[FreightRule] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_FreightRule_TenantId] DEFAULT (1),
    [Code] varchar(40) NOT NULL,
    [Name] nvarchar(100) NULL,
    [RuleSide] tinyint NOT NULL CONSTRAINT [DF_FreightRule_RuleSide] DEFAULT (1),
    [CalcBase] tinyint NOT NULL CONSTRAINT [DF_FreightRule_CalcBase] DEFAULT (1),
    [CarrierId] bigint NULL,
    [RegionId] bigint NULL,
    [TiersJson] nvarchar(max) NULL,
    [BasePrice] decimal(19,4) NOT NULL CONSTRAINT [DF_FreightRule_BasePrice] DEFAULT (0),
    [MinCharge] decimal(19,4) NULL,
    [StartDate] date NULL,
    [EndDate] date NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_FreightRule_Status] DEFAULT (1),
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_FreightRule_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_FreightRule_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_FreightRule] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_FreightRule_TenantId_Code] ON [tms].[FreightRule] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_FreightRule_CarrierId] ON [tms].[FreightRule] ([CarrierId]);
GO
CREATE INDEX [IX_FreightRule_RegionId] ON [tms].[FreightRule] ([RegionId]);
GO
CREATE INDEX [IX_FreightRule_OrgId] ON [tms].[FreightRule] ([OrgId]);
GO
CREATE INDEX [IX_FreightRule_CreatedBy] ON [tms].[FreightRule] ([CreatedBy]);
GO
CREATE INDEX [IX_FreightRule_ModifiedBy] ON [tms].[FreightRule] ([ModifiedBy]);
GO
CREATE INDEX [IX_FreightRule_DeletedBy] ON [tms].[FreightRule] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'运费规则', N'SCHEMA', N'tms', N'TABLE', N'FreightRule';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'方向(1应收客户 2应付承运商)', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'RuleSide';
EXEC sp_addextendedproperty N'MS_Description', N'计费(1按重量 2按体积 3按件数 4按里程 5按金额 6固定)', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'CalcBase';
EXEC sp_addextendedproperty N'MS_Description', N'适用承运商', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'CarrierId';
EXEC sp_addextendedproperty N'MS_Description', N'适用区域', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'RegionId';
EXEC sp_addextendedproperty N'MS_Description', N'阶梯[{min,max,price,firstPrice}]', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'TiersJson';
EXEC sp_addextendedproperty N'MS_Description', N'起步价', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'BasePrice';
EXEC sp_addextendedproperty N'MS_Description', N'最低收费', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'MinCharge';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'tms', N'TABLE', N'FreightRule', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [tms].[FreightCalc] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_FreightCalc_TenantId] DEFAULT (1),
    [SourceType] varchar(40) NOT NULL,
    [SourceId] bigint NOT NULL,
    [RuleId] bigint NULL,
    [RuleSide] tinyint NOT NULL CONSTRAINT [DF_FreightCalc_RuleSide] DEFAULT (1),
    [CalcBase] tinyint NOT NULL CONSTRAINT [DF_FreightCalc_CalcBase] DEFAULT (1),
    [BaseValue] decimal(19,6) NULL,
    [Amount] decimal(19,4) NOT NULL CONSTRAINT [DF_FreightCalc_Amount] DEFAULT (0),
    [AllocatedAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_FreightCalc_AllocatedAmount] DEFAULT (0),
    [IsSettled] bit NOT NULL CONSTRAINT [DF_FreightCalc_IsSettled] DEFAULT (0),
    CONSTRAINT [PK_FreightCalc] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_FreightCalc_SourceType_SourceId] ON [tms].[FreightCalc] ([SourceType], [SourceId]);
GO
CREATE INDEX [IX_FreightCalc_RuleId] ON [tms].[FreightCalc] ([RuleId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'运费计算结果', N'SCHEMA', N'tms', N'TABLE', N'FreightCalc';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'tms', N'TABLE', N'FreightCalc', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'来源(销售出库/配送任务/派车单)', N'SCHEMA', N'tms', N'TABLE', N'FreightCalc', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'规则', N'SCHEMA', N'tms', N'TABLE', N'FreightCalc', N'COLUMN', N'RuleId';
EXEC sp_addextendedproperty N'MS_Description', N'计费基数', N'SCHEMA', N'tms', N'TABLE', N'FreightCalc', N'COLUMN', N'BaseValue';
EXEC sp_addextendedproperty N'MS_Description', N'运费', N'SCHEMA', N'tms', N'TABLE', N'FreightCalc', N'COLUMN', N'Amount';
EXEC sp_addextendedproperty N'MS_Description', N'已分摊金额', N'SCHEMA', N'tms', N'TABLE', N'FreightCalc', N'COLUMN', N'AllocatedAmount';
GO
CREATE TABLE [tms].[CarrierSettlement] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_CarrierSettlement_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_CarrierSettlement_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_CarrierSettlement_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_CarrierSettlement_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [CarrierId] bigint NOT NULL,
    [PeriodFrom] date NOT NULL,
    [PeriodTo] date NOT NULL,
    [TripCount] int NOT NULL CONSTRAINT [DF_CarrierSettlement_TripCount] DEFAULT (0),
    [CalcAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_CarrierSettlement_CalcAmount] DEFAULT (0),
    [ConfirmAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_CarrierSettlement_ConfirmAmount] DEFAULT (0),
    [DiffAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_CarrierSettlement_DiffAmount] DEFAULT (0),
    CONSTRAINT [PK_CarrierSettlement] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_CarrierSettlement_TenantId_DocNo] ON [tms].[CarrierSettlement] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_CarrierSettlement_CarrierId_Status] ON [tms].[CarrierSettlement] ([CarrierId], [Status]);
GO
CREATE INDEX [IX_CarrierSettlement_OrgId] ON [tms].[CarrierSettlement] ([OrgId]);
GO
CREATE INDEX [IX_CarrierSettlement_CreatedBy] ON [tms].[CarrierSettlement] ([CreatedBy]);
GO
CREATE INDEX [IX_CarrierSettlement_ModifiedBy] ON [tms].[CarrierSettlement] ([ModifiedBy]);
GO
CREATE INDEX [IX_CarrierSettlement_DeletedBy] ON [tms].[CarrierSettlement] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'承运商结算', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'承运商', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'CarrierId';
EXEC sp_addextendedproperty N'MS_Description', N'车次数', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'TripCount';
EXEC sp_addextendedproperty N'MS_Description', N'计算运费', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'CalcAmount';
EXEC sp_addextendedproperty N'MS_Description', N'确认运费', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'ConfirmAmount';
EXEC sp_addextendedproperty N'MS_Description', N'差异', N'SCHEMA', N'tms', N'TABLE', N'CarrierSettlement', N'COLUMN', N'DiffAmount';
GO
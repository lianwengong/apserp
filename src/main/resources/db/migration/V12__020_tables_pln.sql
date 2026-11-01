/* =====================================================================
   进销存管理系统 V3 · 表结构 · pln 架构（8 张表）
   数据库：APSErpV3   生成器：db/emit.py（请勿手改，改规格文件后重新生成）
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE TABLE [pln].[Forecast] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Forecast_TenantId] DEFAULT (1),
    [Code] varchar(40) NOT NULL,
    [Name] nvarchar(100) NULL,
    [ForecastType] tinyint NOT NULL CONSTRAINT [DF_Forecast_ForecastType] DEFAULT (1) CONSTRAINT [CK_Forecast_ForecastType] CHECK (ForecastType BETWEEN 1 AND 3),
    [Method] tinyint NOT NULL CONSTRAINT [DF_Forecast_Method] DEFAULT (2) CONSTRAINT [CK_Forecast_Method] CHECK (Method BETWEEN 1 AND 5),
    [PeriodFrom] varchar(10) NOT NULL,
    [PeriodCount] tinyint NOT NULL CONSTRAINT [DF_Forecast_PeriodCount] DEFAULT (3),
    [Dimension] tinyint NOT NULL CONSTRAINT [DF_Forecast_Dimension] DEFAULT (1),
    [Status] tinyint NOT NULL CONSTRAINT [DF_Forecast_Status] DEFAULT (0),
    [Accuracy] decimal(9,4) NULL,
    [GeneratedAt] datetime2(3) NULL,
    [PublishedAt] datetime2(3) NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Forecast_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Forecast_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Forecast] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Forecast_TenantId_Code] ON [pln].[Forecast] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Forecast_OrgId] ON [pln].[Forecast] ([OrgId]);
GO
CREATE INDEX [IX_Forecast_CreatedBy] ON [pln].[Forecast] ([CreatedBy]);
GO
CREATE INDEX [IX_Forecast_ModifiedBy] ON [pln].[Forecast] ([ModifiedBy]);
GO
CREATE INDEX [IX_Forecast_DeletedBy] ON [pln].[Forecast] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'需求预测单', N'SCHEMA', N'pln', N'TABLE', N'Forecast';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1月度 2周 3滚动)', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'ForecastType';
EXEC sp_addextendedproperty N'MS_Description', N'方法(1移动平均 2同比 3季节因子 4加权 5人工)', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'Method';
EXEC sp_addextendedproperty N'MS_Description', N'预测起始期间', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'PeriodFrom';
EXEC sp_addextendedproperty N'MS_Description', N'预测期数(月)', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'PeriodCount';
EXEC sp_addextendedproperty N'MS_Description', N'维度(1商品 2客户 3区域)', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'Dimension';
EXEC sp_addextendedproperty N'MS_Description', N'0生成中 1待确认 2已发布 3已作废', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'回测准确率%', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'Accuracy';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'pln', N'TABLE', N'Forecast', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [pln].[ForecastItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [ForecastId] bigint NOT NULL,
    [SkuId] bigint NOT NULL,
    [PartnerId] bigint NULL,
    [Period] varchar(10) NOT NULL,
    [ForecastQty] decimal(19,6) NOT NULL,
    [ManualQty] decimal(19,6) NULL,
    [ActualQty] decimal(19,6) NULL,
    [Confidence] decimal(9,4) NULL,
    [AdjustReason] nvarchar(200) NULL,
    CONSTRAINT [PK_ForecastItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ForecastItem_ForecastId_SkuId_Period] ON [pln].[ForecastItem] ([ForecastId], [SkuId], [Period]);
GO
CREATE INDEX [IX_ForecastItem_SkuId] ON [pln].[ForecastItem] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'预测明细', N'SCHEMA', N'pln', N'TABLE', N'ForecastItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pln', N'TABLE', N'ForecastItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'客户(按客户预测)', N'SCHEMA', N'pln', N'TABLE', N'ForecastItem', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'期间', N'SCHEMA', N'pln', N'TABLE', N'ForecastItem', N'COLUMN', N'Period';
EXEC sp_addextendedproperty N'MS_Description', N'预测数量', N'SCHEMA', N'pln', N'TABLE', N'ForecastItem', N'COLUMN', N'ForecastQty';
EXEC sp_addextendedproperty N'MS_Description', N'人工调整后数量', N'SCHEMA', N'pln', N'TABLE', N'ForecastItem', N'COLUMN', N'ManualQty';
EXEC sp_addextendedproperty N'MS_Description', N'实际(回测用)', N'SCHEMA', N'pln', N'TABLE', N'ForecastItem', N'COLUMN', N'ActualQty';
EXEC sp_addextendedproperty N'MS_Description', N'置信度', N'SCHEMA', N'pln', N'TABLE', N'ForecastItem', N'COLUMN', N'Confidence';
GO
CREATE TABLE [pln].[SalesPlan] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_SalesPlan_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_SalesPlan_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_SalesPlan_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_SalesPlan_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [Period] varchar(10) NOT NULL,
    [PlanLevel] tinyint NOT NULL CONSTRAINT [DF_SalesPlan_PlanLevel] DEFAULT (1),
    [PlanType] tinyint NOT NULL CONSTRAINT [DF_SalesPlan_PlanType] DEFAULT (1),
    [TotalQty] decimal(19,6) NOT NULL CONSTRAINT [DF_SalesPlan_TotalQty] DEFAULT (0),
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesPlan_TotalAmount] DEFAULT (0),
    [AchievedAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesPlan_AchievedAmount] DEFAULT (0),
    [BudgetId] bigint NULL,
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    CONSTRAINT [PK_SalesPlan] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_SalesPlan_TenantId_DocNo] ON [pln].[SalesPlan] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_SalesPlan_OrgId] ON [pln].[SalesPlan] ([OrgId]);
GO
CREATE INDEX [IX_SalesPlan_CreatedBy] ON [pln].[SalesPlan] ([CreatedBy]);
GO
CREATE INDEX [IX_SalesPlan_ModifiedBy] ON [pln].[SalesPlan] ([ModifiedBy]);
GO
CREATE INDEX [IX_SalesPlan_DeletedBy] ON [pln].[SalesPlan] ([DeletedBy]);
GO
CREATE INDEX [IX_SalesPlan_BudgetId] ON [pln].[SalesPlan] ([BudgetId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'销售计划', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'期间', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'Period';
EXEC sp_addextendedproperty N'MS_Description', N'层级(1公司 2区域 3业务员 4客户 5商品)', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'PlanLevel';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1年度 2季度 3月度 4滚动)', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'PlanType';
EXEC sp_addextendedproperty N'MS_Description', N'关联预算', N'SCHEMA', N'pln', N'TABLE', N'SalesPlan', N'COLUMN', N'BudgetId';
GO
CREATE TABLE [pln].[SalesPlanItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [PlanId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NULL,
    [PartnerId] bigint NULL,
    [TargetId] bigint NULL,
    [Period] varchar(10) NULL,
    [PlanQty] decimal(19,6) NOT NULL,
    [PlanAmount] decimal(19,4) NOT NULL,
    [AchievedQty] decimal(19,6) NOT NULL CONSTRAINT [DF_SalesPlanItem_AchievedQty] DEFAULT (0),
    [AchievedAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_SalesPlanItem_AchievedAmount] DEFAULT (0),
    CONSTRAINT [PK_SalesPlanItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_SalesPlanItem_PlanId] ON [pln].[SalesPlanItem] ([PlanId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'销售计划明细', N'SCHEMA', N'pln', N'TABLE', N'SalesPlanItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pln', N'TABLE', N'SalesPlanItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'pln', N'TABLE', N'SalesPlanItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'pln', N'TABLE', N'SalesPlanItem', N'COLUMN', N'PlanId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'pln', N'TABLE', N'SalesPlanItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'商品', N'SCHEMA', N'pln', N'TABLE', N'SalesPlanItem', N'COLUMN', N'SkuId';
EXEC sp_addextendedproperty N'MS_Description', N'客户', N'SCHEMA', N'pln', N'TABLE', N'SalesPlanItem', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'业务员/区域', N'SCHEMA', N'pln', N'TABLE', N'SalesPlanItem', N'COLUMN', N'TargetId';
EXEC sp_addextendedproperty N'MS_Description', N'期间', N'SCHEMA', N'pln', N'TABLE', N'SalesPlanItem', N'COLUMN', N'Period';
GO
CREATE TABLE [pln].[ReplenishParam] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_ReplenishParam_TenantId] DEFAULT (1),
    [SkuId] bigint NOT NULL,
    [WarehouseId] bigint NOT NULL,
    [SafetyStock] decimal(19,6) NOT NULL CONSTRAINT [DF_ReplenishParam_SafetyStock] DEFAULT (0),
    [ReorderPoint] decimal(19,6) NOT NULL CONSTRAINT [DF_ReplenishParam_ReorderPoint] DEFAULT (0),
    [MaxStock] decimal(19,6) NOT NULL CONSTRAINT [DF_ReplenishParam_MaxStock] DEFAULT (0),
    [MinOrderQty] decimal(19,6) NOT NULL CONSTRAINT [DF_ReplenishParam_MinOrderQty] DEFAULT (1),
    [OrderStep] decimal(19,6) NOT NULL CONSTRAINT [DF_ReplenishParam_OrderStep] DEFAULT (1),
    [CoverDays] int NOT NULL CONSTRAINT [DF_ReplenishParam_CoverDays] DEFAULT (7),
    [LeadDays] int NOT NULL CONSTRAINT [DF_ReplenishParam_LeadDays] DEFAULT (3),
    [SupplierId] bigint NULL,
    [IsAutoSuggest] bit NOT NULL CONSTRAINT [DF_ReplenishParam_IsAutoSuggest] DEFAULT (1),
    [LastCalcAt] datetime2(3) NULL,
    CONSTRAINT [PK_ReplenishParam] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ReplenishParam_TenantId_SkuId_WarehouseId] ON [pln].[ReplenishParam] ([TenantId], [SkuId], [WarehouseId]);
GO
CREATE INDEX [IX_ReplenishParam_SkuId] ON [pln].[ReplenishParam] ([SkuId]);
GO
CREATE INDEX [IX_ReplenishParam_WarehouseId] ON [pln].[ReplenishParam] ([WarehouseId]);
GO
CREATE INDEX [IX_ReplenishParam_SupplierId] ON [pln].[ReplenishParam] ([SupplierId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'补货参数', N'SCHEMA', N'pln', N'TABLE', N'ReplenishParam';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pln', N'TABLE', N'ReplenishParam', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'安全库存', N'SCHEMA', N'pln', N'TABLE', N'ReplenishParam', N'COLUMN', N'SafetyStock';
EXEC sp_addextendedproperty N'MS_Description', N'补货点', N'SCHEMA', N'pln', N'TABLE', N'ReplenishParam', N'COLUMN', N'ReorderPoint';
EXEC sp_addextendedproperty N'MS_Description', N'最高库存', N'SCHEMA', N'pln', N'TABLE', N'ReplenishParam', N'COLUMN', N'MaxStock';
EXEC sp_addextendedproperty N'MS_Description', N'最小起订', N'SCHEMA', N'pln', N'TABLE', N'ReplenishParam', N'COLUMN', N'MinOrderQty';
EXEC sp_addextendedproperty N'MS_Description', N'订货倍数(箱规)', N'SCHEMA', N'pln', N'TABLE', N'ReplenishParam', N'COLUMN', N'OrderStep';
EXEC sp_addextendedproperty N'MS_Description', N'覆盖天数', N'SCHEMA', N'pln', N'TABLE', N'ReplenishParam', N'COLUMN', N'CoverDays';
EXEC sp_addextendedproperty N'MS_Description', N'供应商交期', N'SCHEMA', N'pln', N'TABLE', N'ReplenishParam', N'COLUMN', N'LeadDays';
EXEC sp_addextendedproperty N'MS_Description', N'默认供应商', N'SCHEMA', N'pln', N'TABLE', N'ReplenishParam', N'COLUMN', N'SupplierId';
EXEC sp_addextendedproperty N'MS_Description', N'参与自动建议', N'SCHEMA', N'pln', N'TABLE', N'ReplenishParam', N'COLUMN', N'IsAutoSuggest';
GO
CREATE TABLE [pln].[ReplenishSuggestion] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_ReplenishSuggestion_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_ReplenishSuggestion_Status] DEFAULT (0),
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_ReplenishSuggestion_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_ReplenishSuggestion_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    [SuggestionType] tinyint NOT NULL CONSTRAINT [DF_ReplenishSuggestion_SuggestionType] DEFAULT (1),
    [WarehouseId] bigint NULL,
    [SupplierId] bigint NULL,
    [CalcDate] date NOT NULL,
    [TotalQty] decimal(19,6) NOT NULL CONSTRAINT [DF_ReplenishSuggestion_TotalQty] DEFAULT (0),
    [TotalAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_ReplenishSuggestion_TotalAmount] DEFAULT (0),
    [ConvertedDocNo] varchar(40) NULL,
    [Algorithm] varchar(50) NULL,
    CONSTRAINT [PK_ReplenishSuggestion] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ReplenishSuggestion_TenantId_DocNo] ON [pln].[ReplenishSuggestion] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_ReplenishSuggestion_Status_CalcDate] ON [pln].[ReplenishSuggestion] ([Status], [CalcDate]);
GO
CREATE INDEX [IX_ReplenishSuggestion_OrgId] ON [pln].[ReplenishSuggestion] ([OrgId]);
GO
CREATE INDEX [IX_ReplenishSuggestion_CreatedBy] ON [pln].[ReplenishSuggestion] ([CreatedBy]);
GO
CREATE INDEX [IX_ReplenishSuggestion_ModifiedBy] ON [pln].[ReplenishSuggestion] ([ModifiedBy]);
GO
CREATE INDEX [IX_ReplenishSuggestion_DeletedBy] ON [pln].[ReplenishSuggestion] ([DeletedBy]);
GO
CREATE INDEX [IX_ReplenishSuggestion_WarehouseId] ON [pln].[ReplenishSuggestion] ([WarehouseId]);
GO
CREATE INDEX [IX_ReplenishSuggestion_SupplierId] ON [pln].[ReplenishSuggestion] ([SupplierId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'补货/采购建议单', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'单据号', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1待审 2已审 3执行中 4已完成 9已作废)', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据类型', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源单据Id', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'DeletedAt';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1补货 2采购 3调拨 4清仓)', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'SuggestionType';
EXEC sp_addextendedproperty N'MS_Description', N'目标仓', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'建议供应商', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'SupplierId';
EXEC sp_addextendedproperty N'MS_Description', N'计算日期', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'CalcDate';
EXEC sp_addextendedproperty N'MS_Description', N'转单后的单号', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'ConvertedDocNo';
EXEC sp_addextendedproperty N'MS_Description', N'算法版本', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestion', N'COLUMN', N'Algorithm';
GO
CREATE TABLE [pln].[ReplenishSuggestionItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [SuggestionId] bigint NOT NULL,
    [LineNo] int NOT NULL,
    [SkuId] bigint NOT NULL,
    [CurrentQty] decimal(19,6) NULL,
    [InTransitQty] decimal(19,6) NULL,
    [ReservedQty] decimal(19,6) NULL,
    [AvgDailySales] decimal(19,6) NULL,
    [ForecastQty] decimal(19,6) NULL,
    [SuggestQty] decimal(19,6) NOT NULL,
    [ManualQty] decimal(19,6) NULL,
    [RefPrice] decimal(19,6) NULL,
    [Reason] nvarchar(200) NULL,
    CONSTRAINT [PK_ReplenishSuggestionItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ReplenishSuggestionItem_SuggestionId_SkuId] ON [pln].[ReplenishSuggestionItem] ([SuggestionId], [SkuId]);
GO
CREATE INDEX [IX_ReplenishSuggestionItem_SkuId] ON [pln].[ReplenishSuggestionItem] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'建议明细', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestionItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestionItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户（与主表一致，用于行级隔离）', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestionItem', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'主表Id', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestionItem', N'COLUMN', N'SuggestionId';
EXEC sp_addextendedproperty N'MS_Description', N'行号', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestionItem', N'COLUMN', N'LineNo';
EXEC sp_addextendedproperty N'MS_Description', N'当前可用', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestionItem', N'COLUMN', N'CurrentQty';
EXEC sp_addextendedproperty N'MS_Description', N'在途', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestionItem', N'COLUMN', N'InTransitQty';
EXEC sp_addextendedproperty N'MS_Description', N'占用', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestionItem', N'COLUMN', N'ReservedQty';
EXEC sp_addextendedproperty N'MS_Description', N'日均销量', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestionItem', N'COLUMN', N'AvgDailySales';
EXEC sp_addextendedproperty N'MS_Description', N'预测需求', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestionItem', N'COLUMN', N'ForecastQty';
EXEC sp_addextendedproperty N'MS_Description', N'建议数量(已按箱规取整)', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestionItem', N'COLUMN', N'SuggestQty';
EXEC sp_addextendedproperty N'MS_Description', N'人工调整数量', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestionItem', N'COLUMN', N'ManualQty';
EXEC sp_addextendedproperty N'MS_Description', N'参考单价', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestionItem', N'COLUMN', N'RefPrice';
EXEC sp_addextendedproperty N'MS_Description', N'建议原因(低于补货点/断货风险)', N'SCHEMA', N'pln', N'TABLE', N'ReplenishSuggestionItem', N'COLUMN', N'Reason';
GO
CREATE TABLE [pln].[KpiSnapshot] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_KpiSnapshot_TenantId] DEFAULT (1),
    [Period] varchar(10) NOT NULL,
    [PeriodType] tinyint NOT NULL CONSTRAINT [DF_KpiSnapshot_PeriodType] DEFAULT (3),
    [OrgId] int NULL,
    [KpiCode] varchar(50) NOT NULL,
    [KpiValue] decimal(19,6) NOT NULL,
    [CompareValue] decimal(19,6) NULL,
    [CalcAt] datetime2(3) NOT NULL CONSTRAINT [DF_KpiSnapshot_CalcAt] DEFAULT (sysutcdatetime()),
    CONSTRAINT [PK_KpiSnapshot] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_KpiSnapshot_TenantId_Period_PeriodType_OrgId_KpiCode] ON [pln].[KpiSnapshot] ([TenantId], [Period], [PeriodType], [OrgId], [KpiCode]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'KPI 快照（驾驶舱数据源）', N'SCHEMA', N'pln', N'TABLE', N'KpiSnapshot';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'pln', N'TABLE', N'KpiSnapshot', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'期间(2026-01-15)', N'SCHEMA', N'pln', N'TABLE', N'KpiSnapshot', N'COLUMN', N'Period';
EXEC sp_addextendedproperty N'MS_Description', N'粒度(1年 2月 3日)', N'SCHEMA', N'pln', N'TABLE', N'KpiSnapshot', N'COLUMN', N'PeriodType';
EXEC sp_addextendedproperty N'MS_Description', N'组织', N'SCHEMA', N'pln', N'TABLE', N'KpiSnapshot', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'指标编码(收入/毛利/周转/缺货率)', N'SCHEMA', N'pln', N'TABLE', N'KpiSnapshot', N'COLUMN', N'KpiCode';
EXEC sp_addextendedproperty N'MS_Description', N'指标值', N'SCHEMA', N'pln', N'TABLE', N'KpiSnapshot', N'COLUMN', N'KpiValue';
EXEC sp_addextendedproperty N'MS_Description', N'同比/环比值', N'SCHEMA', N'pln', N'TABLE', N'KpiSnapshot', N'COLUMN', N'CompareValue';
GO
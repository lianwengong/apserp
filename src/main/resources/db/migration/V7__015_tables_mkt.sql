/* =====================================================================
   进销存管理系统 V3 · 表结构 · mkt 架构（13 张表）
   数据库：APSErpV3   生成器：db/emit.py（请勿手改，改规格文件后重新生成）
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE TABLE [mkt].[MemberLevel] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_MemberLevel_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(50) NOT NULL,
    [Level] tinyint NOT NULL CONSTRAINT [DF_MemberLevel_Level] DEFAULT (1),
    [UpgradeType] tinyint NOT NULL CONSTRAINT [DF_MemberLevel_UpgradeType] DEFAULT (1),
    [UpgradeValue] decimal(19,4) NOT NULL CONSTRAINT [DF_MemberLevel_UpgradeValue] DEFAULT (0),
    [KeepValue] decimal(19,4) NULL,
    [DiscountRate] decimal(9,4) NULL,
    [PointRate] decimal(9,2) NOT NULL CONSTRAINT [DF_MemberLevel_PointRate] DEFAULT (1),
    [BenefitsJson] nvarchar(max) NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_MemberLevel_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_MemberLevel_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_MemberLevel_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_MemberLevel] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_MemberLevel_TenantId_Code] ON [mkt].[MemberLevel] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_MemberLevel_CreatedBy] ON [mkt].[MemberLevel] ([CreatedBy]);
GO
CREATE INDEX [IX_MemberLevel_ModifiedBy] ON [mkt].[MemberLevel] ([ModifiedBy]);
GO
CREATE INDEX [IX_MemberLevel_DeletedBy] ON [mkt].[MemberLevel] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'会员等级', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'等级编码', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'等级名称', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'等级序', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'Level';
EXEC sp_addextendedproperty N'MS_Description', N'升级依据(1累计消费 2积分 3次数)', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'UpgradeType';
EXEC sp_addextendedproperty N'MS_Description', N'升级阈值', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'UpgradeValue';
EXEC sp_addextendedproperty N'MS_Description', N'保级阈值', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'KeepValue';
EXEC sp_addextendedproperty N'MS_Description', N'折扣率%', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'DiscountRate';
EXEC sp_addextendedproperty N'MS_Description', N'积分倍率', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'PointRate';
EXEC sp_addextendedproperty N'MS_Description', N'权益(包邮/生日礼/专属客服)', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'BenefitsJson';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'MemberLevel', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [mkt].[Member] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Member_TenantId] DEFAULT (1),
    [MemberNo] varchar(32) NOT NULL,
    [Mobile] varchar(30) NOT NULL,
    [Name] nvarchar(50) NULL,
    [Gender] tinyint NOT NULL CONSTRAINT [DF_Member_Gender] DEFAULT (0),
    [Birthday] date NULL,
    [LevelId] bigint NULL,
    [GrowthValue] int NOT NULL CONSTRAINT [DF_Member_GrowthValue] DEFAULT (0),
    [PointBalance] int NOT NULL CONSTRAINT [DF_Member_PointBalance] DEFAULT (0),
    [TotalConsume] decimal(19,4) NOT NULL CONSTRAINT [DF_Member_TotalConsume] DEFAULT (0),
    [OrderCount] int NOT NULL CONSTRAINT [DF_Member_OrderCount] DEFAULT (0),
    [LastConsumeAt] datetime2(3) NULL,
    [SourceChannel] tinyint NOT NULL CONSTRAINT [DF_Member_SourceChannel] DEFAULT (1),
    [StoreId] bigint NULL,
    [GuideId] bigint NULL,
    [PartnerId] bigint NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Member_IsEnabled] DEFAULT (1),
    [Code] varchar(32) NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Member_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Member_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Member] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Member_TenantId_MemberNo] ON [mkt].[Member] ([TenantId], [MemberNo]) WHERE [IsDeleted] = 0;
GO
CREATE UNIQUE INDEX [UQ_Member_TenantId_Mobile] ON [mkt].[Member] ([TenantId], [Mobile]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Member_LevelId] ON [mkt].[Member] ([LevelId]);
GO
CREATE INDEX [IX_Member_LastConsumeAt] ON [mkt].[Member] ([LastConsumeAt]);
GO
CREATE INDEX [IX_Member_StoreId] ON [mkt].[Member] ([StoreId]);
GO
CREATE INDEX [IX_Member_OrgId] ON [mkt].[Member] ([OrgId]);
GO
CREATE INDEX [IX_Member_CreatedBy] ON [mkt].[Member] ([CreatedBy]);
GO
CREATE INDEX [IX_Member_ModifiedBy] ON [mkt].[Member] ([ModifiedBy]);
GO
CREATE INDEX [IX_Member_DeletedBy] ON [mkt].[Member] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'会员', N'SCHEMA', N'mkt', N'TABLE', N'Member';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'会员号', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'MemberNo';
EXEC sp_addextendedproperty N'MS_Description', N'手机号(唯一)', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'Mobile';
EXEC sp_addextendedproperty N'MS_Description', N'姓名', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'0未知 1男 2女', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'Gender';
EXEC sp_addextendedproperty N'MS_Description', N'生日', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'Birthday';
EXEC sp_addextendedproperty N'MS_Description', N'等级', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'LevelId';
EXEC sp_addextendedproperty N'MS_Description', N'成长值', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'GrowthValue';
EXEC sp_addextendedproperty N'MS_Description', N'积分余额', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'PointBalance';
EXEC sp_addextendedproperty N'MS_Description', N'累计消费', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'TotalConsume';
EXEC sp_addextendedproperty N'MS_Description', N'消费次数', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'OrderCount';
EXEC sp_addextendedproperty N'MS_Description', N'最近消费', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'LastConsumeAt';
EXEC sp_addextendedproperty N'MS_Description', N'来源(1门店 2商城 3小程序 4导入 5线上平台)', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'SourceChannel';
EXEC sp_addextendedproperty N'MS_Description', N'归属门店', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'StoreId';
EXEC sp_addextendedproperty N'MS_Description', N'归属导购', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'GuideId';
EXEC sp_addextendedproperty N'MS_Description', N'关联企业客户', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'业务编码', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'Member', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [mkt].[MemberTag] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_MemberTag_TenantId] DEFAULT (1),
    [Code] varchar(40) NOT NULL,
    [Name] nvarchar(50) NOT NULL,
    [TagType] tinyint NOT NULL CONSTRAINT [DF_MemberTag_TagType] DEFAULT (1),
    [RuleJson] nvarchar(max) NULL,
    [Color] varchar(20) NULL,
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_MemberTag_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_MemberTag_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_MemberTag] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_MemberTag_TenantId_Code] ON [mkt].[MemberTag] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_MemberTag_CreatedBy] ON [mkt].[MemberTag] ([CreatedBy]);
GO
CREATE INDEX [IX_MemberTag_ModifiedBy] ON [mkt].[MemberTag] ([ModifiedBy]);
GO
CREATE INDEX [IX_MemberTag_DeletedBy] ON [mkt].[MemberTag] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'会员标签', N'SCHEMA', N'mkt', N'TABLE', N'MemberTag';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'mkt', N'TABLE', N'MemberTag', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1手工 2规则 3RFM自动)', N'SCHEMA', N'mkt', N'TABLE', N'MemberTag', N'COLUMN', N'TagType';
EXEC sp_addextendedproperty N'MS_Description', N'自动打标规则', N'SCHEMA', N'mkt', N'TABLE', N'MemberTag', N'COLUMN', N'RuleJson';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'mkt', N'TABLE', N'MemberTag', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'mkt', N'TABLE', N'MemberTag', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'mkt', N'TABLE', N'MemberTag', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'mkt', N'TABLE', N'MemberTag', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'MemberTag', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'mkt', N'TABLE', N'MemberTag', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'MemberTag', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'mkt', N'TABLE', N'MemberTag', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'MemberTag', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [mkt].[MemberTagLink] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [MemberId] bigint NOT NULL,
    [TagId] bigint NOT NULL,
    [TaggedAt] datetime2(3) NOT NULL CONSTRAINT [DF_MemberTagLink_TaggedAt] DEFAULT (sysutcdatetime()),
    CONSTRAINT [PK_MemberTagLink] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_MemberTagLink_MemberId_TagId] ON [mkt].[MemberTagLink] ([MemberId], [TagId]);
GO
CREATE INDEX [IX_MemberTagLink_TagId] ON [mkt].[MemberTagLink] ([TagId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'会员标签关联', N'SCHEMA', N'mkt', N'TABLE', N'MemberTagLink';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'mkt', N'TABLE', N'MemberTagLink', N'COLUMN', N'Id';
GO
CREATE TABLE [mkt].[MemberAccount] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_MemberAccount_TenantId] DEFAULT (1),
    [MemberId] bigint NOT NULL,
    [AccountType] tinyint NOT NULL CONSTRAINT [DF_MemberAccount_AccountType] DEFAULT (1),
    [Balance] decimal(19,4) NOT NULL CONSTRAINT [DF_MemberAccount_Balance] DEFAULT (0),
    [FrozenAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_MemberAccount_FrozenAmount] DEFAULT (0),
    [TotalIn] decimal(19,4) NOT NULL CONSTRAINT [DF_MemberAccount_TotalIn] DEFAULT (0),
    [TotalOut] decimal(19,4) NOT NULL CONSTRAINT [DF_MemberAccount_TotalOut] DEFAULT (0),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_MemberAccount] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_MemberAccount_MemberId_AccountType] ON [mkt].[MemberAccount] ([MemberId], [AccountType]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'会员储值账户', N'SCHEMA', N'mkt', N'TABLE', N'MemberAccount';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'mkt', N'TABLE', N'MemberAccount', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1储值 2礼品卡 3预存)', N'SCHEMA', N'mkt', N'TABLE', N'MemberAccount', N'COLUMN', N'AccountType';
EXEC sp_addextendedproperty N'MS_Description', N'余额', N'SCHEMA', N'mkt', N'TABLE', N'MemberAccount', N'COLUMN', N'Balance';
EXEC sp_addextendedproperty N'MS_Description', N'冻结', N'SCHEMA', N'mkt', N'TABLE', N'MemberAccount', N'COLUMN', N'FrozenAmount';
EXEC sp_addextendedproperty N'MS_Description', N'累计充值', N'SCHEMA', N'mkt', N'TABLE', N'MemberAccount', N'COLUMN', N'TotalIn';
EXEC sp_addextendedproperty N'MS_Description', N'累计消费', N'SCHEMA', N'mkt', N'TABLE', N'MemberAccount', N'COLUMN', N'TotalOut';
GO
CREATE TABLE [mkt].[AccountTransaction] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_AccountTransaction_TenantId] DEFAULT (1),
    [AccountId] bigint NOT NULL,
    [TxnType] tinyint NOT NULL CONSTRAINT [DF_AccountTransaction_TxnType] DEFAULT (1) CONSTRAINT [CK_AccountTransaction_TxnType] CHECK (TxnType BETWEEN 1 AND 6),
    [Amount] decimal(19,4) NOT NULL,
    [BalanceAfter] decimal(19,4) NOT NULL,
    [GiftAmount] decimal(19,4) NULL,
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [OperatorId] bigint NULL,
    [At] datetime2(3) NOT NULL CONSTRAINT [DF_AccountTransaction_At] DEFAULT (sysutcdatetime()),
    CONSTRAINT [PK_AccountTransaction] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_AccountTransaction_AccountId_At] ON [mkt].[AccountTransaction] ([AccountId], [At]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'储值流水', N'SCHEMA', N'mkt', N'TABLE', N'AccountTransaction';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'mkt', N'TABLE', N'AccountTransaction', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1充值 2消费 3退款 4赠送 5调整 6过期)', N'SCHEMA', N'mkt', N'TABLE', N'AccountTransaction', N'COLUMN', N'TxnType';
EXEC sp_addextendedproperty N'MS_Description', N'变动金额', N'SCHEMA', N'mkt', N'TABLE', N'AccountTransaction', N'COLUMN', N'Amount';
EXEC sp_addextendedproperty N'MS_Description', N'变动后余额', N'SCHEMA', N'mkt', N'TABLE', N'AccountTransaction', N'COLUMN', N'BalanceAfter';
EXEC sp_addextendedproperty N'MS_Description', N'赠送金额', N'SCHEMA', N'mkt', N'TABLE', N'AccountTransaction', N'COLUMN', N'GiftAmount';
EXEC sp_addextendedproperty N'MS_Description', N'来源(销售单/充值单)', N'SCHEMA', N'mkt', N'TABLE', N'AccountTransaction', N'COLUMN', N'SourceType';
GO
CREATE TABLE [mkt].[PointTransaction] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_PointTransaction_TenantId] DEFAULT (1),
    [MemberId] bigint NOT NULL,
    [TxnType] tinyint NOT NULL CONSTRAINT [DF_PointTransaction_TxnType] DEFAULT (1),
    [Points] int NOT NULL,
    [BalanceAfter] int NOT NULL,
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [ExpireAt] date NULL,
    [At] datetime2(3) NOT NULL CONSTRAINT [DF_PointTransaction_At] DEFAULT (sysutcdatetime()),
    CONSTRAINT [PK_PointTransaction] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_PointTransaction_MemberId_At] ON [mkt].[PointTransaction] ([MemberId], [At]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'积分流水', N'SCHEMA', N'mkt', N'TABLE', N'PointTransaction';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'mkt', N'TABLE', N'PointTransaction', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1获取 2消耗 3调整 4过期)', N'SCHEMA', N'mkt', N'TABLE', N'PointTransaction', N'COLUMN', N'TxnType';
EXEC sp_addextendedproperty N'MS_Description', N'积分变动', N'SCHEMA', N'mkt', N'TABLE', N'PointTransaction', N'COLUMN', N'Points';
EXEC sp_addextendedproperty N'MS_Description', N'过期日', N'SCHEMA', N'mkt', N'TABLE', N'PointTransaction', N'COLUMN', N'ExpireAt';
GO
CREATE TABLE [mkt].[Promotion] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Promotion_TenantId] DEFAULT (1),
    [Code] varchar(40) NOT NULL,
    [Name] nvarchar(100) NULL,
    [PromoType] tinyint NOT NULL CONSTRAINT [DF_Promotion_PromoType] DEFAULT (1) CONSTRAINT [CK_Promotion_PromoType] CHECK (PromoType BETWEEN 1 AND 10),
    [ApplyChannel] int NOT NULL CONSTRAINT [DF_Promotion_ApplyChannel] DEFAULT (7),
    [Priority] int NOT NULL CONSTRAINT [DF_Promotion_Priority] DEFAULT (100),
    [CanStack] bit NOT NULL CONSTRAINT [DF_Promotion_CanStack] DEFAULT (0),
    [StartAt] datetime2(3) NOT NULL,
    [EndAt] datetime2(3) NOT NULL,
    [WeekDays] varchar(20) NULL,
    [TimeRange] varchar(30) NULL,
    [RuleJson] nvarchar(max) NULL,
    [BudgetAmount] decimal(19,4) NULL,
    [UsedAmount] decimal(19,4) NOT NULL CONSTRAINT [DF_Promotion_UsedAmount] DEFAULT (0),
    [IsAuto] bit NOT NULL CONSTRAINT [DF_Promotion_IsAuto] DEFAULT (1),
    [Status] tinyint NOT NULL CONSTRAINT [DF_Promotion_Status] DEFAULT (0),
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Promotion_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Promotion_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Promotion] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Promotion_TenantId_Code] ON [mkt].[Promotion] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Promotion_Status_StartAt] ON [mkt].[Promotion] ([Status], [StartAt]);
GO
CREATE INDEX [IX_Promotion_OrgId] ON [mkt].[Promotion] ([OrgId]);
GO
CREATE INDEX [IX_Promotion_CreatedBy] ON [mkt].[Promotion] ([CreatedBy]);
GO
CREATE INDEX [IX_Promotion_ModifiedBy] ON [mkt].[Promotion] ([ModifiedBy]);
GO
CREATE INDEX [IX_Promotion_DeletedBy] ON [mkt].[Promotion] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'促销活动', N'SCHEMA', N'mkt', N'TABLE', N'Promotion';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'活动名称', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1特价 2折扣 3满减 4满赠 5搭赠 6阶梯 7组合 8买赠 9第N件 10限时)', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'PromoType';
EXEC sp_addextendedproperty N'MS_Description', N'适用渠道位掩码(1批发 2零售 4线上 8全部)', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'ApplyChannel';
EXEC sp_addextendedproperty N'MS_Description', N'可叠加', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'CanStack';
EXEC sp_addextendedproperty N'MS_Description', N'适用星期', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'WeekDays';
EXEC sp_addextendedproperty N'MS_Description', N'适用时段', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'TimeRange';
EXEC sp_addextendedproperty N'MS_Description', N'规则明细(门槛/优惠/赠品/限购)', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'RuleJson';
EXEC sp_addextendedproperty N'MS_Description', N'预算额度', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'BudgetAmount';
EXEC sp_addextendedproperty N'MS_Description', N'已让利', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'UsedAmount';
EXEC sp_addextendedproperty N'MS_Description', N'自动执行(否=需领券)', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'IsAuto';
EXEC sp_addextendedproperty N'MS_Description', N'0草稿 1待审 2进行中 3已结束 9作废', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'Promotion', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [mkt].[PromotionScope] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [PromotionId] bigint NOT NULL,
    [ScopeType] tinyint NOT NULL CONSTRAINT [DF_PromotionScope_ScopeType] DEFAULT (1),
    [ScopeId] bigint NULL,
    [ScopeCode] varchar(40) NULL,
    [Exclude] bit NOT NULL CONSTRAINT [DF_PromotionScope_Exclude] DEFAULT (0),
    CONSTRAINT [PK_PromotionScope] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_PromotionScope_PromotionId_ScopeType] ON [mkt].[PromotionScope] ([PromotionId], [ScopeType]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'促销适用范围', N'SCHEMA', N'mkt', N'TABLE', N'PromotionScope';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'mkt', N'TABLE', N'PromotionScope', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'范围(1商品 2分类 3品牌 4客户 5客户等级 6门店 7渠道)', N'SCHEMA', N'mkt', N'TABLE', N'PromotionScope', N'COLUMN', N'ScopeType';
EXEC sp_addextendedproperty N'MS_Description', N'范围Id', N'SCHEMA', N'mkt', N'TABLE', N'PromotionScope', N'COLUMN', N'ScopeId';
EXEC sp_addextendedproperty N'MS_Description', N'范围编码', N'SCHEMA', N'mkt', N'TABLE', N'PromotionScope', N'COLUMN', N'ScopeCode';
EXEC sp_addextendedproperty N'MS_Description', N'排除', N'SCHEMA', N'mkt', N'TABLE', N'PromotionScope', N'COLUMN', N'Exclude';
GO
CREATE TABLE [mkt].[Coupon] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Coupon_TenantId] DEFAULT (1),
    [Code] varchar(40) NOT NULL,
    [Name] nvarchar(100) NULL,
    [CouponType] tinyint NOT NULL CONSTRAINT [DF_Coupon_CouponType] DEFAULT (1) CONSTRAINT [CK_Coupon_CouponType] CHECK (CouponType BETWEEN 1 AND 5),
    [FaceValue] decimal(19,4) NULL,
    [DiscountRate] decimal(9,4) NULL,
    [Threshold] decimal(19,4) NULL,
    [TotalQty] int NULL,
    [IssuedQty] int NOT NULL CONSTRAINT [DF_Coupon_IssuedQty] DEFAULT (0),
    [UsedQty] int NOT NULL CONSTRAINT [DF_Coupon_UsedQty] DEFAULT (0),
    [PerLimit] int NOT NULL CONSTRAINT [DF_Coupon_PerLimit] DEFAULT (1),
    [ValidFrom] datetime2(3) NULL,
    [ValidTo] datetime2(3) NULL,
    [ValidDays] int NULL,
    [ScopeJson] nvarchar(max) NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_Coupon_Status] DEFAULT (1),
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Coupon_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Coupon_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Coupon] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Coupon_TenantId_Code] ON [mkt].[Coupon] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Coupon_OrgId] ON [mkt].[Coupon] ([OrgId]);
GO
CREATE INDEX [IX_Coupon_CreatedBy] ON [mkt].[Coupon] ([CreatedBy]);
GO
CREATE INDEX [IX_Coupon_ModifiedBy] ON [mkt].[Coupon] ([ModifiedBy]);
GO
CREATE INDEX [IX_Coupon_DeletedBy] ON [mkt].[Coupon] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'优惠券模板', N'SCHEMA', N'mkt', N'TABLE', N'Coupon';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1满减 2折扣 3商品券 4运费券 5新人券)', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'CouponType';
EXEC sp_addextendedproperty N'MS_Description', N'面额', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'FaceValue';
EXEC sp_addextendedproperty N'MS_Description', N'折扣%', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'DiscountRate';
EXEC sp_addextendedproperty N'MS_Description', N'使用门槛', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'Threshold';
EXEC sp_addextendedproperty N'MS_Description', N'发行量', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'TotalQty';
EXEC sp_addextendedproperty N'MS_Description', N'每人限领', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'PerLimit';
EXEC sp_addextendedproperty N'MS_Description', N'领取后有效天数', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'ValidDays';
EXEC sp_addextendedproperty N'MS_Description', N'适用商品/门店', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'ScopeJson';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'Coupon', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [mkt].[CouponIssue] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_CouponIssue_TenantId] DEFAULT (1),
    [CouponId] bigint NOT NULL,
    [MemberId] bigint NULL,
    [IssueCode] varchar(40) NULL,
    [IssueType] tinyint NOT NULL CONSTRAINT [DF_CouponIssue_IssueType] DEFAULT (1),
    [IssuedAt] datetime2(3) NOT NULL CONSTRAINT [DF_CouponIssue_IssuedAt] DEFAULT (sysutcdatetime()),
    [ExpireAt] datetime2(3) NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_CouponIssue_Status] DEFAULT (0),
    [UsedAt] datetime2(3) NULL,
    [UsedSourceType] varchar(30) NULL,
    [UsedSourceId] bigint NULL,
    [DiscountAmount] decimal(19,4) NULL,
    CONSTRAINT [PK_CouponIssue] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_CouponIssue_TenantId_IssueCode] ON [mkt].[CouponIssue] ([TenantId], [IssueCode]);
GO
CREATE INDEX [IX_CouponIssue_MemberId_Status] ON [mkt].[CouponIssue] ([MemberId], [Status]);
GO
CREATE INDEX [IX_CouponIssue_CouponId_Status] ON [mkt].[CouponIssue] ([CouponId], [Status]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'优惠券发放与核销', N'SCHEMA', N'mkt', N'TABLE', N'CouponIssue';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'mkt', N'TABLE', N'CouponIssue', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'会员', N'SCHEMA', N'mkt', N'TABLE', N'CouponIssue', N'COLUMN', N'MemberId';
EXEC sp_addextendedproperty N'MS_Description', N'券码', N'SCHEMA', N'mkt', N'TABLE', N'CouponIssue', N'COLUMN', N'IssueCode';
EXEC sp_addextendedproperty N'MS_Description', N'1定向 2领取 3自动发放 4补偿', N'SCHEMA', N'mkt', N'TABLE', N'CouponIssue', N'COLUMN', N'IssueType';
EXEC sp_addextendedproperty N'MS_Description', N'过期时间', N'SCHEMA', N'mkt', N'TABLE', N'CouponIssue', N'COLUMN', N'ExpireAt';
EXEC sp_addextendedproperty N'MS_Description', N'0未用 1已用 2已过期 3已作废', N'SCHEMA', N'mkt', N'TABLE', N'CouponIssue', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'实际抵扣', N'SCHEMA', N'mkt', N'TABLE', N'CouponIssue', N'COLUMN', N'DiscountAmount';
GO
CREATE TABLE [mkt].[GuideProfile] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_GuideProfile_TenantId] DEFAULT (1),
    [EmployeeId] bigint NOT NULL,
    [StoreId] bigint NULL,
    [GuideCode] varchar(40) NOT NULL,
    [QrCodeUrl] nvarchar(300) NULL,
    [TargetAmount] decimal(19,4) NULL,
    [CommissionRate] decimal(9,4) NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_GuideProfile_IsEnabled] DEFAULT (1),
    [Code] varchar(32) NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_GuideProfile_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_GuideProfile_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_GuideProfile] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_GuideProfile_TenantId_GuideCode] ON [mkt].[GuideProfile] ([TenantId], [GuideCode]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_GuideProfile_EmployeeId] ON [mkt].[GuideProfile] ([EmployeeId]);
GO
CREATE INDEX [IX_GuideProfile_StoreId] ON [mkt].[GuideProfile] ([StoreId]);
GO
CREATE INDEX [IX_GuideProfile_OrgId] ON [mkt].[GuideProfile] ([OrgId]);
GO
CREATE INDEX [IX_GuideProfile_CreatedBy] ON [mkt].[GuideProfile] ([CreatedBy]);
GO
CREATE INDEX [IX_GuideProfile_ModifiedBy] ON [mkt].[GuideProfile] ([ModifiedBy]);
GO
CREATE INDEX [IX_GuideProfile_DeletedBy] ON [mkt].[GuideProfile] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'导购档案', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'员工', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'EmployeeId';
EXEC sp_addextendedproperty N'MS_Description', N'门店', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'StoreId';
EXEC sp_addextendedproperty N'MS_Description', N'专属码', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'GuideCode';
EXEC sp_addextendedproperty N'MS_Description', N'专属二维码', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'QrCodeUrl';
EXEC sp_addextendedproperty N'MS_Description', N'月度目标', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'TargetAmount';
EXEC sp_addextendedproperty N'MS_Description', N'提成比例%', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'CommissionRate';
EXEC sp_addextendedproperty N'MS_Description', N'业务编码', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'GuideProfile', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [mkt].[MemberSegment] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_MemberSegment_TenantId] DEFAULT (1),
    [Code] varchar(40) NOT NULL,
    [Name] nvarchar(100) NULL,
    [SegmentType] tinyint NOT NULL CONSTRAINT [DF_MemberSegment_SegmentType] DEFAULT (1),
    [RuleJson] nvarchar(max) NULL,
    [MemberCount] int NOT NULL CONSTRAINT [DF_MemberSegment_MemberCount] DEFAULT (0),
    [LastCalcAt] datetime2(3) NULL,
    [CreatedBy] bigint NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_MemberSegment_IsDeleted] DEFAULT (0),
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_MemberSegment_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_MemberSegment] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_MemberSegment_TenantId_Code] ON [mkt].[MemberSegment] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_MemberSegment_OrgId] ON [mkt].[MemberSegment] ([OrgId]);
GO
CREATE INDEX [IX_MemberSegment_ModifiedBy] ON [mkt].[MemberSegment] ([ModifiedBy]);
GO
CREATE INDEX [IX_MemberSegment_DeletedBy] ON [mkt].[MemberSegment] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'人群包', N'SCHEMA', N'mkt', N'TABLE', N'MemberSegment';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'mkt', N'TABLE', N'MemberSegment', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1规则圈选 2RFM 3导入)', N'SCHEMA', N'mkt', N'TABLE', N'MemberSegment', N'COLUMN', N'SegmentType';
EXEC sp_addextendedproperty N'MS_Description', N'圈选条件', N'SCHEMA', N'mkt', N'TABLE', N'MemberSegment', N'COLUMN', N'RuleJson';
EXEC sp_addextendedproperty N'MS_Description', N'最近计算', N'SCHEMA', N'mkt', N'TABLE', N'MemberSegment', N'COLUMN', N'LastCalcAt';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'mkt', N'TABLE', N'MemberSegment', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'mkt', N'TABLE', N'MemberSegment', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'mkt', N'TABLE', N'MemberSegment', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'mkt', N'TABLE', N'MemberSegment', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'MemberSegment', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'mkt', N'TABLE', N'MemberSegment', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'MemberSegment', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'mkt', N'TABLE', N'MemberSegment', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'mkt', N'TABLE', N'MemberSegment', N'COLUMN', N'DeletedAt';
GO
/* =====================================================================
   进销存管理系统 V3 · 表结构 · plat 架构（57 张表）
   数据库：APSErpV3   生成器：db/emit.py（请勿手改，改规格文件后重新生成）
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE TABLE [plat].[Tenant] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Code] varchar(20) NULL,
    [Name] nvarchar(100) NULL,
    [ShortName] nvarchar(50) NULL,
    [Industry] nvarchar(50) NULL,
    [Contact] nvarchar(50) NULL,
    [Phone] varchar(30) NULL,
    [TimeZone] varchar(50) NOT NULL CONSTRAINT [DF_Tenant_TimeZone] DEFAULT ('China Standard Time'),
    [CurrencyCode] varchar(3) NOT NULL CONSTRAINT [DF_Tenant_CurrencyCode] DEFAULT ('CNY'),
    [DeploymentMode] tinyint NOT NULL CONSTRAINT [DF_Tenant_DeploymentMode] DEFAULT (1) CONSTRAINT [CK_Tenant_DeploymentMode] CHECK (DeploymentMode BETWEEN 1 AND 2),
    [ConnectionKey] varchar(50) NULL,
    [DbName] varchar(100) NULL,
    [ShardId] int NOT NULL CONSTRAINT [DF_Tenant_ShardId] DEFAULT (0),
    [MaxUsers] int NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Tenant_IsEnabled] DEFAULT (1),
    [ExpireAt] datetime2(3) NULL,
    [LicenseJson] nvarchar(max) NULL,
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Tenant_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Tenant_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Tenant] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Tenant_Code] ON [plat].[Tenant] ([Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Tenant_IsEnabled] ON [plat].[Tenant] ([IsEnabled]);
GO
CREATE INDEX [IX_Tenant_CreatedBy] ON [plat].[Tenant] ([CreatedBy]);
GO
CREATE INDEX [IX_Tenant_ModifiedBy] ON [plat].[Tenant] ([ModifiedBy]);
GO
CREATE INDEX [IX_Tenant_DeletedBy] ON [plat].[Tenant] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'plat', N'TABLE', N'Tenant';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户编码', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'租户名称', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'简称', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'ShortName';
EXEC sp_addextendedproperty N'MS_Description', N'行业', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'Industry';
EXEC sp_addextendedproperty N'MS_Description', N'联系人', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'Contact';
EXEC sp_addextendedproperty N'MS_Description', N'电话', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'Phone';
EXEC sp_addextendedproperty N'MS_Description', N'时区', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'TimeZone';
EXEC sp_addextendedproperty N'MS_Description', N'本位币', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'CurrencyCode';
EXEC sp_addextendedproperty N'MS_Description', N'部署形态(1共享库 2独立库)', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'DeploymentMode';
EXEC sp_addextendedproperty N'MS_Description', N'独立库连接键(引用密钥库,不存明文)', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'ConnectionKey';
EXEC sp_addextendedproperty N'MS_Description', N'独立库名', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'DbName';
EXEC sp_addextendedproperty N'MS_Description', N'分片号(0=未分片)', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'ShardId';
EXEC sp_addextendedproperty N'MS_Description', N'许可用户数', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'MaxUsers';
EXEC sp_addextendedproperty N'MS_Description', N'启用', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'IsEnabled';
EXEC sp_addextendedproperty N'MS_Description', N'到期时间', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'ExpireAt';
EXEC sp_addextendedproperty N'MS_Description', N'授权信息', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'LicenseJson';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Tenant', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[TenantShard] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [ShardId] int NOT NULL CONSTRAINT [DF_TenantShard_ShardId] DEFAULT (0),
    [DbName] varchar(100) NOT NULL,
    [ServerName] varchar(100) NULL,
    [ConnectionKey] varchar(50) NULL,
    [ShardRole] tinyint NOT NULL CONSTRAINT [DF_TenantShard_ShardRole] DEFAULT (1) CONSTRAINT [CK_TenantShard_ShardRole] CHECK (ShardRole BETWEEN 1 AND 3),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_TenantShard_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(300) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_TenantShard_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_TenantShard_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_TenantShard] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_TenantShard_TenantId_ShardId_ShardRole] ON [plat].[TenantShard] ([TenantId], [ShardId], [ShardRole]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_TenantShard_DbName] ON [plat].[TenantShard] ([DbName]);
GO
CREATE INDEX [IX_TenantShard_CreatedBy] ON [plat].[TenantShard] ([CreatedBy]);
GO
CREATE INDEX [IX_TenantShard_ModifiedBy] ON [plat].[TenantShard] ([ModifiedBy]);
GO
CREATE INDEX [IX_TenantShard_DeletedBy] ON [plat].[TenantShard] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'租户分片路由（共享库=1片，独立库=N片）', N'SCHEMA', N'plat', N'TABLE', N'TenantShard';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'TenantShard', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'分片号', N'SCHEMA', N'plat', N'TABLE', N'TenantShard', N'COLUMN', N'ShardId';
EXEC sp_addextendedproperty N'MS_Description', N'数据库名', N'SCHEMA', N'plat', N'TABLE', N'TenantShard', N'COLUMN', N'DbName';
EXEC sp_addextendedproperty N'MS_Description', N'服务器/实例', N'SCHEMA', N'plat', N'TABLE', N'TenantShard', N'COLUMN', N'ServerName';
EXEC sp_addextendedproperty N'MS_Description', N'连接键(密钥库引用)', N'SCHEMA', N'plat', N'TABLE', N'TenantShard', N'COLUMN', N'ConnectionKey';
EXEC sp_addextendedproperty N'MS_Description', N'角色(1主库读写 2只读副本 3归档库)', N'SCHEMA', N'plat', N'TABLE', N'TenantShard', N'COLUMN', N'ShardRole';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'TenantShard', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'TenantShard', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'TenantShard', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'TenantShard', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'TenantShard', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'TenantShard', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'TenantShard', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'TenantShard', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[SchemaVersion] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [DbName] varchar(100) NOT NULL,
    [Version] varchar(30) NOT NULL,
    [ScriptName] varchar(200) NULL,
    [ContentHash] varchar(64) NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_SchemaVersion_Status] DEFAULT (1) CONSTRAINT [CK_SchemaVersion_Status] CHECK (Status BETWEEN 1 AND 3),
    [DurationMs] int NULL,
    [AppliedBy] varchar(50) NULL,
    [AppliedAt] datetime2(3) NOT NULL CONSTRAINT [DF_SchemaVersion_AppliedAt] DEFAULT (sysutcdatetime()),
    [Remark] nvarchar(500) NULL,
    CONSTRAINT [PK_SchemaVersion] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_SchemaVersion_DbName_Version_ScriptName] ON [plat].[SchemaVersion] ([DbName], [Version], [ScriptName]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'库级版本（独立库部署与升级记录）', N'SCHEMA', N'plat', N'TABLE', N'SchemaVersion';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'SchemaVersion', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'数据库名', N'SCHEMA', N'plat', N'TABLE', N'SchemaVersion', N'COLUMN', N'DbName';
EXEC sp_addextendedproperty N'MS_Description', N'版本号', N'SCHEMA', N'plat', N'TABLE', N'SchemaVersion', N'COLUMN', N'Version';
EXEC sp_addextendedproperty N'MS_Description', N'脚本名', N'SCHEMA', N'plat', N'TABLE', N'SchemaVersion', N'COLUMN', N'ScriptName';
EXEC sp_addextendedproperty N'MS_Description', N'内容哈希', N'SCHEMA', N'plat', N'TABLE', N'SchemaVersion', N'COLUMN', N'ContentHash';
EXEC sp_addextendedproperty N'MS_Description', N'状态(1成功 2失败 3已回滚)', N'SCHEMA', N'plat', N'TABLE', N'SchemaVersion', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'耗时', N'SCHEMA', N'plat', N'TABLE', N'SchemaVersion', N'COLUMN', N'DurationMs';
EXEC sp_addextendedproperty N'MS_Description', N'执行人', N'SCHEMA', N'plat', N'TABLE', N'SchemaVersion', N'COLUMN', N'AppliedBy';
GO
CREATE TABLE [plat].[TenantQuota] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL,
    [QuotaType] tinyint NOT NULL CONSTRAINT [DF_TenantQuota_QuotaType] DEFAULT (1) CONSTRAINT [CK_TenantQuota_QuotaType] CHECK (QuotaType BETWEEN 1 AND 6),
    [Period] varchar(10) NOT NULL CONSTRAINT [DF_TenantQuota_Period] DEFAULT ('ALL'),
    [QuotaValue] decimal(19,4) NOT NULL CONSTRAINT [DF_TenantQuota_QuotaValue] DEFAULT (0),
    [UsedValue] decimal(19,4) NOT NULL CONSTRAINT [DF_TenantQuota_UsedValue] DEFAULT (0),
    [WarnRate] decimal(9,4) NOT NULL CONSTRAINT [DF_TenantQuota_WarnRate] DEFAULT (80),
    [ResetCycle] tinyint NOT NULL CONSTRAINT [DF_TenantQuota_ResetCycle] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_TenantQuota_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(300) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_TenantQuota_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_TenantQuota_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_TenantQuota] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_TenantQuota_TenantId_QuotaType_Period] ON [plat].[TenantQuota] ([TenantId], [QuotaType], [Period]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_TenantQuota_CreatedBy] ON [plat].[TenantQuota] ([CreatedBy]);
GO
CREATE INDEX [IX_TenantQuota_ModifiedBy] ON [plat].[TenantQuota] ([ModifiedBy]);
GO
CREATE INDEX [IX_TenantQuota_DeletedBy] ON [plat].[TenantQuota] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'租户配额（限流与计费）', N'SCHEMA', N'plat', N'TABLE', N'TenantQuota';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'TenantQuota', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1存储GB 2并发 3单据量/月 4API/日 5用户数 6附件GB)', N'SCHEMA', N'plat', N'TABLE', N'TenantQuota', N'COLUMN', N'QuotaType';
EXEC sp_addextendedproperty N'MS_Description', N'周期(ALL/2026-01/20260101)', N'SCHEMA', N'plat', N'TABLE', N'TenantQuota', N'COLUMN', N'Period';
EXEC sp_addextendedproperty N'MS_Description', N'配额', N'SCHEMA', N'plat', N'TABLE', N'TenantQuota', N'COLUMN', N'QuotaValue';
EXEC sp_addextendedproperty N'MS_Description', N'已用', N'SCHEMA', N'plat', N'TABLE', N'TenantQuota', N'COLUMN', N'UsedValue';
EXEC sp_addextendedproperty N'MS_Description', N'预警阈值%', N'SCHEMA', N'plat', N'TABLE', N'TenantQuota', N'COLUMN', N'WarnRate';
EXEC sp_addextendedproperty N'MS_Description', N'重置(0不重置 1月 2日)', N'SCHEMA', N'plat', N'TABLE', N'TenantQuota', N'COLUMN', N'ResetCycle';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'TenantQuota', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'TenantQuota', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'TenantQuota', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'TenantQuota', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'TenantQuota', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'TenantQuota', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'TenantQuota', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'TenantQuota', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[Org] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Org_TenantId] DEFAULT (1),
    [ParentId] int NULL,
    [Code] varchar(32) NULL,
    [Name] nvarchar(100) NULL,
    [OrgType] tinyint NOT NULL CONSTRAINT [DF_Org_OrgType] DEFAULT (1) CONSTRAINT [CK_Org_OrgType] CHECK (OrgType BETWEEN 1 AND 5),
    [Path] varchar(500) NULL,
    [Level] tinyint NOT NULL CONSTRAINT [DF_Org_Level] DEFAULT (1),
    [ManagerId] bigint NULL,
    [Address] nvarchar(200) NULL,
    [Phone] varchar(30) NULL,
    [IsLeaf] bit NOT NULL CONSTRAINT [DF_Org_IsLeaf] DEFAULT (1),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Org_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Org_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Org_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Org] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Org_TenantId_Code] ON [plat].[Org] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Org_TenantId_ParentId] ON [plat].[Org] ([TenantId], [ParentId]);
GO
CREATE INDEX [IX_Org_TenantId_OrgType] ON [plat].[Org] ([TenantId], [OrgType]);
GO
CREATE INDEX [IX_Org_ParentId] ON [plat].[Org] ([ParentId]);
GO
CREATE INDEX [IX_Org_CreatedBy] ON [plat].[Org] ([CreatedBy]);
GO
CREATE INDEX [IX_Org_ModifiedBy] ON [plat].[Org] ([ModifiedBy]);
GO
CREATE INDEX [IX_Org_DeletedBy] ON [plat].[Org] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'组织（公司/部门/门店/仓库统一树）', N'SCHEMA', N'plat', N'TABLE', N'Org';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'租户', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'TenantId';
EXEC sp_addextendedproperty N'MS_Description', N'上级组织', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'ParentId';
EXEC sp_addextendedproperty N'MS_Description', N'组织编码', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'组织名称', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1公司 2部门 3门店 4仓库 5小组)', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'OrgType';
EXEC sp_addextendedproperty N'MS_Description', N'层级路径(/1/5/12/)', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'Path';
EXEC sp_addextendedproperty N'MS_Description', N'层级', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'Level';
EXEC sp_addextendedproperty N'MS_Description', N'负责人', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'ManagerId';
EXEC sp_addextendedproperty N'MS_Description', N'地址', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'Address';
EXEC sp_addextendedproperty N'MS_Description', N'电话', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'Phone';
EXEC sp_addextendedproperty N'MS_Description', N'是否末级', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'IsLeaf';
EXEC sp_addextendedproperty N'MS_Description', N'启用', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'IsEnabled';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Org', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[Employee] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Employee_TenantId] DEFAULT (1),
    [Code] varchar(32) NULL,
    [Name] nvarchar(50) NULL,
    [OrgId] int NULL,
    [Position] nvarchar(50) NULL,
    [Mobile] varchar(30) NULL,
    [IdCard] varchar(30) NULL,
    [HireDate] date NULL,
    [LeaveDate] date NULL,
    [IsSalesman] bit NOT NULL CONSTRAINT [DF_Employee_IsSalesman] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Employee_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Employee_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Employee_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Employee] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Employee_TenantId_Code] ON [plat].[Employee] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Employee_TenantId_OrgId] ON [plat].[Employee] ([TenantId], [OrgId]);
GO
CREATE INDEX [IX_Employee_OrgId] ON [plat].[Employee] ([OrgId]);
GO
CREATE INDEX [IX_Employee_CreatedBy] ON [plat].[Employee] ([CreatedBy]);
GO
CREATE INDEX [IX_Employee_ModifiedBy] ON [plat].[Employee] ([ModifiedBy]);
GO
CREATE INDEX [IX_Employee_DeletedBy] ON [plat].[Employee] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'员工', N'SCHEMA', N'plat', N'TABLE', N'Employee';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'工号', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'姓名', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'所属组织', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'岗位', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'Position';
EXEC sp_addextendedproperty N'MS_Description', N'手机', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'Mobile';
EXEC sp_addextendedproperty N'MS_Description', N'身份证', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'IdCard';
EXEC sp_addextendedproperty N'MS_Description', N'入职日期', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'HireDate';
EXEC sp_addextendedproperty N'MS_Description', N'离职日期', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'LeaveDate';
EXEC sp_addextendedproperty N'MS_Description', N'是否业务员(业绩归属)', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'IsSalesman';
EXEC sp_addextendedproperty N'MS_Description', N'启用', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'IsEnabled';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Employee', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[User] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_User_TenantId] DEFAULT (1),
    [UserName] varchar(50) NULL,
    [PasswordHash] varchar(200) NULL,
    [PasswordSalt] varchar(50) NULL,
    [PasswordUpdatedAt] datetime2(3) NULL,
    [EmployeeId] bigint NULL,
    [DisplayName] nvarchar(50) NULL,
    [UserType] tinyint NOT NULL CONSTRAINT [DF_User_UserType] DEFAULT (1) CONSTRAINT [CK_User_UserType] CHECK (UserType BETWEEN 1 AND 4),
    [PartnerId] bigint NULL,
    [Mobile] varchar(30) NULL,
    [Email] varchar(100) NULL,
    [DefaultOrgId] int NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_User_IsEnabled] DEFAULT (1),
    [LockedUntil] datetime2(3) NULL,
    [FailCount] int NOT NULL CONSTRAINT [DF_User_FailCount] DEFAULT (0),
    [MustChangePwd] bit NOT NULL CONSTRAINT [DF_User_MustChangePwd] DEFAULT (0),
    [MfaEnabled] bit NOT NULL CONSTRAINT [DF_User_MfaEnabled] DEFAULT (0),
    [LastLoginAt] datetime2(3) NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_User_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_User_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_User] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_User_TenantId_UserName] ON [plat].[User] ([TenantId], [UserName]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_User_TenantId_EmployeeId] ON [plat].[User] ([TenantId], [EmployeeId]);
GO
CREATE INDEX [IX_User_TenantId_UserType] ON [plat].[User] ([TenantId], [UserType]);
GO
CREATE INDEX [IX_User_EmployeeId] ON [plat].[User] ([EmployeeId]);
GO
CREATE INDEX [IX_User_DefaultOrgId] ON [plat].[User] ([DefaultOrgId]);
GO
CREATE INDEX [IX_User_CreatedBy] ON [plat].[User] ([CreatedBy]);
GO
CREATE INDEX [IX_User_ModifiedBy] ON [plat].[User] ([ModifiedBy]);
GO
CREATE INDEX [IX_User_DeletedBy] ON [plat].[User] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'登录账号', N'SCHEMA', N'plat', N'TABLE', N'User';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'登录名', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'UserName';
EXEC sp_addextendedproperty N'MS_Description', N'密码哈希(PBKDF2/BCrypt)', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'PasswordHash';
EXEC sp_addextendedproperty N'MS_Description', N'盐', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'PasswordSalt';
EXEC sp_addextendedproperty N'MS_Description', N'密码修改时间', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'PasswordUpdatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'关联员工', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'EmployeeId';
EXEC sp_addextendedproperty N'MS_Description', N'显示名', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'DisplayName';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1内部 2供应商 3经销商 4服务商)', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'UserType';
EXEC sp_addextendedproperty N'MS_Description', N'外部用户关联往来单位', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'手机', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'Mobile';
EXEC sp_addextendedproperty N'MS_Description', N'邮箱', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'Email';
EXEC sp_addextendedproperty N'MS_Description', N'默认组织', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'DefaultOrgId';
EXEC sp_addextendedproperty N'MS_Description', N'启用', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'IsEnabled';
EXEC sp_addextendedproperty N'MS_Description', N'锁定至', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'LockedUntil';
EXEC sp_addextendedproperty N'MS_Description', N'连续失败次数', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'FailCount';
EXEC sp_addextendedproperty N'MS_Description', N'首次登录改密', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'MustChangePwd';
EXEC sp_addextendedproperty N'MS_Description', N'双因子', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'MfaEnabled';
EXEC sp_addextendedproperty N'MS_Description', N'最后登录', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'LastLoginAt';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[UserOrg] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_UserOrg_TenantId] DEFAULT (1),
    [UserId] bigint NOT NULL,
    [OrgId] int NOT NULL,
    [IncludeChild] bit NOT NULL CONSTRAINT [DF_UserOrg_IncludeChild] DEFAULT (1),
    CONSTRAINT [PK_UserOrg] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_UserOrg_UserId_OrgId] ON [plat].[UserOrg] ([UserId], [OrgId]);
GO
CREATE INDEX [IX_UserOrg_OrgId] ON [plat].[UserOrg] ([OrgId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'用户数据范围（可访问组织）', N'SCHEMA', N'plat', N'TABLE', N'UserOrg';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'UserOrg', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'含下级', N'SCHEMA', N'plat', N'TABLE', N'UserOrg', N'COLUMN', N'IncludeChild';
GO
CREATE TABLE [plat].[Role] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Role_TenantId] DEFAULT (1),
    [Code] varchar(32) NULL,
    [Name] nvarchar(50) NULL,
    [RoleType] tinyint NOT NULL CONSTRAINT [DF_Role_RoleType] DEFAULT (1) CONSTRAINT [CK_Role_RoleType] CHECK (RoleType BETWEEN 1 AND 3),
    [IsSystem] bit NOT NULL CONSTRAINT [DF_Role_IsSystem] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Role_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Role_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Role_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Role] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Role_TenantId_Code] ON [plat].[Role] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Role_CreatedBy] ON [plat].[Role] ([CreatedBy]);
GO
CREATE INDEX [IX_Role_ModifiedBy] ON [plat].[Role] ([ModifiedBy]);
GO
CREATE INDEX [IX_Role_DeletedBy] ON [plat].[Role] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'角色', N'SCHEMA', N'plat', N'TABLE', N'Role';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'Role', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'角色编码', N'SCHEMA', N'plat', N'TABLE', N'Role', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'角色名称', N'SCHEMA', N'plat', N'TABLE', N'Role', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1内部 2外部供应商 3外部经销商)', N'SCHEMA', N'plat', N'TABLE', N'Role', N'COLUMN', N'RoleType';
EXEC sp_addextendedproperty N'MS_Description', N'系统内置(不可删)', N'SCHEMA', N'plat', N'TABLE', N'Role', N'COLUMN', N'IsSystem';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'Role', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'Role', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'Role', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'Role', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Role', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'Role', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Role', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'Role', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Role', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[UserRole] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_UserRole_TenantId] DEFAULT (1),
    [UserId] bigint NOT NULL,
    [RoleId] bigint NOT NULL,
    [OrgId] int NULL,
    CONSTRAINT [PK_UserRole] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_UserRole_UserId_RoleId_OrgId] ON [plat].[UserRole] ([UserId], [RoleId], [OrgId]);
GO
CREATE INDEX [IX_UserRole_RoleId] ON [plat].[UserRole] ([RoleId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'用户角色', N'SCHEMA', N'plat', N'TABLE', N'UserRole';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'UserRole', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'授权范围组织(空=全组织)', N'SCHEMA', N'plat', N'TABLE', N'UserRole', N'COLUMN', N'OrgId';
GO
CREATE TABLE [plat].[Permission] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Permission_TenantId] DEFAULT (1),
    [ResourceKey] varchar(120) NOT NULL,
    [ResourceType] tinyint NOT NULL CONSTRAINT [DF_Permission_ResourceType] DEFAULT (1) CONSTRAINT [CK_Permission_ResourceType] CHECK (ResourceType BETWEEN 1 AND 6),
    [Name] nvarchar(100) NULL,
    [ParentKey] varchar(120) NULL,
    [ModuleId] bigint NULL,
    [FunctionId] bigint NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Permission_IsEnabled] DEFAULT (1),
    CONSTRAINT [PK_Permission] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Permission_TenantId_ResourceKey] ON [plat].[Permission] ([TenantId], [ResourceKey]);
GO
CREATE INDEX [IX_Permission_TenantId_ResourceType] ON [plat].[Permission] ([TenantId], [ResourceType]);
GO
CREATE INDEX [IX_Permission_ParentKey] ON [plat].[Permission] ([ParentKey]);
GO
CREATE INDEX [IX_Permission_ModuleId] ON [plat].[Permission] ([ModuleId]);
GO
CREATE INDEX [IX_Permission_FunctionId] ON [plat].[Permission] ([FunctionId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'权限资源', N'SCHEMA', N'plat', N'TABLE', N'Permission';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'Permission', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'资源码(MOD:/FUN:/BTN:/FIELD:/API:)', N'SCHEMA', N'plat', N'TABLE', N'Permission', N'COLUMN', N'ResourceKey';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1模块 2功能 3按钮 4字段 5接口 6数据集)', N'SCHEMA', N'plat', N'TABLE', N'Permission', N'COLUMN', N'ResourceType';
EXEC sp_addextendedproperty N'MS_Description', N'名称', N'SCHEMA', N'plat', N'TABLE', N'Permission', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'父资源码', N'SCHEMA', N'plat', N'TABLE', N'Permission', N'COLUMN', N'ParentKey';
EXEC sp_addextendedproperty N'MS_Description', N'关联模块', N'SCHEMA', N'plat', N'TABLE', N'Permission', N'COLUMN', N'ModuleId';
EXEC sp_addextendedproperty N'MS_Description', N'关联功能', N'SCHEMA', N'plat', N'TABLE', N'Permission', N'COLUMN', N'FunctionId';
GO
CREATE TABLE [plat].[RolePermission] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_RolePermission_TenantId] DEFAULT (1),
    [RoleId] bigint NOT NULL,
    [PermissionId] bigint NOT NULL,
    [Allow] bit NOT NULL CONSTRAINT [DF_RolePermission_Allow] DEFAULT (1),
    [CanRead] bit NOT NULL CONSTRAINT [DF_RolePermission_CanRead] DEFAULT (1),
    [CanWrite] bit NOT NULL CONSTRAINT [DF_RolePermission_CanWrite] DEFAULT (0),
    [CanApprove] bit NOT NULL CONSTRAINT [DF_RolePermission_CanApprove] DEFAULT (0),
    [CanExport] bit NOT NULL CONSTRAINT [DF_RolePermission_CanExport] DEFAULT (0),
    [CanDelete] bit NOT NULL CONSTRAINT [DF_RolePermission_CanDelete] DEFAULT (0),
    [DataScope] tinyint NOT NULL CONSTRAINT [DF_RolePermission_DataScope] DEFAULT (2) CONSTRAINT [CK_RolePermission_DataScope] CHECK (DataScope BETWEEN 1 AND 5),
    [ScopeOrgIds] nvarchar(max) NULL,
    [GrantedBy] bigint NULL,
    [GrantedAt] datetime2(3) NOT NULL CONSTRAINT [DF_RolePermission_GrantedAt] DEFAULT (sysutcdatetime()),
    CONSTRAINT [PK_RolePermission] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_RolePermission_RoleId_PermissionId] ON [plat].[RolePermission] ([RoleId], [PermissionId]);
GO
CREATE INDEX [IX_RolePermission_TenantId_PermissionId] ON [plat].[RolePermission] ([TenantId], [PermissionId]);
GO
CREATE INDEX [IX_RolePermission_PermissionId] ON [plat].[RolePermission] ([PermissionId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'角色权限（含数据范围）', N'SCHEMA', N'plat', N'TABLE', N'RolePermission';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'RolePermission', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'允许/拒绝', N'SCHEMA', N'plat', N'TABLE', N'RolePermission', N'COLUMN', N'Allow';
EXEC sp_addextendedproperty N'MS_Description', N'数据范围(1全部 2本组织及下级 3本组织 4本人 5自定义)', N'SCHEMA', N'plat', N'TABLE', N'RolePermission', N'COLUMN', N'DataScope';
EXEC sp_addextendedproperty N'MS_Description', N'自定义范围组织JSON', N'SCHEMA', N'plat', N'TABLE', N'RolePermission', N'COLUMN', N'ScopeOrgIds';
EXEC sp_addextendedproperty N'MS_Description', N'授权人', N'SCHEMA', N'plat', N'TABLE', N'RolePermission', N'COLUMN', N'GrantedBy';
GO
CREATE TABLE [plat].[FieldPermission] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_FieldPermission_TenantId] DEFAULT (1),
    [RoleId] bigint NOT NULL,
    [ObjectName] varchar(100) NOT NULL,
    [FieldName] varchar(100) NOT NULL,
    [Access] tinyint NOT NULL CONSTRAINT [DF_FieldPermission_Access] DEFAULT (0) CONSTRAINT [CK_FieldPermission_Access] CHECK (Access BETWEEN 0 AND 2),
    CONSTRAINT [PK_FieldPermission] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_FieldPermission_RoleId_ObjectName_FieldName] ON [plat].[FieldPermission] ([RoleId], [ObjectName], [FieldName]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'字段级权限（成本/底价等敏感字段）', N'SCHEMA', N'plat', N'TABLE', N'FieldPermission';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'FieldPermission', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'表/数据对象', N'SCHEMA', N'plat', N'TABLE', N'FieldPermission', N'COLUMN', N'ObjectName';
EXEC sp_addextendedproperty N'MS_Description', N'字段', N'SCHEMA', N'plat', N'TABLE', N'FieldPermission', N'COLUMN', N'FieldName';
EXEC sp_addextendedproperty N'MS_Description', N'权限(0隐藏 1只读 2可写)', N'SCHEMA', N'plat', N'TABLE', N'FieldPermission', N'COLUMN', N'Access';
GO
CREATE TABLE [plat].[Module] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Module_TenantId] DEFAULT (1),
    [ParentId] bigint NULL,
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    [EnCode] varchar(20) NULL,
    [Level] tinyint NOT NULL CONSTRAINT [DF_Module_Level] DEFAULT (1) CONSTRAINT [CK_Module_Level] CHECK ([Level] BETWEEN 1 AND 3),
    [ModuleType] tinyint NOT NULL CONSTRAINT [DF_Module_ModuleType] DEFAULT (1) CONSTRAINT [CK_Module_ModuleType] CHECK (ModuleType BETWEEN 1 AND 3),
    [Sort] int NOT NULL CONSTRAINT [DF_Module_Sort] DEFAULT (0),
    [Icon] varchar(100) NULL,
    [Description] nvarchar(500) NULL,
    [DocType] varchar(30) NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Module_IsEnabled] DEFAULT (1),
    [Version] int NOT NULL CONSTRAINT [DF_Module_Version] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Module_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Module_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Module] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Module_TenantId_Code] ON [plat].[Module] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Module_TenantId_ParentId_Sort] ON [plat].[Module] ([TenantId], [ParentId], [Sort]);
GO
CREATE INDEX [IX_Module_ParentId] ON [plat].[Module] ([ParentId]);
GO
CREATE INDEX [IX_Module_CreatedBy] ON [plat].[Module] ([CreatedBy]);
GO
CREATE INDEX [IX_Module_ModifiedBy] ON [plat].[Module] ([ModifiedBy]);
GO
CREATE INDEX [IX_Module_DeletedBy] ON [plat].[Module] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'模块（域/二级/菜单三级树）', N'SCHEMA', N'plat', N'TABLE', N'Module';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'上级模块', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'ParentId';
EXEC sp_addextendedproperty N'MS_Description', N'模块编码(01/0101/010101)', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'模块名称', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'英文域码(PLT/PUR/SAL...)', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'EnCode';
EXEC sp_addextendedproperty N'MS_Description', N'层级(1域 2二级 3菜单)', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'Level';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1目录 2功能菜单 3虚拟菜单)', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'ModuleType';
EXEC sp_addextendedproperty N'MS_Description', N'排序', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'Sort';
EXEC sp_addextendedproperty N'MS_Description', N'图标', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'Icon';
EXEC sp_addextendedproperty N'MS_Description', N'职责说明', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'Description';
EXEC sp_addextendedproperty N'MS_Description', N'单据类型(生成单号用)', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'DocType';
EXEC sp_addextendedproperty N'MS_Description', N'元数据版本', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'Version';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Module', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[ModuleFunction] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_ModuleFunction_TenantId] DEFAULT (1),
    [ModuleId] bigint NOT NULL,
    [Code] varchar(60) NOT NULL,
    [Name] nvarchar(50) NOT NULL,
    [FunType] tinyint NOT NULL CONSTRAINT [DF_ModuleFunction_FunType] DEFAULT (1) CONSTRAINT [CK_ModuleFunction_FunType] CHECK (FunType BETWEEN 1 AND 4),
    [Sort] int NOT NULL CONSTRAINT [DF_ModuleFunction_Sort] DEFAULT (0),
    [IsPermissionPoint] bit NOT NULL CONSTRAINT [DF_ModuleFunction_IsPermissionPoint] DEFAULT (1),
    [ConfirmText] nvarchar(200) NULL,
    [SuccessMessage] nvarchar(200) NULL,
    [Icon] varchar(100) NULL,
    [HotKey] varchar(30) NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_ModuleFunction_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_ModuleFunction_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_ModuleFunction_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_ModuleFunction] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ModuleFunction_TenantId_ModuleId_Code] ON [plat].[ModuleFunction] ([TenantId], [ModuleId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_ModuleFunction_ModuleId] ON [plat].[ModuleFunction] ([ModuleId]);
GO
CREATE INDEX [IX_ModuleFunction_CreatedBy] ON [plat].[ModuleFunction] ([CreatedBy]);
GO
CREATE INDEX [IX_ModuleFunction_ModifiedBy] ON [plat].[ModuleFunction] ([ModifiedBy]);
GO
CREATE INDEX [IX_ModuleFunction_DeletedBy] ON [plat].[ModuleFunction] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'模块功能点（替代 FunName01..15）', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'功能编码(VIEW/ADD/EDIT/DEL/AUDIT/...)', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'功能名称', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1内置动作 2自定义动作 3脚本 4接口)', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'FunType';
EXEC sp_addextendedproperty N'MS_Description', N'是否作为权限点', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'IsPermissionPoint';
EXEC sp_addextendedproperty N'MS_Description', N'二次确认提示', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'ConfirmText';
EXEC sp_addextendedproperty N'MS_Description', N'成功提示', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'SuccessMessage';
EXEC sp_addextendedproperty N'MS_Description', N'图标', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'Icon';
EXEC sp_addextendedproperty N'MS_Description', N'快捷键', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'HotKey';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'ModuleFunction', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[FunctionAction] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_FunctionAction_TenantId] DEFAULT (1),
    [FunctionId] bigint NOT NULL,
    [Seq] int NOT NULL CONSTRAINT [DF_FunctionAction_Seq] DEFAULT (10),
    [Phase] tinyint NOT NULL CONSTRAINT [DF_FunctionAction_Phase] DEFAULT (1) CONSTRAINT [CK_FunctionAction_Phase] CHECK (Phase BETWEEN 1 AND 6),
    [ActionType] tinyint NOT NULL CONSTRAINT [DF_FunctionAction_ActionType] DEFAULT (1) CONSTRAINT [CK_FunctionAction_ActionType] CHECK (ActionType BETWEEN 1 AND 5),
    [ActionCode] varchar(60) NULL,
    [Target] varchar(200) NULL,
    [Command] nvarchar(max) NULL,
    [ParamJson] nvarchar(max) NULL,
    [ContinueOnError] bit NOT NULL CONSTRAINT [DF_FunctionAction_ContinueOnError] DEFAULT (0),
    [ErrorMessage] nvarchar(200) NULL,
    [TimeoutSeconds] int NOT NULL CONSTRAINT [DF_FunctionAction_TimeoutSeconds] DEFAULT (30),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_FunctionAction_IsEnabled] DEFAULT (1),
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    CONSTRAINT [PK_FunctionAction] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_FunctionAction_FunctionId_Phase_Seq] ON [plat].[FunctionAction] ([FunctionId], [Phase], [Seq]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'功能执行定义（受控钩子，替代 ExecSQL 表）', N'SCHEMA', N'plat', N'TABLE', N'FunctionAction';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'FunctionAction', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'执行顺序', N'SCHEMA', N'plat', N'TABLE', N'FunctionAction', N'COLUMN', N'Seq';
EXEC sp_addextendedproperty N'MS_Description', N'阶段(1前置校验 2执行前 3执行后 4提交前 5提交后 6异常)', N'SCHEMA', N'plat', N'TABLE', N'FunctionAction', N'COLUMN', N'Phase';
EXEC sp_addextendedproperty N'MS_Description', N'动作(1SQL 2存储过程 3WebApi 4领域事件 5脚本)', N'SCHEMA', N'plat', N'TABLE', N'FunctionAction', N'COLUMN', N'ActionType';
EXEC sp_addextendedproperty N'MS_Description', N'动作标识', N'SCHEMA', N'plat', N'TABLE', N'FunctionAction', N'COLUMN', N'ActionCode';
EXEC sp_addextendedproperty N'MS_Description', N'目标(表/存储过程/URL/事件名)', N'SCHEMA', N'plat', N'TABLE', N'FunctionAction', N'COLUMN', N'Target';
EXEC sp_addextendedproperty N'MS_Description', N'命令内容(参数化SQL/模板)', N'SCHEMA', N'plat', N'TABLE', N'FunctionAction', N'COLUMN', N'Command';
EXEC sp_addextendedproperty N'MS_Description', N'参数映射', N'SCHEMA', N'plat', N'TABLE', N'FunctionAction', N'COLUMN', N'ParamJson';
EXEC sp_addextendedproperty N'MS_Description', N'失败继续', N'SCHEMA', N'plat', N'TABLE', N'FunctionAction', N'COLUMN', N'ContinueOnError';
EXEC sp_addextendedproperty N'MS_Description', N'失败提示', N'SCHEMA', N'plat', N'TABLE', N'FunctionAction', N'COLUMN', N'ErrorMessage';
EXEC sp_addextendedproperty N'MS_Description', N'上线审批人', N'SCHEMA', N'plat', N'TABLE', N'FunctionAction', N'COLUMN', N'ApprovedBy';
EXEC sp_addextendedproperty N'MS_Description', N'上线审批时间', N'SCHEMA', N'plat', N'TABLE', N'FunctionAction', N'COLUMN', N'ApprovedAt';
GO
CREATE TABLE [plat].[ModuleTerminal] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_ModuleTerminal_TenantId] DEFAULT (1),
    [ModuleId] bigint NOT NULL,
    [TerminalType] tinyint NOT NULL CONSTRAINT [CK_ModuleTerminal_TerminalType] CHECK (TerminalType BETWEEN 1 AND 6),
    [IsVisible] bit NOT NULL CONSTRAINT [DF_ModuleTerminal_IsVisible] DEFAULT (1),
    CONSTRAINT [PK_ModuleTerminal] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ModuleTerminal_ModuleId_TerminalType] ON [plat].[ModuleTerminal] ([ModuleId], [TerminalType]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'模块终端可用性（一份定义多端复用）', N'SCHEMA', N'plat', N'TABLE', N'ModuleTerminal';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'ModuleTerminal', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'终端(1PC 2POS 3PDA 4APP 5小程序 6门户)', N'SCHEMA', N'plat', N'TABLE', N'ModuleTerminal', N'COLUMN', N'TerminalType';
GO
CREATE TABLE [plat].[Menu] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Menu_TenantId] DEFAULT (1),
    [ParentId] bigint NULL,
    [Code] varchar(40) NOT NULL,
    [Name] nvarchar(50) NOT NULL,
    [ModuleId] bigint NULL,
    [PageId] bigint NULL,
    [MenuType] tinyint NOT NULL CONSTRAINT [DF_Menu_MenuType] DEFAULT (1) CONSTRAINT [CK_Menu_MenuType] CHECK (MenuType BETWEEN 1 AND 4),
    [Route] varchar(200) NULL,
    [Icon] varchar(100) NULL,
    [Sort] int NOT NULL CONSTRAINT [DF_Menu_Sort] DEFAULT (0),
    [IsVisible] bit NOT NULL CONSTRAINT [DF_Menu_IsVisible] DEFAULT (1),
    [OpenMode] tinyint NOT NULL CONSTRAINT [DF_Menu_OpenMode] DEFAULT (1),
    [BadgeExpr] varchar(200) NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Menu_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Menu_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Menu_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Menu] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Menu_TenantId_Code] ON [plat].[Menu] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Menu_TenantId_ParentId_Sort] ON [plat].[Menu] ([TenantId], [ParentId], [Sort]);
GO
CREATE INDEX [IX_Menu_ParentId] ON [plat].[Menu] ([ParentId]);
GO
CREATE INDEX [IX_Menu_ModuleId] ON [plat].[Menu] ([ModuleId]);
GO
CREATE INDEX [IX_Menu_PageId] ON [plat].[Menu] ([PageId]);
GO
CREATE INDEX [IX_Menu_CreatedBy] ON [plat].[Menu] ([CreatedBy]);
GO
CREATE INDEX [IX_Menu_ModifiedBy] ON [plat].[Menu] ([ModifiedBy]);
GO
CREATE INDEX [IX_Menu_DeletedBy] ON [plat].[Menu] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'菜单树', N'SCHEMA', N'plat', N'TABLE', N'Menu';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'上级菜单', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'ParentId';
EXEC sp_addextendedproperty N'MS_Description', N'菜单编码', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'菜单名称', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'关联模块', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'ModuleId';
EXEC sp_addextendedproperty N'MS_Description', N'默认页面', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'PageId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1目录 2菜单 3外链 4分组)', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'MenuType';
EXEC sp_addextendedproperty N'MS_Description', N'前端路由', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'Route';
EXEC sp_addextendedproperty N'MS_Description', N'图标', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'Icon';
EXEC sp_addextendedproperty N'MS_Description', N'打开方式(1内嵌 2新窗 3弹窗)', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'OpenMode';
EXEC sp_addextendedproperty N'MS_Description', N'角标表达式(待办数)', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'BadgeExpr';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[MenuTerminal] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [MenuId] bigint NOT NULL,
    [TerminalType] tinyint NOT NULL,
    [IsVisible] bit NOT NULL CONSTRAINT [DF_MenuTerminal_IsVisible] DEFAULT (1),
    [Sort] int NOT NULL CONSTRAINT [DF_MenuTerminal_Sort] DEFAULT (0),
    CONSTRAINT [PK_MenuTerminal] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_MenuTerminal_MenuId_TerminalType] ON [plat].[MenuTerminal] ([MenuId], [TerminalType]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'菜单终端可见性', N'SCHEMA', N'plat', N'TABLE', N'MenuTerminal';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'MenuTerminal', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'终端(1PC 2POS 3PDA 4APP 5小程序 6门户)', N'SCHEMA', N'plat', N'TABLE', N'MenuTerminal', N'COLUMN', N'TerminalType';
GO
CREATE TABLE [plat].[Page] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Page_TenantId] DEFAULT (1),
    [Code] varchar(60) NOT NULL,
    [Name] nvarchar(100) NULL,
    [PageType] tinyint NOT NULL CONSTRAINT [DF_Page_PageType] DEFAULT (1) CONSTRAINT [CK_Page_PageType] CHECK (PageType BETWEEN 1 AND 6),
    [ModuleId] bigint NULL,
    [Layout] varchar(50) NULL,
    [Title] nvarchar(200) NULL,
    [ParamsJson] nvarchar(max) NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Page_IsEnabled] DEFAULT (1),
    [Version] int NOT NULL CONSTRAINT [DF_Page_Version] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Page_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Page_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Page] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Page_TenantId_Code] ON [plat].[Page] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Page_ModuleId] ON [plat].[Page] ([ModuleId]);
GO
CREATE INDEX [IX_Page_CreatedBy] ON [plat].[Page] ([CreatedBy]);
GO
CREATE INDEX [IX_Page_ModifiedBy] ON [plat].[Page] ([ModifiedBy]);
GO
CREATE INDEX [IX_Page_DeletedBy] ON [plat].[Page] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'页面', N'SCHEMA', N'plat', N'TABLE', N'Page';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'页面编码', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'页面名称', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1列表 2表单 3单据 4报表 5看板 6自定义)', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'PageType';
EXEC sp_addextendedproperty N'MS_Description', N'所属模块', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'ModuleId';
EXEC sp_addextendedproperty N'MS_Description', N'布局模板(master-detail/tabs/grid)', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'Layout';
EXEC sp_addextendedproperty N'MS_Description', N'标题表达式', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'Title';
EXEC sp_addextendedproperty N'MS_Description', N'页面参数', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'ParamsJson';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Page', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[PageBlock] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [PageId] bigint NOT NULL,
    [Code] varchar(60) NOT NULL,
    [BlockType] tinyint NOT NULL CONSTRAINT [DF_PageBlock_BlockType] DEFAULT (1) CONSTRAINT [CK_PageBlock_BlockType] CHECK (BlockType BETWEEN 1 AND 7),
    [Title] nvarchar(100) NULL,
    [DataObjectId] bigint NULL,
    [ListViewId] bigint NULL,
    [FormLayoutId] bigint NULL,
    [ParentBlockId] bigint NULL,
    [LinkField] varchar(50) NULL,
    [Span] tinyint NOT NULL CONSTRAINT [DF_PageBlock_Span] DEFAULT (12),
    [Row] int NOT NULL CONSTRAINT [DF_PageBlock_Row] DEFAULT (0),
    [VisibleExpr] varchar(300) NULL,
    [Sort] int NOT NULL CONSTRAINT [DF_PageBlock_Sort] DEFAULT (0),
    CONSTRAINT [PK_PageBlock] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PageBlock_PageId_Code] ON [plat].[PageBlock] ([PageId], [Code]);
GO
CREATE INDEX [IX_PageBlock_DataObjectId] ON [plat].[PageBlock] ([DataObjectId]);
GO
CREATE INDEX [IX_PageBlock_ListViewId] ON [plat].[PageBlock] ([ListViewId]);
GO
CREATE INDEX [IX_PageBlock_FormLayoutId] ON [plat].[PageBlock] ([FormLayoutId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'页面区块', N'SCHEMA', N'plat', N'TABLE', N'PageBlock';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'PageBlock', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'区块编码', N'SCHEMA', N'plat', N'TABLE', N'PageBlock', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1主表表单 2明细表格 3查询区 4工具栏 5图表 6标签 7自定义)', N'SCHEMA', N'plat', N'TABLE', N'PageBlock', N'COLUMN', N'BlockType';
EXEC sp_addextendedproperty N'MS_Description', N'区块标题', N'SCHEMA', N'plat', N'TABLE', N'PageBlock', N'COLUMN', N'Title';
EXEC sp_addextendedproperty N'MS_Description', N'数据对象', N'SCHEMA', N'plat', N'TABLE', N'PageBlock', N'COLUMN', N'DataObjectId';
EXEC sp_addextendedproperty N'MS_Description', N'列表视图', N'SCHEMA', N'plat', N'TABLE', N'PageBlock', N'COLUMN', N'ListViewId';
EXEC sp_addextendedproperty N'MS_Description', N'表单布局', N'SCHEMA', N'plat', N'TABLE', N'PageBlock', N'COLUMN', N'FormLayoutId';
EXEC sp_addextendedproperty N'MS_Description', N'父区块(主子表关系)', N'SCHEMA', N'plat', N'TABLE', N'PageBlock', N'COLUMN', N'ParentBlockId';
EXEC sp_addextendedproperty N'MS_Description', N'关联字段', N'SCHEMA', N'plat', N'TABLE', N'PageBlock', N'COLUMN', N'LinkField';
EXEC sp_addextendedproperty N'MS_Description', N'栅格宽度(24)', N'SCHEMA', N'plat', N'TABLE', N'PageBlock', N'COLUMN', N'Span';
EXEC sp_addextendedproperty N'MS_Description', N'可见表达式', N'SCHEMA', N'plat', N'TABLE', N'PageBlock', N'COLUMN', N'VisibleExpr';
GO
CREATE TABLE [plat].[DataObject] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_DataObject_TenantId] DEFAULT (1),
    [Code] varchar(60) NOT NULL,
    [Name] nvarchar(100) NULL,
    [ObjectType] tinyint NOT NULL CONSTRAINT [DF_DataObject_ObjectType] DEFAULT (1) CONSTRAINT [CK_DataObject_ObjectType] CHECK (ObjectType BETWEEN 1 AND 4),
    [SchemaName] varchar(50) NULL,
    [ObjectName] varchar(100) NULL,
    [PrimaryKey] varchar(100) NULL,
    [DocNoField] varchar(100) NULL,
    [OrgField] varchar(100) NULL,
    [StatusField] varchar(100) NULL,
    [TenantField] varchar(100) NULL,
    [BaseWhere] nvarchar(500) NULL,
    [DefaultOrder] varchar(300) NULL,
    [IsReadOnly] bit NOT NULL CONSTRAINT [DF_DataObject_IsReadOnly] DEFAULT (0),
    [IsAuditEnabled] bit NOT NULL CONSTRAINT [DF_DataObject_IsAuditEnabled] DEFAULT (1),
    [CacheSeconds] int NOT NULL CONSTRAINT [DF_DataObject_CacheSeconds] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_DataObject_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_DataObject_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_DataObject_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_DataObject] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_DataObject_TenantId_Code] ON [plat].[DataObject] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_DataObject_CreatedBy] ON [plat].[DataObject] ([CreatedBy]);
GO
CREATE INDEX [IX_DataObject_ModifiedBy] ON [plat].[DataObject] ([ModifiedBy]);
GO
CREATE INDEX [IX_DataObject_DeletedBy] ON [plat].[DataObject] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'数据对象（表/视图/SQL/存储过程）', N'SCHEMA', N'plat', N'TABLE', N'DataObject';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'对象编码', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'名称', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1表 2视图 3存储过程 4SQL)', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'ObjectType';
EXEC sp_addextendedproperty N'MS_Description', N'架构名', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'SchemaName';
EXEC sp_addextendedproperty N'MS_Description', N'物理对象名', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'ObjectName';
EXEC sp_addextendedproperty N'MS_Description', N'主键字段', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'PrimaryKey';
EXEC sp_addextendedproperty N'MS_Description', N'单据号字段', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'DocNoField';
EXEC sp_addextendedproperty N'MS_Description', N'组织字段(数据权限)', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'OrgField';
EXEC sp_addextendedproperty N'MS_Description', N'状态字段', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'StatusField';
EXEC sp_addextendedproperty N'MS_Description', N'租户字段', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'TenantField';
EXEC sp_addextendedproperty N'MS_Description', N'基础条件', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'BaseWhere';
EXEC sp_addextendedproperty N'MS_Description', N'默认排序', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'DefaultOrder';
EXEC sp_addextendedproperty N'MS_Description', N'只读对象', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'IsReadOnly';
EXEC sp_addextendedproperty N'MS_Description', N'写审计', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'IsAuditEnabled';
EXEC sp_addextendedproperty N'MS_Description', N'缓存秒', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'CacheSeconds';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'DataObject', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[DataObjectField] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [DataObjectId] bigint NOT NULL,
    [FieldName] varchar(100) NOT NULL,
    [DisplayName] nvarchar(100) NULL,
    [DataType] varchar(30) NULL,
    [MaxLength] int NULL,
    [Precision] tinyint NULL,
    [Scale] tinyint NULL,
    [IsNullable] bit NOT NULL CONSTRAINT [DF_DataObjectField_IsNullable] DEFAULT (1),
    [IsPrimaryKey] bit NOT NULL CONSTRAINT [DF_DataObjectField_IsPrimaryKey] DEFAULT (0),
    [IsIdentity] bit NOT NULL CONSTRAINT [DF_DataObjectField_IsIdentity] DEFAULT (0),
    [IsRequired] bit NOT NULL CONSTRAINT [DF_DataObjectField_IsRequired] DEFAULT (0),
    [DefaultValue] nvarchar(200) NULL,
    [LookupType] tinyint NOT NULL CONSTRAINT [DF_DataObjectField_LookupType] DEFAULT (0) CONSTRAINT [CK_DataObjectField_LookupType] CHECK (LookupType BETWEEN 0 AND 4),
    [LookupSource] varchar(200) NULL,
    [LookupValueField] varchar(50) NULL,
    [LookupDisplayField] varchar(100) NULL,
    [LookupFilter] varchar(300) NULL,
    [Format] varchar(50) NULL,
    [Unit] nvarchar(20) NULL,
    [IsVisible] bit NOT NULL CONSTRAINT [DF_DataObjectField_IsVisible] DEFAULT (1),
    [Sort] int NOT NULL CONSTRAINT [DF_DataObjectField_Sort] DEFAULT (0),
    [IsComputed] bit NOT NULL CONSTRAINT [DF_DataObjectField_IsComputed] DEFAULT (0),
    [ComputeExpr] nvarchar(500) NULL,
    CONSTRAINT [PK_DataObjectField] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_DataObjectField_DataObjectId_FieldName] ON [plat].[DataObjectField] ([DataObjectId], [FieldName]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'数据对象字段元数据', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'字段名', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'FieldName';
EXEC sp_addextendedproperty N'MS_Description', N'显示名', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'DisplayName';
EXEC sp_addextendedproperty N'MS_Description', N'数据类型', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'DataType';
EXEC sp_addextendedproperty N'MS_Description', N'长度', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'MaxLength';
EXEC sp_addextendedproperty N'MS_Description', N'精度', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'Precision';
EXEC sp_addextendedproperty N'MS_Description', N'小数位', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'Scale';
EXEC sp_addextendedproperty N'MS_Description', N'默认值', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'DefaultValue';
EXEC sp_addextendedproperty N'MS_Description', N'来源(0无 1字典 2表 3SQL 4枚举)', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'LookupType';
EXEC sp_addextendedproperty N'MS_Description', N'来源(dict:code / md.Partner)', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'LookupSource';
EXEC sp_addextendedproperty N'MS_Description', N'值字段', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'LookupValueField';
EXEC sp_addextendedproperty N'MS_Description', N'显示字段', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'LookupDisplayField';
EXEC sp_addextendedproperty N'MS_Description', N'来源过滤', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'LookupFilter';
EXEC sp_addextendedproperty N'MS_Description', N'显示格式', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'Format';
EXEC sp_addextendedproperty N'MS_Description', N'单位', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'Unit';
EXEC sp_addextendedproperty N'MS_Description', N'计算列', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'IsComputed';
EXEC sp_addextendedproperty N'MS_Description', N'计算表达式', N'SCHEMA', N'plat', N'TABLE', N'DataObjectField', N'COLUMN', N'ComputeExpr';
GO
CREATE TABLE [plat].[ListView] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_ListView_TenantId] DEFAULT (1),
    [Code] varchar(60) NOT NULL,
    [Name] nvarchar(100) NULL,
    [DataObjectId] bigint NOT NULL,
    [PageSize] int NOT NULL CONSTRAINT [DF_ListView_PageSize] DEFAULT (50),
    [DefaultSort] varchar(300) NULL,
    [FixedFilter] nvarchar(500) NULL,
    [IsDefault] bit NOT NULL CONSTRAINT [DF_ListView_IsDefault] DEFAULT (0),
    [RowActionStyle] tinyint NOT NULL CONSTRAINT [DF_ListView_RowActionStyle] DEFAULT (1),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_ListView_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_ListView_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_ListView_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_ListView] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ListView_TenantId_Code] ON [plat].[ListView] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_ListView_DataObjectId] ON [plat].[ListView] ([DataObjectId]);
GO
CREATE INDEX [IX_ListView_CreatedBy] ON [plat].[ListView] ([CreatedBy]);
GO
CREATE INDEX [IX_ListView_ModifiedBy] ON [plat].[ListView] ([ModifiedBy]);
GO
CREATE INDEX [IX_ListView_DeletedBy] ON [plat].[ListView] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'列表视图', N'SCHEMA', N'plat', N'TABLE', N'ListView';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'ListView', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'视图名称', N'SCHEMA', N'plat', N'TABLE', N'ListView', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'默认排序', N'SCHEMA', N'plat', N'TABLE', N'ListView', N'COLUMN', N'DefaultSort';
EXEC sp_addextendedproperty N'MS_Description', N'固定过滤', N'SCHEMA', N'plat', N'TABLE', N'ListView', N'COLUMN', N'FixedFilter';
EXEC sp_addextendedproperty N'MS_Description', N'行操作(1右侧 2下拉)', N'SCHEMA', N'plat', N'TABLE', N'ListView', N'COLUMN', N'RowActionStyle';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'ListView', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'plat', N'TABLE', N'ListView', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'ListView', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'ListView', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'ListView', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'ListView', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'ListView', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'ListView', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'ListView', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'ListView', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[ListViewColumn] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [ListViewId] bigint NOT NULL,
    [FieldName] varchar(100) NOT NULL,
    [Title] nvarchar(100) NULL,
    [Width] int NOT NULL CONSTRAINT [DF_ListViewColumn_Width] DEFAULT (120),
    [Align] tinyint NOT NULL CONSTRAINT [DF_ListViewColumn_Align] DEFAULT (1),
    [Sort] int NOT NULL CONSTRAINT [DF_ListViewColumn_Sort] DEFAULT (0),
    [IsVisible] bit NOT NULL CONSTRAINT [DF_ListViewColumn_IsVisible] DEFAULT (1),
    [IsFrozen] bit NOT NULL CONSTRAINT [DF_ListViewColumn_IsFrozen] DEFAULT (0),
    [IsSum] bit NOT NULL CONSTRAINT [DF_ListViewColumn_IsSum] DEFAULT (0),
    [Format] varchar(50) NULL,
    [LinkPageId] bigint NULL,
    [ColorRule] nvarchar(300) NULL,
    [IsDrill] bit NOT NULL CONSTRAINT [DF_ListViewColumn_IsDrill] DEFAULT (0),
    CONSTRAINT [PK_ListViewColumn] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_ListViewColumn_ListViewId_FieldName] ON [plat].[ListViewColumn] ([ListViewId], [FieldName]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'列表列定义', N'SCHEMA', N'plat', N'TABLE', N'ListViewColumn';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'ListViewColumn', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'列标题', N'SCHEMA', N'plat', N'TABLE', N'ListViewColumn', N'COLUMN', N'Title';
EXEC sp_addextendedproperty N'MS_Description', N'对齐(1左 2中 3右)', N'SCHEMA', N'plat', N'TABLE', N'ListViewColumn', N'COLUMN', N'Align';
EXEC sp_addextendedproperty N'MS_Description', N'合计行', N'SCHEMA', N'plat', N'TABLE', N'ListViewColumn', N'COLUMN', N'IsSum';
EXEC sp_addextendedproperty N'MS_Description', N'格式', N'SCHEMA', N'plat', N'TABLE', N'ListViewColumn', N'COLUMN', N'Format';
EXEC sp_addextendedproperty N'MS_Description', N'点击跳转页面', N'SCHEMA', N'plat', N'TABLE', N'ListViewColumn', N'COLUMN', N'LinkPageId';
EXEC sp_addextendedproperty N'MS_Description', N'颜色规则', N'SCHEMA', N'plat', N'TABLE', N'ListViewColumn', N'COLUMN', N'ColorRule';
EXEC sp_addextendedproperty N'MS_Description', N'可下钻', N'SCHEMA', N'plat', N'TABLE', N'ListViewColumn', N'COLUMN', N'IsDrill';
GO
CREATE TABLE [plat].[FormLayout] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_FormLayout_TenantId] DEFAULT (1),
    [Code] varchar(60) NOT NULL,
    [Name] nvarchar(100) NULL,
    [DataObjectId] bigint NOT NULL,
    [Mode] tinyint NOT NULL CONSTRAINT [DF_FormLayout_Mode] DEFAULT (1) CONSTRAINT [CK_FormLayout_Mode] CHECK (Mode BETWEEN 1 AND 4),
    [Columns] tinyint NOT NULL CONSTRAINT [DF_FormLayout_Columns] DEFAULT (2),
    [GroupsJson] nvarchar(max) NULL,
    [IsDefault] bit NOT NULL CONSTRAINT [DF_FormLayout_IsDefault] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_FormLayout_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_FormLayout_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_FormLayout_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_FormLayout] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_FormLayout_TenantId_Code] ON [plat].[FormLayout] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_FormLayout_DataObjectId] ON [plat].[FormLayout] ([DataObjectId]);
GO
CREATE INDEX [IX_FormLayout_CreatedBy] ON [plat].[FormLayout] ([CreatedBy]);
GO
CREATE INDEX [IX_FormLayout_ModifiedBy] ON [plat].[FormLayout] ([ModifiedBy]);
GO
CREATE INDEX [IX_FormLayout_DeletedBy] ON [plat].[FormLayout] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'表单布局', N'SCHEMA', N'plat', N'TABLE', N'FormLayout';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'FormLayout', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'模式(1新增 2修改 3查看 4复制)', N'SCHEMA', N'plat', N'TABLE', N'FormLayout', N'COLUMN', N'Mode';
EXEC sp_addextendedproperty N'MS_Description', N'栅格列数(1/2/3/4)', N'SCHEMA', N'plat', N'TABLE', N'FormLayout', N'COLUMN', N'Columns';
EXEC sp_addextendedproperty N'MS_Description', N'分组/标签页定义', N'SCHEMA', N'plat', N'TABLE', N'FormLayout', N'COLUMN', N'GroupsJson';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'FormLayout', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'plat', N'TABLE', N'FormLayout', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'FormLayout', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'FormLayout', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'FormLayout', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'FormLayout', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'FormLayout', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'FormLayout', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'FormLayout', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'FormLayout', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[FormField] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [FormLayoutId] bigint NOT NULL,
    [FieldName] varchar(100) NOT NULL,
    [Label] nvarchar(100) NULL,
    [ControlType] tinyint NOT NULL CONSTRAINT [DF_FormField_ControlType] DEFAULT (1) CONSTRAINT [CK_FormField_ControlType] CHECK (ControlType BETWEEN 1 AND 13),
    [Row] int NOT NULL CONSTRAINT [DF_FormField_Row] DEFAULT (0),
    [Col] int NOT NULL CONSTRAINT [DF_FormField_Col] DEFAULT (0),
    [Span] tinyint NOT NULL CONSTRAINT [DF_FormField_Span] DEFAULT (12),
    [IsReadOnly] bit NOT NULL CONSTRAINT [DF_FormField_IsReadOnly] DEFAULT (0),
    [IsRequired] bit NOT NULL CONSTRAINT [DF_FormField_IsRequired] DEFAULT (0),
    [IsHidden] bit NOT NULL CONSTRAINT [DF_FormField_IsHidden] DEFAULT (0),
    [DefaultExpr] nvarchar(300) NULL,
    [Placeholder] nvarchar(200) NULL,
    [HelpText] nvarchar(500) NULL,
    [GroupName] nvarchar(50) NULL,
    [Sort] int NOT NULL CONSTRAINT [DF_FormField_Sort] DEFAULT (0),
    [AccessExpr] varchar(300) NULL,
    CONSTRAINT [PK_FormField] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_FormField_FormLayoutId_FieldName] ON [plat].[FormField] ([FormLayoutId], [FieldName]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'表单字段（控件与布局）', N'SCHEMA', N'plat', N'TABLE', N'FormField';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'FormField', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'标签', N'SCHEMA', N'plat', N'TABLE', N'FormField', N'COLUMN', N'Label';
EXEC sp_addextendedproperty N'MS_Description', N'控件(1文本 2数字 3金额 4日期 5下拉 6查找 7多选 8开关 9富文本 10附件 11子表 12公式 13条码扫描)', N'SCHEMA', N'plat', N'TABLE', N'FormField', N'COLUMN', N'ControlType';
EXEC sp_addextendedproperty N'MS_Description', N'默认值表达式', N'SCHEMA', N'plat', N'TABLE', N'FormField', N'COLUMN', N'DefaultExpr';
EXEC sp_addextendedproperty N'MS_Description', N'帮助说明', N'SCHEMA', N'plat', N'TABLE', N'FormField', N'COLUMN', N'HelpText';
EXEC sp_addextendedproperty N'MS_Description', N'分组', N'SCHEMA', N'plat', N'TABLE', N'FormField', N'COLUMN', N'GroupName';
EXEC sp_addextendedproperty N'MS_Description', N'可写条件表达式', N'SCHEMA', N'plat', N'TABLE', N'FormField', N'COLUMN', N'AccessExpr';
GO
CREATE TABLE [plat].[QueryScheme] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_QueryScheme_TenantId] DEFAULT (1),
    [Code] varchar(60) NOT NULL,
    [Name] nvarchar(100) NULL,
    [DataObjectId] bigint NOT NULL,
    [OwnerId] bigint NULL,
    [IsShared] bit NOT NULL CONSTRAINT [DF_QueryScheme_IsShared] DEFAULT (0),
    [FilterJson] nvarchar(max) NULL,
    [SortJson] nvarchar(max) NULL,
    [IsDefault] bit NOT NULL CONSTRAINT [DF_QueryScheme_IsDefault] DEFAULT (0),
    CONSTRAINT [PK_QueryScheme] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_QueryScheme_TenantId_Code] ON [plat].[QueryScheme] ([TenantId], [Code]);
GO
CREATE INDEX [IX_QueryScheme_DataObjectId] ON [plat].[QueryScheme] ([DataObjectId]);
GO
CREATE INDEX [IX_QueryScheme_OwnerId] ON [plat].[QueryScheme] ([OwnerId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'查询方案（可保存的筛选）', N'SCHEMA', N'plat', N'TABLE', N'QueryScheme';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'QueryScheme', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'所有者(空=公共)', N'SCHEMA', N'plat', N'TABLE', N'QueryScheme', N'COLUMN', N'OwnerId';
EXEC sp_addextendedproperty N'MS_Description', N'筛选条件JSON', N'SCHEMA', N'plat', N'TABLE', N'QueryScheme', N'COLUMN', N'FilterJson';
EXEC sp_addextendedproperty N'MS_Description', N'排序JSON', N'SCHEMA', N'plat', N'TABLE', N'QueryScheme', N'COLUMN', N'SortJson';
GO
CREATE TABLE [plat].[Button] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Button_TenantId] DEFAULT (1),
    [Code] varchar(60) NOT NULL,
    [Name] nvarchar(50) NULL,
    [Text] nvarchar(50) NULL,
    [Icon] varchar(100) NULL,
    [ButtonType] tinyint NOT NULL CONSTRAINT [DF_Button_ButtonType] DEFAULT (1) CONSTRAINT [CK_Button_ButtonType] CHECK (ButtonType BETWEEN 1 AND 5),
    [FunctionId] bigint NULL,
    [Sort] int NOT NULL CONSTRAINT [DF_Button_Sort] DEFAULT (0),
    [IsVisible] bit NOT NULL CONSTRAINT [DF_Button_IsVisible] DEFAULT (1),
    [VisibleExpr] varchar(300) NULL,
    [IsEnabledExpr] varchar(300) NULL,
    [Style] varchar(30) NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Button_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Button_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Button] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Button_TenantId_Code] ON [plat].[Button] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Button_FunctionId] ON [plat].[Button] ([FunctionId]);
GO
CREATE INDEX [IX_Button_CreatedBy] ON [plat].[Button] ([CreatedBy]);
GO
CREATE INDEX [IX_Button_ModifiedBy] ON [plat].[Button] ([ModifiedBy]);
GO
CREATE INDEX [IX_Button_DeletedBy] ON [plat].[Button] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'按钮定义', N'SCHEMA', N'plat', N'TABLE', N'Button';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'按钮编码', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'名称', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'按钮文字', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'Text';
EXEC sp_addextendedproperty N'MS_Description', N'位置(1工具栏 2行内 3页脚 4批量 5右键)', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'ButtonType';
EXEC sp_addextendedproperty N'MS_Description', N'绑定功能点(决定权限)', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'FunctionId';
EXEC sp_addextendedproperty N'MS_Description', N'可见表达式', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'VisibleExpr';
EXEC sp_addextendedproperty N'MS_Description', N'可用表达式', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'IsEnabledExpr';
EXEC sp_addextendedproperty N'MS_Description', N'样式(primary/danger/default)', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'Style';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'Button', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[ButtonAction] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [ButtonId] bigint NOT NULL,
    [Seq] int NOT NULL CONSTRAINT [DF_ButtonAction_Seq] DEFAULT (10),
    [ActionType] tinyint NOT NULL CONSTRAINT [DF_ButtonAction_ActionType] DEFAULT (1) CONSTRAINT [CK_ButtonAction_ActionType] CHECK (ActionType BETWEEN 1 AND 5),
    [BuiltinCode] varchar(40) NULL,
    [Target] varchar(200) NULL,
    [Command] nvarchar(max) NULL,
    [ParamJson] nvarchar(max) NULL,
    [ConfirmText] nvarchar(200) NULL,
    [SuccessMessage] nvarchar(200) NULL,
    [NeedWorkflow] bit NOT NULL CONSTRAINT [DF_ButtonAction_NeedWorkflow] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_ButtonAction_IsEnabled] DEFAULT (1),
    CONSTRAINT [PK_ButtonAction] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_ButtonAction_ButtonId_Seq] ON [plat].[ButtonAction] ([ButtonId], [Seq]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'按钮行为', N'SCHEMA', N'plat', N'TABLE', N'ButtonAction';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'ButtonAction', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1内置动作 2存储过程 3WebApi 4领域事件 5脚本)', N'SCHEMA', N'plat', N'TABLE', N'ButtonAction', N'COLUMN', N'ActionType';
EXEC sp_addextendedproperty N'MS_Description', N'内置动作(SAVE/SUBMIT/AUDIT/UNAUDIT/VOID/PRINT/EXPORT/IMPORT/COPY/CLOSE/SUBSCRIBE)', N'SCHEMA', N'plat', N'TABLE', N'ButtonAction', N'COLUMN', N'BuiltinCode';
EXEC sp_addextendedproperty N'MS_Description', N'目标', N'SCHEMA', N'plat', N'TABLE', N'ButtonAction', N'COLUMN', N'Target';
EXEC sp_addextendedproperty N'MS_Description', N'命令/参数', N'SCHEMA', N'plat', N'TABLE', N'ButtonAction', N'COLUMN', N'Command';
EXEC sp_addextendedproperty N'MS_Description', N'参数映射', N'SCHEMA', N'plat', N'TABLE', N'ButtonAction', N'COLUMN', N'ParamJson';
EXEC sp_addextendedproperty N'MS_Description', N'确认提示', N'SCHEMA', N'plat', N'TABLE', N'ButtonAction', N'COLUMN', N'ConfirmText';
EXEC sp_addextendedproperty N'MS_Description', N'触发审批', N'SCHEMA', N'plat', N'TABLE', N'ButtonAction', N'COLUMN', N'NeedWorkflow';
GO
CREATE TABLE [plat].[BizRule] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_BizRule_TenantId] DEFAULT (1),
    [Code] varchar(60) NOT NULL,
    [Name] nvarchar(100) NULL,
    [RuleType] tinyint NOT NULL CONSTRAINT [DF_BizRule_RuleType] DEFAULT (1) CONSTRAINT [CK_BizRule_RuleType] CHECK (RuleType BETWEEN 1 AND 10),
    [Expression] nvarchar(max) NULL,
    [ErrorMessage] nvarchar(300) NULL,
    [Severity] tinyint NOT NULL CONSTRAINT [DF_BizRule_Severity] DEFAULT (1) CONSTRAINT [CK_BizRule_Severity] CHECK (Severity BETWEEN 1 AND 3),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_BizRule_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_BizRule_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_BizRule_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_BizRule] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_BizRule_TenantId_Code] ON [plat].[BizRule] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_BizRule_CreatedBy] ON [plat].[BizRule] ([CreatedBy]);
GO
CREATE INDEX [IX_BizRule_ModifiedBy] ON [plat].[BizRule] ([ModifiedBy]);
GO
CREATE INDEX [IX_BizRule_DeletedBy] ON [plat].[BizRule] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'业务规则（校验/联动/公式/只读）', N'SCHEMA', N'plat', N'TABLE', N'BizRule';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'BizRule', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'规则名称', N'SCHEMA', N'plat', N'TABLE', N'BizRule', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1必填 2正则 3范围 4唯一 5存在性 6公式 7联动 8只读 9警示 10自动赋值)', N'SCHEMA', N'plat', N'TABLE', N'BizRule', N'COLUMN', N'RuleType';
EXEC sp_addextendedproperty N'MS_Description', N'表达式(受限语法)', N'SCHEMA', N'plat', N'TABLE', N'BizRule', N'COLUMN', N'Expression';
EXEC sp_addextendedproperty N'MS_Description', N'错误提示', N'SCHEMA', N'plat', N'TABLE', N'BizRule', N'COLUMN', N'ErrorMessage';
EXEC sp_addextendedproperty N'MS_Description', N'级别(1阻断 2警告 3提示)', N'SCHEMA', N'plat', N'TABLE', N'BizRule', N'COLUMN', N'Severity';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'BizRule', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'BizRule', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'BizRule', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'BizRule', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'BizRule', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'BizRule', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'BizRule', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'BizRule', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'BizRule', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[RuleBinding] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [RuleId] bigint NOT NULL,
    [DataObjectId] bigint NOT NULL,
    [FieldName] varchar(100) NULL,
    [TriggerEvent] tinyint NOT NULL CONSTRAINT [DF_RuleBinding_TriggerEvent] DEFAULT (1) CONSTRAINT [CK_RuleBinding_TriggerEvent] CHECK (TriggerEvent BETWEEN 1 AND 6),
    [Sort] int NOT NULL CONSTRAINT [DF_RuleBinding_Sort] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_RuleBinding_IsEnabled] DEFAULT (1),
    CONSTRAINT [PK_RuleBinding] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_RuleBinding_DataObjectId_TriggerEvent] ON [plat].[RuleBinding] ([DataObjectId], [TriggerEvent]);
GO
CREATE INDEX [IX_RuleBinding_RuleId] ON [plat].[RuleBinding] ([RuleId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'规则绑定', N'SCHEMA', N'plat', N'TABLE', N'RuleBinding';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'RuleBinding', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'目标字段(空=整单)', N'SCHEMA', N'plat', N'TABLE', N'RuleBinding', N'COLUMN', N'FieldName';
EXEC sp_addextendedproperty N'MS_Description', N'触发(1保存前 2保存后 3字段变更 4加载 5提交前 6审核前)', N'SCHEMA', N'plat', N'TABLE', N'RuleBinding', N'COLUMN', N'TriggerEvent';
GO
CREATE TABLE [plat].[RuleParam] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [RuleBindingId] bigint NOT NULL,
    [Name] varchar(60) NOT NULL,
    [Value] nvarchar(500) NULL,
    CONSTRAINT [PK_RuleParam] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_RuleParam_RuleBindingId_Name] ON [plat].[RuleParam] ([RuleBindingId], [Name]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'规则参数', N'SCHEMA', N'plat', N'TABLE', N'RuleParam';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'RuleParam', N'COLUMN', N'Id';
GO
CREATE TABLE [plat].[WorkflowDef] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_WorkflowDef_TenantId] DEFAULT (1),
    [Code] varchar(60) NOT NULL,
    [Name] nvarchar(100) NULL,
    [DataObjectId] bigint NULL,
    [ModuleId] bigint NULL,
    [Version] int NOT NULL CONSTRAINT [DF_WorkflowDef_Version] DEFAULT (1),
    [ConditionExpr] nvarchar(500) NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_WorkflowDef_Status] DEFAULT (0),
    [PublishedAt] datetime2(3) NULL,
    [IsDefault] bit NOT NULL CONSTRAINT [DF_WorkflowDef_IsDefault] DEFAULT (0),
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_WorkflowDef_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_WorkflowDef_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_WorkflowDef] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_WorkflowDef_TenantId_Code_Version] ON [plat].[WorkflowDef] ([TenantId], [Code], [Version]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_WorkflowDef_DataObjectId] ON [plat].[WorkflowDef] ([DataObjectId]);
GO
CREATE INDEX [IX_WorkflowDef_ModuleId] ON [plat].[WorkflowDef] ([ModuleId]);
GO
CREATE INDEX [IX_WorkflowDef_CreatedBy] ON [plat].[WorkflowDef] ([CreatedBy]);
GO
CREATE INDEX [IX_WorkflowDef_ModifiedBy] ON [plat].[WorkflowDef] ([ModifiedBy]);
GO
CREATE INDEX [IX_WorkflowDef_DeletedBy] ON [plat].[WorkflowDef] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'审批流定义', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'绑定业务对象', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef', N'COLUMN', N'DataObjectId';
EXEC sp_addextendedproperty N'MS_Description', N'绑定模块', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef', N'COLUMN', N'ModuleId';
EXEC sp_addextendedproperty N'MS_Description', N'适用条件(金额/组织)', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef', N'COLUMN', N'ConditionExpr';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0草稿 1已发布 2停用)', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'发布时间', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef', N'COLUMN', N'PublishedAt';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'WorkflowDef', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[WorkflowNode] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [WorkflowDefId] bigint NOT NULL,
    [Code] varchar(40) NOT NULL,
    [Name] nvarchar(100) NULL,
    [NodeType] tinyint NOT NULL CONSTRAINT [DF_WorkflowNode_NodeType] DEFAULT (2) CONSTRAINT [CK_WorkflowNode_NodeType] CHECK (NodeType BETWEEN 1 AND 5),
    [Sort] int NOT NULL CONSTRAINT [DF_WorkflowNode_Sort] DEFAULT (0),
    [ApproveMode] tinyint NOT NULL CONSTRAINT [DF_WorkflowNode_ApproveMode] DEFAULT (1) CONSTRAINT [CK_WorkflowNode_ApproveMode] CHECK (ApproveMode BETWEEN 1 AND 3),
    [RejectMode] tinyint NOT NULL CONSTRAINT [DF_WorkflowNode_RejectMode] DEFAULT (1) CONSTRAINT [CK_WorkflowNode_RejectMode] CHECK (RejectMode BETWEEN 1 AND 3),
    [TimeLimitHours] int NULL,
    [ConditionExpr] nvarchar(500) NULL,
    [AllowDelegate] bit NOT NULL CONSTRAINT [DF_WorkflowNode_AllowDelegate] DEFAULT (1),
    [AllowAddSign] bit NOT NULL CONSTRAINT [DF_WorkflowNode_AllowAddSign] DEFAULT (1),
    CONSTRAINT [PK_WorkflowNode] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_WorkflowNode_WorkflowDefId_Code] ON [plat].[WorkflowNode] ([WorkflowDefId], [Code]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'审批流节点', N'SCHEMA', N'plat', N'TABLE', N'WorkflowNode';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'WorkflowNode', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'节点名称', N'SCHEMA', N'plat', N'TABLE', N'WorkflowNode', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1开始 2审批 3条件 4抄送 5结束)', N'SCHEMA', N'plat', N'TABLE', N'WorkflowNode', N'COLUMN', N'NodeType';
EXEC sp_addextendedproperty N'MS_Description', N'审批方式(1或签 2会签 3依次)', N'SCHEMA', N'plat', N'TABLE', N'WorkflowNode', N'COLUMN', N'ApproveMode';
EXEC sp_addextendedproperty N'MS_Description', N'驳回(1回发起人 2回上一节点 3结束)', N'SCHEMA', N'plat', N'TABLE', N'WorkflowNode', N'COLUMN', N'RejectMode';
EXEC sp_addextendedproperty N'MS_Description', N'时限(小时)', N'SCHEMA', N'plat', N'TABLE', N'WorkflowNode', N'COLUMN', N'TimeLimitHours';
EXEC sp_addextendedproperty N'MS_Description', N'条件表达式', N'SCHEMA', N'plat', N'TABLE', N'WorkflowNode', N'COLUMN', N'ConditionExpr';
EXEC sp_addextendedproperty N'MS_Description', N'允许转办', N'SCHEMA', N'plat', N'TABLE', N'WorkflowNode', N'COLUMN', N'AllowDelegate';
EXEC sp_addextendedproperty N'MS_Description', N'允许加签', N'SCHEMA', N'plat', N'TABLE', N'WorkflowNode', N'COLUMN', N'AllowAddSign';
GO
CREATE TABLE [plat].[WorkflowNodeApprover] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [WorkflowNodeId] bigint NOT NULL,
    [ApproverType] tinyint NOT NULL CONSTRAINT [DF_WorkflowNodeApprover_ApproverType] DEFAULT (1) CONSTRAINT [CK_WorkflowNodeApprover_ApproverType] CHECK (ApproverType BETWEEN 1 AND 6),
    [ApproverId] bigint NULL,
    [Expression] nvarchar(300) NULL,
    [Sort] int NOT NULL CONSTRAINT [DF_WorkflowNodeApprover_Sort] DEFAULT (0),
    CONSTRAINT [PK_WorkflowNodeApprover] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_WorkflowNodeApprover_WorkflowNodeId] ON [plat].[WorkflowNodeApprover] ([WorkflowNodeId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'节点审批人', N'SCHEMA', N'plat', N'TABLE', N'WorkflowNodeApprover';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'WorkflowNodeApprover', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1用户 2角色 3岗位 4发起人主管 5字段指定 6表达式)', N'SCHEMA', N'plat', N'TABLE', N'WorkflowNodeApprover', N'COLUMN', N'ApproverType';
EXEC sp_addextendedproperty N'MS_Description', N'用户/角色Id', N'SCHEMA', N'plat', N'TABLE', N'WorkflowNodeApprover', N'COLUMN', N'ApproverId';
EXEC sp_addextendedproperty N'MS_Description', N'表达式(如: 金额>10000)', N'SCHEMA', N'plat', N'TABLE', N'WorkflowNodeApprover', N'COLUMN', N'Expression';
GO
CREATE TABLE [plat].[WorkflowInstance] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_WorkflowInstance_TenantId] DEFAULT (1),
    [WorkflowDefId] bigint NOT NULL,
    [DefSnapshot] nvarchar(max) NULL,
    [DataObjectCode] varchar(60) NULL,
    [BusinessId] bigint NOT NULL,
    [BusinessNo] varchar(40) NULL,
    [Title] nvarchar(200) NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_WorkflowInstance_Status] DEFAULT (0) CONSTRAINT [CK_WorkflowInstance_Status] CHECK (Status BETWEEN 0 AND 9),
    [CurrentNodeId] bigint NULL,
    [StartedBy] bigint NULL,
    [StartedAt] datetime2(3) NOT NULL CONSTRAINT [DF_WorkflowInstance_StartedAt] DEFAULT (sysutcdatetime()),
    [FinishedAt] datetime2(3) NULL,
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_WorkflowInstance] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_WorkflowInstance_TenantId_Status] ON [plat].[WorkflowInstance] ([TenantId], [Status]);
GO
CREATE INDEX [IX_WorkflowInstance_DataObjectCode_BusinessId] ON [plat].[WorkflowInstance] ([DataObjectCode], [BusinessId]);
GO
CREATE INDEX [IX_WorkflowInstance_WorkflowDefId] ON [plat].[WorkflowInstance] ([WorkflowDefId]);
GO
CREATE INDEX [IX_WorkflowInstance_StartedBy] ON [plat].[WorkflowInstance] ([StartedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'审批实例', N'SCHEMA', N'plat', N'TABLE', N'WorkflowInstance';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'WorkflowInstance', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'流程快照(JSON)', N'SCHEMA', N'plat', N'TABLE', N'WorkflowInstance', N'COLUMN', N'DefSnapshot';
EXEC sp_addextendedproperty N'MS_Description', N'业务对象', N'SCHEMA', N'plat', N'TABLE', N'WorkflowInstance', N'COLUMN', N'DataObjectCode';
EXEC sp_addextendedproperty N'MS_Description', N'业务单据Id', N'SCHEMA', N'plat', N'TABLE', N'WorkflowInstance', N'COLUMN', N'BusinessId';
EXEC sp_addextendedproperty N'MS_Description', N'业务单号', N'SCHEMA', N'plat', N'TABLE', N'WorkflowInstance', N'COLUMN', N'BusinessNo';
EXEC sp_addextendedproperty N'MS_Description', N'流程标题', N'SCHEMA', N'plat', N'TABLE', N'WorkflowInstance', N'COLUMN', N'Title';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0审批中 1通过 2驳回 3撤回 9终止)', N'SCHEMA', N'plat', N'TABLE', N'WorkflowInstance', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'当前节点', N'SCHEMA', N'plat', N'TABLE', N'WorkflowInstance', N'COLUMN', N'CurrentNodeId';
EXEC sp_addextendedproperty N'MS_Description', N'发起人', N'SCHEMA', N'plat', N'TABLE', N'WorkflowInstance', N'COLUMN', N'StartedBy';
EXEC sp_addextendedproperty N'MS_Description', N'结束时间', N'SCHEMA', N'plat', N'TABLE', N'WorkflowInstance', N'COLUMN', N'FinishedAt';
GO
CREATE TABLE [plat].[WorkflowTask] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [InstanceId] bigint NOT NULL,
    [NodeId] bigint NOT NULL,
    [NodeName] nvarchar(100) NULL,
    [ApproverId] bigint NOT NULL,
    [ApproveStatus] tinyint NOT NULL CONSTRAINT [DF_WorkflowTask_ApproveStatus] DEFAULT (0) CONSTRAINT [CK_WorkflowTask_ApproveStatus] CHECK (ApproveStatus BETWEEN 0 AND 5),
    [Opinion] nvarchar(500) NULL,
    [HandledAt] datetime2(3) NULL,
    [DueAt] datetime2(3) NULL,
    [Sort] int NOT NULL CONSTRAINT [DF_WorkflowTask_Sort] DEFAULT (0),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_WorkflowTask] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_WorkflowTask_ApproverId_ApproveStatus] ON [plat].[WorkflowTask] ([ApproverId], [ApproveStatus]);
GO
CREATE INDEX [IX_WorkflowTask_InstanceId] ON [plat].[WorkflowTask] ([InstanceId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'审批任务', N'SCHEMA', N'plat', N'TABLE', N'WorkflowTask';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'WorkflowTask', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'节点', N'SCHEMA', N'plat', N'TABLE', N'WorkflowTask', N'COLUMN', N'NodeId';
EXEC sp_addextendedproperty N'MS_Description', N'节点名称快照', N'SCHEMA', N'plat', N'TABLE', N'WorkflowTask', N'COLUMN', N'NodeName';
EXEC sp_addextendedproperty N'MS_Description', N'审批人', N'SCHEMA', N'plat', N'TABLE', N'WorkflowTask', N'COLUMN', N'ApproverId';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0待办 1同意 2驳回 3转办 4加签 5跳过)', N'SCHEMA', N'plat', N'TABLE', N'WorkflowTask', N'COLUMN', N'ApproveStatus';
EXEC sp_addextendedproperty N'MS_Description', N'意见', N'SCHEMA', N'plat', N'TABLE', N'WorkflowTask', N'COLUMN', N'Opinion';
EXEC sp_addextendedproperty N'MS_Description', N'处理时间', N'SCHEMA', N'plat', N'TABLE', N'WorkflowTask', N'COLUMN', N'HandledAt';
EXEC sp_addextendedproperty N'MS_Description', N'截止时间', N'SCHEMA', N'plat', N'TABLE', N'WorkflowTask', N'COLUMN', N'DueAt';
GO
CREATE TABLE [plat].[WorkflowActionLog] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [InstanceId] bigint NOT NULL,
    [TaskId] bigint NULL,
    [Action] varchar(30) NULL,
    [OperatorId] bigint NULL,
    [Opinion] nvarchar(500) NULL,
    [SnapshotJson] nvarchar(max) NULL,
    [At] datetime2(3) NOT NULL CONSTRAINT [DF_WorkflowActionLog_At] DEFAULT (sysutcdatetime()),
    CONSTRAINT [PK_WorkflowActionLog] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_WorkflowActionLog_InstanceId_At] ON [plat].[WorkflowActionLog] ([InstanceId], [At]);
GO
CREATE INDEX [IX_WorkflowActionLog_OperatorId] ON [plat].[WorkflowActionLog] ([OperatorId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'审批动作日志', N'SCHEMA', N'plat', N'TABLE', N'WorkflowActionLog';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'WorkflowActionLog', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'任务', N'SCHEMA', N'plat', N'TABLE', N'WorkflowActionLog', N'COLUMN', N'TaskId';
EXEC sp_addextendedproperty N'MS_Description', N'动作(SUBMIT/APPROVE/REJECT/TRANSFER/ADD_SIGN/WITHDRAW)', N'SCHEMA', N'plat', N'TABLE', N'WorkflowActionLog', N'COLUMN', N'Action';
EXEC sp_addextendedproperty N'MS_Description', N'操作人', N'SCHEMA', N'plat', N'TABLE', N'WorkflowActionLog', N'COLUMN', N'OperatorId';
EXEC sp_addextendedproperty N'MS_Description', N'单据关键字段快照', N'SCHEMA', N'plat', N'TABLE', N'WorkflowActionLog', N'COLUMN', N'SnapshotJson';
GO
CREATE TABLE [plat].[DictType] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_DictType_TenantId] DEFAULT (1),
    [Code] varchar(60) NOT NULL,
    [Name] nvarchar(100) NULL,
    [IsSystem] bit NOT NULL CONSTRAINT [DF_DictType_IsSystem] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_DictType_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_DictType_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_DictType_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_DictType] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_DictType_TenantId_Code] ON [plat].[DictType] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_DictType_CreatedBy] ON [plat].[DictType] ([CreatedBy]);
GO
CREATE INDEX [IX_DictType_ModifiedBy] ON [plat].[DictType] ([ModifiedBy]);
GO
CREATE INDEX [IX_DictType_DeletedBy] ON [plat].[DictType] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'字典类型', N'SCHEMA', N'plat', N'TABLE', N'DictType';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'DictType', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'字典编码', N'SCHEMA', N'plat', N'TABLE', N'DictType', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'字典名称', N'SCHEMA', N'plat', N'TABLE', N'DictType', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'系统内置', N'SCHEMA', N'plat', N'TABLE', N'DictType', N'COLUMN', N'IsSystem';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'DictType', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'DictType', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'DictType', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'DictType', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'DictType', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'DictType', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'DictType', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'DictType', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'DictType', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[DictItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [DictTypeId] bigint NOT NULL,
    [Code] varchar(60) NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    [Value] nvarchar(200) NULL,
    [ParentCode] varchar(60) NULL,
    [Sort] int NOT NULL CONSTRAINT [DF_DictItem_Sort] DEFAULT (0),
    [IsDefault] bit NOT NULL CONSTRAINT [DF_DictItem_IsDefault] DEFAULT (0),
    [ExtJson] nvarchar(max) NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_DictItem_IsEnabled] DEFAULT (1),
    CONSTRAINT [PK_DictItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_DictItem_DictTypeId_Code] ON [plat].[DictItem] ([DictTypeId], [Code]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'字典项', N'SCHEMA', N'plat', N'TABLE', N'DictItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'DictItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'项编码', N'SCHEMA', N'plat', N'TABLE', N'DictItem', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'项名称', N'SCHEMA', N'plat', N'TABLE', N'DictItem', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'值', N'SCHEMA', N'plat', N'TABLE', N'DictItem', N'COLUMN', N'Value';
EXEC sp_addextendedproperty N'MS_Description', N'父项(树形字典)', N'SCHEMA', N'plat', N'TABLE', N'DictItem', N'COLUMN', N'ParentCode';
EXEC sp_addextendedproperty N'MS_Description', N'扩展(颜色/图标)', N'SCHEMA', N'plat', N'TABLE', N'DictItem', N'COLUMN', N'ExtJson';
GO
CREATE TABLE [plat].[CodeRule] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_CodeRule_TenantId] DEFAULT (1),
    [Code] varchar(60) NOT NULL,
    [Name] nvarchar(100) NULL,
    [ObjectType] varchar(60) NULL,
    [Separator] varchar(5) NULL,
    [ResetCycle] tinyint NOT NULL CONSTRAINT [DF_CodeRule_ResetCycle] DEFAULT (0) CONSTRAINT [CK_CodeRule_ResetCycle] CHECK (ResetCycle BETWEEN 0 AND 3),
    [Sample] varchar(100) NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_CodeRule_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_CodeRule_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_CodeRule_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_CodeRule] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_CodeRule_TenantId_Code] ON [plat].[CodeRule] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_CodeRule_CreatedBy] ON [plat].[CodeRule] ([CreatedBy]);
GO
CREATE INDEX [IX_CodeRule_ModifiedBy] ON [plat].[CodeRule] ([ModifiedBy]);
GO
CREATE INDEX [IX_CodeRule_DeletedBy] ON [plat].[CodeRule] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'编码规则', N'SCHEMA', N'plat', N'TABLE', N'CodeRule';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'CodeRule', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'规则编码', N'SCHEMA', N'plat', N'TABLE', N'CodeRule', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'规则名称', N'SCHEMA', N'plat', N'TABLE', N'CodeRule', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'适用单据/实体', N'SCHEMA', N'plat', N'TABLE', N'CodeRule', N'COLUMN', N'ObjectType';
EXEC sp_addextendedproperty N'MS_Description', N'分隔符', N'SCHEMA', N'plat', N'TABLE', N'CodeRule', N'COLUMN', N'Separator';
EXEC sp_addextendedproperty N'MS_Description', N'重置(0不重置 1按年 2按月 3按日)', N'SCHEMA', N'plat', N'TABLE', N'CodeRule', N'COLUMN', N'ResetCycle';
EXEC sp_addextendedproperty N'MS_Description', N'示例(XS20260101-0001)', N'SCHEMA', N'plat', N'TABLE', N'CodeRule', N'COLUMN', N'Sample';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'CodeRule', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'CodeRule', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'CodeRule', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'CodeRule', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'CodeRule', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'CodeRule', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'CodeRule', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'CodeRule', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'CodeRule', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[CodeRuleSegment] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [CodeRuleId] bigint NOT NULL,
    [Seq] int NOT NULL CONSTRAINT [DF_CodeRuleSegment_Seq] DEFAULT (1),
    [SegmentType] tinyint NOT NULL CONSTRAINT [DF_CodeRuleSegment_SegmentType] DEFAULT (3) CONSTRAINT [CK_CodeRuleSegment_SegmentType] CHECK (SegmentType BETWEEN 1 AND 6),
    [Format] varchar(30) NULL,
    [ValueSource] varchar(100) NULL,
    [Length] int NULL,
    [PadChar] char(1) NULL CONSTRAINT [DF_CodeRuleSegment_PadChar] DEFAULT ('0'),
    CONSTRAINT [PK_CodeRuleSegment] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_CodeRuleSegment_CodeRuleId_Seq] ON [plat].[CodeRuleSegment] ([CodeRuleId], [Seq]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'编码规则片段', N'SCHEMA', N'plat', N'TABLE', N'CodeRuleSegment';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'CodeRuleSegment', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1固定文本 2日期 3流水号 4字段值 5组织码 6单据类型)', N'SCHEMA', N'plat', N'TABLE', N'CodeRuleSegment', N'COLUMN', N'SegmentType';
EXEC sp_addextendedproperty N'MS_Description', N'格式(yyyyMMdd / 0000)', N'SCHEMA', N'plat', N'TABLE', N'CodeRuleSegment', N'COLUMN', N'Format';
EXEC sp_addextendedproperty N'MS_Description', N'字段值来源', N'SCHEMA', N'plat', N'TABLE', N'CodeRuleSegment', N'COLUMN', N'ValueSource';
EXEC sp_addextendedproperty N'MS_Description', N'长度', N'SCHEMA', N'plat', N'TABLE', N'CodeRuleSegment', N'COLUMN', N'Length';
EXEC sp_addextendedproperty N'MS_Description', N'补位字符', N'SCHEMA', N'plat', N'TABLE', N'CodeRuleSegment', N'COLUMN', N'PadChar';
GO
CREATE TABLE [plat].[CodeSeed] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_CodeSeed_TenantId] DEFAULT (1),
    [CodeRuleId] bigint NOT NULL,
    [PeriodKey] varchar(20) NOT NULL,
    [CurrentValue] bigint NOT NULL CONSTRAINT [DF_CodeSeed_CurrentValue] DEFAULT (0),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_CodeSeed] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_CodeSeed_TenantId_CodeRuleId_PeriodKey] ON [plat].[CodeSeed] ([TenantId], [CodeRuleId], [PeriodKey]);
GO
CREATE INDEX [IX_CodeSeed_CodeRuleId] ON [plat].[CodeSeed] ([CodeRuleId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'流水号种子（并发出号）', N'SCHEMA', N'plat', N'TABLE', N'CodeSeed';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'CodeSeed', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'周期键(2026/202601/20260101)', N'SCHEMA', N'plat', N'TABLE', N'CodeSeed', N'COLUMN', N'PeriodKey';
EXEC sp_addextendedproperty N'MS_Description', N'当前值', N'SCHEMA', N'plat', N'TABLE', N'CodeSeed', N'COLUMN', N'CurrentValue';
GO
CREATE TABLE [plat].[Attachment] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Attachment_TenantId] DEFAULT (1),
    [BusinessType] varchar(60) NULL,
    [BusinessId] bigint NULL,
    [FileName] nvarchar(200) NULL,
    [Ext] varchar(20) NULL,
    [FileSize] bigint NULL,
    [StorageType] tinyint NOT NULL CONSTRAINT [DF_Attachment_StorageType] DEFAULT (1),
    [Path] nvarchar(500) NULL,
    [Url] nvarchar(500) NULL,
    [FileHash] varchar(64) NULL,
    [UploadedBy] bigint NULL,
    [UploadedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Attachment_UploadedAt] DEFAULT (sysutcdatetime()),
    CONSTRAINT [PK_Attachment] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_Attachment_BusinessType_BusinessId] ON [plat].[Attachment] ([BusinessType], [BusinessId]);
GO
CREATE INDEX [IX_Attachment_FileHash] ON [plat].[Attachment] ([FileHash]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'附件', N'SCHEMA', N'plat', N'TABLE', N'Attachment';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'Attachment', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'业务类型', N'SCHEMA', N'plat', N'TABLE', N'Attachment', N'COLUMN', N'BusinessType';
EXEC sp_addextendedproperty N'MS_Description', N'业务Id', N'SCHEMA', N'plat', N'TABLE', N'Attachment', N'COLUMN', N'BusinessId';
EXEC sp_addextendedproperty N'MS_Description', N'文件名', N'SCHEMA', N'plat', N'TABLE', N'Attachment', N'COLUMN', N'FileName';
EXEC sp_addextendedproperty N'MS_Description', N'扩展名', N'SCHEMA', N'plat', N'TABLE', N'Attachment', N'COLUMN', N'Ext';
EXEC sp_addextendedproperty N'MS_Description', N'字节数', N'SCHEMA', N'plat', N'TABLE', N'Attachment', N'COLUMN', N'FileSize';
EXEC sp_addextendedproperty N'MS_Description', N'存储(1本地 2OSS 3S3)', N'SCHEMA', N'plat', N'TABLE', N'Attachment', N'COLUMN', N'StorageType';
EXEC sp_addextendedproperty N'MS_Description', N'存储路径', N'SCHEMA', N'plat', N'TABLE', N'Attachment', N'COLUMN', N'Path';
EXEC sp_addextendedproperty N'MS_Description', N'访问地址', N'SCHEMA', N'plat', N'TABLE', N'Attachment', N'COLUMN', N'Url';
EXEC sp_addextendedproperty N'MS_Description', N'SHA256(秒传/去重)', N'SCHEMA', N'plat', N'TABLE', N'Attachment', N'COLUMN', N'FileHash';
EXEC sp_addextendedproperty N'MS_Description', N'上传人', N'SCHEMA', N'plat', N'TABLE', N'Attachment', N'COLUMN', N'UploadedBy';
GO
CREATE TABLE [plat].[AuditLog] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_AuditLog_TenantId] DEFAULT (1),
    [UserId] bigint NULL,
    [UserName] nvarchar(50) NULL,
    [ActionType] tinyint NOT NULL CONSTRAINT [DF_AuditLog_ActionType] DEFAULT (1) CONSTRAINT [CK_AuditLog_ActionType] CHECK (ActionType BETWEEN 1 AND 11),
    [ObjectType] varchar(60) NULL,
    [ObjectId] bigint NULL,
    [ObjectNo] varchar(60) NULL,
    [FieldChanges] nvarchar(max) NULL,
    [Ip] varchar(50) NULL,
    [UserAgent] nvarchar(300) NULL,
    [DurationMs] int NULL,
    [At] datetime2(3) NOT NULL CONSTRAINT [DF_AuditLog_At] DEFAULT (sysutcdatetime()),
    CONSTRAINT [PK_AuditLog] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_AuditLog_TenantId_At] ON [plat].[AuditLog] ([TenantId], [At]);
GO
CREATE INDEX [IX_AuditLog_ObjectType_ObjectId] ON [plat].[AuditLog] ([ObjectType], [ObjectId]);
GO
CREATE INDEX [IX_AuditLog_UserId_At] ON [plat].[AuditLog] ([UserId], [At]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'操作审计', N'SCHEMA', N'plat', N'TABLE', N'AuditLog';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'AuditLog', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'操作人', N'SCHEMA', N'plat', N'TABLE', N'AuditLog', N'COLUMN', N'UserId';
EXEC sp_addextendedproperty N'MS_Description', N'操作人快照', N'SCHEMA', N'plat', N'TABLE', N'AuditLog', N'COLUMN', N'UserName';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1新增 2修改 3删除 4审核 5反审 6导出 7登录 8打印 9导入 10配置 11作废)', N'SCHEMA', N'plat', N'TABLE', N'AuditLog', N'COLUMN', N'ActionType';
EXEC sp_addextendedproperty N'MS_Description', N'对象类型', N'SCHEMA', N'plat', N'TABLE', N'AuditLog', N'COLUMN', N'ObjectType';
EXEC sp_addextendedproperty N'MS_Description', N'对象Id', N'SCHEMA', N'plat', N'TABLE', N'AuditLog', N'COLUMN', N'ObjectId';
EXEC sp_addextendedproperty N'MS_Description', N'对象编号', N'SCHEMA', N'plat', N'TABLE', N'AuditLog', N'COLUMN', N'ObjectNo';
EXEC sp_addextendedproperty N'MS_Description', N'字段变更(JSON before/after)', N'SCHEMA', N'plat', N'TABLE', N'AuditLog', N'COLUMN', N'FieldChanges';
EXEC sp_addextendedproperty N'MS_Description', N'耗时', N'SCHEMA', N'plat', N'TABLE', N'AuditLog', N'COLUMN', N'DurationMs';
GO
CREATE TABLE [plat].[Notification] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Notification_TenantId] DEFAULT (1),
    [RecipientId] bigint NOT NULL,
    [Title] nvarchar(200) NULL,
    [Content] nvarchar(1000) NULL,
    [MsgType] tinyint NOT NULL CONSTRAINT [DF_Notification_MsgType] DEFAULT (1) CONSTRAINT [CK_Notification_MsgType] CHECK (MsgType BETWEEN 1 AND 4),
    [BusinessType] varchar(60) NULL,
    [BusinessId] bigint NULL,
    [LinkUrl] varchar(300) NULL,
    [IsRead] bit NOT NULL CONSTRAINT [DF_Notification_IsRead] DEFAULT (0),
    [ReadAt] datetime2(3) NULL,
    [At] datetime2(3) NOT NULL CONSTRAINT [DF_Notification_At] DEFAULT (sysutcdatetime()),
    CONSTRAINT [PK_Notification] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_Notification_RecipientId_IsRead_At] ON [plat].[Notification] ([RecipientId], [IsRead], [At]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'消息与待办', N'SCHEMA', N'plat', N'TABLE', N'Notification';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'Notification', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'接收人', N'SCHEMA', N'plat', N'TABLE', N'Notification', N'COLUMN', N'RecipientId';
EXEC sp_addextendedproperty N'MS_Description', N'标题', N'SCHEMA', N'plat', N'TABLE', N'Notification', N'COLUMN', N'Title';
EXEC sp_addextendedproperty N'MS_Description', N'内容', N'SCHEMA', N'plat', N'TABLE', N'Notification', N'COLUMN', N'Content';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1待办 2预警 3公告 4系统)', N'SCHEMA', N'plat', N'TABLE', N'Notification', N'COLUMN', N'MsgType';
EXEC sp_addextendedproperty N'MS_Description', N'业务类型', N'SCHEMA', N'plat', N'TABLE', N'Notification', N'COLUMN', N'BusinessType';
EXEC sp_addextendedproperty N'MS_Description', N'业务Id', N'SCHEMA', N'plat', N'TABLE', N'Notification', N'COLUMN', N'BusinessId';
EXEC sp_addextendedproperty N'MS_Description', N'跳转地址', N'SCHEMA', N'plat', N'TABLE', N'Notification', N'COLUMN', N'LinkUrl';
EXEC sp_addextendedproperty N'MS_Description', N'阅读时间', N'SCHEMA', N'plat', N'TABLE', N'Notification', N'COLUMN', N'ReadAt';
GO
CREATE TABLE [plat].[CustomField] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_CustomField_TenantId] DEFAULT (1),
    [ObjectName] varchar(100) NOT NULL,
    [FieldName] varchar(60) NOT NULL,
    [DisplayName] nvarchar(100) NULL,
    [DataType] varchar(30) NOT NULL CONSTRAINT [DF_CustomField_DataType] DEFAULT ('string'),
    [MaxLength] int NULL,
    [DefaultValue] nvarchar(200) NULL,
    [DictTypeCode] varchar(60) NULL,
    [IsRequired] bit NOT NULL CONSTRAINT [DF_CustomField_IsRequired] DEFAULT (0),
    [Sort] int NOT NULL CONSTRAINT [DF_CustomField_Sort] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_CustomField_IsEnabled] DEFAULT (1),
    CONSTRAINT [PK_CustomField] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_CustomField_TenantId_ObjectName_FieldName] ON [plat].[CustomField] ([TenantId], [ObjectName], [FieldName]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'自定义字段（不改变物理表）', N'SCHEMA', N'plat', N'TABLE', N'CustomField';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'CustomField', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'物理表/对象', N'SCHEMA', N'plat', N'TABLE', N'CustomField', N'COLUMN', N'ObjectName';
EXEC sp_addextendedproperty N'MS_Description', N'字段名', N'SCHEMA', N'plat', N'TABLE', N'CustomField', N'COLUMN', N'FieldName';
EXEC sp_addextendedproperty N'MS_Description', N'显示名', N'SCHEMA', N'plat', N'TABLE', N'CustomField', N'COLUMN', N'DisplayName';
EXEC sp_addextendedproperty N'MS_Description', N'类型(string/number/date/bool)', N'SCHEMA', N'plat', N'TABLE', N'CustomField', N'COLUMN', N'DataType';
EXEC sp_addextendedproperty N'MS_Description', N'长度', N'SCHEMA', N'plat', N'TABLE', N'CustomField', N'COLUMN', N'MaxLength';
EXEC sp_addextendedproperty N'MS_Description', N'字典', N'SCHEMA', N'plat', N'TABLE', N'CustomField', N'COLUMN', N'DictTypeCode';
GO
CREATE TABLE [plat].[Translation] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Translation_TenantId] DEFAULT (1),
    [Lang] varchar(10) NOT NULL,
    [ResourceType] varchar(30) NOT NULL,
    [ResourceKey] varchar(200) NOT NULL,
    [Text] nvarchar(500) NULL,
    CONSTRAINT [PK_Translation] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Translation_TenantId_Lang_ResourceType_ResourceKey] ON [plat].[Translation] ([TenantId], [Lang], [ResourceType], [ResourceKey]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'多语言', N'SCHEMA', N'plat', N'TABLE', N'Translation';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'Translation', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'语言(zh-CN/en-US)', N'SCHEMA', N'plat', N'TABLE', N'Translation', N'COLUMN', N'Lang';
EXEC sp_addextendedproperty N'MS_Description', N'资源类型(menu/field/dict/msg)', N'SCHEMA', N'plat', N'TABLE', N'Translation', N'COLUMN', N'ResourceType';
EXEC sp_addextendedproperty N'MS_Description', N'资源键', N'SCHEMA', N'plat', N'TABLE', N'Translation', N'COLUMN', N'ResourceKey';
EXEC sp_addextendedproperty N'MS_Description', N'译文', N'SCHEMA', N'plat', N'TABLE', N'Translation', N'COLUMN', N'Text';
GO
CREATE TABLE [plat].[Setting] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Setting_TenantId] DEFAULT (1),
    [Category] varchar(50) NOT NULL,
    [Key] varchar(100) NOT NULL,
    [Value] nvarchar(max) NULL,
    [ValueType] varchar(20) NOT NULL CONSTRAINT [DF_Setting_ValueType] DEFAULT ('string'),
    [Description] nvarchar(300) NULL,
    [IsSystem] bit NOT NULL CONSTRAINT [DF_Setting_IsSystem] DEFAULT (0),
    CONSTRAINT [PK_Setting] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Setting_TenantId_Category_Key] ON [plat].[Setting] ([TenantId], [Category], [Key]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'系统参数', N'SCHEMA', N'plat', N'TABLE', N'Setting';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'Setting', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'分组', N'SCHEMA', N'plat', N'TABLE', N'Setting', N'COLUMN', N'Category';
EXEC sp_addextendedproperty N'MS_Description', N'参数键', N'SCHEMA', N'plat', N'TABLE', N'Setting', N'COLUMN', N'Key';
EXEC sp_addextendedproperty N'MS_Description', N'参数值', N'SCHEMA', N'plat', N'TABLE', N'Setting', N'COLUMN', N'Value';
EXEC sp_addextendedproperty N'MS_Description', N'类型(string/int/bool/json)', N'SCHEMA', N'plat', N'TABLE', N'Setting', N'COLUMN', N'ValueType';
EXEC sp_addextendedproperty N'MS_Description', N'系统内置(不可删)', N'SCHEMA', N'plat', N'TABLE', N'Setting', N'COLUMN', N'IsSystem';
GO
CREATE TABLE [plat].[JobDefinition] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_JobDefinition_TenantId] DEFAULT (1),
    [Code] varchar(60) NOT NULL,
    [Name] nvarchar(100) NULL,
    [JobType] tinyint NOT NULL CONSTRAINT [DF_JobDefinition_JobType] DEFAULT (1) CONSTRAINT [CK_JobDefinition_JobType] CHECK (JobType BETWEEN 1 AND 4),
    [Target] varchar(300) NULL,
    [Cron] varchar(60) NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_JobDefinition_IsEnabled] DEFAULT (1),
    [LastRunAt] datetime2(3) NULL,
    [LastResult] nvarchar(500) NULL,
    [NextRunAt] datetime2(3) NULL,
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_JobDefinition_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_JobDefinition_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_JobDefinition] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_JobDefinition_TenantId_Code] ON [plat].[JobDefinition] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_JobDefinition_CreatedBy] ON [plat].[JobDefinition] ([CreatedBy]);
GO
CREATE INDEX [IX_JobDefinition_ModifiedBy] ON [plat].[JobDefinition] ([ModifiedBy]);
GO
CREATE INDEX [IX_JobDefinition_DeletedBy] ON [plat].[JobDefinition] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'定时任务', N'SCHEMA', N'plat', N'TABLE', N'JobDefinition';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'JobDefinition', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1存储过程 2SQL 3HTTP 4领域事件)', N'SCHEMA', N'plat', N'TABLE', N'JobDefinition', N'COLUMN', N'JobType';
EXEC sp_addextendedproperty N'MS_Description', N'目标', N'SCHEMA', N'plat', N'TABLE', N'JobDefinition', N'COLUMN', N'Target';
EXEC sp_addextendedproperty N'MS_Description', N'Cron表达式', N'SCHEMA', N'plat', N'TABLE', N'JobDefinition', N'COLUMN', N'Cron';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'JobDefinition', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'JobDefinition', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'JobDefinition', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'JobDefinition', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'JobDefinition', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'JobDefinition', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'JobDefinition', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'JobDefinition', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'JobDefinition', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[JobLog] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [JobId] bigint NOT NULL,
    [StartedAt] datetime2(3) NOT NULL CONSTRAINT [DF_JobLog_StartedAt] DEFAULT (sysutcdatetime()),
    [FinishedAt] datetime2(3) NULL,
    [Success] bit NOT NULL CONSTRAINT [DF_JobLog_Success] DEFAULT (0),
    [Message] nvarchar(1000) NULL,
    [AffectedRows] int NULL,
    CONSTRAINT [PK_JobLog] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_JobLog_JobId_StartedAt] ON [plat].[JobLog] ([JobId], [StartedAt]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'任务执行日志', N'SCHEMA', N'plat', N'TABLE', N'JobLog';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'JobLog', N'COLUMN', N'Id';
GO
CREATE TABLE [plat].[ImportTask] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_ImportTask_TenantId] DEFAULT (1),
    [Code] varchar(60) NULL,
    [DataObjectCode] varchar(60) NULL,
    [TemplateJson] nvarchar(max) NULL,
    [FileName] nvarchar(200) NULL,
    [TotalRows] int NOT NULL CONSTRAINT [DF_ImportTask_TotalRows] DEFAULT (0),
    [SuccessRows] int NOT NULL CONSTRAINT [DF_ImportTask_SuccessRows] DEFAULT (0),
    [FailRows] int NOT NULL CONSTRAINT [DF_ImportTask_FailRows] DEFAULT (0),
    [Status] tinyint NOT NULL CONSTRAINT [DF_ImportTask_Status] DEFAULT (0),
    [ErrorJson] nvarchar(max) NULL,
    [StartedAt] datetime2(3) NULL,
    [FinishedAt] datetime2(3) NULL,
    [UserId] bigint NULL,
    CONSTRAINT [PK_ImportTask] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_ImportTask_TenantId_Status] ON [plat].[ImportTask] ([TenantId], [Status]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'导入任务', N'SCHEMA', N'plat', N'TABLE', N'ImportTask';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'ImportTask', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'任务号', N'SCHEMA', N'plat', N'TABLE', N'ImportTask', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'目标对象', N'SCHEMA', N'plat', N'TABLE', N'ImportTask', N'COLUMN', N'DataObjectCode';
EXEC sp_addextendedproperty N'MS_Description', N'字段映射', N'SCHEMA', N'plat', N'TABLE', N'ImportTask', N'COLUMN', N'TemplateJson';
EXEC sp_addextendedproperty N'MS_Description', N'0待处理 1处理中 2完成 3失败', N'SCHEMA', N'plat', N'TABLE', N'ImportTask', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'错误明细', N'SCHEMA', N'plat', N'TABLE', N'ImportTask', N'COLUMN', N'ErrorJson';
GO
CREATE TABLE [plat].[IntegrationEndpoint] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_IntegrationEndpoint_TenantId] DEFAULT (1),
    [Code] varchar(60) NOT NULL,
    [Name] nvarchar(100) NULL,
    [EndpointType] tinyint NOT NULL CONSTRAINT [DF_IntegrationEndpoint_EndpointType] DEFAULT (1) CONSTRAINT [CK_IntegrationEndpoint_EndpointType] CHECK (EndpointType BETWEEN 1 AND 6),
    [Provider] varchar(60) NULL,
    [BaseUrl] varchar(300) NULL,
    [AuthType] tinyint NOT NULL CONSTRAINT [DF_IntegrationEndpoint_AuthType] DEFAULT (1),
    [CredentialRef] varchar(200) NULL,
    [TimeoutSeconds] int NOT NULL CONSTRAINT [DF_IntegrationEndpoint_TimeoutSeconds] DEFAULT (30),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_IntegrationEndpoint_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_IntegrationEndpoint_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_IntegrationEndpoint_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_IntegrationEndpoint] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_IntegrationEndpoint_TenantId_Code] ON [plat].[IntegrationEndpoint] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_IntegrationEndpoint_CreatedBy] ON [plat].[IntegrationEndpoint] ([CreatedBy]);
GO
CREATE INDEX [IX_IntegrationEndpoint_ModifiedBy] ON [plat].[IntegrationEndpoint] ([ModifiedBy]);
GO
CREATE INDEX [IX_IntegrationEndpoint_DeletedBy] ON [plat].[IntegrationEndpoint] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'集成端点', N'SCHEMA', N'plat', N'TABLE', N'IntegrationEndpoint';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'IntegrationEndpoint', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'端点编码(TAOBAO/JD/WECHAT...)', N'SCHEMA', N'plat', N'TABLE', N'IntegrationEndpoint', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1电商 2物流 3支付 4发票 5协同 6其他)', N'SCHEMA', N'plat', N'TABLE', N'IntegrationEndpoint', N'COLUMN', N'EndpointType';
EXEC sp_addextendedproperty N'MS_Description', N'服务商', N'SCHEMA', N'plat', N'TABLE', N'IntegrationEndpoint', N'COLUMN', N'Provider';
EXEC sp_addextendedproperty N'MS_Description', N'鉴权(1OAuth 2AK/SK 3证书 4Token)', N'SCHEMA', N'plat', N'TABLE', N'IntegrationEndpoint', N'COLUMN', N'AuthType';
EXEC sp_addextendedproperty N'MS_Description', N'凭据引用(不存明文)', N'SCHEMA', N'plat', N'TABLE', N'IntegrationEndpoint', N'COLUMN', N'CredentialRef';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'plat', N'TABLE', N'IntegrationEndpoint', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'plat', N'TABLE', N'IntegrationEndpoint', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'plat', N'TABLE', N'IntegrationEndpoint', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'plat', N'TABLE', N'IntegrationEndpoint', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'IntegrationEndpoint', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'plat', N'TABLE', N'IntegrationEndpoint', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'IntegrationEndpoint', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'plat', N'TABLE', N'IntegrationEndpoint', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'plat', N'TABLE', N'IntegrationEndpoint', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [plat].[IntegrationLog] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_IntegrationLog_TenantId] DEFAULT (1),
    [EndpointId] bigint NULL,
    [Direction] tinyint NOT NULL CONSTRAINT [DF_IntegrationLog_Direction] DEFAULT (1),
    [Method] varchar(10) NULL,
    [Url] varchar(500) NULL,
    [RequestBody] nvarchar(max) NULL,
    [ResponseBody] nvarchar(max) NULL,
    [StatusCode] int NULL,
    [Success] bit NOT NULL CONSTRAINT [DF_IntegrationLog_Success] DEFAULT (0),
    [ErrorMessage] nvarchar(1000) NULL,
    [DurationMs] int NULL,
    [RetryCount] int NOT NULL CONSTRAINT [DF_IntegrationLog_RetryCount] DEFAULT (0),
    [At] datetime2(3) NOT NULL CONSTRAINT [DF_IntegrationLog_At] DEFAULT (sysutcdatetime()),
    CONSTRAINT [PK_IntegrationLog] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_IntegrationLog_TenantId_At] ON [plat].[IntegrationLog] ([TenantId], [At]);
GO
CREATE INDEX [IX_IntegrationLog_Success_At] ON [plat].[IntegrationLog] ([Success], [At]);
GO
CREATE INDEX [IX_IntegrationLog_EndpointId] ON [plat].[IntegrationLog] ([EndpointId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'接口调用日志', N'SCHEMA', N'plat', N'TABLE', N'IntegrationLog';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'IntegrationLog', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'端点', N'SCHEMA', N'plat', N'TABLE', N'IntegrationLog', N'COLUMN', N'EndpointId';
EXEC sp_addextendedproperty N'MS_Description', N'方向(1出 2入)', N'SCHEMA', N'plat', N'TABLE', N'IntegrationLog', N'COLUMN', N'Direction';
EXEC sp_addextendedproperty N'MS_Description', N'HTTP方法', N'SCHEMA', N'plat', N'TABLE', N'IntegrationLog', N'COLUMN', N'Method';
GO
CREATE TABLE [plat].[MetaVersion] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_MetaVersion_TenantId] DEFAULT (1),
    [Version] int NOT NULL,
    [Scope] varchar(100) NULL,
    [ContentHash] varchar(64) NULL,
    [Payload] nvarchar(max) NULL,
    [PublishedBy] bigint NULL,
    [PublishedAt] datetime2(3) NOT NULL CONSTRAINT [DF_MetaVersion_PublishedAt] DEFAULT (sysutcdatetime()),
    [RollbackOf] int NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_MetaVersion_Status] DEFAULT (1),
    [Remark] nvarchar(300) NULL,
    CONSTRAINT [PK_MetaVersion] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_MetaVersion_TenantId_Version] ON [plat].[MetaVersion] ([TenantId], [Version]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'元数据版本（发布与回滚）', N'SCHEMA', N'plat', N'TABLE', N'MetaVersion';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'MetaVersion', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'版本号', N'SCHEMA', N'plat', N'TABLE', N'MetaVersion', N'COLUMN', N'Version';
EXEC sp_addextendedproperty N'MS_Description', N'发布范围(模块/页面/全量)', N'SCHEMA', N'plat', N'TABLE', N'MetaVersion', N'COLUMN', N'Scope';
EXEC sp_addextendedproperty N'MS_Description', N'内容哈希', N'SCHEMA', N'plat', N'TABLE', N'MetaVersion', N'COLUMN', N'ContentHash';
EXEC sp_addextendedproperty N'MS_Description', N'快照', N'SCHEMA', N'plat', N'TABLE', N'MetaVersion', N'COLUMN', N'Payload';
EXEC sp_addextendedproperty N'MS_Description', N'回滚自哪个版本', N'SCHEMA', N'plat', N'TABLE', N'MetaVersion', N'COLUMN', N'RollbackOf';
EXEC sp_addextendedproperty N'MS_Description', N'状态(1已发布 2已回滚)', N'SCHEMA', N'plat', N'TABLE', N'MetaVersion', N'COLUMN', N'Status';
GO
CREATE TABLE [plat].[DomainEvent] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_DomainEvent_TenantId] DEFAULT (1),
    [EventType] varchar(100) NOT NULL,
    [AggregateType] varchar(60) NULL,
    [AggregateId] bigint NULL,
    [PayloadJson] nvarchar(max) NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_DomainEvent_Status] DEFAULT (0) CONSTRAINT [CK_DomainEvent_Status] CHECK (Status BETWEEN 0 AND 3),
    [RetryCount] int NOT NULL CONSTRAINT [DF_DomainEvent_RetryCount] DEFAULT (0),
    [NextRetryAt] datetime2(3) NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_DomainEvent_CreatedAt] DEFAULT (sysutcdatetime()),
    [ProcessedAt] datetime2(3) NULL,
    [ErrorMessage] nvarchar(1000) NULL,
    CONSTRAINT [PK_DomainEvent] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_DomainEvent_Status_NextRetryAt] ON [plat].[DomainEvent] ([Status], [NextRetryAt]);
GO
CREATE INDEX [IX_DomainEvent_AggregateType_AggregateId] ON [plat].[DomainEvent] ([AggregateType], [AggregateId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'领域事件（Outbox，保证最终一致）', N'SCHEMA', N'plat', N'TABLE', N'DomainEvent';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'plat', N'TABLE', N'DomainEvent', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'事件类型(SalesOrder.Audited)', N'SCHEMA', N'plat', N'TABLE', N'DomainEvent', N'COLUMN', N'EventType';
EXEC sp_addextendedproperty N'MS_Description', N'聚合根', N'SCHEMA', N'plat', N'TABLE', N'DomainEvent', N'COLUMN', N'AggregateType';
EXEC sp_addextendedproperty N'MS_Description', N'聚合根Id', N'SCHEMA', N'plat', N'TABLE', N'DomainEvent', N'COLUMN', N'AggregateId';
EXEC sp_addextendedproperty N'MS_Description', N'事件载荷', N'SCHEMA', N'plat', N'TABLE', N'DomainEvent', N'COLUMN', N'PayloadJson';
EXEC sp_addextendedproperty N'MS_Description', N'状态(0待投递 1已投递 2失败 3忽略)', N'SCHEMA', N'plat', N'TABLE', N'DomainEvent', N'COLUMN', N'Status';
GO
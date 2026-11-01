/* =====================================================================
   进销存管理系统 V3 · 表结构 · md 架构（35 张表）
   数据库：APSErpV3   生成器：db/emit.py（请勿手改，改规格文件后重新生成）
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE TABLE [md].[Unit] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Unit_TenantId] DEFAULT (1),
    [Code] varchar(20) NOT NULL,
    [Name] nvarchar(20) NOT NULL,
    [IsDecimal] bit NOT NULL CONSTRAINT [DF_Unit_IsDecimal] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Unit_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Unit_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Unit_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Unit] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Unit_TenantId_Code] ON [md].[Unit] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Unit_CreatedBy] ON [md].[Unit] ([CreatedBy]);
GO
CREATE INDEX [IX_Unit_ModifiedBy] ON [md].[Unit] ([ModifiedBy]);
GO
CREATE INDEX [IX_Unit_DeletedBy] ON [md].[Unit] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'计量单位', N'SCHEMA', N'md', N'TABLE', N'Unit';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'Unit', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'单位编码', N'SCHEMA', N'md', N'TABLE', N'Unit', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'单位名称', N'SCHEMA', N'md', N'TABLE', N'Unit', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'允许小数(千克/米)', N'SCHEMA', N'md', N'TABLE', N'Unit', N'COLUMN', N'IsDecimal';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'Unit', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'Unit', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'Unit', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'Unit', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Unit', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'Unit', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Unit', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'Unit', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Unit', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[UnitConversion] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_UnitConversion_TenantId] DEFAULT (1),
    [FromUnitId] bigint NOT NULL,
    [ToUnitId] bigint NOT NULL,
    [Rate] decimal(19,6) NOT NULL,
    CONSTRAINT [PK_UnitConversion] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_UnitConversion_FromUnitId_ToUnitId] ON [md].[UnitConversion] ([FromUnitId], [ToUnitId]);
GO
CREATE INDEX [IX_UnitConversion_ToUnitId] ON [md].[UnitConversion] ([ToUnitId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'单位换算（全局）', N'SCHEMA', N'md', N'TABLE', N'UnitConversion';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'UnitConversion', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'源单位', N'SCHEMA', N'md', N'TABLE', N'UnitConversion', N'COLUMN', N'FromUnitId';
EXEC sp_addextendedproperty N'MS_Description', N'目标单位', N'SCHEMA', N'md', N'TABLE', N'UnitConversion', N'COLUMN', N'ToUnitId';
EXEC sp_addextendedproperty N'MS_Description', N'换算率(1源=Rate目标)', N'SCHEMA', N'md', N'TABLE', N'UnitConversion', N'COLUMN', N'Rate';
GO
CREATE TABLE [md].[Category] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Category_TenantId] DEFAULT (1),
    [ParentId] bigint NULL,
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(50) NOT NULL,
    [Path] varchar(500) NULL,
    [Level] tinyint NOT NULL CONSTRAINT [DF_Category_Level] DEFAULT (1),
    [CategoryType] tinyint NOT NULL CONSTRAINT [DF_Category_CategoryType] DEFAULT (1) CONSTRAINT [CK_Category_CategoryType] CHECK (CategoryType BETWEEN 1 AND 4),
    [FinAccountCode] varchar(30) NULL,
    [Sort] int NOT NULL CONSTRAINT [DF_Category_Sort] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Category_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Category_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Category_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Category] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Category_TenantId_Code] ON [md].[Category] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Category_TenantId_ParentId_Sort] ON [md].[Category] ([TenantId], [ParentId], [Sort]);
GO
CREATE INDEX [IX_Category_ParentId] ON [md].[Category] ([ParentId]);
GO
CREATE INDEX [IX_Category_CreatedBy] ON [md].[Category] ([CreatedBy]);
GO
CREATE INDEX [IX_Category_ModifiedBy] ON [md].[Category] ([ModifiedBy]);
GO
CREATE INDEX [IX_Category_DeletedBy] ON [md].[Category] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'商品分类（树）', N'SCHEMA', N'md', N'TABLE', N'Category';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'Category', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'上级分类', N'SCHEMA', N'md', N'TABLE', N'Category', N'COLUMN', N'ParentId';
EXEC sp_addextendedproperty N'MS_Description', N'分类编码', N'SCHEMA', N'md', N'TABLE', N'Category', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'分类名称', N'SCHEMA', N'md', N'TABLE', N'Category', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'层级路径', N'SCHEMA', N'md', N'TABLE', N'Category', N'COLUMN', N'Path';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1经营 2财务 3渠道 4仓储)', N'SCHEMA', N'md', N'TABLE', N'Category', N'COLUMN', N'CategoryType';
EXEC sp_addextendedproperty N'MS_Description', N'对应收入/成本科目', N'SCHEMA', N'md', N'TABLE', N'Category', N'COLUMN', N'FinAccountCode';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'Category', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'Category', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'Category', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'Category', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Category', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'Category', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Category', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'Category', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Category', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[Brand] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Brand_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(50) NOT NULL,
    [EnName] nvarchar(100) NULL,
    [ManufacturerId] bigint NULL,
    [Sort] int NOT NULL CONSTRAINT [DF_Brand_Sort] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Brand_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Brand_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Brand_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Brand] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Brand_TenantId_Code] ON [md].[Brand] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Brand_ManufacturerId] ON [md].[Brand] ([ManufacturerId]);
GO
CREATE INDEX [IX_Brand_CreatedBy] ON [md].[Brand] ([CreatedBy]);
GO
CREATE INDEX [IX_Brand_ModifiedBy] ON [md].[Brand] ([ModifiedBy]);
GO
CREATE INDEX [IX_Brand_DeletedBy] ON [md].[Brand] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'品牌', N'SCHEMA', N'md', N'TABLE', N'Brand';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'Brand', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'品牌名称', N'SCHEMA', N'md', N'TABLE', N'Brand', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'英文名', N'SCHEMA', N'md', N'TABLE', N'Brand', N'COLUMN', N'EnName';
EXEC sp_addextendedproperty N'MS_Description', N'所属厂家', N'SCHEMA', N'md', N'TABLE', N'Brand', N'COLUMN', N'ManufacturerId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'Brand', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'Brand', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'Brand', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'Brand', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Brand', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'Brand', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Brand', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'Brand', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Brand', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[Manufacturer] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Manufacturer_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    [LicenseNo] varchar(50) NULL,
    [Address] nvarchar(200) NULL,
    [Contact] nvarchar(50) NULL,
    [Phone] varchar(30) NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Manufacturer_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Manufacturer_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Manufacturer_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Manufacturer] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Manufacturer_TenantId_Code] ON [md].[Manufacturer] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Manufacturer_CreatedBy] ON [md].[Manufacturer] ([CreatedBy]);
GO
CREATE INDEX [IX_Manufacturer_ModifiedBy] ON [md].[Manufacturer] ([ModifiedBy]);
GO
CREATE INDEX [IX_Manufacturer_DeletedBy] ON [md].[Manufacturer] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'厂家', N'SCHEMA', N'md', N'TABLE', N'Manufacturer';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'Manufacturer', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'厂家名称', N'SCHEMA', N'md', N'TABLE', N'Manufacturer', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'生产许可证号', N'SCHEMA', N'md', N'TABLE', N'Manufacturer', N'COLUMN', N'LicenseNo';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'Manufacturer', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'Manufacturer', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'Manufacturer', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'Manufacturer', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Manufacturer', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'Manufacturer', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Manufacturer', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'Manufacturer', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Manufacturer', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[Product] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Product_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [ShortName] nvarchar(50) NULL,
    [EnName] nvarchar(200) NULL,
    [Mnemonic] varchar(50) NULL,
    [CategoryId] bigint NULL,
    [BrandId] bigint NULL,
    [ManufacturerId] bigint NULL,
    [ProductType] tinyint NOT NULL CONSTRAINT [DF_Product_ProductType] DEFAULT (1) CONSTRAINT [CK_Product_ProductType] CHECK (ProductType BETWEEN 1 AND 5),
    [Spec] nvarchar(100) NULL,
    [Model] nvarchar(100) NULL,
    [BaseUnitId] bigint NOT NULL,
    [TaxRate] decimal(9,4) NOT NULL CONSTRAINT [DF_Product_TaxRate] DEFAULT (13),
    [IsBatchManaged] bit NOT NULL CONSTRAINT [DF_Product_IsBatchManaged] DEFAULT (0),
    [IsSerialManaged] bit NOT NULL CONSTRAINT [DF_Product_IsSerialManaged] DEFAULT (0),
    [ShelfLifeDays] int NULL,
    [WarnDays] int NULL,
    [LifecycleStatus] tinyint NOT NULL CONSTRAINT [DF_Product_LifecycleStatus] DEFAULT (1) CONSTRAINT [CK_Product_LifecycleStatus] CHECK (LifecycleStatus BETWEEN 1 AND 5),
    [CanPurchase] bit NOT NULL CONSTRAINT [DF_Product_CanPurchase] DEFAULT (1),
    [CanSale] bit NOT NULL CONSTRAINT [DF_Product_CanSale] DEFAULT (1),
    [CanInventory] bit NOT NULL CONSTRAINT [DF_Product_CanInventory] DEFAULT (1),
    [CanOnline] bit NOT NULL CONSTRAINT [DF_Product_CanOnline] DEFAULT (0),
    [DefaultSupplierId] bigint NULL,
    [MinSalePrice] decimal(19,6) NULL,
    [StandardCost] decimal(19,6) NULL,
    [Weight] decimal(19,6) NULL,
    [Volume] decimal(19,6) NULL,
    [ImageUrl] nvarchar(300) NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Product_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Product_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Product_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Product] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Product_TenantId_Code] ON [md].[Product] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Product_TenantId_CategoryId] ON [md].[Product] ([TenantId], [CategoryId]);
GO
CREATE INDEX [IX_Product_TenantId_Name] ON [md].[Product] ([TenantId], [Name]);
GO
CREATE INDEX [IX_Product_Mnemonic] ON [md].[Product] ([Mnemonic]);
GO
CREATE INDEX [IX_Product_CategoryId] ON [md].[Product] ([CategoryId]);
GO
CREATE INDEX [IX_Product_BrandId] ON [md].[Product] ([BrandId]);
GO
CREATE INDEX [IX_Product_ManufacturerId] ON [md].[Product] ([ManufacturerId]);
GO
CREATE INDEX [IX_Product_BaseUnitId] ON [md].[Product] ([BaseUnitId]);
GO
CREATE INDEX [IX_Product_CreatedBy] ON [md].[Product] ([CreatedBy]);
GO
CREATE INDEX [IX_Product_ModifiedBy] ON [md].[Product] ([ModifiedBy]);
GO
CREATE INDEX [IX_Product_DeletedBy] ON [md].[Product] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'商品（SPU）', N'SCHEMA', N'md', N'TABLE', N'Product';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'商品编码', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'商品名称', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'简称', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'ShortName';
EXEC sp_addextendedproperty N'MS_Description', N'英文名(替代旧epm列)', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'EnName';
EXEC sp_addextendedproperty N'MS_Description', N'助记码', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'Mnemonic';
EXEC sp_addextendedproperty N'MS_Description', N'分类', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'CategoryId';
EXEC sp_addextendedproperty N'MS_Description', N'品牌', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'BrandId';
EXEC sp_addextendedproperty N'MS_Description', N'厂家', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'ManufacturerId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1普通 2组合 3称重 4服务 5赠品)', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'ProductType';
EXEC sp_addextendedproperty N'MS_Description', N'规格', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'Spec';
EXEC sp_addextendedproperty N'MS_Description', N'型号', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'Model';
EXEC sp_addextendedproperty N'MS_Description', N'基本单位', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'BaseUnitId';
EXEC sp_addextendedproperty N'MS_Description', N'税率%', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'TaxRate';
EXEC sp_addextendedproperty N'MS_Description', N'批次管理', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'IsBatchManaged';
EXEC sp_addextendedproperty N'MS_Description', N'序列号管理', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'IsSerialManaged';
EXEC sp_addextendedproperty N'MS_Description', N'保质期天数', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'ShelfLifeDays';
EXEC sp_addextendedproperty N'MS_Description', N'临期预警天数', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'WarnDays';
EXEC sp_addextendedproperty N'MS_Description', N'生命周期(1新品 2在售 3清仓 4停售 5淘汰)', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'LifecycleStatus';
EXEC sp_addextendedproperty N'MS_Description', N'可采购', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'CanPurchase';
EXEC sp_addextendedproperty N'MS_Description', N'可销售', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'CanSale';
EXEC sp_addextendedproperty N'MS_Description', N'可库存', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'CanInventory';
EXEC sp_addextendedproperty N'MS_Description', N'可线上销售', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'CanOnline';
EXEC sp_addextendedproperty N'MS_Description', N'默认供应商', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'DefaultSupplierId';
EXEC sp_addextendedproperty N'MS_Description', N'最低售价(毛利红线)', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'MinSalePrice';
EXEC sp_addextendedproperty N'MS_Description', N'标准成本', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'StandardCost';
EXEC sp_addextendedproperty N'MS_Description', N'毛重kg', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'Weight';
EXEC sp_addextendedproperty N'MS_Description', N'体积m3', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'Volume';
EXEC sp_addextendedproperty N'MS_Description', N'主图', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'ImageUrl';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Product', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[Sku] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Sku_TenantId] DEFAULT (1),
    [ProductId] bigint NOT NULL,
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [SpecValue] nvarchar(200) NULL,
    [BaseUnitId] bigint NOT NULL,
    [RetailPrice] decimal(19,6) NULL,
    [StandardCost] decimal(19,6) NULL,
    [Weight] decimal(19,6) NULL,
    [Volume] decimal(19,6) NULL,
    [ImageUrl] nvarchar(300) NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Sku_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Sku_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Sku_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Sku] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Sku_TenantId_Code] ON [md].[Sku] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Sku_ProductId] ON [md].[Sku] ([ProductId]);
GO
CREATE INDEX [IX_Sku_BaseUnitId] ON [md].[Sku] ([BaseUnitId]);
GO
CREATE INDEX [IX_Sku_CreatedBy] ON [md].[Sku] ([CreatedBy]);
GO
CREATE INDEX [IX_Sku_ModifiedBy] ON [md].[Sku] ([ModifiedBy]);
GO
CREATE INDEX [IX_Sku_DeletedBy] ON [md].[Sku] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'SKU（规格/单品）', N'SCHEMA', N'md', N'TABLE', N'Sku';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'所属商品', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'ProductId';
EXEC sp_addextendedproperty N'MS_Description', N'SKU编码', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'SKU名称', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'规格值(红/XL)', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'SpecValue';
EXEC sp_addextendedproperty N'MS_Description', N'基本单位', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'BaseUnitId';
EXEC sp_addextendedproperty N'MS_Description', N'零售价', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'RetailPrice';
EXEC sp_addextendedproperty N'MS_Description', N'标准成本', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'StandardCost';
EXEC sp_addextendedproperty N'MS_Description', N'毛重', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'Weight';
EXEC sp_addextendedproperty N'MS_Description', N'体积', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'Volume';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Sku', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[SkuBarcode] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_SkuBarcode_TenantId] DEFAULT (1),
    [SkuId] bigint NOT NULL,
    [Barcode] varchar(50) NOT NULL,
    [BarcodeType] tinyint NOT NULL CONSTRAINT [DF_SkuBarcode_BarcodeType] DEFAULT (1) CONSTRAINT [CK_SkuBarcode_BarcodeType] CHECK (BarcodeType BETWEEN 1 AND 5),
    [UnitId] bigint NULL,
    [IsDefault] bit NOT NULL CONSTRAINT [DF_SkuBarcode_IsDefault] DEFAULT (0),
    CONSTRAINT [PK_SkuBarcode] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_SkuBarcode_TenantId_Barcode] ON [md].[SkuBarcode] ([TenantId], [Barcode]);
GO
CREATE INDEX [IX_SkuBarcode_SkuId] ON [md].[SkuBarcode] ([SkuId]);
GO
CREATE INDEX [IX_SkuBarcode_UnitId] ON [md].[SkuBarcode] ([UnitId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'SKU 条码（多码）', N'SCHEMA', N'md', N'TABLE', N'SkuBarcode';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'SkuBarcode', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'条码', N'SCHEMA', N'md', N'TABLE', N'SkuBarcode', N'COLUMN', N'Barcode';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1主码 2辅码 3箱码 4店内码 5称重码)', N'SCHEMA', N'md', N'TABLE', N'SkuBarcode', N'COLUMN', N'BarcodeType';
EXEC sp_addextendedproperty N'MS_Description', N'对应单位', N'SCHEMA', N'md', N'TABLE', N'SkuBarcode', N'COLUMN', N'UnitId';
GO
CREATE TABLE [md].[SkuUnit] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_SkuUnit_TenantId] DEFAULT (1),
    [SkuId] bigint NOT NULL,
    [UnitId] bigint NOT NULL,
    [ConvertRate] decimal(19,6) NOT NULL,
    [UnitType] tinyint NOT NULL CONSTRAINT [DF_SkuUnit_UnitType] DEFAULT (1) CONSTRAINT [CK_SkuUnit_UnitType] CHECK (UnitType BETWEEN 1 AND 4),
    [IsDefault] bit NOT NULL CONSTRAINT [DF_SkuUnit_IsDefault] DEFAULT (0),
    CONSTRAINT [PK_SkuUnit] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_SkuUnit_SkuId_UnitId] ON [md].[SkuUnit] ([SkuId], [UnitId]);
GO
CREATE INDEX [IX_SkuUnit_UnitId] ON [md].[SkuUnit] ([UnitId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'SKU 多单位与箱规', N'SCHEMA', N'md', N'TABLE', N'SkuUnit';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'SkuUnit', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'对基本单位换算率', N'SCHEMA', N'md', N'TABLE', N'SkuUnit', N'COLUMN', N'ConvertRate';
EXEC sp_addextendedproperty N'MS_Description', N'用途(1基本 2采购 3销售 4仓储)', N'SCHEMA', N'md', N'TABLE', N'SkuUnit', N'COLUMN', N'UnitType';
GO
CREATE TABLE [md].[Attribute] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Attribute_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(50) NOT NULL,
    [InputType] tinyint NOT NULL CONSTRAINT [DF_Attribute_InputType] DEFAULT (1) CONSTRAINT [CK_Attribute_InputType] CHECK (InputType BETWEEN 1 AND 5),
    [IsSpec] bit NOT NULL CONSTRAINT [DF_Attribute_IsSpec] DEFAULT (0),
    [OptionsJson] nvarchar(max) NULL,
    [Sort] int NOT NULL CONSTRAINT [DF_Attribute_Sort] DEFAULT (0),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Attribute_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Attribute_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Attribute] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Attribute_TenantId_Code] ON [md].[Attribute] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Attribute_CreatedBy] ON [md].[Attribute] ([CreatedBy]);
GO
CREATE INDEX [IX_Attribute_ModifiedBy] ON [md].[Attribute] ([ModifiedBy]);
GO
CREATE INDEX [IX_Attribute_DeletedBy] ON [md].[Attribute] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'商品属性定义', N'SCHEMA', N'md', N'TABLE', N'Attribute';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'Attribute', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'属性名', N'SCHEMA', N'md', N'TABLE', N'Attribute', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'录入(1文本 2数字 3单选 4多选 5日期)', N'SCHEMA', N'md', N'TABLE', N'Attribute', N'COLUMN', N'InputType';
EXEC sp_addextendedproperty N'MS_Description', N'是否规格属性(生成SKU)', N'SCHEMA', N'md', N'TABLE', N'Attribute', N'COLUMN', N'IsSpec';
EXEC sp_addextendedproperty N'MS_Description', N'可选项', N'SCHEMA', N'md', N'TABLE', N'Attribute', N'COLUMN', N'OptionsJson';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'Attribute', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'Attribute', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'Attribute', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'Attribute', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Attribute', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'Attribute', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Attribute', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'Attribute', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Attribute', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[AttributeValue] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [SkuId] bigint NOT NULL,
    [AttributeId] bigint NOT NULL,
    [Value] nvarchar(200) NULL,
    CONSTRAINT [PK_AttributeValue] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_AttributeValue_SkuId_AttributeId] ON [md].[AttributeValue] ([SkuId], [AttributeId]);
GO
CREATE INDEX [IX_AttributeValue_AttributeId] ON [md].[AttributeValue] ([AttributeId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'商品属性值', N'SCHEMA', N'md', N'TABLE', N'AttributeValue';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'AttributeValue', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'属性值', N'SCHEMA', N'md', N'TABLE', N'AttributeValue', N'COLUMN', N'Value';
GO
CREATE TABLE [md].[Bundle] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Bundle_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(100) NULL,
    [SkuId] bigint NOT NULL,
    [BundleType] tinyint NOT NULL CONSTRAINT [DF_Bundle_BundleType] DEFAULT (1),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Bundle_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Bundle_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Bundle_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Bundle] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Bundle_TenantId_Code] ON [md].[Bundle] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Bundle_SkuId] ON [md].[Bundle] ([SkuId]);
GO
CREATE INDEX [IX_Bundle_CreatedBy] ON [md].[Bundle] ([CreatedBy]);
GO
CREATE INDEX [IX_Bundle_ModifiedBy] ON [md].[Bundle] ([ModifiedBy]);
GO
CREATE INDEX [IX_Bundle_DeletedBy] ON [md].[Bundle] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'组合商品', N'SCHEMA', N'md', N'TABLE', N'Bundle';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'Bundle', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'组合名称', N'SCHEMA', N'md', N'TABLE', N'Bundle', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'组合后SKU', N'SCHEMA', N'md', N'TABLE', N'Bundle', N'COLUMN', N'SkuId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1固定 2可选)', N'SCHEMA', N'md', N'TABLE', N'Bundle', N'COLUMN', N'BundleType';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'Bundle', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'Bundle', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'Bundle', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'Bundle', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Bundle', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'Bundle', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Bundle', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'Bundle', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Bundle', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[BundleItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [BundleId] bigint NOT NULL,
    [ComponentSkuId] bigint NOT NULL,
    [Qty] decimal(19,6) NOT NULL CONSTRAINT [DF_BundleItem_Qty] DEFAULT (1),
    CONSTRAINT [PK_BundleItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_BundleItem_BundleId] ON [md].[BundleItem] ([BundleId]);
GO
CREATE INDEX [IX_BundleItem_ComponentSkuId] ON [md].[BundleItem] ([ComponentSkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'组合明细', N'SCHEMA', N'md', N'TABLE', N'BundleItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'BundleItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'子件SKU', N'SCHEMA', N'md', N'TABLE', N'BundleItem', N'COLUMN', N'ComponentSkuId';
EXEC sp_addextendedproperty N'MS_Description', N'用量', N'SCHEMA', N'md', N'TABLE', N'BundleItem', N'COLUMN', N'Qty';
GO
CREATE TABLE [md].[StoreProduct] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_StoreProduct_TenantId] DEFAULT (1),
    [StoreId] bigint NOT NULL,
    [SkuId] bigint NOT NULL,
    [IsOnSale] bit NOT NULL CONSTRAINT [DF_StoreProduct_IsOnSale] DEFAULT (1),
    [StorePrice] decimal(19,6) NULL,
    [MinStock] decimal(19,6) NULL,
    [MaxStock] decimal(19,6) NULL,
    [Sort] int NOT NULL CONSTRAINT [DF_StoreProduct_Sort] DEFAULT (0),
    CONSTRAINT [PK_StoreProduct] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_StoreProduct_StoreId_SkuId] ON [md].[StoreProduct] ([StoreId], [SkuId]);
GO
CREATE INDEX [IX_StoreProduct_SkuId] ON [md].[StoreProduct] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'门店商品（经营范围与门店价）', N'SCHEMA', N'md', N'TABLE', N'StoreProduct';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'StoreProduct', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'门店', N'SCHEMA', N'md', N'TABLE', N'StoreProduct', N'COLUMN', N'StoreId';
EXEC sp_addextendedproperty N'MS_Description', N'上架', N'SCHEMA', N'md', N'TABLE', N'StoreProduct', N'COLUMN', N'IsOnSale';
EXEC sp_addextendedproperty N'MS_Description', N'门店价(空=用价格表)', N'SCHEMA', N'md', N'TABLE', N'StoreProduct', N'COLUMN', N'StorePrice';
EXEC sp_addextendedproperty N'MS_Description', N'最小库存', N'SCHEMA', N'md', N'TABLE', N'StoreProduct', N'COLUMN', N'MinStock';
EXEC sp_addextendedproperty N'MS_Description', N'最大库存', N'SCHEMA', N'md', N'TABLE', N'StoreProduct', N'COLUMN', N'MaxStock';
GO
CREATE TABLE [md].[PriceType] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_PriceType_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(50) NOT NULL,
    [Priority] int NOT NULL CONSTRAINT [DF_PriceType_Priority] DEFAULT (100),
    [IsDefault] bit NOT NULL CONSTRAINT [DF_PriceType_IsDefault] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_PriceType_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_PriceType_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_PriceType_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_PriceType] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PriceType_TenantId_Code] ON [md].[PriceType] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_PriceType_CreatedBy] ON [md].[PriceType] ([CreatedBy]);
GO
CREATE INDEX [IX_PriceType_ModifiedBy] ON [md].[PriceType] ([ModifiedBy]);
GO
CREATE INDEX [IX_PriceType_DeletedBy] ON [md].[PriceType] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'价格类型', N'SCHEMA', N'md', N'TABLE', N'PriceType';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'PriceType', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'价格类型名称', N'SCHEMA', N'md', N'TABLE', N'PriceType', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'取价优先级(小优先)', N'SCHEMA', N'md', N'TABLE', N'PriceType', N'COLUMN', N'Priority';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'PriceType', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'PriceType', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'PriceType', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'PriceType', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'PriceType', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'PriceType', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'PriceType', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'PriceType', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'PriceType', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[PriceList] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_PriceList_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(100) NULL,
    [PriceTypeId] bigint NOT NULL,
    [ScopeType] tinyint NOT NULL CONSTRAINT [DF_PriceList_ScopeType] DEFAULT (1) CONSTRAINT [CK_PriceList_ScopeType] CHECK (ScopeType BETWEEN 1 AND 4),
    [ScopeId] bigint NULL,
    [CurrencyCode] varchar(3) NOT NULL CONSTRAINT [DF_PriceList_CurrencyCode] DEFAULT ('CNY'),
    [EffectiveFrom] date NULL,
    [EffectiveTo] date NULL,
    [Priority] int NOT NULL CONSTRAINT [DF_PriceList_Priority] DEFAULT (100),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_PriceList_IsEnabled] DEFAULT (1),
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_PriceList_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_PriceList_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_PriceList] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PriceList_TenantId_Code] ON [md].[PriceList] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_PriceList_PriceTypeId] ON [md].[PriceList] ([PriceTypeId]);
GO
CREATE INDEX [IX_PriceList_OrgId] ON [md].[PriceList] ([OrgId]);
GO
CREATE INDEX [IX_PriceList_CreatedBy] ON [md].[PriceList] ([CreatedBy]);
GO
CREATE INDEX [IX_PriceList_ModifiedBy] ON [md].[PriceList] ([ModifiedBy]);
GO
CREATE INDEX [IX_PriceList_DeletedBy] ON [md].[PriceList] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'价格表', N'SCHEMA', N'md', N'TABLE', N'PriceList';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'价格表名称', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'适用范围(1全公司 2区域 3渠道 4门店)', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'ScopeType';
EXEC sp_addextendedproperty N'MS_Description', N'范围Id', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'ScopeId';
EXEC sp_addextendedproperty N'MS_Description', N'生效起', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'EffectiveFrom';
EXEC sp_addextendedproperty N'MS_Description', N'生效止', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'EffectiveTo';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'PriceList', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[PriceListItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [PriceListId] bigint NOT NULL,
    [SkuId] bigint NOT NULL,
    [Price] decimal(19,6) NOT NULL,
    [MinPrice] decimal(19,6) NULL,
    [MinQty] decimal(19,6) NULL,
    [MaxQty] decimal(19,6) NULL,
    [Discount] decimal(9,4) NULL,
    CONSTRAINT [PK_PriceListItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PriceListItem_PriceListId_SkuId_MinQty] ON [md].[PriceListItem] ([PriceListId], [SkuId], [MinQty]);
GO
CREATE INDEX [IX_PriceListItem_SkuId] ON [md].[PriceListItem] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'价格明细', N'SCHEMA', N'md', N'TABLE', N'PriceListItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'PriceListItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'价格', N'SCHEMA', N'md', N'TABLE', N'PriceListItem', N'COLUMN', N'Price';
EXEC sp_addextendedproperty N'MS_Description', N'最低成交价', N'SCHEMA', N'md', N'TABLE', N'PriceListItem', N'COLUMN', N'MinPrice';
EXEC sp_addextendedproperty N'MS_Description', N'起订量', N'SCHEMA', N'md', N'TABLE', N'PriceListItem', N'COLUMN', N'MinQty';
EXEC sp_addextendedproperty N'MS_Description', N'阶梯上限', N'SCHEMA', N'md', N'TABLE', N'PriceListItem', N'COLUMN', N'MaxQty';
EXEC sp_addextendedproperty N'MS_Description', N'折扣%', N'SCHEMA', N'md', N'TABLE', N'PriceListItem', N'COLUMN', N'Discount';
GO
CREATE TABLE [md].[PriceAgreement] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_PriceAgreement_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(100) NULL,
    [PartnerId] bigint NOT NULL,
    [EffectiveFrom] date NOT NULL,
    [EffectiveTo] date NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_PriceAgreement_Status] DEFAULT (1),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_PriceAgreement_IsEnabled] DEFAULT (1),
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_PriceAgreement_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_PriceAgreement_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_PriceAgreement] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PriceAgreement_TenantId_Code] ON [md].[PriceAgreement] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_PriceAgreement_PartnerId_Status] ON [md].[PriceAgreement] ([PartnerId], [Status]);
GO
CREATE INDEX [IX_PriceAgreement_OrgId] ON [md].[PriceAgreement] ([OrgId]);
GO
CREATE INDEX [IX_PriceAgreement_CreatedBy] ON [md].[PriceAgreement] ([CreatedBy]);
GO
CREATE INDEX [IX_PriceAgreement_ModifiedBy] ON [md].[PriceAgreement] ([ModifiedBy]);
GO
CREATE INDEX [IX_PriceAgreement_DeletedBy] ON [md].[PriceAgreement] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'协议价/合同价', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'协议名称', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'客户', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'PartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'生效起', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'EffectiveFrom';
EXEC sp_addextendedproperty N'MS_Description', N'生效止', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'EffectiveTo';
EXEC sp_addextendedproperty N'MS_Description', N'0草稿 1生效 2失效', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'PriceAgreement', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[PriceAgreementItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [AgreementId] bigint NOT NULL,
    [SkuId] bigint NOT NULL,
    [Price] decimal(19,6) NOT NULL,
    [MinQty] decimal(19,6) NOT NULL CONSTRAINT [DF_PriceAgreementItem_MinQty] DEFAULT (1),
    [MinPrice] decimal(19,6) NULL,
    CONSTRAINT [PK_PriceAgreementItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PriceAgreementItem_AgreementId_SkuId_MinQty] ON [md].[PriceAgreementItem] ([AgreementId], [SkuId], [MinQty]);
GO
CREATE INDEX [IX_PriceAgreementItem_SkuId] ON [md].[PriceAgreementItem] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'协议价明细', N'SCHEMA', N'md', N'TABLE', N'PriceAgreementItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'PriceAgreementItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'最低成交价', N'SCHEMA', N'md', N'TABLE', N'PriceAgreementItem', N'COLUMN', N'MinPrice';
GO
CREATE TABLE [md].[PriceChange] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_PriceChange_TenantId] DEFAULT (1),
    [DocNo] varchar(40) NOT NULL,
    [BizDate] date NOT NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_PriceChange_Status] DEFAULT (0),
    [PriceTypeId] bigint NULL,
    [ScopeType] tinyint NOT NULL CONSTRAINT [DF_PriceChange_ScopeType] DEFAULT (1),
    [ScopeId] bigint NULL,
    [EffectiveAt] datetime2(3) NULL,
    [Reason] nvarchar(300) NULL,
    [ApprovedBy] bigint NULL,
    [ApprovedAt] datetime2(3) NULL,
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_PriceChange_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_PriceChange_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_PriceChange] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PriceChange_TenantId_DocNo] ON [md].[PriceChange] ([TenantId], [DocNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_PriceChange_Status_BizDate] ON [md].[PriceChange] ([Status], [BizDate]);
GO
CREATE INDEX [IX_PriceChange_PriceTypeId] ON [md].[PriceChange] ([PriceTypeId]);
GO
CREATE INDEX [IX_PriceChange_OrgId] ON [md].[PriceChange] ([OrgId]);
GO
CREATE INDEX [IX_PriceChange_CreatedBy] ON [md].[PriceChange] ([CreatedBy]);
GO
CREATE INDEX [IX_PriceChange_ModifiedBy] ON [md].[PriceChange] ([ModifiedBy]);
GO
CREATE INDEX [IX_PriceChange_DeletedBy] ON [md].[PriceChange] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'调价单', N'SCHEMA', N'md', N'TABLE', N'PriceChange';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'调价单号', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'DocNo';
EXEC sp_addextendedproperty N'MS_Description', N'业务日期', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'BizDate';
EXEC sp_addextendedproperty N'MS_Description', N'0草稿 1待审 2已审 3待执行 4已执行 9作废', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'价格类型', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'PriceTypeId';
EXEC sp_addextendedproperty N'MS_Description', N'范围(1全公司 2门店 3区域)', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'ScopeType';
EXEC sp_addextendedproperty N'MS_Description', N'范围Id', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'ScopeId';
EXEC sp_addextendedproperty N'MS_Description', N'定时生效时间', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'EffectiveAt';
EXEC sp_addextendedproperty N'MS_Description', N'调价原因', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'Reason';
EXEC sp_addextendedproperty N'MS_Description', N'审批人', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'ApprovedBy';
EXEC sp_addextendedproperty N'MS_Description', N'审批时间', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'ApprovedAt';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'PriceChange', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[PriceChangeItem] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [ChangeId] bigint NOT NULL,
    [SkuId] bigint NOT NULL,
    [OldPrice] decimal(19,6) NULL,
    [NewPrice] decimal(19,6) NOT NULL,
    [MinPrice] decimal(19,6) NULL,
    [MarginRate] decimal(9,4) NULL,
    CONSTRAINT [PK_PriceChangeItem] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_PriceChangeItem_ChangeId_SkuId] ON [md].[PriceChangeItem] ([ChangeId], [SkuId]);
GO
CREATE INDEX [IX_PriceChangeItem_SkuId] ON [md].[PriceChangeItem] ([SkuId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'调价明细', N'SCHEMA', N'md', N'TABLE', N'PriceChangeItem';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'PriceChangeItem', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'原价', N'SCHEMA', N'md', N'TABLE', N'PriceChangeItem', N'COLUMN', N'OldPrice';
EXEC sp_addextendedproperty N'MS_Description', N'新价', N'SCHEMA', N'md', N'TABLE', N'PriceChangeItem', N'COLUMN', N'NewPrice';
EXEC sp_addextendedproperty N'MS_Description', N'最低售价', N'SCHEMA', N'md', N'TABLE', N'PriceChangeItem', N'COLUMN', N'MinPrice';
EXEC sp_addextendedproperty N'MS_Description', N'毛利率变化%', N'SCHEMA', N'md', N'TABLE', N'PriceChangeItem', N'COLUMN', N'MarginRate';
GO
CREATE TABLE [md].[PriceHistory] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_PriceHistory_TenantId] DEFAULT (1),
    [SkuId] bigint NOT NULL,
    [PriceTypeId] bigint NULL,
    [Price] decimal(19,6) NOT NULL,
    [EffectiveFrom] datetime2(3) NOT NULL,
    [SourceType] varchar(30) NULL,
    [SourceId] bigint NULL,
    [ChangedBy] bigint NULL,
    CONSTRAINT [PK_PriceHistory] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_PriceHistory_SkuId_EffectiveFrom] ON [md].[PriceHistory] ([SkuId], [EffectiveFrom]);
GO
CREATE INDEX [IX_PriceHistory_PriceTypeId] ON [md].[PriceHistory] ([PriceTypeId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'价格变更历史', N'SCHEMA', N'md', N'TABLE', N'PriceHistory';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'PriceHistory', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'价格类型', N'SCHEMA', N'md', N'TABLE', N'PriceHistory', N'COLUMN', N'PriceTypeId';
EXEC sp_addextendedproperty N'MS_Description', N'价格', N'SCHEMA', N'md', N'TABLE', N'PriceHistory', N'COLUMN', N'Price';
EXEC sp_addextendedproperty N'MS_Description', N'生效时间', N'SCHEMA', N'md', N'TABLE', N'PriceHistory', N'COLUMN', N'EffectiveFrom';
EXEC sp_addextendedproperty N'MS_Description', N'来源(调价单/协议价/促销)', N'SCHEMA', N'md', N'TABLE', N'PriceHistory', N'COLUMN', N'SourceType';
EXEC sp_addextendedproperty N'MS_Description', N'来源Id', N'SCHEMA', N'md', N'TABLE', N'PriceHistory', N'COLUMN', N'SourceId';
EXEC sp_addextendedproperty N'MS_Description', N'操作人', N'SCHEMA', N'md', N'TABLE', N'PriceHistory', N'COLUMN', N'ChangedBy';
GO
CREATE TABLE [md].[Partner] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Partner_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [ShortName] nvarchar(50) NULL,
    [Mnemonic] varchar(50) NULL,
    [PartnerType] int NOT NULL CONSTRAINT [DF_Partner_PartnerType] DEFAULT (1) CONSTRAINT [CK_Partner_PartnerType] CHECK (PartnerType > 0),
    [CustomerLevel] tinyint NULL,
    [PriceTypeId] bigint NULL,
    [SalesmanId] bigint NULL,
    [RegionId] bigint NULL,
    [ParentPartnerId] bigint NULL,
    [ChannelType] tinyint NULL,
    [CreditLimit] decimal(19,4) NOT NULL CONSTRAINT [DF_Partner_CreditLimit] DEFAULT (0),
    [CreditDays] int NOT NULL CONSTRAINT [DF_Partner_CreditDays] DEFAULT (0),
    [CreditControl] tinyint NOT NULL CONSTRAINT [DF_Partner_CreditControl] DEFAULT (1) CONSTRAINT [CK_Partner_CreditControl] CHECK (CreditControl BETWEEN 1 AND 3),
    [SettleType] tinyint NOT NULL CONSTRAINT [DF_Partner_SettleType] DEFAULT (1) CONSTRAINT [CK_Partner_SettleType] CHECK (SettleType BETWEEN 1 AND 4),
    [TaxNo] varchar(30) NULL,
    [BankName] nvarchar(100) NULL,
    [BankAccount] varchar(50) NULL,
    [DeliveryMode] tinyint NOT NULL CONSTRAINT [DF_Partner_DeliveryMode] DEFAULT (1),
    [RouteId] bigint NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_Partner_Status] DEFAULT (1),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Partner_IsEnabled] DEFAULT (1),
    [OrgId] int NULL,
    [Remark] nvarchar(500) NULL,
    [ExtJson] nvarchar(max) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Partner_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Partner_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Partner] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Partner_TenantId_Code] ON [md].[Partner] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Partner_TenantId_Name] ON [md].[Partner] ([TenantId], [Name]);
GO
CREATE INDEX [IX_Partner_TenantId_PartnerType] ON [md].[Partner] ([TenantId], [PartnerType]);
GO
CREATE INDEX [IX_Partner_Mnemonic] ON [md].[Partner] ([Mnemonic]);
GO
CREATE INDEX [IX_Partner_SalesmanId] ON [md].[Partner] ([SalesmanId]);
GO
CREATE INDEX [IX_Partner_PriceTypeId] ON [md].[Partner] ([PriceTypeId]);
GO
CREATE INDEX [IX_Partner_RegionId] ON [md].[Partner] ([RegionId]);
GO
CREATE INDEX [IX_Partner_ParentPartnerId] ON [md].[Partner] ([ParentPartnerId]);
GO
CREATE INDEX [IX_Partner_RouteId] ON [md].[Partner] ([RouteId]);
GO
CREATE INDEX [IX_Partner_OrgId] ON [md].[Partner] ([OrgId]);
GO
CREATE INDEX [IX_Partner_CreatedBy] ON [md].[Partner] ([CreatedBy]);
GO
CREATE INDEX [IX_Partner_ModifiedBy] ON [md].[Partner] ([ModifiedBy]);
GO
CREATE INDEX [IX_Partner_DeletedBy] ON [md].[Partner] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'往来单位（客户/供应商/经销商）', N'SCHEMA', N'md', N'TABLE', N'Partner';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'单位编码', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'单位名称', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'简称', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'ShortName';
EXEC sp_addextendedproperty N'MS_Description', N'助记码', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'Mnemonic';
EXEC sp_addextendedproperty N'MS_Description', N'类型位掩码(1客户 2供应商 4经销商 8加盟商 16终端)', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'PartnerType';
EXEC sp_addextendedproperty N'MS_Description', N'客户等级(1KA 2A 3B 4C)', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'CustomerLevel';
EXEC sp_addextendedproperty N'MS_Description', N'默认价格等级', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'PriceTypeId';
EXEC sp_addextendedproperty N'MS_Description', N'归属业务员', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'SalesmanId';
EXEC sp_addextendedproperty N'MS_Description', N'所属区域', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'RegionId';
EXEC sp_addextendedproperty N'MS_Description', N'上级经销商', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'ParentPartnerId';
EXEC sp_addextendedproperty N'MS_Description', N'渠道(1直营 2经销 3二批 4终端 5线上)', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'ChannelType';
EXEC sp_addextendedproperty N'MS_Description', N'信用额度', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'CreditLimit';
EXEC sp_addextendedproperty N'MS_Description', N'账期天数', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'CreditDays';
EXEC sp_addextendedproperty N'MS_Description', N'超限策略(1拦截 2审批 3放行)', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'CreditControl';
EXEC sp_addextendedproperty N'MS_Description', N'结算方式(1现结 2账期 3预存 4货到付款)', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'SettleType';
EXEC sp_addextendedproperty N'MS_Description', N'税号', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'TaxNo';
EXEC sp_addextendedproperty N'MS_Description', N'收货方式(1送货 2自提 3快递)', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'DeliveryMode';
EXEC sp_addextendedproperty N'MS_Description', N'配送线路', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'RouteId';
EXEC sp_addextendedproperty N'MS_Description', N'状态(1合作 2暂停 3淘汰)', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'Status';
EXEC sp_addextendedproperty N'MS_Description', N'组织/门店/仓库归属(数据权限)', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'扩展字段(自定义字段值)', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'ExtJson';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Partner', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[PartnerContact] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [PartnerId] bigint NOT NULL,
    [Name] nvarchar(50) NOT NULL,
    [Position] nvarchar(50) NULL,
    [Phone] varchar(30) NULL,
    [Mobile] varchar(30) NULL,
    [Email] varchar(100) NULL,
    [IsDefault] bit NOT NULL CONSTRAINT [DF_PartnerContact_IsDefault] DEFAULT (0),
    CONSTRAINT [PK_PartnerContact] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_PartnerContact_PartnerId] ON [md].[PartnerContact] ([PartnerId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'往来单位联系人', N'SCHEMA', N'md', N'TABLE', N'PartnerContact';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'PartnerContact', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'职务', N'SCHEMA', N'md', N'TABLE', N'PartnerContact', N'COLUMN', N'Position';
GO
CREATE TABLE [md].[PartnerAddress] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [PartnerId] bigint NOT NULL,
    [AddressType] tinyint NOT NULL CONSTRAINT [DF_PartnerAddress_AddressType] DEFAULT (1),
    [Receiver] nvarchar(50) NULL,
    [Phone] varchar(30) NULL,
    [Province] nvarchar(50) NULL,
    [City] nvarchar(50) NULL,
    [District] nvarchar(50) NULL,
    [Detail] nvarchar(300) NULL,
    [RegionId] bigint NULL,
    [IsDefault] bit NOT NULL CONSTRAINT [DF_PartnerAddress_IsDefault] DEFAULT (0),
    CONSTRAINT [PK_PartnerAddress] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_PartnerAddress_PartnerId_AddressType] ON [md].[PartnerAddress] ([PartnerId], [AddressType]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'往来单位地址', N'SCHEMA', N'md', N'TABLE', N'PartnerAddress';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'PartnerAddress', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1收货 2开票 3注册)', N'SCHEMA', N'md', N'TABLE', N'PartnerAddress', N'COLUMN', N'AddressType';
EXEC sp_addextendedproperty N'MS_Description', N'收货人', N'SCHEMA', N'md', N'TABLE', N'PartnerAddress', N'COLUMN', N'Receiver';
EXEC sp_addextendedproperty N'MS_Description', N'详细地址', N'SCHEMA', N'md', N'TABLE', N'PartnerAddress', N'COLUMN', N'Detail';
EXEC sp_addextendedproperty N'MS_Description', N'配送区域', N'SCHEMA', N'md', N'TABLE', N'PartnerAddress', N'COLUMN', N'RegionId';
GO
CREATE TABLE [md].[PartnerQualification] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [PartnerId] bigint NOT NULL,
    [QuaType] tinyint NOT NULL CONSTRAINT [DF_PartnerQualification_QuaType] DEFAULT (1),
    [QuaNo] varchar(100) NULL,
    [IssueDate] date NULL,
    [ExpireDate] date NULL,
    [AttachmentId] bigint NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_PartnerQualification_Status] DEFAULT (1),
    CONSTRAINT [PK_PartnerQualification] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_PartnerQualification_PartnerId] ON [md].[PartnerQualification] ([PartnerId]);
GO
CREATE INDEX [IX_PartnerQualification_ExpireDate] ON [md].[PartnerQualification] ([ExpireDate]);
GO
CREATE INDEX [IX_PartnerQualification_AttachmentId] ON [md].[PartnerQualification] ([AttachmentId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'资质证照', N'SCHEMA', N'md', N'TABLE', N'PartnerQualification';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'PartnerQualification', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1营业执照 2食品经营许可 3生产许可 4检测报告 5授权书 6其他)', N'SCHEMA', N'md', N'TABLE', N'PartnerQualification', N'COLUMN', N'QuaType';
EXEC sp_addextendedproperty N'MS_Description', N'证照号', N'SCHEMA', N'md', N'TABLE', N'PartnerQualification', N'COLUMN', N'QuaNo';
EXEC sp_addextendedproperty N'MS_Description', N'发证日', N'SCHEMA', N'md', N'TABLE', N'PartnerQualification', N'COLUMN', N'IssueDate';
EXEC sp_addextendedproperty N'MS_Description', N'到期日', N'SCHEMA', N'md', N'TABLE', N'PartnerQualification', N'COLUMN', N'ExpireDate';
EXEC sp_addextendedproperty N'MS_Description', N'附件', N'SCHEMA', N'md', N'TABLE', N'PartnerQualification', N'COLUMN', N'AttachmentId';
EXEC sp_addextendedproperty N'MS_Description', N'1有效 2即将到期 3已过期', N'SCHEMA', N'md', N'TABLE', N'PartnerQualification', N'COLUMN', N'Status';
GO
CREATE TABLE [md].[Warehouse] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Warehouse_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    [WarehouseType] tinyint NOT NULL CONSTRAINT [DF_Warehouse_WarehouseType] DEFAULT (1) CONSTRAINT [CK_Warehouse_WarehouseType] CHECK (WarehouseType BETWEEN 1 AND 6),
    [OrgId] int NULL,
    [ManagerId] bigint NULL,
    [Address] nvarchar(200) NULL,
    [Area] decimal(19,4) NULL,
    [IsAllowNegative] bit NOT NULL CONSTRAINT [DF_Warehouse_IsAllowNegative] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Warehouse_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Warehouse_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Warehouse_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Warehouse] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Warehouse_TenantId_Code] ON [md].[Warehouse] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Warehouse_OrgId] ON [md].[Warehouse] ([OrgId]);
GO
CREATE INDEX [IX_Warehouse_ManagerId] ON [md].[Warehouse] ([ManagerId]);
GO
CREATE INDEX [IX_Warehouse_CreatedBy] ON [md].[Warehouse] ([CreatedBy]);
GO
CREATE INDEX [IX_Warehouse_ModifiedBy] ON [md].[Warehouse] ([ModifiedBy]);
GO
CREATE INDEX [IX_Warehouse_DeletedBy] ON [md].[Warehouse] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'仓库', N'SCHEMA', N'md', N'TABLE', N'Warehouse';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'Warehouse', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'仓库名称', N'SCHEMA', N'md', N'TABLE', N'Warehouse', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1普通 2冷藏 3危化 4虚拟 5门店仓 6寄售)', N'SCHEMA', N'md', N'TABLE', N'Warehouse', N'COLUMN', N'WarehouseType';
EXEC sp_addextendedproperty N'MS_Description', N'所属组织', N'SCHEMA', N'md', N'TABLE', N'Warehouse', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'负责人', N'SCHEMA', N'md', N'TABLE', N'Warehouse', N'COLUMN', N'ManagerId';
EXEC sp_addextendedproperty N'MS_Description', N'面积m2', N'SCHEMA', N'md', N'TABLE', N'Warehouse', N'COLUMN', N'Area';
EXEC sp_addextendedproperty N'MS_Description', N'允许负库存', N'SCHEMA', N'md', N'TABLE', N'Warehouse', N'COLUMN', N'IsAllowNegative';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'Warehouse', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'Warehouse', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'Warehouse', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'Warehouse', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Warehouse', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'Warehouse', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Warehouse', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'Warehouse', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Warehouse', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[WarehouseZone] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [WarehouseId] bigint NOT NULL,
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(50) NOT NULL,
    [ZoneType] tinyint NOT NULL CONSTRAINT [DF_WarehouseZone_ZoneType] DEFAULT (2) CONSTRAINT [CK_WarehouseZone_ZoneType] CHECK (ZoneType BETWEEN 1 AND 6),
    [Sort] int NOT NULL CONSTRAINT [DF_WarehouseZone_Sort] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_WarehouseZone_IsEnabled] DEFAULT (1),
    CONSTRAINT [PK_WarehouseZone] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_WarehouseZone_WarehouseId_Code] ON [md].[WarehouseZone] ([WarehouseId], [Code]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'库区', N'SCHEMA', N'md', N'TABLE', N'WarehouseZone';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'WarehouseZone', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'库区名称', N'SCHEMA', N'md', N'TABLE', N'WarehouseZone', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1收货 2存储 3拣货 4发货 5退货 6不良品)', N'SCHEMA', N'md', N'TABLE', N'WarehouseZone', N'COLUMN', N'ZoneType';
GO
CREATE TABLE [md].[WarehouseLocation] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [WarehouseId] bigint NOT NULL,
    [ZoneId] bigint NOT NULL,
    [Code] varchar(40) NOT NULL,
    [Name] nvarchar(50) NULL,
    [Shelf] varchar(20) NULL,
    [Layer] int NULL,
    [Position] int NULL,
    [MaxQty] decimal(19,6) NULL,
    [MaxWeight] decimal(19,4) NULL,
    [MaxVolume] decimal(19,4) NULL,
    [IsMixSku] bit NOT NULL CONSTRAINT [DF_WarehouseLocation_IsMixSku] DEFAULT (0),
    [IsMixBatch] bit NOT NULL CONSTRAINT [DF_WarehouseLocation_IsMixBatch] DEFAULT (1),
    [Status] tinyint NOT NULL CONSTRAINT [DF_WarehouseLocation_Status] DEFAULT (1),
    CONSTRAINT [PK_WarehouseLocation] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_WarehouseLocation_WarehouseId_Code] ON [md].[WarehouseLocation] ([WarehouseId], [Code]);
GO
CREATE INDEX [IX_WarehouseLocation_ZoneId] ON [md].[WarehouseLocation] ([ZoneId]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'货位', N'SCHEMA', N'md', N'TABLE', N'WarehouseLocation';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'WarehouseLocation', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'货位编码(区-架-层-位)', N'SCHEMA', N'md', N'TABLE', N'WarehouseLocation', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'货位名称', N'SCHEMA', N'md', N'TABLE', N'WarehouseLocation', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'货架', N'SCHEMA', N'md', N'TABLE', N'WarehouseLocation', N'COLUMN', N'Shelf';
EXEC sp_addextendedproperty N'MS_Description', N'层', N'SCHEMA', N'md', N'TABLE', N'WarehouseLocation', N'COLUMN', N'Layer';
EXEC sp_addextendedproperty N'MS_Description', N'位', N'SCHEMA', N'md', N'TABLE', N'WarehouseLocation', N'COLUMN', N'Position';
EXEC sp_addextendedproperty N'MS_Description', N'容量(件)', N'SCHEMA', N'md', N'TABLE', N'WarehouseLocation', N'COLUMN', N'MaxQty';
EXEC sp_addextendedproperty N'MS_Description', N'承重kg', N'SCHEMA', N'md', N'TABLE', N'WarehouseLocation', N'COLUMN', N'MaxWeight';
EXEC sp_addextendedproperty N'MS_Description', N'容积m3', N'SCHEMA', N'md', N'TABLE', N'WarehouseLocation', N'COLUMN', N'MaxVolume';
EXEC sp_addextendedproperty N'MS_Description', N'允许混放SKU', N'SCHEMA', N'md', N'TABLE', N'WarehouseLocation', N'COLUMN', N'IsMixSku';
EXEC sp_addextendedproperty N'MS_Description', N'允许混放批次', N'SCHEMA', N'md', N'TABLE', N'WarehouseLocation', N'COLUMN', N'IsMixBatch';
EXEC sp_addextendedproperty N'MS_Description', N'1可用 2锁定 3停用', N'SCHEMA', N'md', N'TABLE', N'WarehouseLocation', N'COLUMN', N'Status';
GO
CREATE TABLE [md].[Store] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Store_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    [OrgId] int NULL,
    [StoreType] tinyint NOT NULL CONSTRAINT [DF_Store_StoreType] DEFAULT (1) CONSTRAINT [CK_Store_StoreType] CHECK (StoreType BETWEEN 1 AND 5),
    [RegionId] bigint NULL,
    [WarehouseId] bigint NULL,
    [RouteId] bigint NULL,
    [ManagerId] bigint NULL,
    [Address] nvarchar(200) NULL,
    [Phone] varchar(30) NULL,
    [OpenTime] time NULL,
    [CloseTime] time NULL,
    [Area] decimal(19,4) NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Store_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Store_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Store_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Store] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Store_TenantId_Code] ON [md].[Store] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Store_OrgId] ON [md].[Store] ([OrgId]);
GO
CREATE INDEX [IX_Store_RegionId] ON [md].[Store] ([RegionId]);
GO
CREATE INDEX [IX_Store_WarehouseId] ON [md].[Store] ([WarehouseId]);
GO
CREATE INDEX [IX_Store_RouteId] ON [md].[Store] ([RouteId]);
GO
CREATE INDEX [IX_Store_ManagerId] ON [md].[Store] ([ManagerId]);
GO
CREATE INDEX [IX_Store_CreatedBy] ON [md].[Store] ([CreatedBy]);
GO
CREATE INDEX [IX_Store_ModifiedBy] ON [md].[Store] ([ModifiedBy]);
GO
CREATE INDEX [IX_Store_DeletedBy] ON [md].[Store] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'门店', N'SCHEMA', N'md', N'TABLE', N'Store';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'门店名称', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'Name';
EXEC sp_addextendedproperty N'MS_Description', N'所属组织', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'OrgId';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1直营 2加盟 3联营 4专卖 5超市)', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'StoreType';
EXEC sp_addextendedproperty N'MS_Description', N'所属区域', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'RegionId';
EXEC sp_addextendedproperty N'MS_Description', N'要货仓', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'配送线路', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'RouteId';
EXEC sp_addextendedproperty N'MS_Description', N'店长', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'ManagerId';
EXEC sp_addextendedproperty N'MS_Description', N'营业开始', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'OpenTime';
EXEC sp_addextendedproperty N'MS_Description', N'营业结束', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'CloseTime';
EXEC sp_addextendedproperty N'MS_Description', N'营业面积m2', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'Area';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Store', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[Region] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Region_TenantId] DEFAULT (1),
    [ParentId] bigint NULL,
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(50) NOT NULL,
    [Level] tinyint NOT NULL CONSTRAINT [DF_Region_Level] DEFAULT (1),
    [Path] varchar(500) NULL,
    [Sort] int NOT NULL CONSTRAINT [DF_Region_Sort] DEFAULT (0),
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Region_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Region_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Region_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Region] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Region_TenantId_Code] ON [md].[Region] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Region_ParentId] ON [md].[Region] ([ParentId]);
GO
CREATE INDEX [IX_Region_CreatedBy] ON [md].[Region] ([CreatedBy]);
GO
CREATE INDEX [IX_Region_ModifiedBy] ON [md].[Region] ([ModifiedBy]);
GO
CREATE INDEX [IX_Region_DeletedBy] ON [md].[Region] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'区域/片区', N'SCHEMA', N'md', N'TABLE', N'Region';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'Region', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'上级区域', N'SCHEMA', N'md', N'TABLE', N'Region', N'COLUMN', N'ParentId';
EXEC sp_addextendedproperty N'MS_Description', N'层级(1大区 2省 3市 4片区)', N'SCHEMA', N'md', N'TABLE', N'Region', N'COLUMN', N'Level';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'Region', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'Region', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'Region', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'Region', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Region', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'Region', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Region', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'Region', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Region', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[Vehicle] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Vehicle_TenantId] DEFAULT (1),
    [PlateNo] varchar(20) NOT NULL,
    [VehicleType] tinyint NOT NULL CONSTRAINT [DF_Vehicle_VehicleType] DEFAULT (1),
    [LoadWeight] decimal(19,4) NULL,
    [LoadVolume] decimal(19,4) NULL,
    [CarrierId] bigint NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Vehicle_IsEnabled] DEFAULT (1),
    [Code] varchar(32) NULL,
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Vehicle_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Vehicle_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Vehicle] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Vehicle_TenantId_PlateNo] ON [md].[Vehicle] ([TenantId], [PlateNo]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Vehicle_CarrierId] ON [md].[Vehicle] ([CarrierId]);
GO
CREATE INDEX [IX_Vehicle_CreatedBy] ON [md].[Vehicle] ([CreatedBy]);
GO
CREATE INDEX [IX_Vehicle_ModifiedBy] ON [md].[Vehicle] ([ModifiedBy]);
GO
CREATE INDEX [IX_Vehicle_DeletedBy] ON [md].[Vehicle] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'车辆', N'SCHEMA', N'md', N'TABLE', N'Vehicle';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'Vehicle', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'车牌号', N'SCHEMA', N'md', N'TABLE', N'Vehicle', N'COLUMN', N'PlateNo';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1厢货 2高栏 3冷藏 4三轮 5依维柯)', N'SCHEMA', N'md', N'TABLE', N'Vehicle', N'COLUMN', N'VehicleType';
EXEC sp_addextendedproperty N'MS_Description', N'载重kg', N'SCHEMA', N'md', N'TABLE', N'Vehicle', N'COLUMN', N'LoadWeight';
EXEC sp_addextendedproperty N'MS_Description', N'容积m3', N'SCHEMA', N'md', N'TABLE', N'Vehicle', N'COLUMN', N'LoadVolume';
EXEC sp_addextendedproperty N'MS_Description', N'所属承运商', N'SCHEMA', N'md', N'TABLE', N'Vehicle', N'COLUMN', N'CarrierId';
EXEC sp_addextendedproperty N'MS_Description', N'业务编码', N'SCHEMA', N'md', N'TABLE', N'Vehicle', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'Vehicle', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'Vehicle', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'Vehicle', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'Vehicle', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Vehicle', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'Vehicle', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Vehicle', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'Vehicle', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Vehicle', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[Driver] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Driver_TenantId] DEFAULT (1),
    [Name] nvarchar(50) NOT NULL,
    [Mobile] varchar(30) NULL,
    [LicenseNo] varchar(50) NULL,
    [LicenseExpire] date NULL,
    [CarrierId] bigint NULL,
    [UserId] bigint NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Driver_IsEnabled] DEFAULT (1),
    [Code] varchar(32) NULL,
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Driver_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Driver_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Driver] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE INDEX [IX_Driver_CarrierId] ON [md].[Driver] ([CarrierId]);
GO
CREATE INDEX [IX_Driver_UserId] ON [md].[Driver] ([UserId]);
GO
CREATE INDEX [IX_Driver_CreatedBy] ON [md].[Driver] ([CreatedBy]);
GO
CREATE INDEX [IX_Driver_ModifiedBy] ON [md].[Driver] ([ModifiedBy]);
GO
CREATE INDEX [IX_Driver_DeletedBy] ON [md].[Driver] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'司机', N'SCHEMA', N'md', N'TABLE', N'Driver';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'Driver', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'驾驶证号', N'SCHEMA', N'md', N'TABLE', N'Driver', N'COLUMN', N'LicenseNo';
EXEC sp_addextendedproperty N'MS_Description', N'驾照到期', N'SCHEMA', N'md', N'TABLE', N'Driver', N'COLUMN', N'LicenseExpire';
EXEC sp_addextendedproperty N'MS_Description', N'所属承运商', N'SCHEMA', N'md', N'TABLE', N'Driver', N'COLUMN', N'CarrierId';
EXEC sp_addextendedproperty N'MS_Description', N'司机APP账号', N'SCHEMA', N'md', N'TABLE', N'Driver', N'COLUMN', N'UserId';
EXEC sp_addextendedproperty N'MS_Description', N'业务编码', N'SCHEMA', N'md', N'TABLE', N'Driver', N'COLUMN', N'Code';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'Driver', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'Driver', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'Driver', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'Driver', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Driver', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'Driver', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Driver', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'Driver', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Driver', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[Carrier] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_Carrier_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    [CarrierType] tinyint NOT NULL CONSTRAINT [DF_Carrier_CarrierType] DEFAULT (1),
    [SettleType] tinyint NOT NULL CONSTRAINT [DF_Carrier_SettleType] DEFAULT (2),
    [CreditDays] int NOT NULL CONSTRAINT [DF_Carrier_CreditDays] DEFAULT (30),
    [Contact] nvarchar(50) NULL,
    [Phone] varchar(30) NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_Carrier_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_Carrier_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_Carrier_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Carrier] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_Carrier_TenantId_Code] ON [md].[Carrier] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_Carrier_CreatedBy] ON [md].[Carrier] ([CreatedBy]);
GO
CREATE INDEX [IX_Carrier_ModifiedBy] ON [md].[Carrier] ([ModifiedBy]);
GO
CREATE INDEX [IX_Carrier_DeletedBy] ON [md].[Carrier] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'承运商', N'SCHEMA', N'md', N'TABLE', N'Carrier';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'Carrier', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'类型(1自有 2外协 3快递 4即时配送)', N'SCHEMA', N'md', N'TABLE', N'Carrier', N'COLUMN', N'CarrierType';
EXEC sp_addextendedproperty N'MS_Description', N'结算(1现结 2月结 3预付)', N'SCHEMA', N'md', N'TABLE', N'Carrier', N'COLUMN', N'SettleType';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'Carrier', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'Carrier', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'Carrier', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'Carrier', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Carrier', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'Carrier', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Carrier', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'Carrier', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'Carrier', N'COLUMN', N'DeletedAt';
GO
CREATE TABLE [md].[DeliveryRoute] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [TenantId] int NOT NULL CONSTRAINT [DF_DeliveryRoute_TenantId] DEFAULT (1),
    [Code] varchar(32) NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    [RegionId] bigint NULL,
    [WarehouseId] bigint NULL,
    [CarrierId] bigint NULL,
    [CycleDays] tinyint NOT NULL CONSTRAINT [DF_DeliveryRoute_CycleDays] DEFAULT (1),
    [DeliveryDays] varchar(20) NULL,
    [IsEnabled] bit NOT NULL CONSTRAINT [DF_DeliveryRoute_IsEnabled] DEFAULT (1),
    [Remark] nvarchar(500) NULL,
    [RowVersion] rowversion NOT NULL,
    [IsDeleted] bit NOT NULL CONSTRAINT [DF_DeliveryRoute_IsDeleted] DEFAULT (0),
    [CreatedBy] bigint NULL,
    [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_DeliveryRoute_CreatedAt] DEFAULT (sysutcdatetime()),
    [ModifiedBy] bigint NULL,
    [ModifiedAt] datetime2(3) NULL,
    [DeletedBy] bigint NULL,
    [DeletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_DeliveryRoute] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE UNIQUE INDEX [UQ_DeliveryRoute_TenantId_Code] ON [md].[DeliveryRoute] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
GO
CREATE INDEX [IX_DeliveryRoute_RegionId] ON [md].[DeliveryRoute] ([RegionId]);
GO
CREATE INDEX [IX_DeliveryRoute_WarehouseId] ON [md].[DeliveryRoute] ([WarehouseId]);
GO
CREATE INDEX [IX_DeliveryRoute_CarrierId] ON [md].[DeliveryRoute] ([CarrierId]);
GO
CREATE INDEX [IX_DeliveryRoute_CreatedBy] ON [md].[DeliveryRoute] ([CreatedBy]);
GO
CREATE INDEX [IX_DeliveryRoute_ModifiedBy] ON [md].[DeliveryRoute] ([ModifiedBy]);
GO
CREATE INDEX [IX_DeliveryRoute_DeletedBy] ON [md].[DeliveryRoute] ([DeletedBy]);
GO
EXEC sp_addextendedproperty N'MS_Description', N'配送线路', N'SCHEMA', N'md', N'TABLE', N'DeliveryRoute';
EXEC sp_addextendedproperty N'MS_Description', N'主键', N'SCHEMA', N'md', N'TABLE', N'DeliveryRoute', N'COLUMN', N'Id';
EXEC sp_addextendedproperty N'MS_Description', N'区域', N'SCHEMA', N'md', N'TABLE', N'DeliveryRoute', N'COLUMN', N'RegionId';
EXEC sp_addextendedproperty N'MS_Description', N'发货仓', N'SCHEMA', N'md', N'TABLE', N'DeliveryRoute', N'COLUMN', N'WarehouseId';
EXEC sp_addextendedproperty N'MS_Description', N'承运商', N'SCHEMA', N'md', N'TABLE', N'DeliveryRoute', N'COLUMN', N'CarrierId';
EXEC sp_addextendedproperty N'MS_Description', N'配送周期(天)', N'SCHEMA', N'md', N'TABLE', N'DeliveryRoute', N'COLUMN', N'CycleDays';
EXEC sp_addextendedproperty N'MS_Description', N'配送日(1,3,5)', N'SCHEMA', N'md', N'TABLE', N'DeliveryRoute', N'COLUMN', N'DeliveryDays';
EXEC sp_addextendedproperty N'MS_Description', N'备注', N'SCHEMA', N'md', N'TABLE', N'DeliveryRoute', N'COLUMN', N'Remark';
EXEC sp_addextendedproperty N'MS_Description', N'并发版本', N'SCHEMA', N'md', N'TABLE', N'DeliveryRoute', N'COLUMN', N'RowVersion';
EXEC sp_addextendedproperty N'MS_Description', N'软删除', N'SCHEMA', N'md', N'TABLE', N'DeliveryRoute', N'COLUMN', N'IsDeleted';
EXEC sp_addextendedproperty N'MS_Description', N'创建人', N'SCHEMA', N'md', N'TABLE', N'DeliveryRoute', N'COLUMN', N'CreatedBy';
EXEC sp_addextendedproperty N'MS_Description', N'创建时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'DeliveryRoute', N'COLUMN', N'CreatedAt';
EXEC sp_addextendedproperty N'MS_Description', N'修改人', N'SCHEMA', N'md', N'TABLE', N'DeliveryRoute', N'COLUMN', N'ModifiedBy';
EXEC sp_addextendedproperty N'MS_Description', N'修改时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'DeliveryRoute', N'COLUMN', N'ModifiedAt';
EXEC sp_addextendedproperty N'MS_Description', N'删除人', N'SCHEMA', N'md', N'TABLE', N'DeliveryRoute', N'COLUMN', N'DeletedBy';
EXEC sp_addextendedproperty N'MS_Description', N'删除时间(UTC)', N'SCHEMA', N'md', N'TABLE', N'DeliveryRoute', N'COLUMN', N'DeletedAt';
GO
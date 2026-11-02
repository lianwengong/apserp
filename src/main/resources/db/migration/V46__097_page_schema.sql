/* =====================================================================
   V46 · 远程 PageSchema
   ---------------------------------------------------------------------
   前端页面组合从“代码里的本地定义”升级为“后端可配置、前端回退”：
     · plat.PageSchema 按租户存一份完整 PageSchema JSON；
     · /api/page-schema/{code} 给运行时读取（只读、已启用）；
     · /api/admin/page-schemas 给平台管理页面编排使用；
     · 种子 workbench / master-data 与前端本地定义保持一致，便于灰度与回退。
   幂等：表、索引、RLS、种子都存在则跳过。
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

IF OBJECT_ID('plat.PageSchema', 'U') IS NULL
BEGIN
    CREATE TABLE [plat].[PageSchema] (
        [Id] bigint IDENTITY(1,1) NOT NULL,
        [TenantId] int NOT NULL CONSTRAINT [DF_PageSchema_TenantId] DEFAULT (1),
        [Code] varchar(64) NOT NULL,
        [Title] nvarchar(100) NOT NULL,
        [Kind] varchar(20) NOT NULL,
        [ConfigJson] nvarchar(max) NOT NULL,
        [Version] int NOT NULL CONSTRAINT [DF_PageSchema_Version] DEFAULT (1),
        [IsEnabled] bit NOT NULL CONSTRAINT [DF_PageSchema_IsEnabled] DEFAULT (1),
        [Remark] nvarchar(500) NULL,
        [RowVersion] rowversion NOT NULL,
        [IsDeleted] bit NOT NULL CONSTRAINT [DF_PageSchema_IsDeleted] DEFAULT (0),
        [CreatedBy] bigint NULL,
        [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_PageSchema_CreatedAt] DEFAULT (sysutcdatetime()),
        [ModifiedBy] bigint NULL,
        [ModifiedAt] datetime2(3) NULL,
        CONSTRAINT [PK_PageSchema] PRIMARY KEY CLUSTERED ([Id])
    );
    CREATE UNIQUE INDEX [UQ_PageSchema_Code]
        ON [plat].[PageSchema] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
    CREATE INDEX [IX_PageSchema_Enabled]
        ON [plat].[PageSchema] ([TenantId], [IsEnabled], [IsDeleted]);
    EXEC sp_addextendedproperty N'MS_Description', N'页面组合定义（PageSchema JSON）',
        N'SCHEMA', N'plat', N'TABLE', N'PageSchema';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.security_predicates WHERE target_object_id = OBJECT_ID('plat.PageSchema'))
    ALTER SECURITY POLICY plat.TenantPolicy
        ADD FILTER PREDICATE plat.fn_TenantFilter(TenantId) ON [plat].[PageSchema];
GO

/* 种子：与前端本地定义同构，远程编辑后前端优先使用远程版本 */
IF NOT EXISTS (SELECT 1 FROM plat.PageSchema WHERE TenantId = 1 AND Code = 'workbench' AND IsDeleted = 0)
BEGIN
    INSERT plat.PageSchema
        (TenantId, Code, Title, Kind, ConfigJson, Version, IsEnabled, Remark, CreatedAt)
    VALUES
        (1, 'workbench', N'数据看板', 'dashboard',
N'{"code":"workbench","title":"数据看板","kind":"dashboard","description":"今日待办、基础资料规模与常用入口","dashboard":{"cards":[{"key":"brand","label":"品牌","objectCode":"md.brand","icon":"PriceTag","to":"/object/md.brand"},{"key":"brandcontact","label":"品牌联系人","objectCode":"md.brandcontact","icon":"User","to":"/object/md.brandcontact"},{"key":"partner","label":"往来单位","objectCode":"md.partner","icon":"OfficeBuilding","to":"/object/md.partner"},{"key":"menus","label":"功能菜单","value":"菜单","hint":"侧边栏已启用","icon":"Grid","to":"/page/master-data"}],"shortcuts":[{"label":"基础资料中心","to":"/page/master-data","icon":"Files"},{"label":"品牌管理","to":"/object/md.brand","icon":"PriceTag"},{"label":"往来单位","to":"/object/md.partner","icon":"OfficeBuilding"},{"label":"设计器中心","to":"/design","icon":"SetUp"}],"recentObjectCodes":["md.brand","md.brandcontact","md.partner"]},"permissions":[]}',
         1, 1, N'种子：与前端 workbench 本地定义一致', sysutcdatetime());
END
GO

IF NOT EXISTS (SELECT 1 FROM plat.PageSchema WHERE TenantId = 1 AND Code = 'master-data' AND IsDeleted = 0)
BEGIN
    INSERT plat.PageSchema
        (TenantId, Code, Title, Kind, ConfigJson, Version, IsEnabled, Remark, CreatedAt)
    VALUES
        (1, 'master-data', N'基础资料中心', 'tabs',
N'{"code":"master-data","title":"基础资料中心","kind":"tabs","description":"品牌、联系人、往来单位在同一屏内切换；每个页签都是真实数据对象页面","tabs":[{"key":"brand","label":"品牌","icon":"PriceTag","objectCode":"md.brand"},{"key":"brandcontact","label":"品牌联系人","icon":"User","objectCode":"md.brandcontact"},{"key":"partner","label":"往来单位","icon":"OfficeBuilding","objectCode":"md.partner"}],"permissions":[]}',
         1, 1, N'种子：与前端 master-data 本地定义一致', sysutcdatetime());
END
GO

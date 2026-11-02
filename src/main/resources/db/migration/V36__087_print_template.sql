/* =====================================================================
   V36 · 打印模板
   ---------------------------------------------------------------------
   背景：PRINT 动作一直只是个提示，没有真正的单据打印。
   做法：模板存 plat.PrintTemplate（HTML + 占位符），运行时用单据数据渲染成
        可打印的 HTML 页面；PRINT 动作返回 print 类型，前端开新窗口打印。
   占位符：
     {{FieldName}}           取主表字段（HTML 已转义）
     {{#ChildAlias}}…{{/ChildAlias}}  子表区块，区块内 {{Field}} 先取子行，取不到再取主表
   幂等。
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

IF OBJECT_ID('plat.PrintTemplate', 'U') IS NULL
BEGIN
    CREATE TABLE [plat].[PrintTemplate] (
        [Id] bigint IDENTITY(1,1) NOT NULL,
        [TenantId] int NOT NULL CONSTRAINT [DF_PrintTemplate_TenantId] DEFAULT (1),
        [DataObjectId] bigint NOT NULL,
        [Code] varchar(60) NOT NULL,
        [Name] nvarchar(100) NOT NULL,
        [Content] nvarchar(max) NOT NULL,
        [PaperSize] varchar(20) NOT NULL CONSTRAINT [DF_PrintTemplate_PaperSize] DEFAULT ('A4'),
        [IsDefault] bit NOT NULL CONSTRAINT [DF_PrintTemplate_IsDefault] DEFAULT (0),
        [IsEnabled] bit NOT NULL CONSTRAINT [DF_PrintTemplate_IsEnabled] DEFAULT (1),
        [Remark] nvarchar(500) NULL,
        [RowVersion] rowversion NOT NULL,
        [IsDeleted] bit NOT NULL CONSTRAINT [DF_PrintTemplate_IsDeleted] DEFAULT (0),
        [CreatedBy] bigint NULL,
        [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_PrintTemplate_CreatedAt] DEFAULT (sysutcdatetime()),
        [ModifiedBy] bigint NULL,
        [ModifiedAt] datetime2(3) NULL,
        CONSTRAINT [PK_PrintTemplate] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_PrintTemplate_Object] FOREIGN KEY ([DataObjectId]) REFERENCES [plat].[DataObject] ([Id])
    );
    CREATE UNIQUE INDEX [UQ_PrintTemplate_Code]
        ON [plat].[PrintTemplate] ([TenantId], [Code]) WHERE [IsDeleted] = 0;
    CREATE INDEX [IX_PrintTemplate_Object] ON [plat].[PrintTemplate] ([TenantId], [DataObjectId]);
    EXEC sp_addextendedproperty N'MS_Description', N'打印模板（HTML + 占位符）',
        N'SCHEMA', N'plat', N'TABLE', N'PrintTemplate';
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.security_predicates WHERE target_object_id = OBJECT_ID('plat.PrintTemplate'))
    ALTER SECURITY POLICY plat.TenantPolicy
        ADD FILTER PREDICATE plat.fn_TenantFilter(TenantId) ON [plat].[PrintTemplate];
GO

/* 演示模板：品牌档案（含联系人明细） */
DECLARE @brand bigint = (SELECT Id FROM plat.DataObject WHERE TenantId = 1 AND Code = 'md.brand');
IF @brand IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM plat.PrintTemplate WHERE TenantId = 1 AND Code = 'pt.brand')
BEGIN
    INSERT plat.PrintTemplate (TenantId, DataObjectId, Code, Name, Content, PaperSize, IsDefault,
                               IsEnabled, IsDeleted, CreatedAt)
    VALUES (1, @brand, 'pt.brand', N'品牌档案打印',
N'<!DOCTYPE html>
<html lang="zh-CN"><head><meta charset="utf-8"><title>品牌档案</title>
<style>
  body { font-family: "Microsoft YaHei", sans-serif; margin: 24px; color: #222; }
  h1 { font-size: 20px; text-align: center; margin: 0 0 4px; }
  .sub { text-align: center; color: #888; font-size: 12px; margin-bottom: 18px; }
  table { width: 100%; border-collapse: collapse; font-size: 13px; }
  th, td { border: 1px solid #ccc; padding: 6px 8px; text-align: left; }
  th { background: #f5f7fa; width: 120px; }
  h2 { font-size: 14px; margin: 18px 0 6px; }
</style></head>
<body>
  <h1>品牌档案</h1>
  <div class="sub">编码 {{Code}} · 打印时间 {{PrintedAt}}</div>
  <table>
    <tr><th>品牌编码</th><td>{{Code}}</td><th>品牌名称</th><td>{{Name}}</td></tr>
    <tr><th>英文名</th><td>{{EnName}}</td><th>排序</th><td>{{Sort}}</td></tr>
    <tr><th>状态</th><td>{{Status}}</td><th>创建时间</th><td>{{CreatedAt}}</td></tr>
  </table>
  <h2>联系人</h2>
  <table>
    <thead><tr><th>姓名</th><th>手机</th><th>邮箱</th><th>主联系人</th></tr></thead>
    <tbody>
      {{#Contacts}}
      <tr><td>{{ContactName}}</td><td>{{Mobile}}</td><td>{{Email}}</td><td>{{IsPrimary}}</td></tr>
      {{/Contacts}}
    </tbody>
  </table>
</body></html>', 'A4', 1, 1, 0, sysutcdatetime());
END
GO

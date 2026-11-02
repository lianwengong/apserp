/* =====================================================================
   V33 · 元数据灰度发布
   ---------------------------------------------------------------------
   背景：发布后所有改动立刻对所有人生效，没地方先小范围验证。
   做法：
     1) plat.MetaVersion.Status  0=历史 1=当前生效 2=灰度中
     2) plat.MetaVersionGray     灰度名单（哪些用户先看到这一版）
   约定：同一租户同时只有一个「当前生效」版本；灰度版本不改变生效版本，
        只是把名单里的用户标记为「先行者」，运行时读元数据时按此判定。
   幂等。
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

IF OBJECT_ID('plat.MetaVersionGray', 'U') IS NULL
BEGIN
    CREATE TABLE [plat].[MetaVersionGray] (
        [Id] bigint IDENTITY(1,1) NOT NULL,
        [TenantId] int NOT NULL CONSTRAINT [DF_MetaVersionGray_TenantId] DEFAULT (1),
        [MetaVersionId] bigint NOT NULL,
        [UserId] bigint NOT NULL,
        [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_MetaVersionGray_CreatedAt] DEFAULT (sysutcdatetime()),
        CONSTRAINT [PK_MetaVersionGray] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_MetaVersionGray_Version] FOREIGN KEY ([MetaVersionId]) REFERENCES [plat].[MetaVersion] ([Id]),
        CONSTRAINT [FK_MetaVersionGray_User] FOREIGN KEY ([UserId]) REFERENCES [plat].[User] ([Id])
    );
    CREATE UNIQUE INDEX [UQ_MetaVersionGray_Version_User]
        ON [plat].[MetaVersionGray] ([MetaVersionId], [UserId]);
    CREATE INDEX [IX_MetaVersionGray_User] ON [plat].[MetaVersionGray] ([TenantId], [UserId]);
    EXEC sp_addextendedproperty N'MS_Description', N'元数据灰度名单（哪个用户先吃哪一版）',
        N'SCHEMA', N'plat', N'TABLE', N'MetaVersionGray';
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.security_predicates WHERE target_object_id = OBJECT_ID('plat.MetaVersionGray'))
    ALTER SECURITY POLICY plat.TenantPolicy
        ADD FILTER PREDICATE plat.fn_TenantFilter(TenantId) ON [plat].[MetaVersionGray];
GO

/* 兼容：把最新一版置为「当前生效」，避免历史数据里没有生效版本 */
IF NOT EXISTS (SELECT 1 FROM plat.MetaVersion WHERE TenantId = 1 AND Status = 1)
BEGIN
    DECLARE @latest bigint = (SELECT MAX(Version) FROM plat.MetaVersion WHERE TenantId = 1);
    IF @latest IS NOT NULL
        UPDATE plat.MetaVersion SET Status = 1 WHERE TenantId = 1 AND Version = @latest;
END
GO

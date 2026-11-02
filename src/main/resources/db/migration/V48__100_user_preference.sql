/* =====================================================================
   V48 · 用户偏好（跨设备）
   ---------------------------------------------------------------------
   背景：外观偏好存在 localStorage，是「设备级」的；换台机器就回到默认。
   做法：plat.UserPreference 按 (租户, 用户, 键) 存一段 JSON，前端登录后拉取、
        修改时防抖回写。键用短字符串（如 appearance），值上限 64KB。
   幂等。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

IF OBJECT_ID('plat.UserPreference', 'U') IS NULL
BEGIN
    CREATE TABLE [plat].[UserPreference] (
        [Id] bigint IDENTITY(1,1) NOT NULL,
        [TenantId] int NOT NULL CONSTRAINT [DF_UserPreference_TenantId] DEFAULT (1),
        [UserId] bigint NOT NULL,
        [PrefKey] varchar(60) NOT NULL,
        [PrefValue] nvarchar(max) NULL,
        [RowVersion] rowversion NOT NULL,
        [IsDeleted] bit NOT NULL CONSTRAINT [DF_UserPreference_IsDeleted] DEFAULT (0),
        [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_UserPreference_CreatedAt] DEFAULT (sysutcdatetime()),
        [ModifiedAt] datetime2(3) NULL,
        CONSTRAINT [PK_UserPreference] PRIMARY KEY CLUSTERED ([Id])
    );
    CREATE UNIQUE INDEX [UQ_UserPreference_User_Key]
        ON [plat].[UserPreference] ([TenantId], [UserId], [PrefKey]) WHERE [IsDeleted] = 0;

    EXEC sp_addextendedproperty N'MS_Description', N'用户偏好（外观/布局等，跨设备同步）',
        N'SCHEMA', N'plat', N'TABLE', N'UserPreference';
    EXEC sp_addextendedproperty N'MS_Description', N'偏好键（如 appearance）',
        N'SCHEMA', N'plat', N'TABLE', N'UserPreference', N'COLUMN', N'PrefKey';
    EXEC sp_addextendedproperty N'MS_Description', N'偏好值（JSON 文本，≤64KB）',
        N'SCHEMA', N'plat', N'TABLE', N'UserPreference', N'COLUMN', N'PrefValue';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.security_predicates
               WHERE target_object_id = OBJECT_ID('plat.UserPreference'))
    ALTER SECURITY POLICY plat.TenantPolicy
        ADD FILTER PREDICATE plat.fn_TenantFilter(TenantId) ON [plat].[UserPreference];
GO

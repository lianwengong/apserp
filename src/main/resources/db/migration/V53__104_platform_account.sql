/* =====================================================================
   V53 · 平台账号（不绑定租户的登录方式）
   ---------------------------------------------------------------------
   背景：登录分成两种——
     · 租户登录：租户名 + 账号 + 口令，进业务管理入口，只管自己租户；
     · 平台登录：只有账号 + 口令，没有租户名，进平台管理入口，管所有租户。
   为了区分「谁能做平台登录」，给账号加一个显式标记，而不是靠
   「用户名碰巧在某个租户里是 SYSADMIN」——那样多租户下 admin 重名就分不清。
   种子管理员是演示用的平台账号；上线时应改为独立的运维账号。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

IF COL_LENGTH('plat.[User]', 'IsPlatformAccount') IS NULL
    ALTER TABLE plat.[User] ADD [IsPlatformAccount] bit NOT NULL
        CONSTRAINT [DF_User_IsPlatformAccount] DEFAULT (0);
GO
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties
               WHERE major_id = OBJECT_ID('plat.[User]') AND name = 'MS_Description'
                 AND minor_id = COLUMNPROPERTY(OBJECT_ID('plat.[User]'), 'IsPlatformAccount', 'ColumnId'))
    EXEC sp_addextendedproperty N'MS_Description', N'平台账号(可无租户名登录、管理所有租户)',
        N'SCHEMA', N'plat', N'TABLE', N'User', N'COLUMN', N'IsPlatformAccount';
GO

/* 种子管理员同时是平台账号：演示时既能做租户业务，也能做平台运维 */
UPDATE plat.[User]
SET IsPlatformAccount = 1
WHERE UserName = 'admin' AND TenantId = 1 AND IsDeleted = 0;
GO

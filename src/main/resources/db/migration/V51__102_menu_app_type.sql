/* =====================================================================
   V51 · 平台管理 / 业务管理 两个入口
   ---------------------------------------------------------------------
   背景：目前一棵菜单树混着「平台管理」（90 子树，43 条）和「业务管理」
        （01..10 子树，1104 条），登录后全塞进同一个侧边栏，平台配置与业务
        操作互相干扰；登录也不区分身份，谁都看到全部入口。
   做法：
     1) plat.Menu 增加 AppType：1=平台管理，2=业务管理；
     2) 把 90 子树（含子孙）标成平台入口，其余保持业务；
     3) 加索引 (TenantId, AppType, TerminalType, Sort)，菜单树按入口直接查。
   幂等。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

IF COL_LENGTH('plat.Menu', 'AppType') IS NULL
    ALTER TABLE plat.[Menu] ADD [AppType] tinyint NOT NULL
        CONSTRAINT [DF_Menu_AppType] DEFAULT (2);
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE name = 'CK_Menu_AppType' AND parent_object_id = OBJECT_ID('plat.Menu'))
    ALTER TABLE plat.[Menu]
        ADD CONSTRAINT [CK_Menu_AppType] CHECK ([AppType] IN (1, 2));
GO
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties
               WHERE major_id = OBJECT_ID('plat.Menu') AND name = 'MS_Description'
                 AND minor_id = COLUMNPROPERTY(OBJECT_ID('plat.Menu'), 'AppType', 'ColumnId'))
    EXEC sp_addextendedproperty N'MS_Description', N'所属入口(1平台管理 2业务管理)',
        N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'AppType';
GO

/* 90 子树（含子孙）整体标成平台入口 */
;WITH tree AS (
    SELECT Id FROM plat.[Menu]
    WHERE TenantId = 1 AND IsDeleted = 0 AND Code = '90'
    UNION ALL
    SELECT m.Id FROM plat.[Menu] m JOIN tree t ON m.ParentId = t.Id
    WHERE m.TenantId = 1 AND m.IsDeleted = 0
)
UPDATE m SET AppType = 1
FROM plat.[Menu] m JOIN tree t ON t.Id = m.Id;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Menu_App_Terminal'
               AND object_id = OBJECT_ID('plat.Menu'))
    CREATE INDEX [IX_Menu_App_Terminal]
        ON [plat].[Menu] ([TenantId], [AppType], [TerminalType], [Sort]);
GO

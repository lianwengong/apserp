/* =====================================================================
   V41 · 终端—功能模块—菜单 关系规范化
   ---------------------------------------------------------------------
   规则（负责人定）：
     1) 终端配置「能用的功能模块」——plat.ModuleTerminal 是唯一来源；
     2) 菜单必须指定唯一终端——plat.Menu.TerminalType；
     3) 菜单绑定的功能模块，必须在该终端已启用。
   本脚本做五件事：
     A. Menu 加 TerminalType（单值）；
     B. 终端向上闭合：子菜单支持的终端，父菜单也必须支持（否则子树在该终端上够不着）；
     C. 按已登记终端回填每条的 TerminalType（取最小值，没登记过的默认 PC）；
     D. 同一菜单原来挂多个终端的，按终端拆成多条（Code 加终端后缀），逐层克隆；
     E. MenuTerminal 收敛为「每个菜单一行」，并用 (ModuleId, TerminalType) 反推 ModuleTerminal。
   幂等：可重复执行。
   ===================================================================== */
SET NOCOUNT ON;
IF @@TRANCOUNT = 0 SET XACT_ABORT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

/* ---------------------------------------------------------------- A. 加列 */
/* 注意：加列与「引用新列」的语句必须分批次，否则整批编译时新列还不存在 */
IF COL_LENGTH('plat.Menu', 'TerminalType') IS NULL
BEGIN
    ALTER TABLE plat.[Menu]
        ADD [TerminalType] tinyint NOT NULL
            CONSTRAINT [DF_Menu_TerminalType] DEFAULT (1);
    EXEC sp_addextendedproperty N'MS_Description', N'所属终端(1PC 2PDA 3POS 4移动 5小程序 6其他)',
        N'SCHEMA', N'plat', N'TABLE', N'Menu', N'COLUMN', N'TerminalType';
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE name = 'CK_Menu_TerminalType' AND parent_object_id = OBJECT_ID('plat.Menu'))
    ALTER TABLE plat.[Menu]
        ADD CONSTRAINT [CK_Menu_TerminalType] CHECK ([TerminalType] BETWEEN 1 AND 6);
GO

/* ---------------------------------------------------------------- B. 终端向上闭合 */
DECLARE @grow int = 1;
WHILE @grow > 0
BEGIN
    INSERT plat.MenuTerminal (MenuId, TerminalType, IsVisible, Sort)
    SELECT DISTINCT p.Id, ct.TerminalType, 1, p.Sort
    FROM plat.[Menu] c
    JOIN plat.[Menu] p ON p.Id = c.ParentId
    JOIN plat.MenuTerminal ct ON ct.MenuId = c.Id
    WHERE c.IsDeleted = 0 AND p.IsDeleted = 0
      AND NOT EXISTS (SELECT 1 FROM plat.MenuTerminal pt
                      WHERE pt.MenuId = p.Id AND pt.TerminalType = ct.TerminalType);
    SET @grow = @@ROWCOUNT;
END
GO

/* ---------------------------------------------------------------- C. 回填主终端 */
UPDATE m
SET TerminalType = ISNULL((SELECT MIN(mt.TerminalType) FROM plat.MenuTerminal mt WHERE mt.MenuId = m.Id), 1)
FROM plat.[Menu] m
WHERE m.IsDeleted = 0;
GO

/* ---------------------------------------------------------------- D. 按终端拆分菜单 */
DECLARE @t tinyint = 2;
DECLARE @suffix varchar(10);
DECLARE @rows int;

WHILE @t <= 6
BEGIN
    SET @suffix = CASE @t WHEN 2 THEN '.PDA' WHEN 3 THEN '.POS' WHEN 4 THEN '.MOBILE'
                          WHEN 5 THEN '.MINIAPP' WHEN 6 THEN '.OTHER' END;

    /* D1. 根节点 */
    INSERT plat.[Menu] (TenantId, ParentId, Code, Name, MenuType, ModuleId, PageId, Route, Icon,
                        Sort, IsVisible, OpenMode, BadgeExpr, IsEnabled, Remark, TerminalType,
                        CreatedAt)
    SELECT m.TenantId, NULL, m.Code + @suffix, m.Name, m.MenuType, m.ModuleId, m.PageId, m.Route,
           m.Icon, m.Sort, m.IsVisible, m.OpenMode, m.BadgeExpr, m.IsEnabled, m.Remark, @t,
           sysutcdatetime()
    FROM plat.[Menu] m
    WHERE m.ParentId IS NULL AND m.IsDeleted = 0 AND m.TerminalType <> @t
      AND EXISTS (SELECT 1 FROM plat.MenuTerminal mt WHERE mt.MenuId = m.Id AND mt.TerminalType = @t)
      AND NOT EXISTS (SELECT 1 FROM plat.[Menu] x
                      WHERE x.TenantId = m.TenantId AND x.Code = m.Code + @suffix);

    /* D2. 子节点：父节点已克隆，逐层往下 */
    SET @rows = 1;
    WHILE @rows > 0
    BEGIN
        INSERT plat.[Menu] (TenantId, ParentId, Code, Name, MenuType, ModuleId, PageId, Route, Icon,
                            Sort, IsVisible, OpenMode, BadgeExpr, IsEnabled, Remark, TerminalType,
                            CreatedAt)
        SELECT m.TenantId, np.Id, m.Code + @suffix, m.Name, m.MenuType, m.ModuleId, m.PageId,
               m.Route, m.Icon, m.Sort, m.IsVisible, m.OpenMode, m.BadgeExpr, m.IsEnabled,
               m.Remark, @t, sysutcdatetime()
        FROM plat.[Menu] m
        JOIN plat.[Menu] p ON p.Id = m.ParentId
        JOIN plat.[Menu] np ON np.TenantId = m.TenantId AND np.TerminalType = @t
                          AND np.Code = p.Code + @suffix
        WHERE m.IsDeleted = 0 AND m.TerminalType <> @t
          AND m.Code NOT LIKE '%' + @suffix
          AND EXISTS (SELECT 1 FROM plat.MenuTerminal mt WHERE mt.MenuId = m.Id AND mt.TerminalType = @t)
          AND NOT EXISTS (SELECT 1 FROM plat.[Menu] x
                          WHERE x.TenantId = m.TenantId AND x.Code = m.Code + @suffix);
        SET @rows = @@ROWCOUNT;
    END

    SET @t = @t + 1;
END
GO

/* ---------------------------------------------------------------- E. 收敛与反推 */
DELETE FROM plat.MenuTerminal;
GO
INSERT plat.MenuTerminal (MenuId, TerminalType, IsVisible, Sort)
SELECT m.Id, m.TerminalType, 1, m.Sort
FROM plat.[Menu] m
WHERE m.IsDeleted = 0;
GO
INSERT plat.ModuleTerminal (TenantId, ModuleId, TerminalType, IsVisible)
SELECT DISTINCT m.TenantId, m.ModuleId, m.TerminalType, 1
FROM plat.[Menu] m
WHERE m.IsDeleted = 0 AND m.ModuleId IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM plat.ModuleTerminal mt
                  WHERE mt.ModuleId = m.ModuleId AND mt.TerminalType = m.TerminalType);
GO

/* ---------------------------------------------------------------- F. 索引 */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Menu_Tenant_Terminal'
               AND object_id = OBJECT_ID('plat.Menu'))
    CREATE INDEX [IX_Menu_Tenant_Terminal] ON [plat].[Menu] ([TenantId], [TerminalType], [Sort]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ModuleTerminal_Terminal'
               AND object_id = OBJECT_ID('plat.ModuleTerminal'))
    CREATE INDEX [IX_ModuleTerminal_Terminal] ON [plat].[ModuleTerminal] ([TenantId], [TerminalType]);
GO

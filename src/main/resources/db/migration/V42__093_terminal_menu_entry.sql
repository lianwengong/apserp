/* =====================================================================
   V42 · 平台管理菜单补「终端与功能」入口
   ---------------------------------------------------------------------
   规则落地后，菜单必须指定终端（V41），所以入口一律显式写 TerminalType。
   本脚本在「90 平台管理 → 9003 元数据设计」下新增 900309 终端与功能，
   指向 /system/terminals；同时补齐 MenuTerminal 镜像。
   幂等。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

DECLARE @parent bigint = (SELECT Id FROM plat.[Menu]
                          WHERE TenantId = 1 AND Code = '9003' AND IsDeleted = 0);

IF @parent IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM plat.[Menu] WHERE TenantId = 1 AND Code = '900309' AND IsDeleted = 0)
BEGIN
    INSERT plat.[Menu] (TenantId, ParentId, Code, Name, MenuType, Route, Icon, Sort, IsVisible,
                        OpenMode, IsEnabled, TerminalType, CreatedAt)
    VALUES (1, @parent, '900309', N'终端与功能', 2, '/system/terminals', 'Monitor', 45, 1, 1, 1, 1,
            sysutcdatetime());
END
GO

INSERT plat.MenuTerminal (MenuId, TerminalType, IsVisible, Sort)
SELECT m.Id, m.TerminalType, 1, m.Sort
FROM plat.[Menu] m
WHERE m.TenantId = 1 AND m.Code = '900309' AND m.IsDeleted = 0
  AND NOT EXISTS (SELECT 1 FROM plat.MenuTerminal mt WHERE mt.MenuId = m.Id);
GO

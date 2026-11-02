/* =====================================================================
   V37 · 系统功能模块管理 / 菜单设置管理
   ---------------------------------------------------------------------
   背景：模块（plat.Module，635 行）与菜单（plat.Menu，636 行）都是种子数据，
        没有任何管理界面，加一个功能点或调一次排序都要写迁移脚本。
   本脚本只做三件事：
     1) 补两个管理窗口的权限点：DESIGN:module、DESIGN:menu
     2) 给菜单管理的常用查询补索引（按父节点 + 排序、按模块）
     3) 数据治理：合并同名菜单（「角色管理」「登录用户」历史上重复录入）
   幂等。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

/* ---------------------------------------------------------------- 1. 权限点 */
IF NOT EXISTS (SELECT 1 FROM plat.Permission WHERE TenantId = 1 AND ResourceKey = 'DESIGN:module')
    INSERT plat.Permission (TenantId, ResourceKey, ResourceType, Name, IsEnabled)
    VALUES (1, 'DESIGN:module', 1, N'设计器：功能模块', 1);
GO
IF NOT EXISTS (SELECT 1 FROM plat.Permission WHERE TenantId = 1 AND ResourceKey = 'DESIGN:menu')
    INSERT plat.Permission (TenantId, ResourceKey, ResourceType, Name, IsEnabled)
    VALUES (1, 'DESIGN:menu', 1, N'设计器：菜单设置', 1);
GO
/* 管理员角色默认拿到这两个权限点，否则打开窗口就是 403 */
INSERT plat.RolePermission (RoleId, PermissionId)
SELECT r.Id, p.Id
FROM plat.Role r
JOIN plat.Permission p ON p.TenantId = r.TenantId
WHERE r.TenantId = 1 AND r.Code IN ('ADMIN', 'BOSS')
  AND p.ResourceKey IN ('DESIGN:module', 'DESIGN:menu')
  AND NOT EXISTS (SELECT 1 FROM plat.RolePermission rp
                  WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id);
GO

/* ---------------------------------------------------------------- 2. 索引 */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Menu_Parent_Sort'
               AND object_id = OBJECT_ID('plat.Menu'))
    CREATE INDEX [IX_Menu_Parent_Sort] ON [plat].[Menu] ([TenantId], [ParentId], [Sort]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Menu_Module'
               AND object_id = OBJECT_ID('plat.Menu'))
    CREATE INDEX [IX_Menu_Module] ON [plat].[Menu] ([TenantId], [ModuleId]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Module_Parent_Sort'
               AND object_id = OBJECT_ID('plat.Module'))
    CREATE INDEX [IX_Module_Parent_Sort] ON [plat].[Module] ([TenantId], [ParentId], [Sort]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ModuleFunction_Module'
               AND object_id = OBJECT_ID('plat.ModuleFunction'))
    CREATE INDEX [IX_ModuleFunction_Module] ON [plat].[ModuleFunction] ([TenantId], [ModuleId], [Sort]);
GO

/* ---------------------------------------------------------------- 3. 同名菜单治理 */
/* 同一父节点下 Code 相同的重复菜单：保留 Id 最小的一条，其余软删；
   子菜单与终端归属改挂到保留项，避免出现「点进去两份一模一样的菜单」。 */
DECLARE dup CURSOR LOCAL FAST_FORWARD FOR
    SELECT m.Id, keepId = (
        SELECT MIN(m2.Id) FROM plat.Menu m2
        WHERE m2.TenantId = m.TenantId
          AND m2.IsDeleted = 0
          AND ISNULL(m2.ParentId, 0) = ISNULL(m.ParentId, 0)
          AND m2.Code = m.Code)
    FROM plat.Menu m
    WHERE m.TenantId = 1 AND m.IsDeleted = 0
      AND m.Id <> (SELECT MIN(m2.Id) FROM plat.Menu m2
                   WHERE m2.TenantId = m.TenantId AND m2.IsDeleted = 0
                     AND ISNULL(m2.ParentId, 0) = ISNULL(m.ParentId, 0)
                     AND m2.Code = m.Code);
DECLARE @dupId bigint, @keepId bigint;
OPEN dup;
FETCH NEXT FROM dup INTO @dupId, @keepId;
WHILE @@FETCH_STATUS = 0
BEGIN
    UPDATE plat.Menu SET ParentId = @keepId WHERE ParentId = @dupId AND IsDeleted = 0;
    UPDATE plat.Menu SET IsDeleted = 1, IsEnabled = 0 WHERE Id = @dupId;
    FETCH NEXT FROM dup INTO @dupId, @keepId;
END
CLOSE dup; DEALLOCATE dup;
GO

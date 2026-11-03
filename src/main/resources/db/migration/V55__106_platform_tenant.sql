/* =====================================================================
   V55 · 平台账号与租户解绑：引入「平台租户」
   ---------------------------------------------------------------------
   问题：平台账号挂在 T001 名下，于是「停用 T001」被一条护栏挡住
        （不能停用平台账号所属租户），而且平台账号还会出现在 T001 的用户
        列表里——平台运维身份与某个业务租户绑在一起，概念就是错的。

   做法：
     1) plat.Tenant 增加 IsPlatformTenant 标记，插入保留租户 Id=0（T000 平台运营）；
     2) 把平台菜单（AppType=1，43 条）从 T001 复制到平台租户（按 Code 对齐父子关系）；
     3) 建平台账号 platadmin（放在平台租户里，口令沿用种子管理员的哈希，
        即 AsChain@2026）；
     4) 原 admin 摘掉平台标记，回归为 T001 的租户管理员。
   幂等：平台租户/菜单/账号已存在时跳过。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

IF COL_LENGTH('plat.Tenant', 'IsPlatformTenant') IS NULL
    ALTER TABLE plat.Tenant ADD [IsPlatformTenant] bit NOT NULL
        CONSTRAINT [DF_Tenant_IsPlatformTenant] DEFAULT (0);
GO

SET IDENTITY_INSERT plat.Tenant ON;
IF NOT EXISTS (SELECT 1 FROM plat.Tenant WHERE Id = 0)
    INSERT plat.Tenant (Id, Code, Name, ShortName, Industry, TimeZone, CurrencyCode,
                        DeploymentMode, ShardId, IsEnabled, IsPlatformTenant, Remark,
                        IsDeleted, CreatedAt)
    VALUES (0, 'T000', N'平台运营', N'平台', N'平台运营', 'Asia/Shanghai', 'CNY',
            1, 0, 1, 1, N'保留租户：只承载平台账号与平台菜单，不参与业务', 0, sysutcdatetime());
SET IDENTITY_INSERT plat.Tenant OFF;
GO
UPDATE plat.Tenant SET IsPlatformTenant = 1 WHERE Id = 0;
GO

/* ---------- 平台菜单复制到平台租户：先根，再按 Code 找父节点逐层展开 ---------- */
IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = 0 AND IsDeleted = 0)
BEGIN
    INSERT plat.Menu (TenantId, ParentId, Code, Name, ModuleId, PageId, MenuType, Route, Icon,
                      Sort, IsVisible, OpenMode, BadgeExpr, IsEnabled, TerminalType, AppType,
                      Remark, ExtJson, IsDeleted, CreatedAt)
    SELECT 0, NULL, src.Code, src.Name, NULL, NULL, src.MenuType, src.Route, src.Icon,
           src.Sort, src.IsVisible, src.OpenMode, src.BadgeExpr, src.IsEnabled,
           src.TerminalType, 1, src.Remark, src.ExtJson, 0, sysutcdatetime()
    FROM plat.Menu src
    WHERE src.TenantId = 1 AND src.AppType = 1 AND src.ParentId IS NULL AND src.IsDeleted = 0;

    DECLARE @round int = 0, @insertedCount int = 1;
    WHILE @insertedCount > 0 AND @round < 10
    BEGIN
        SET @round += 1;
        INSERT plat.Menu (TenantId, ParentId, Code, Name, ModuleId, PageId, MenuType, Route, Icon,
                          Sort, IsVisible, OpenMode, BadgeExpr, IsEnabled, TerminalType, AppType,
                          Remark, ExtJson, IsDeleted, CreatedAt)
        SELECT 0,
               (SELECT p0.Id FROM plat.Menu p0 WHERE p0.TenantId = 0 AND p0.Code = parent.Code),
               src.Code, src.Name, NULL, NULL, src.MenuType, src.Route, src.Icon,
               src.Sort, src.IsVisible, src.OpenMode, src.BadgeExpr, src.IsEnabled,
               src.TerminalType, 1, src.Remark, src.ExtJson, 0, sysutcdatetime()
        FROM plat.Menu src
        JOIN plat.Menu parent ON parent.Id = src.ParentId
        WHERE src.TenantId = 1 AND src.AppType = 1 AND src.IsDeleted = 0
          AND src.ParentId IS NOT NULL
          AND EXISTS (SELECT 1 FROM plat.Menu p0 WHERE p0.TenantId = 0 AND p0.Code = parent.Code)
          AND NOT EXISTS (SELECT 1 FROM plat.Menu x
                          WHERE x.TenantId = 0 AND x.Code = src.Code AND x.IsDeleted = 0);
        SET @insertedCount = @@ROWCOUNT;
    END

    INSERT plat.MenuTerminal (MenuId, TerminalType, IsVisible, Sort)
    SELECT m0.Id, t.TerminalType, t.IsVisible, t.Sort
    FROM plat.MenuTerminal t
    JOIN plat.Menu src ON src.Id = t.MenuId
    JOIN plat.Menu m0 ON m0.TenantId = 0 AND m0.Code = src.Code AND m0.IsDeleted = 0
    WHERE src.TenantId = 1 AND src.AppType = 1;
END
GO

/* ---------- 平台账号：放到平台租户，口令沿用种子管理员的哈希 ---------- */
IF NOT EXISTS (SELECT 1 FROM plat.[User] WHERE UserName = 'platadmin' AND IsDeleted = 0)
BEGIN
    INSERT plat.[User] (TenantId, UserName, PasswordHash, PasswordSalt, DisplayName,
                        UserType, IsEnabled, MustChangePwd, FailCount, IsPlatformAccount,
                        IsDeleted, CreatedAt)
    SELECT 0, 'platadmin', u.PasswordHash, u.PasswordSalt, N'平台管理员',
           1, 1, 0, 0, 1, 0, sysutcdatetime()
    FROM plat.[User] u
    WHERE u.UserName = 'admin' AND u.TenantId = 1 AND u.IsDeleted = 0;
END
GO

/* admin 回归为纯租户管理员；platadmin 固定在平台租户 */
UPDATE plat.[User]
SET IsPlatformAccount = 0, ModifiedAt = sysutcdatetime()
WHERE UserName = 'admin' AND TenantId = 1 AND IsPlatformAccount = 1;
GO

UPDATE plat.[User]
SET TenantId = 0, IsPlatformAccount = 1, ModifiedAt = sysutcdatetime()
WHERE UserName = 'platadmin' AND IsDeleted = 0 AND TenantId <> 0;
GO

/* =====================================================================
   V56 · 补齐存量租户的租户管理员
   ---------------------------------------------------------------------
   问题：种子/历史租户（如 T002）只有租户行与角色，没有登录用户，
        于是「租户管理 → 管理员口令」报「该租户没有管理员账号」。
        开通流程（V55 之前就有）会给新租户建 admin，但存量租户没补。
   做法：对每个业务租户，如果没有启用中的 SYSADMIN 用户，就建一个
        `admin` 占位账号：
         · PasswordHash 写入一个随机 Base64（不可能匹配任何口令），
           即「必须先由平台管理员在租户管理里重置口令」；
         · MustChangePwd=1，重置后首次登录强制改密；
         · SYSADMIN 角色不存在时补建，然后绑定。
   幂等：已有 SYSADMIN 用户的租户跳过。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

/* 1) 缺 SYSADMIN 角色的租户先补角色 */
INSERT plat.Role (TenantId, Code, Name, RoleType, IsSystem, IsEnabled, Remark, IsDeleted, CreatedAt)
SELECT t.Id, 'SYSADMIN', N'系统管理员', 1, 1, 1, N'租户管理员（补齐）', 0, sysutcdatetime()
FROM plat.Tenant t
WHERE t.IsDeleted = 0 AND t.IsPlatformTenant = 0
  AND NOT EXISTS (SELECT 1 FROM plat.Role r
                  WHERE r.TenantId = t.Id AND r.Code = 'SYSADMIN' AND r.IsDeleted = 0);
GO

/* 2) 缺管理员账号的租户补一个占位 admin（口令不可用，必须后台重置） */
INSERT plat.[User] (TenantId, UserName, PasswordHash, PasswordSalt, DisplayName,
                    UserType, IsEnabled, MustChangePwd, FailCount, IsPlatformAccount,
                    IsDeleted, CreatedAt)
SELECT t.Id, 'admin',
       CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varchar(64), NEWID())), 2),
       'AAAAAAAAAAAAAAAAAAAAAA==',
       N'租户管理员', 1, 1, 1, 0, 0, 0, sysutcdatetime()
FROM plat.Tenant t
WHERE t.IsDeleted = 0 AND t.IsPlatformTenant = 0
  AND NOT EXISTS (
      SELECT 1
      FROM plat.[User] u
      JOIN plat.UserRole ur ON ur.UserId = u.Id
      JOIN plat.Role r ON r.Id = ur.RoleId AND r.Code = 'SYSADMIN'
      WHERE u.TenantId = t.Id AND u.IsDeleted = 0 AND u.IsEnabled = 1
  );
GO

/* 3) 把占位 admin 绑到本租户的 SYSADMIN 角色 */
INSERT plat.UserRole (TenantId, UserId, RoleId)
SELECT u.TenantId, u.Id, r.Id
FROM plat.[User] u
JOIN plat.Role r ON r.TenantId = u.TenantId AND r.Code = 'SYSADMIN' AND r.IsDeleted = 0
WHERE u.UserName = 'admin' AND u.IsDeleted = 0
  AND NOT EXISTS (SELECT 1 FROM plat.UserRole ur WHERE ur.UserId = u.Id AND ur.RoleId = r.Id);
GO

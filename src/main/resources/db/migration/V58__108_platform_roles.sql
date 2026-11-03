/* =====================================================================
   V58 · 平台角色与权限
   ---------------------------------------------------------------------
   问题：平台入口的「角色与权限」指向的是元数据设计器的权限页，那里改的是
        **某个租户内部**的角色，和平台运营权限没有关系；平台账号也没有任何
        权限点可分配（登录即全权）。
   做法：
     1) 在平台租户（Id=0）里定义平台权限点 PLAT:*（租户/账号/菜单/模块/编号/监控/审计/角色）；
     2) 建三个平台角色：PLAT_ADMIN（全权）、PLAT_OPS（运维）、PLAT_AUDIT（只读审计），
        并写入 RolePermission；
     3) 现有平台账号全部绑定 PLAT_ADMIN（升级不降权）；
     4) 菜单 900204「角色与权限」改指向新增的 /admin/roles 页面。
   幂等：权限点/角色/绑定/菜单路由均按「不存在才插」处理。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

/* ---------- 1. 平台权限点 ---------- */
INSERT plat.Permission (TenantId, ResourceKey, ResourceType, Name, ParentKey, IsEnabled)
SELECT 0, src.ResourceKey, 1, src.Name, 'PLAT', 1
FROM (VALUES
    ('PLAT', N'平台管理'),
    ('PLAT:TENANT', N'租户管理（开通/停用/编辑/管理员口令）'),
    ('PLAT:ACCOUNT', N'平台账号（新增/启停/重置口令/角色）'),
    ('PLAT:ROLE', N'平台角色与权限'),
    ('PLAT:MENU', N'菜单总览'),
    ('PLAT:MODULE', N'模块/终端/编号规则'),
    ('PLAT:MONITOR', N'监控与运维（到期扫描、通知）'),
    ('PLAT:AUDIT', N'审计与日志')
) AS src(ResourceKey, Name)
WHERE NOT EXISTS (SELECT 1 FROM plat.Permission p
                  WHERE p.TenantId = 0 AND p.ResourceKey = src.ResourceKey);
GO

/* ---------- 2. 平台角色 ---------- */
INSERT plat.Role (TenantId, Code, Name, RoleType, IsSystem, IsEnabled, Remark, IsDeleted, CreatedAt)
SELECT 0, src.Code, src.Name, 1, 1, 1, N'平台角色', 0, sysutcdatetime()
FROM (VALUES
    ('PLAT_ADMIN', N'平台管理员'),
    ('PLAT_OPS', N'平台运维'),
    ('PLAT_AUDIT', N'平台审计（只读）')
) AS src(Code, Name)
WHERE NOT EXISTS (SELECT 1 FROM plat.Role r WHERE r.TenantId = 0 AND r.Code = src.Code);
GO

/* ---------- 3. 角色权限 ---------- */
/* 平台管理员：全部 */
INSERT plat.RolePermission (TenantId, RoleId, PermissionId, Allow, CanRead, CanWrite,
                            CanApprove, CanExport, CanDelete, DataScope, GrantedAt)
SELECT 0, r.Id, p.Id, 1, 1, 1, 1, 1, 1, 1, sysutcdatetime()
FROM plat.Role r
JOIN plat.Permission p ON p.TenantId = 0 AND p.ResourceKey LIKE 'PLAT%'
WHERE r.TenantId = 0 AND r.Code = 'PLAT_ADMIN'
  AND NOT EXISTS (SELECT 1 FROM plat.RolePermission rp WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id);
GO

/* 平台运维：租户/账号/菜单/模块/监控，不含角色与审计 */
INSERT plat.RolePermission (TenantId, RoleId, PermissionId, Allow, CanRead, CanWrite,
                            CanApprove, CanExport, CanDelete, DataScope, GrantedAt)
SELECT 0, r.Id, p.Id, 1, 1, 1, 0, 1, 1, 1, sysutcdatetime()
FROM plat.Role r
JOIN plat.Permission p ON p.TenantId = 0
     AND p.ResourceKey IN ('PLAT', 'PLAT:TENANT', 'PLAT:ACCOUNT', 'PLAT:MENU', 'PLAT:MODULE', 'PLAT:MONITOR')
WHERE r.TenantId = 0 AND r.Code = 'PLAT_OPS'
  AND NOT EXISTS (SELECT 1 FROM plat.RolePermission rp WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id);
GO

/* 平台审计：只读 */
INSERT plat.RolePermission (TenantId, RoleId, PermissionId, Allow, CanRead, CanWrite,
                            CanApprove, CanExport, CanDelete, DataScope, GrantedAt)
SELECT 0, r.Id, p.Id, 1, 1, 0, 0, 1, 0, 1, sysutcdatetime()
FROM plat.Role r
JOIN plat.Permission p ON p.TenantId = 0
     AND p.ResourceKey IN ('PLAT', 'PLAT:TENANT', 'PLAT:MENU', 'PLAT:AUDIT')
WHERE r.TenantId = 0 AND r.Code = 'PLAT_AUDIT'
  AND NOT EXISTS (SELECT 1 FROM plat.RolePermission rp WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id);
GO

/* ---------- 4. 现有平台账号绑定 PLAT_ADMIN（升级不降权） ---------- */
INSERT plat.UserRole (TenantId, UserId, RoleId)
SELECT 0, u.Id, r.Id
FROM plat.[User] u
JOIN plat.Role r ON r.TenantId = 0 AND r.Code = 'PLAT_ADMIN'
WHERE u.IsPlatformAccount = 1 AND u.IsDeleted = 0
  AND NOT EXISTS (SELECT 1 FROM plat.UserRole ur WHERE ur.UserId = u.Id AND ur.RoleId = r.Id);
GO

/* ---------- 5. 菜单：角色与权限 → 新页面 ---------- */
UPDATE plat.[Menu]
SET Route = '/admin/roles', ModifiedAt = sysutcdatetime()
WHERE Code = '900204' AND IsDeleted = 0;
GO

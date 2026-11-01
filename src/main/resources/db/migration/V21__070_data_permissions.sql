/* 数据对象级权限点：DATA:{objectCode}
   现有的 ResourceKey 只有 MOD:/FUN: 两类，数据对象的增删改查没有对应权限点。
   这里从 plat.DataObject 自动生成，保证"每个数据对象都能单独授权"。 */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO
INSERT plat.Permission (TenantId, ResourceKey, ResourceType, Name, ParentKey, ModuleId, FunctionId, IsEnabled)
SELECT o.TenantId,
       'DATA:' + o.Code,
       3,
       N'数据：' + o.Name,
       NULL,
       NULL,
       NULL,
       1
FROM plat.DataObject o
WHERE o.IsDeleted = 0
  AND NOT EXISTS (
      SELECT 1 FROM plat.Permission p
      WHERE p.TenantId = o.TenantId AND p.ResourceKey = 'DATA:' + o.Code
  );
GO
/* 已有角色（含 SYSADMIN）授予只读；写权限按需逐角色开，避免默认给太大 */
INSERT plat.RolePermission (TenantId, RoleId, PermissionId, Allow, CanRead, CanWrite,
                            CanApprove, CanExport, CanDelete, DataScope, GrantedAt)
SELECT p.TenantId, r.Id, p.Id, 1, 1, 0, 0, 0, 0, 4, sysutcdatetime()
FROM plat.Permission p
JOIN plat.Role r ON r.TenantId = p.TenantId
WHERE p.ResourceKey LIKE 'DATA:%'
  AND NOT EXISTS (
      SELECT 1 FROM plat.RolePermission rp
      WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id
  );
GO

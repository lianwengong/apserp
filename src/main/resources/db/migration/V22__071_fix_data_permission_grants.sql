/* 修正 V21 的过度授权：数据对象只读权限不应默认发给所有角色。
   V21 把 DATA:* 的只读权限发给了全部角色，等于"新建角色自动能看全部数据"，
   违反最小权限。这里收回，只保留 SYSADMIN（且管理员本身在 ufn_Perm_Check 里直通）。 */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO
DELETE rp
FROM plat.RolePermission rp
JOIN plat.Permission p ON p.Id = rp.PermissionId
JOIN plat.Role r ON r.Id = rp.RoleId
WHERE p.ResourceKey LIKE 'DATA:%'
  AND r.Code <> 'SYSADMIN';
GO
INSERT plat.RolePermission (TenantId, RoleId, PermissionId, Allow, CanRead, CanWrite,
                            CanApprove, CanExport, CanDelete, DataScope, GrantedAt)
SELECT p.TenantId, r.Id, p.Id, 1, 1, 1, 0, 0, 0, 1, sysutcdatetime()
FROM plat.Permission p
JOIN plat.Role r ON r.TenantId = p.TenantId AND r.Code = 'SYSADMIN'
WHERE p.ResourceKey LIKE 'DATA:%'
  AND NOT EXISTS (SELECT 1 FROM plat.RolePermission rp
                  WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id);
GO

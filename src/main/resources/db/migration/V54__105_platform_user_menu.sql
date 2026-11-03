/* =====================================================================
   V54 · 平台管理「用户管理」菜单指向真实页面
   ---------------------------------------------------------------------
   背景：900203 用户管理 一直落在 /m/900203 占位页；平台入口新增了
        /admin/users（跨租户用户与权限），把菜单绑过去，避免「点开是占位页」。
   幂等：只更新路由为空或指向 /m/ 占位的那条。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

UPDATE plat.[Menu]
SET Route = '/admin/users',
    ModifiedAt = sysutcdatetime()
WHERE Code = '900203'
  AND IsDeleted = 0
  AND (Route IS NULL OR Route LIKE '/m/%');
GO

/* 删除平台管理下的「组织架构」入口（菜单编码 900202）
   ------------------------------------------------------------------
   理由：
   1) 平台管理是运营方后台，运营方自身没有进销存业务；
   2) 组织（部门/门店/仓库）是**租户内部的业务数据**，平台方不应编辑；
   3) 该菜单无后端接口、无前端页面，点击只会落到 /m/900202 占位页。

   处理方式：软删除（IsDeleted=1），随时可回滚——
   把 IsDeleted/IsEnabled/IsVisible 改回 1 即可恢复。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO
/* 1) 先清子表：终端可见性（MenuTerminal 没有软删除列，直接删除） */
DELETE mt
FROM plat.MenuTerminal mt
JOIN plat.Menu m ON m.Id = mt.MenuId
WHERE m.Code = '900202';
GO
/* 2) 软删除菜单（覆盖所有租户的同编码节点） */
UPDATE plat.Menu
SET IsDeleted = 1,
    IsEnabled = 0,
    IsVisible = 0,
    DeletedAt = sysutcdatetime()
WHERE Code = '900202'
  AND IsDeleted = 0;
GO

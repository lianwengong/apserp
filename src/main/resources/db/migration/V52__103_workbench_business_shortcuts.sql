/* =====================================================================
   V52 · 工作台看板去掉「设计器中心」快捷入口
   ---------------------------------------------------------------------
   背景：平台管理 / 业务管理拆成两个入口后，业务工作台仍挂着一个指向
        /design 的快捷入口——那是平台管理入口的页面，点进去会被路由守卫
        弹回业务首页，属于「看着能点、点了没反应」的死入口。
   做法：把库里的 PageSchema（workbench）里这条快捷入口换成业务侧的
        「我的待办」；本地 pages.ts 的兜底定义同步改过。
   幂等：REPLACE 找不到目标串时不变更。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

UPDATE plat.PageSchema
SET ConfigJson = REPLACE(ConfigJson,
        '{"label":"设计器中心","to":"/design","icon":"SetUp"}',
        '{"label":"我的待办","to":"/todo","icon":"Grid"}'),
    ModifiedAt = sysutcdatetime()
WHERE Code = 'workbench'
  AND IsDeleted = 0
  AND ConfigJson LIKE '%设计器中心%';
GO

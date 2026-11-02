/* =====================================================================
   V39 · 平台管理菜单重组
   ---------------------------------------------------------------------
   目标：侧边栏不再同时出现「平台」和「功能菜单 → 平台管理」两个入口。
   做法：
     1) 平台管理树内改为真实页面：模块管理 /system/modules、菜单设置
        /system/menus、设计器中心 /design、状态机 /design?tab=status、
        打印模板 /design?tab=print；
     2) 流程中心、我的待办移到前端「工作台」组（人人可见），从平台管理树
        软删，避免重复；
     3) 旧的页面与表单入口改名为状态机。
   只处理模板租户 T001。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

DECLARE @t int = (SELECT TOP 1 Id FROM plat.Tenant WHERE Code = 'T001' AND IsDeleted = 0 ORDER BY Id);
IF @t IS NOT NULL
BEGIN
    UPDATE plat.[Menu] SET Name = N'状态机', Route = '/design?tab=status'
    WHERE TenantId = @t AND Code = '900303';

    UPDATE plat.[Menu] SET Route = '/system/modules'
    WHERE TenantId = @t AND Code = '900304';

    UPDATE plat.[Menu] SET Route = '/system/menus'
    WHERE TenantId = @t AND Code = '900305';

    DECLARE @m3 bigint = (SELECT Id FROM plat.[Menu] WHERE TenantId = @t AND Code = '9003');

    IF NOT EXISTS (SELECT 1 FROM plat.[Menu] WHERE TenantId = @t AND Code = '900307')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m3, '900307', N'打印模板', 2, '/design?tab=print', 35, 1, 1);

    IF NOT EXISTS (SELECT 1 FROM plat.[Menu] WHERE TenantId = @t AND Code = '900308')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m3, '900308', N'设计器中心', 2, '/design', 5, 1, 1);

    /* 流程中心 / 我的待办 统一放「工作台」，平台管理树里不再重复 */
    UPDATE plat.[Menu] SET IsDeleted = 1, IsEnabled = 0
    WHERE TenantId = @t AND Code IN ('900404', '900405');
END
GO

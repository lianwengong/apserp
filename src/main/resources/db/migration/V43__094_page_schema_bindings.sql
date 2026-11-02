/* =====================================================================
   V43 · 页面组合绑定
   ---------------------------------------------------------------------
   把已经有真实页面的菜单从 /m/:code 占位页切到真实路由：
     · 0102 商品与主数据 → 新增「基础资料中心」/page/master-data（多页签）
     · 010203 品牌信息 / 010299 品牌管理(演示) → /object/md.brand
     · 010401 供应商信息 / 010402 客户信息 → /object/md.partner
   只处理模板租户 T001；其它租户由开通流程复制。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

DECLARE @t int = (SELECT TOP 1 Id FROM plat.Tenant WHERE Code = 'T001' AND IsDeleted = 0 ORDER BY Id);
IF @t IS NOT NULL
BEGIN
    UPDATE plat.[Menu] SET Route = '/object/md.brand'
    WHERE TenantId = @t AND Code IN ('010203', '010299');

    UPDATE plat.[Menu] SET Route = '/object/md.partner'
    WHERE TenantId = @t AND Code IN ('010401', '010402');

    DECLARE @parent bigint = (SELECT Id FROM plat.[Menu] WHERE TenantId = @t AND Code = '0102');

    IF @parent IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM plat.[Menu] WHERE TenantId = @t AND Code = '010200')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @parent, '010200', N'基础资料中心', 2, '/page/master-data', 1, 1, 1);
END
GO

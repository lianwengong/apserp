/* V47 · 平台管理 → 元数据设计 → 页面编排 */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

DECLARE @t int = (SELECT TOP 1 Id FROM plat.Tenant WHERE Code = 'T001' AND IsDeleted = 0 ORDER BY Id);
IF @t IS NOT NULL
BEGIN
    DECLARE @parent bigint = (SELECT Id FROM plat.[Menu] WHERE TenantId = @t AND Code = '9003');
    IF @parent IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM plat.[Menu] WHERE TenantId = @t AND Code = '900310')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @parent, '900310', N'页面编排', 2, '/system/pages', 15, 1, 1);
END
GO

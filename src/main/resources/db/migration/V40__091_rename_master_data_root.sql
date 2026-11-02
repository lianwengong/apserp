/* V40 · 业务菜单根改名：去掉与“平台管理”混淆的“平台”字样
   01 下仍是业务主数据（组织/商品/价格/往来/期初），系统/安全/集成等
   历史子模块保留，后续可再迁入平台管理树。 */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO
UPDATE plat.[Menu] SET Name = N'主数据'
WHERE TenantId = 1 AND Code = '01';
GO

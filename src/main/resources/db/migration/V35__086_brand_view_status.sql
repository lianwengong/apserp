/* =====================================================================
   V35 · 状态列进默认列表视图
   ---------------------------------------------------------------------
   背景：状态机接入后，品牌默认视图 lv.brand 没有「状态」列，
        列表上看不到单据处在哪一步，用户只能靠猜。
   做法：给 lv.brand 补一列 Status（标题「状态」），排在启用之后。
   幂等：已有该列则跳过。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO
DECLARE @view bigint = (
    SELECT v.Id FROM plat.ListView v
    JOIN plat.DataObject o ON o.Id = v.DataObjectId
    WHERE v.TenantId = 1 AND o.Code = 'md.brand' AND v.Code = 'lv.brand');
IF @view IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM plat.ListViewColumn WHERE ListViewId = @view AND FieldName = 'Status')
BEGIN
    INSERT plat.ListViewColumn (ListViewId, FieldName, Title, Width, Align, Sort, IsVisible)
    VALUES (@view, 'Status', N'状态', 100, 2, 45, 1);
END
GO

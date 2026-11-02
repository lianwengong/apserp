/* V45 · 品牌联系人表单补“品牌”参照字段
   有 BrandId 元数据但默认表单布局没有它，用户无法从界面建立品牌关系。
   补一个 ControlType=6（查找）的表单字段，走 RecordPicker；非必填，避免历史数据无法编辑。 */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

DECLARE @layout bigint = (
    SELECT TOP 1 Id FROM plat.FormLayout
    WHERE TenantId = 1 AND Code = 'fl.brandcontact' AND IsDeleted = 0
);

IF @layout IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM plat.FormField
       WHERE FormLayoutId = @layout AND FieldName = 'BrandId'
   )
BEGIN
    INSERT plat.FormField
        (FormLayoutId, FieldName, Label, ControlType, Row, Col, Span,
         IsReadOnly, IsRequired, IsHidden, GroupName, Sort)
    VALUES
        (@layout, 'BrandId', N'品牌', 6, 0, 0, 12,
         0, 0, 0, N'基本信息', 5);
END
GO

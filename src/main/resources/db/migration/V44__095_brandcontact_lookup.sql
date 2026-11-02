/* V44 · 让品牌联系人可参照选择品牌
   BrandId 是真实的关联字段，但种子只登记为普通 bigint；补成 LookupType=2 后，
   表单会显示“高级选择”，走 RecordPicker（关键字 + 分页 + 默认视图列）。
   幂等：只在当前还没有查找源时更新。 */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO
UPDATE f
SET f.LookupType = 2,
    f.LookupSource = 'md.brand',
    f.LookupDisplayField = 'Name'
FROM plat.DataObjectField f
JOIN plat.DataObject o ON o.Id = f.DataObjectId
WHERE o.Code = 'md.brandcontact'
  AND o.TenantId = 1
  AND f.FieldName = 'BrandId'
  AND ISNULL(f.LookupSource, '') = '';
GO

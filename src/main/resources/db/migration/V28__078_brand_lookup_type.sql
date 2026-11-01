/* 补齐 md.brand 的字段元数据：ManufacturerId 为下拉引用（LookupType=2）
   背景：V27 从开发库复制 md.brand 定义时漏了查找类型，集成测试 MetaDefinitionIT 断言不一致。
   幂等：只在当前值为 0/NULL 时更新。 */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO
UPDATE f
SET f.LookupType = 2
FROM plat.DataObjectField f
JOIN plat.DataObject o ON o.Id = f.DataObjectId
WHERE o.Code = 'md.brand'
  AND o.TenantId = 1
  AND f.FieldName = 'ManufacturerId'
  AND ISNULL(f.LookupType, 0) = 0;
GO

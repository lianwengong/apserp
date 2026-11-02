/* =====================================================================
   V31 · 子表软删除与列表引擎对齐
   ---------------------------------------------------------------------
   背景：`usp_Meta_List` 只有在对象的字段元数据里登记了 `IsDeleted` 时才追加
         `AND t.[IsDeleted] = 0`。md.brandcontact 之前没有登记该字段，
         于是主子表级联删除（软删）后，明细里仍然能看到已删除的子行。
   处理：把 IsDeleted 登记为「不可见字段」——仅用于过滤，前端看不到也改不了。
   幂等：已存在则跳过。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO
IF NOT EXISTS (SELECT 1 FROM plat.DataObjectField f JOIN plat.DataObject o ON o.Id = f.DataObjectId
               WHERE o.TenantId = 1 AND o.Code = 'md.brandcontact' AND f.FieldName = 'IsDeleted')
    INSERT plat.DataObjectField (DataObjectId, FieldName, DisplayName, DataType, MaxLength,
                                 IsNullable, IsPrimaryKey, IsIdentity, IsRequired, IsVisible, Sort)
    SELECT Id, 'IsDeleted', N'删除标记', 'bit', NULL, 0, 0, 0, 0, 0, 900
    FROM plat.DataObject WHERE TenantId = 1 AND Code = 'md.brandcontact';
GO
IF NOT EXISTS (SELECT 1 FROM plat.DataObjectField f JOIN plat.DataObject o ON o.Id = f.DataObjectId
               WHERE o.TenantId = 1 AND o.Code = 'md.brand' AND f.FieldName = 'IsDeleted')
    INSERT plat.DataObjectField (DataObjectId, FieldName, DisplayName, DataType, MaxLength,
                                 IsNullable, IsPrimaryKey, IsIdentity, IsRequired, IsVisible, Sort)
    SELECT Id, 'IsDeleted', N'删除标记', 'bit', NULL, 0, 0, 0, 0, 0, 900
    FROM plat.DataObject WHERE TenantId = 1 AND Code = 'md.brand';
GO

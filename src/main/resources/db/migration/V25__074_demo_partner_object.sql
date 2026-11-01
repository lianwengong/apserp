/* 标准演示对象：往来单位（md.Partner）
   用途：1) 演示带 OrgField 的数据范围过滤；2) 后续业务模块的参照。
   幂等：已存在则跳过。 */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO
IF NOT EXISTS (SELECT 1 FROM plat.DataObject WHERE TenantId = 1 AND Code = 'md.partner')
BEGIN
    DECLARE @oid bigint;

    INSERT plat.DataObject (TenantId, Code, Name, ObjectType, SchemaName, ObjectName, PrimaryKey,
                            OrgField, TenantField, DefaultOrder, IsEnabled, IsDeleted, CreatedAt)
    VALUES (1, 'md.partner', N'往来单位', 1, 'md', 'Partner', 'Id',
            'OrgId', 'TenantId', 'Id', 1, 0, sysutcdatetime());
    SET @oid = SCOPE_IDENTITY();

    INSERT plat.DataObjectField (DataObjectId, FieldName, DisplayName, DataType, MaxLength,
                                 IsNullable, IsPrimaryKey, IsIdentity, IsRequired, IsVisible, Sort)
    VALUES (@oid, 'Id',    N'主键',   'bigint',        NULL, 0, 1, 1, 0, 1,  0),
           (@oid, 'Code',  N'编码',   'varchar(32)',   32,   0, 0, 0, 1, 1, 10),
           (@oid, 'Name',  N'名称',   'nvarchar(100)', 100,  0, 0, 0, 1, 1, 20),
           (@oid, 'OrgId', N'组织',   'int',           NULL, 1, 0, 0, 0, 1, 30),
           (@oid, 'IsDeleted', N'删除', 'bit',         NULL, 0, 0, 0, 0, 0, 40);

    INSERT plat.Permission (TenantId, ResourceKey, ResourceType, Name, IsEnabled)
    VALUES (1, 'DATA:md.partner', 3, N'数据：往来单位', 1);
END
GO

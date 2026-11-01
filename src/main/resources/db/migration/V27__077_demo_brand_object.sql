/* 演示对象：品牌（md.Brand）
   背景：md.brand 对象与 4 条品牌数据此前只存在于开发库（手工维护），未进入版本化迁移，
        导致“空库重放 V1–V26”之后集成测试找不到该对象（CI 红）。
   本脚本把开发库的既有定义补齐为迁移，内容为幂等：已存在则整段跳过。
   注意：只增不改，不回写历史脚本。 */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO
IF NOT EXISTS (SELECT 1 FROM plat.DataObject WHERE TenantId = 1 AND Code = 'md.brand')
BEGIN
    DECLARE @oid bigint;

    INSERT plat.DataObject (TenantId, Code, Name, ObjectType, SchemaName, ObjectName, PrimaryKey,
                            OrgField, TenantField, DefaultOrder, IsEnabled, IsDeleted, CreatedAt)
    VALUES (1, 'md.brand', N'品牌', 1, 'md', 'Brand', 'Id',
            NULL, 'TenantId', 'Sort', 1, 0, sysutcdatetime());
    SET @oid = SCOPE_IDENTITY();

    INSERT plat.DataObjectField (DataObjectId, FieldName, DisplayName, DataType, MaxLength,
                                 IsNullable, IsPrimaryKey, IsIdentity, IsRequired, IsVisible, Sort)
    VALUES (@oid, 'Id',         N'主键',      'bigint',        NULL, 0, 1, 1, 0, 1,  0),
           (@oid, 'Code',       N'品牌编码',  'varchar(32)',   32,   0, 0, 0, 1, 1, 10),
           (@oid, 'Name',       N'品牌名称',  'nvarchar(50)',  50,   0, 0, 0, 1, 1, 20),
           (@oid, 'EnName',     N'英文名',    'nvarchar(100)', 100,  1, 0, 0, 0, 1, 30),
           (@oid, 'ManufacturerId', N'厂家',  'bigint',        NULL, 1, 0, 0, 0, 1, 40),
           (@oid, 'Sort',       N'排序',      'int',           NULL, 0, 0, 0, 0, 1, 50),
           (@oid, 'IsEnabled',  N'启用',      'bit',           NULL, 0, 0, 0, 0, 1, 60),
           (@oid, 'CreatedAt',  N'创建时间',  'datetime2(3)',   NULL, 0, 0, 0, 0, 1, 70);

    INSERT plat.Permission (TenantId, ResourceKey, ResourceType, Name, IsEnabled)
    VALUES (1, 'DATA:md.brand', 3, N'数据：品牌', 1);
END
GO

/* 演示数据：租户 1 四个品牌、租户 2 一个独立品牌（用于验证租户隔离） */
IF NOT EXISTS (SELECT 1 FROM md.Brand WHERE TenantId = 1 AND Code = 'B001')
BEGIN
    INSERT md.Brand (TenantId, Code, Name, Sort, IsEnabled, CreatedAt)
    VALUES (1, 'B001', N'农夫山泉', 10, 1, sysutcdatetime()),
           (1, 'B002', N'可口可乐', 20, 1, sysutcdatetime()),
           (1, 'B003', N'伊利',     30, 1, sysutcdatetime()),
           (1, 'B004', N'元气森林', 40, 1, sysutcdatetime());
END
IF NOT EXISTS (SELECT 1 FROM md.Brand WHERE TenantId = 2 AND Code = 'B001')
BEGIN
    INSERT md.Brand (TenantId, Code, Name, Sort, IsEnabled, CreatedAt)
    VALUES (2, 'B001', N'二租户专有品牌', 10, 1, sysutcdatetime());
END
GO

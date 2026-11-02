/* =====================================================================
   V30 · 主子表（明细）级联保存
   ---------------------------------------------------------------------
   1) plat.DataObjectRelation：父对象 → 子对象的关系元数据
      （JSON 别名、子表外键字段、级联删除策略）
   2) md.BrandContact：演示子表（品牌联系人），带外键 + RLS
   3) usp_Meta_Save 改造：强制写入租户字段
      原实现只插入前端提交的字段，TenantId 依赖 DDL 默认值 1；
      租户 2 新增数据会被写成租户 1（越权写入，且唯一键冲突）。
      现改为：对象声明了 TenantField 时，插入强制注入 @TenantId，
      更新追加 "AND TenantId = @TenantId" 作为第二道防线（RLS 是第一道）。
   全部幂等：可重复执行。
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

/* ---------------------------------------------------------------- 1. 关系元数据 */
IF OBJECT_ID('plat.DataObjectRelation', 'U') IS NULL
BEGIN
    CREATE TABLE [plat].[DataObjectRelation] (
        [Id] bigint IDENTITY(1,1) NOT NULL,
        [TenantId] int NOT NULL CONSTRAINT [DF_DataObjectRelation_TenantId] DEFAULT (1),
        [ParentObjectId] bigint NOT NULL,
        [ChildObjectId] bigint NOT NULL,
        [ChildAlias] varchar(60) NOT NULL,
        [ForeignKeyField] varchar(100) NOT NULL,
        [DisplayName] nvarchar(100) NULL,
        [Sort] int NOT NULL CONSTRAINT [DF_DataObjectRelation_Sort] DEFAULT (10),
        /* 1=软删除未提交的子行（默认）；2=不动（子行只能改不能删） */
        [CascadeDelete] tinyint NOT NULL CONSTRAINT [DF_DataObjectRelation_CascadeDelete] DEFAULT (1)
            CONSTRAINT [CK_DataObjectRelation_CascadeDelete] CHECK (CascadeDelete IN (1, 2)),
        [MaxRows] int NOT NULL CONSTRAINT [DF_DataObjectRelation_MaxRows] DEFAULT (500),
        [IsEnabled] bit NOT NULL CONSTRAINT [DF_DataObjectRelation_IsEnabled] DEFAULT (1),
        [Remark] nvarchar(500) NULL,
        [RowVersion] rowversion NOT NULL,
        [IsDeleted] bit NOT NULL CONSTRAINT [DF_DataObjectRelation_IsDeleted] DEFAULT (0),
        [CreatedBy] bigint NULL,
        [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_DataObjectRelation_CreatedAt] DEFAULT (sysutcdatetime()),
        [ModifiedBy] bigint NULL,
        [ModifiedAt] datetime2(3) NULL,
        [DeletedBy] bigint NULL,
        [DeletedAt] datetime2(3) NULL,
        CONSTRAINT [PK_DataObjectRelation] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_DataObjectRelation_Parent] FOREIGN KEY ([ParentObjectId]) REFERENCES [plat].[DataObject] ([Id]),
        CONSTRAINT [FK_DataObjectRelation_Child] FOREIGN KEY ([ChildObjectId]) REFERENCES [plat].[DataObject] ([Id])
    );
    CREATE UNIQUE INDEX [UQ_DataObjectRelation_Alias]
        ON [plat].[DataObjectRelation] ([TenantId], [ParentObjectId], [ChildAlias]) WHERE [IsDeleted] = 0;
    CREATE INDEX [IX_DataObjectRelation_Child] ON [plat].[DataObjectRelation] ([ChildObjectId]);
    EXEC sp_addextendedproperty N'MS_Description', N'主子表关系（父对象 → 子对象 + JSON 别名 + 外键字段）',
        N'SCHEMA', N'plat', N'TABLE', N'DataObjectRelation';
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.security_predicates
               WHERE target_object_id = OBJECT_ID('plat.DataObjectRelation'))
    ALTER SECURITY POLICY plat.TenantPolicy
        ADD FILTER PREDICATE plat.fn_TenantFilter(TenantId) ON [plat].[DataObjectRelation];
GO

/* ---------------------------------------------------------------- 2. 演示子表：品牌联系人 */
IF OBJECT_ID('md.BrandContact', 'U') IS NULL
BEGIN
    CREATE TABLE [md].[BrandContact] (
        [Id] bigint IDENTITY(1,1) NOT NULL,
        [TenantId] int NOT NULL CONSTRAINT [DF_BrandContact_TenantId] DEFAULT (1),
        [BrandId] bigint NOT NULL,
        [ContactName] nvarchar(50) NOT NULL,
        [Mobile] varchar(30) NULL,
        [Email] varchar(100) NULL,
        [IsPrimary] bit NOT NULL CONSTRAINT [DF_BrandContact_IsPrimary] DEFAULT (0),
        [Sort] int NOT NULL CONSTRAINT [DF_BrandContact_Sort] DEFAULT (0),
        [Remark] nvarchar(200) NULL,
        [RowVersion] rowversion NOT NULL,
        [IsDeleted] bit NOT NULL CONSTRAINT [DF_BrandContact_IsDeleted] DEFAULT (0),
        [CreatedBy] bigint NULL,
        [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_BrandContact_CreatedAt] DEFAULT (sysutcdatetime()),
        [ModifiedBy] bigint NULL,
        [ModifiedAt] datetime2(3) NULL,
        [DeletedBy] bigint NULL,
        [DeletedAt] datetime2(3) NULL,
        CONSTRAINT [PK_BrandContact] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_BrandContact_Brand] FOREIGN KEY ([BrandId]) REFERENCES [md].[Brand] ([Id])
    );
    CREATE INDEX [IX_BrandContact_BrandId] ON [md].[BrandContact] ([BrandId]);
    EXEC sp_addextendedproperty N'MS_Description', N'品牌联系人（演示子表）',
        N'SCHEMA', N'md', N'TABLE', N'BrandContact';
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.security_predicates
               WHERE target_object_id = OBJECT_ID('md.BrandContact'))
    ALTER SECURITY POLICY plat.TenantPolicy
        ADD FILTER PREDICATE plat.fn_TenantFilter(TenantId) ON [md].[BrandContact];
GO

/* ---------------------------------------------------------------- 3. 保存引擎：租户字段强制注入 */
CREATE OR ALTER PROCEDURE plat.usp_Meta_Save
    @TenantId   int,
    @UserId     bigint,
    @ObjectCode varchar(60),
    @Json       nvarchar(max),
    @Id         bigint OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @schema varchar(50), @table varchar(100), @pk varchar(100), @objId bigint,
            @readonly bit, @tenantField varchar(100);
    SELECT @schema = SchemaName, @table = ObjectName, @pk = ISNULL(PrimaryKey,'Id'),
           @objId = Id, @readonly = IsReadOnly,
           @tenantField = NULLIF(LTRIM(RTRIM(ISNULL(TenantField, ''))), '')
    FROM plat.DataObject WHERE TenantId = @TenantId AND Code = @ObjectCode AND IsEnabled = 1;
    IF @table IS NULL BEGIN RAISERROR(N'数据对象不存在: %s',16,1,@ObjectCode); RETURN; END
    IF @readonly = 1 BEGIN RAISERROR(N'只读对象不可保存',16,1); RETURN; END

    SELECT @Id = TRY_CAST(JSON_VALUE(@Json, '$.Id') AS bigint);
    DECLARE @isInsert bit = CASE WHEN @Id IS NULL THEN 1 ELSE 0 END;

    /* 值表：仅保留已注册、非主键、非计算字段 */
    CREATE TABLE #kv (FieldName varchar(100) COLLATE DATABASE_DEFAULT PRIMARY KEY,
                      Value nvarchar(max) COLLATE DATABASE_DEFAULT,
                      DataType varchar(40) COLLATE DATABASE_DEFAULT);
    INSERT INTO #kv(FieldName, Value, DataType)
    SELECT f.FieldName, x.v, ISNULL(NULLIF(f.DataType,''),'nvarchar(max)')
    FROM plat.DataObjectField f
    JOIN plat.DataObject o ON o.Id = f.DataObjectId AND o.Code = @ObjectCode
    CROSS APPLY (SELECT j2.[value] AS v FROM OPENJSON(@Json) j2
                 WHERE j2.[key] COLLATE DATABASE_DEFAULT = f.FieldName) x
    WHERE f.IsPrimaryKey = 0 AND ISNULL(f.IsComputed,0) = 0;

    /* 必填校验（新增时） */
    IF @isInsert = 1 AND EXISTS (
        SELECT 1 FROM plat.DataObjectField f
        JOIN plat.DataObject o ON o.Id = f.DataObjectId AND o.Code = @ObjectCode
        WHERE f.IsRequired = 1 AND ISNULL(f.IsComputed,0) = 0
          AND NOT EXISTS (SELECT 1 FROM #kv k WHERE k.FieldName = f.FieldName
                          AND k.Value IS NOT NULL AND k.Value <> N''))
    BEGIN
        DECLARE @miss nvarchar(200) = (SELECT TOP 1 f.DisplayName FROM plat.DataObjectField f
            JOIN plat.DataObject o ON o.Id=f.DataObjectId AND o.Code=@ObjectCode
            WHERE f.IsRequired=1 AND ISNULL(f.IsComputed,0)=0
              AND NOT EXISTS (SELECT 1 FROM #kv k WHERE k.FieldName=f.FieldName
                              AND k.Value IS NOT NULL AND k.Value <> N''));
        RAISERROR(N'必填字段缺失: %s',16,1,@miss); RETURN;
    END

    /* 构建字面量 */
    DECLARE @colList nvarchar(max)=N'', @valList nvarchar(max)=N'', @setList nvarchar(max)=N'';
    DECLARE @f varchar(100), @v nvarchar(max), @typ varchar(40), @lit nvarchar(max);
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT FieldName, Value, DataType FROM #kv ORDER BY FieldName;
    OPEN cur;
    FETCH NEXT FROM cur INTO @f, @v, @typ;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @v IS NULL
            SET @lit = N'NULL';
        ELSE IF @typ = 'bit'
            SET @lit = N'CASE WHEN N''' + REPLACE(@v, N'''', N'''''') + N''' IN (N''true'',N''1'') THEN 1 ELSE 0 END';
        ELSE
            SET @lit = N'TRY_CAST(N''' + REPLACE(@v, N'''', N'''''') + N''' AS ' + @typ + N')';
        SET @colList += QUOTENAME(@f) + N',';
        SET @valList += @lit + N',';
        SET @setList += QUOTENAME(@f) + N' = ' + @lit + N',';
        FETCH NEXT FROM cur INTO @f, @v, @typ;
    END
    CLOSE cur; DEALLOCATE cur;

    /* 租户字段：前端不可指定，插入时强制注入（未登记为字段也能生效） */
    DECLARE @useTenant bit = 0;
    IF @tenantField IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #kv WHERE FieldName = @tenantField)
    BEGIN
        SET @useTenant = 1;
        SET @colList += QUOTENAME(@tenantField) + N',';
        SET @valList += N'@pTenant,';
    END

    IF @colList = N'' BEGIN RAISERROR(N'没有可保存的字段',16,1); RETURN END

    BEGIN TRY
        BEGIN TRAN;
        DECLARE @sql nvarchar(max);
        IF @isInsert = 1
        BEGIN
            SET @sql = N'INSERT INTO ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                     + N' (' + LEFT(@colList, LEN(@colList)-1) + N') VALUES ('
                     + LEFT(@valList, LEN(@valList)-1) + N'); SET @pId = SCOPE_IDENTITY();';
            EXEC sp_executesql @sql, N'@pId bigint OUTPUT, @pTenant int', @pId = @Id OUTPUT, @pTenant = @TenantId;
        END
        ELSE
        BEGIN
            SET @sql = N'UPDATE ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                     + N' SET ' + LEFT(@setList, LEN(@setList)-1)
                     + N' WHERE ' + QUOTENAME(@pk) + N' = @pId';
            IF @tenantField IS NOT NULL
                SET @sql += N' AND ' + QUOTENAME(@tenantField) + N' = @pTenant';
            SET @sql += N';';
            DECLARE @pid2 bigint = @Id;
            EXEC sp_executesql @sql, N'@pId bigint, @pTenant int', @pId = @pid2, @pTenant = @TenantId;
        END

        DECLARE @act tinyint = CASE WHEN @isInsert = 1 THEN 1 ELSE 2 END;
        EXEC plat.usp_Audit_Write @TenantId, @UserId, @act, @ObjectCode, @Id, NULL, @Json;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

/* ---------------------------------------------------------------- 4. 子表对象元数据 */
IF NOT EXISTS (SELECT 1 FROM plat.DataObject WHERE TenantId = 1 AND Code = 'md.brandcontact')
BEGIN
    DECLARE @cid bigint, @pid bigint;

    INSERT plat.DataObject (TenantId, Code, Name, ObjectType, SchemaName, ObjectName, PrimaryKey,
                            OrgField, TenantField, DefaultOrder, IsEnabled, IsDeleted, CreatedAt)
    VALUES (1, 'md.brandcontact', N'品牌联系人', 1, 'md', 'BrandContact', 'Id',
            NULL, 'TenantId', 'Sort', 1, 0, sysutcdatetime());
    SET @cid = SCOPE_IDENTITY();

    INSERT plat.DataObjectField (DataObjectId, FieldName, DisplayName, DataType, MaxLength,
                                 IsNullable, IsPrimaryKey, IsIdentity, IsRequired, IsVisible, Sort)
    VALUES (@cid, 'Id',          N'主键',   'bigint',        NULL, 0, 1, 1, 0, 1,  0),
           (@cid, 'BrandId',     N'品牌',   'bigint',        NULL, 0, 0, 0, 1, 1, 10),
           (@cid, 'ContactName', N'联系人', 'nvarchar(50)',  50,   0, 0, 0, 1, 1, 20),
           (@cid, 'Mobile',      N'手机',   'varchar(30)',   30,   1, 0, 0, 0, 1, 30),
           (@cid, 'Email',       N'邮箱',   'varchar(100)',  100,  1, 0, 0, 0, 1, 40),
           (@cid, 'IsPrimary',   N'主联系人', 'bit',         NULL, 0, 0, 0, 0, 1, 50),
           (@cid, 'Sort',        N'排序',   'int',           NULL, 0, 0, 0, 0, 1, 60),
           (@cid, 'Remark',      N'备注',   'nvarchar(200)', 200,  1, 0, 0, 0, 1, 70);

    /* 列表视图：子表在单据里以表格呈现 */
    DECLARE @vid bigint;
    INSERT plat.ListView (TenantId, Code, Name, DataObjectId, PageSize, DefaultSort, IsDefault,
                          IsEnabled, IsDeleted, CreatedAt)
    VALUES (1, 'lv.brandcontact', N'品牌联系人列表', @cid, 50, N'Sort,Id', 1, 1, 0, sysutcdatetime());
    SET @vid = SCOPE_IDENTITY();
    INSERT plat.ListViewColumn (ListViewId, FieldName, Title, Width, Align, Sort, IsVisible)
    VALUES (@vid, 'ContactName', N'联系人', 140, 1, 10, 1),
           (@vid, 'Mobile',      N'手机',   140, 1, 20, 1),
           (@vid, 'Email',       N'邮箱',   180, 1, 30, 1),
           (@vid, 'IsPrimary',   N'主联系人', 100, 2, 40, 1);

    /* 表单布局：联系人编辑 */
    DECLARE @fid bigint;
    INSERT plat.FormLayout (TenantId, Code, Name, DataObjectId, Mode, Columns, IsDefault,
                            IsEnabled, IsDeleted, CreatedAt)
    VALUES (1, 'fl.brandcontact', N'品牌联系人表单', @cid, 1, 2, 1, 1, 0, sysutcdatetime());
    SET @fid = SCOPE_IDENTITY();
    INSERT plat.FormField (FormLayoutId, FieldName, Label, ControlType, Row, Col, Span,
                           IsRequired, GroupName, Sort)
    VALUES (@fid, 'ContactName', N'联系人',  1, 0, 0, 6, 1, N'基本信息', 10),
           (@fid, 'Mobile',      N'手机',    1, 0, 6, 6, 0, N'基本信息', 20),
           (@fid, 'Email',       N'邮箱',    1, 1, 0, 6, 0, N'基本信息', 30),
           (@fid, 'IsPrimary',   N'主联系人', 5, 1, 6, 6, 0, N'基本信息', 40),
           (@fid, 'Sort',        N'排序',    2, 2, 0, 6, 0, N'其它',     50),
           (@fid, 'Remark',      N'备注',    1, 2, 6, 12, 0, N'其它',    60);

    INSERT plat.Permission (TenantId, ResourceKey, ResourceType, Name, IsEnabled)
    VALUES (1, 'DATA:md.brandcontact', 3, N'数据：品牌联系人', 1);

    /* 父对象 = 品牌；JSON 里用 Contacts 承载子行 */
    SELECT @pid = Id FROM plat.DataObject WHERE TenantId = 1 AND Code = 'md.brand';
    IF @pid IS NOT NULL
        INSERT plat.DataObjectRelation (TenantId, ParentObjectId, ChildObjectId, ChildAlias,
                                        ForeignKeyField, DisplayName, Sort, CascadeDelete, MaxRows,
                                        IsEnabled, IsDeleted, CreatedAt)
        VALUES (1, @pid, @cid, 'Contacts', 'BrandId', N'联系人', 10, 1, 200, 1, 0, sysutcdatetime());
END
GO

/* ---------------------------------------------------------------- 5. 演示子表数据 */
IF NOT EXISTS (SELECT 1 FROM md.BrandContact WHERE TenantId = 1 AND ContactName = N'张三')
BEGIN
    DECLARE @b1 bigint = (SELECT Id FROM md.Brand WHERE TenantId = 1 AND Code = 'B001');
    IF @b1 IS NOT NULL
        INSERT md.BrandContact (TenantId, BrandId, ContactName, Mobile, Email, IsPrimary, Sort, CreatedAt)
        VALUES (1, @b1, N'张三', '13800000001', 'zhangsan@example.com', 1, 10, sysutcdatetime()),
               (1, @b1, N'李四', '13800000002', NULL, 0, 20, sysutcdatetime());
END
GO

/* 修复数据范围 scope=4（自定义）分支：
   原写法把存储过程变量 @TenantId/@UserId 拼进了动态 SQL，而 sp_executesql 只声明了
   @pTenant/@pUser，执行时报"必须声明标量变量 @TenantId"。
   改为在静态 SQL 里取到组织列表，再把数字列表安全嵌入。 */
SET NOCOUNT ON;
GO
/* --------------------------------------------------------------- 列表查询 */
CREATE OR ALTER PROCEDURE plat.usp_Meta_List
    @TenantId   int,
    @UserId     bigint,
    @ObjectCode varchar(60),
    @Filters    nvarchar(max) = NULL,   -- [{"f":"Name","op":"like","v":"abc"}]
    @Sort       varchar(200) = NULL,
    @Page       int = 1,
    @PageSize   int = 50,
    @TotalRows  int = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @schema varchar(50), @table varchar(100), @pk varchar(100),
            @orgField varchar(100), @tenantField varchar(100), @statusField varchar(100),
            @baseWhere nvarchar(500), @defaultOrder varchar(300), @readonly bit;

    SELECT @schema = SchemaName, @table = ObjectName, @pk = ISNULL(PrimaryKey,'Id'),
           @orgField = OrgField, @tenantField = TenantField, @statusField = StatusField,
           @baseWhere = BaseWhere, @defaultOrder = DefaultOrder, @readonly = IsReadOnly
    FROM plat.DataObject
    WHERE TenantId = @TenantId AND Code = @ObjectCode AND IsEnabled = 1;

    IF @table IS NULL
    BEGIN
        RAISERROR(N'数据对象不存在: %s', 16, 1, @ObjectCode);
        RETURN;
    END

    /* 字段白名单 */
    DECLARE @cols nvarchar(max) = N'';
    SELECT @cols = @cols + QUOTENAME(FieldName) + N','
    FROM plat.DataObjectField f
    JOIN plat.DataObject o ON o.Id = f.DataObjectId
    WHERE o.Code = @ObjectCode AND f.IsVisible = 1
    ORDER BY f.Sort;
    IF @cols = N'' SET @cols = N'*';
    ELSE SET @cols = LEFT(@cols, LEN(@cols) - 1);

    /* 条件 */
    DECLARE @where nvarchar(max) = N' WHERE 1=1';
    IF @tenantField IS NOT NULL AND @tenantField <> ''
        SET @where += N' AND t.' + QUOTENAME(@tenantField) + N' = @pTenant';
    IF EXISTS (SELECT 1 FROM plat.DataObjectField f JOIN plat.DataObject o ON o.Id=f.DataObjectId
               WHERE o.Code=@ObjectCode AND f.FieldName='IsDeleted')
        SET @where += N' AND t.[IsDeleted] = 0';
    IF @baseWhere IS NOT NULL AND @baseWhere <> ''
        SET @where += N' AND (' + @baseWhere + N')';

    /* 数据权限：按用户在该对象上的有效数据范围过滤
       0=无权限(看不到任何数据) 1=全部 2/3=组织范围 4=自定义 5=仅本人 */
    IF @orgField IS NOT NULL AND @orgField <> ''
    BEGIN
        DECLARE @scope tinyint = plat.ufn_Perm_DataScope(@TenantId, @UserId, 'DATA:' + @ObjectCode);
        IF @scope = 0
            SET @where += N' AND 1 = 0';
        ELSE IF @scope = 1
            SET @where += N'';   -- 全部数据：不加条件
        ELSE IF @scope = 4
        BEGIN
            /* 自定义范围：先在静态 SQL 里取到组织列表，再把"数字列表"安全地嵌入动态 SQL。
               注意不能把 @TenantId/@UserId 写进动态 SQL —— 那里只有 @pTenant/@pUser。 */
            DECLARE @ids varchar(2000) = plat.ufn_Perm_ScopeOrgIds(@TenantId, @UserId, 'DATA:' + @ObjectCode);
            IF @ids IS NULL OR LTRIM(RTRIM(@ids)) = ''
                SET @where += N' AND 1 = 0';
            ELSE
                SET @where += N' AND t.' + QUOTENAME(@orgField)
                             + N' IN (SELECT TRY_CAST(value AS int) FROM STRING_SPLIT(N'''
                             + REPLACE(@ids, N'''', N'''''') + N''', '',''))';
        END
        ELSE IF @scope = 5
            SET @where += N' AND t.[CreatedBy] = @pUser';
        ELSE
            SET @where += N' AND (t.' + QUOTENAME(@orgField) + N' IS NULL OR EXISTS (SELECT 1 FROM plat.ufn_Perm_OrgIds(@pUser) p WHERE p.OrgId = t.' + QUOTENAME(@orgField) + N'))';
    END

    /* 用户筛选：只接受已注册字段 */
    IF @Filters IS NOT NULL AND LEN(@Filters) > 2
    BEGIN
        SELECT @where += N' AND ' + QUOTENAME(j.f) + CASE j.op
                WHEN 'eq'      THEN N' = '
                WHEN 'neq'     THEN N' <> '
                WHEN 'gt'      THEN N' > '
                WHEN 'gte'     THEN N' >= '
                WHEN 'lt'      THEN N' < '
                WHEN 'lte'     THEN N' <= '
                WHEN 'like'    THEN N' LIKE '
                WHEN 'in'      THEN N' IN '
                WHEN 'between' THEN N' BETWEEN '
                ELSE N' = ' END
            + CASE j.op
                WHEN 'like'    THEN N'N''%' + REPLACE(COALESCE(j.v,''), N'''', N'''''') + N'%'''
                WHEN 'in'      THEN COALESCE(j.v, N'(0)')
                WHEN 'between' THEN COALESCE(j.v, N'0 AND 0')
                ELSE N'N''' + REPLACE(COALESCE(j.v,''), N'''', N'''''') + N'''' END
        FROM OPENJSON(@Filters) WITH (f varchar(100) '$.f', op varchar(20) '$.op', v nvarchar(300) '$.v') j
        JOIN plat.DataObject o ON o.Code = @ObjectCode
        JOIN plat.DataObjectField df ON df.DataObjectId = o.Id AND df.FieldName = j.f COLLATE DATABASE_DEFAULT;
    END

    /* 排序 */
    DECLARE @order nvarchar(300);
    IF @Sort IS NOT NULL AND @Sort <> ''
    BEGIN
        SET @order = N'';
        SELECT @order += QUOTENAME(s.value) + N' ASC,'
        FROM STRING_SPLIT(@Sort, ',') s
        JOIN plat.DataObject o ON o.Code = @ObjectCode
        JOIN plat.DataObjectField f ON f.DataObjectId = o.Id AND f.FieldName = LTRIM(RTRIM(s.value)) COLLATE DATABASE_DEFAULT;
        IF @order <> N'' SET @order = N' ORDER BY ' + LEFT(@order, LEN(@order)-1);
    END
    IF @order IS NULL
        SET @order = N' ORDER BY t.' + QUOTENAME(@pk) + N' DESC';

    IF @Page < 1 SET @Page = 1;
    IF @PageSize < 1 SET @PageSize = 50;
    IF @PageSize > 500 SET @PageSize = 500;

    DECLARE @sql nvarchar(max) = N'
        SELECT @pTotal = COUNT(1) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N' t' + @where + N';
        SELECT ' + @cols + N' FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N' t'
        + @where + @order + N' OFFSET ' + CAST((@Page-1)*@PageSize AS varchar(10))
        + N' ROWS FETCH NEXT ' + CAST(@PageSize AS varchar(10)) + N' ROWS ONLY;';

    EXEC sp_executesql @sql,
        N'@pTenant int, @pUser bigint, @pTotal int OUTPUT',
        @pTenant = @TenantId, @pUser = @UserId, @pTotal = @TotalRows OUTPUT;
END
GO

/* 列表引擎的数据范围过滤：真正使用 RolePermission.DataScope
   ------------------------------------------------------------------
   原实现无视 DataScope，一律按 ufn_Perm_OrgIds 过滤，导致：
   1) 权限为"全部数据"的用户被错误收窄；
   2) 管理员未分配组织时反而看不到任何组织数据。
   本脚本新增 ufn_Perm_DataScope，并改写 usp_Meta_List 的数据权限分支。 */
SET NOCOUNT ON;
GO
IF OBJECT_ID('plat.ufn_Perm_DataScope') IS NOT NULL
    DROP FUNCTION plat.ufn_Perm_DataScope;
GO
CREATE FUNCTION plat.ufn_Perm_DataScope
(
    @TenantId int,
    @UserId   bigint,
    @ResourceKey varchar(120)
)
RETURNS tinyint
AS
BEGIN
    /* SYSADMIN 直通：全部数据 */
    IF EXISTS (SELECT 1 FROM plat.[User] u
               WHERE u.Id = @UserId AND u.UserType = 1
                 AND EXISTS (SELECT 1 FROM plat.UserRole ur JOIN plat.Role r ON r.Id = ur.RoleId
                             WHERE ur.UserId = @UserId AND r.Code = 'SYSADMIN'))
        RETURN 1;

    DECLARE @scope tinyint;
    /* 多角色取最宽：DataScope 数字越小范围越大 */
    SELECT @scope = MIN(rp.DataScope)
    FROM plat.UserRole ur
    JOIN plat.RolePermission rp ON rp.RoleId = ur.RoleId AND rp.Allow = 1
    JOIN plat.Permission p ON p.Id = rp.PermissionId
    WHERE ur.UserId = @UserId
      AND rp.TenantId = @TenantId
      AND p.ResourceKey = @ResourceKey
      AND p.IsEnabled = 1
      AND rp.CanRead = 1;

    RETURN ISNULL(@scope, 0);   -- 没有任何授权 -> 0，看不到数据
END
GO
IF OBJECT_ID('plat.ufn_Perm_ScopeOrgIds') IS NOT NULL
    DROP FUNCTION plat.ufn_Perm_ScopeOrgIds;
GO
CREATE FUNCTION plat.ufn_Perm_ScopeOrgIds
(
    @TenantId int,
    @UserId   bigint,
    @ResourceKey varchar(120)
)
RETURNS varchar(2000)
AS
BEGIN
    /* 自定义数据范围：取该资源上最宽（DataScope 最小）那条授权的 ScopeOrgIds */
    DECLARE @ids varchar(2000);
    SELECT TOP 1 @ids = rp.ScopeOrgIds
    FROM plat.UserRole ur
    JOIN plat.RolePermission rp ON rp.RoleId = ur.RoleId AND rp.Allow = 1
    JOIN plat.Permission p ON p.Id = rp.PermissionId
    WHERE ur.UserId = @UserId AND rp.TenantId = @TenantId
      AND p.ResourceKey = @ResourceKey AND p.IsEnabled = 1 AND rp.CanRead = 1
    ORDER BY rp.DataScope;
    RETURN ISNULL(@ids, '');
END
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
            SET @where += N' AND t.' + QUOTENAME(@orgField) + N' IN (SELECT TRY_CAST(value AS int) FROM STRING_SPLIT(plat.ufn_Perm_ScopeOrgIds(@TenantId, @UserId, ''DATA:'' + @ObjectCode), '',''))';
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
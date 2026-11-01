/* usp_Meta_Save v2：基于元数据的安全保存（值以转义字面量拼接，类型由元数据决定） */
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

    DECLARE @schema varchar(50), @table varchar(100), @pk varchar(100), @objId bigint, @readonly bit;
    SELECT @schema = SchemaName, @table = ObjectName, @pk = ISNULL(PrimaryKey,'Id'),
           @objId = Id, @readonly = IsReadOnly
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

    IF @colList = N'' BEGIN RAISERROR(N'没有可保存的字段',16,1); RETURN; END

    BEGIN TRY
        BEGIN TRAN;
        DECLARE @sql nvarchar(max);
        IF @isInsert = 1
        BEGIN
            SET @sql = N'INSERT INTO ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                     + N' (' + LEFT(@colList, LEN(@colList)-1) + N') VALUES ('
                     + LEFT(@valList, LEN(@valList)-1) + N'); SET @pId = SCOPE_IDENTITY();';
            EXEC sp_executesql @sql, N'@pId bigint OUTPUT', @pId = @Id OUTPUT;
        END
        ELSE
        BEGIN
            SET @sql = N'UPDATE ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                     + N' SET ' + LEFT(@setList, LEN(@setList)-1)
                     + N' WHERE ' + QUOTENAME(@pk) + N' = @pId;';
            DECLARE @pid2 bigint = @Id;
            EXEC sp_executesql @sql, N'@pId bigint', @pId = @pid2;
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

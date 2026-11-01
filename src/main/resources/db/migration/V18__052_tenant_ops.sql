/* =====================================================================
   多租户运维工具：上下文设置 / 租户级导出 / 行数核对
   仅限运维与迁移使用（需要 db_ddladmin 以上权限）
   ===================================================================== */
SET NOCOUNT ON;
GO

/* 1) 应用连接上下文：每个连接打开后必须调用一次
      - 设置 TenantId 后，RLS 只放行该租户的数据
      - @Bypass = 1 仅用于运维/迁移，业务连接禁止使用 */
CREATE OR ALTER PROCEDURE plat.usp_TenantContext
    @TenantId int = NULL,
    @UserId   bigint = NULL,
    @Bypass   bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @bp int = CASE WHEN @Bypass = 1 THEN 1 ELSE 0 END;
    EXEC sys.sp_set_session_context N'TenantId', @TenantId;
    EXEC sys.sp_set_session_context N'UserId', @UserId;
    EXEC sys.sp_set_session_context N'BypassRls', @bp;
    SELECT CAST(SESSION_CONTEXT(N'TenantId') AS int) AS TenantId,
           CAST(SESSION_CONTEXT(N'UserId') AS bigint) AS UserId,
           CAST(SESSION_CONTEXT(N'BypassRls') AS int) AS BypassRls;
END
GO

/* 2) 租户级导出：把某租户的全部数据复制到指定架构（默认 exp）下的 schema_table 表
      导出后可用 BACPAC / bcp / 生成脚本 带走，用于大客户迁库、单租户备份、合规审计 */
CREATE OR ALTER PROCEDURE plat.usp_Tenant_Export
    @TenantId int,
    @Schema   sysname = 'exp',
    @IncludeEmpty bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @TenantId IS NULL BEGIN RAISERROR(N'必须指定租户',16,1); RETURN; END

    DECLARE @prevBypass int = CAST(SESSION_CONTEXT(N'BypassRls') AS int);
    EXEC sys.sp_set_session_context N'BypassRls', 1;

    IF SCHEMA_ID(@Schema) IS NULL
        EXEC('CREATE SCHEMA [' + @Schema + ']');

    DECLARE @manifestName nvarchar(200) = @Schema + N'._manifest';
    IF OBJECT_ID(@manifestName) IS NULL
        EXEC('CREATE TABLE [' + @Schema + N']._manifest(TableName sysname, [RowCount] bigint, ExportedAt datetime2(3) DEFAULT sysutcdatetime())');
    ELSE
        EXEC('TRUNCATE TABLE [' + @Schema + N']._manifest');

    DECLARE @sch sysname, @tbl sysname, @target nvarchar(300), @sql nvarchar(max), @cnt bigint;
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT s.name, t.name
        FROM sys.tables t
        JOIN sys.schemas s ON s.schema_id = t.schema_id
        WHERE EXISTS (SELECT 1 FROM sys.columns c
                      WHERE c.object_id = t.object_id AND c.name = N'TenantId')
          AND s.name <> @Schema
          AND t.is_ms_shipped = 0
        ORDER BY s.name, t.name;

    OPEN cur;
    FETCH NEXT FROM cur INTO @sch, @tbl;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @target = N'[' + @Schema + N'].[' + @sch + N'_' + @tbl + N']';
        DECLARE @existName nvarchar(300) = @Schema + N'.' + @sch + N'_' + @tbl;
        IF OBJECT_ID(@existName) IS NOT NULL
            EXEC(N'DROP TABLE ' + @target);

        SET @sql = N'SELECT @c = COUNT_BIG(1) FROM [' + @sch + N'].[' + @tbl + N'] WHERE TenantId = @p;';
        EXEC sp_executesql @sql, N'@p int, @c bigint OUTPUT', @p = @TenantId, @c = @cnt OUTPUT;

        IF @cnt > 0 OR @IncludeEmpty = 1
        BEGIN
            SET @sql = N'SELECT * INTO ' + @target + N' FROM [' + @sch + N'].[' + @tbl
                     + N'] WHERE TenantId = @p;';
            EXEC sp_executesql @sql, N'@p int', @p = @TenantId;
            SET @sql = N'INSERT INTO [' + @Schema + N']._manifest(TableName, [RowCount]) VALUES(@n, @c);';
            DECLARE @tblFull sysname = @sch + N'.' + @tbl;
            EXEC sp_executesql @sql, N'@n sysname, @c bigint', @n = @tblFull, @c = @cnt;
        END
        FETCH NEXT FROM cur INTO @sch, @tbl;
    END
    CLOSE cur; DEALLOCATE cur;

    EXEC sys.sp_set_session_context N'BypassRls', @prevBypass;

    DECLARE @msql nvarchar(300) = N'SELECT TableName, [RowCount], ExportedAt FROM [' + @Schema + N']._manifest ORDER BY TableName;';
    EXEC sp_executesql @msql;
END
GO

/* 3) 租户行数核对：迁移双跑时用于逐表比对 */
CREATE OR ALTER PROCEDURE plat.usp_Tenant_RowCount
    @TenantId int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @prevBypass int = CAST(SESSION_CONTEXT(N'BypassRls') AS int);
    EXEC sys.sp_set_session_context N'BypassRls', 1;

    CREATE TABLE #rc (SchemaName sysname, TableName sysname, [RowCount] bigint);

    DECLARE @sch sysname, @tbl sysname, @sql nvarchar(max), @cnt bigint;
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT s.name, t.name FROM sys.tables t
        JOIN sys.schemas s ON s.schema_id = t.schema_id
        WHERE EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id=t.object_id AND c.name=N'TenantId')
          AND t.is_ms_shipped = 0
        ORDER BY s.name, t.name;
    OPEN cur;
    FETCH NEXT FROM cur INTO @sch, @tbl;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = N'SELECT @c = COUNT_BIG(1) FROM [' + @sch + N'].[' + @tbl + N'] WHERE TenantId = @p;';
        EXEC sp_executesql @sql, N'@p int, @c bigint OUTPUT', @p = @TenantId, @c = @cnt OUTPUT;
        IF @cnt > 0
            INSERT INTO #rc VALUES(@sch, @tbl, @cnt);
        FETCH NEXT FROM cur INTO @sch, @tbl;
    END
    CLOSE cur; DEALLOCATE cur;

    EXEC sys.sp_set_session_context N'BypassRls', @prevBypass;
    SELECT SchemaName, TableName, [RowCount] FROM #rc ORDER BY SchemaName, TableName;
    SELECT COUNT(1) AS TableCount, SUM([RowCount]) AS TotalRows FROM #rc;
END
GO

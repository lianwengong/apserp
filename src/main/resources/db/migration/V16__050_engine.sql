/* =====================================================================
   引擎层：元数据驱动的通用服务
   设计原则：
     1) 一切动态 SQL 只允许使用「已注册」的字段与对象，杜绝拼接注入；
     2) 数据权限、软删除、租户隔离由引擎统一注入，业务代码不得绕过；
     3) 审批/编号/审计为平台服务，业务对象通过元数据绑定。
   ===================================================================== */
SET NOCOUNT ON;
GO

/* --------------------------------------------------------------- 权限 */
CREATE OR ALTER FUNCTION plat.ufn_Perm_Check
(
    @TenantId int,
    @UserId   bigint,
    @ResourceKey varchar(120),
    @Action   varchar(20) = 'read'   -- read/write/approve/export/delete
)
RETURNS bit
AS
BEGIN
    IF EXISTS (SELECT 1 FROM plat.[User] u WHERE u.Id = @UserId AND u.UserType = 1
               AND EXISTS (SELECT 1 FROM plat.UserRole ur JOIN plat.Role r ON r.Id = ur.RoleId
                           WHERE ur.UserId = @UserId AND r.Code = 'SYSADMIN'))
        RETURN 1;

    DECLARE @ok bit = 0;
    SELECT @ok = 1
    FROM plat.UserRole ur
    JOIN plat.RolePermission rp ON rp.RoleId = ur.RoleId
    JOIN plat.Permission p ON p.Id = rp.PermissionId
    WHERE ur.UserId = @UserId
      AND rp.TenantId = @TenantId
      AND p.ResourceKey = @ResourceKey
      AND p.IsEnabled = 1
      AND rp.Allow = 1
      AND (   (@Action = 'read'    AND rp.CanRead = 1)
           OR (@Action = 'write'   AND rp.CanWrite = 1)
           OR (@Action = 'approve' AND rp.CanApprove = 1)
           OR (@Action = 'export'  AND rp.CanExport = 1)
           OR (@Action = 'delete'  AND rp.CanDelete = 1));
    RETURN ISNULL(@ok, 0);
END
GO

/* 用户可见组织范围（含下级） */
CREATE OR ALTER FUNCTION plat.ufn_Perm_OrgIds(@UserId bigint)
RETURNS TABLE
AS
RETURN
    WITH base AS (
        SELECT o.Id, o.Path, uo.IncludeChild
        FROM plat.UserOrg uo JOIN plat.Org o ON o.Id = uo.OrgId
        WHERE uo.UserId = @UserId
    )
    SELECT o.Id AS OrgId
    FROM plat.Org o
    WHERE EXISTS (SELECT 1 FROM base b
                  WHERE o.Id = b.Id
                     OR (b.IncludeChild = 1 AND o.Path LIKE b.Path + '%'))
GO

/* --------------------------------------------------------------- 编号 */
CREATE OR ALTER PROCEDURE plat.usp_CodeRule_Next
    @TenantId int,
    @RuleCode varchar(60),
    @DocNo    varchar(60) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @RuleId bigint, @Cycle tinyint, @Sep varchar(5), @Period varchar(20);
    SELECT @RuleId = Id, @Cycle = ResetCycle, @Sep = ISNULL(Separator, '')
    FROM plat.CodeRule WHERE TenantId = @TenantId AND Code = @RuleCode AND IsEnabled = 1;

    IF @RuleId IS NULL
    BEGIN
        RAISERROR(N'编码规则不存在: %s', 16, 1, @RuleCode);
        RETURN;
    END

    SET @Period = CASE @Cycle WHEN 1 THEN CONVERT(varchar(4), GETDATE(), 112)
                              WHEN 2 THEN CONVERT(varchar(6), GETDATE(), 112)
                              WHEN 3 THEN CONVERT(varchar(8), GETDATE(), 112)
                              ELSE 'ALL' END;

    DECLARE @val bigint;
    UPDATE plat.CodeSeed WITH (UPDLOCK, ROWLOCK)
       SET @val = CurrentValue = CurrentValue + 1
     WHERE TenantId = @TenantId AND CodeRuleId = @RuleId AND PeriodKey = @Period;

    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO plat.CodeSeed(TenantId, CodeRuleId, PeriodKey, CurrentValue)
        VALUES(@TenantId, @RuleId, @Period, 1);
        SET @val = 1;
    END

    DECLARE @out nvarchar(200) = N'';
    DECLARE @seq int, @segType tinyint, @fmt varchar(30), @len int, @pad char(1), @src varchar(100);
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT Seq, SegmentType, Format, ISNULL(Length,4), ISNULL(PadChar,'0'), ValueSource
        FROM plat.CodeRuleSegment WHERE CodeRuleId = @RuleId ORDER BY Seq;
    OPEN cur;
    FETCH NEXT FROM cur INTO @seq, @segType, @fmt, @len, @pad, @src;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @out = @out + CASE @segType
            WHEN 1 THEN ISNULL(@fmt, '')                        -- 固定文本
            WHEN 2 THEN FORMAT(GETDATE(), ISNULL(@fmt,'yyyyMMdd'))
            WHEN 3 THEN RIGHT(REPLICATE(@pad, @len) + CAST(@val AS varchar(20)), @len)
            WHEN 6 THEN ISNULL(@fmt, '')
            ELSE '' END;
        IF @seq > 0 AND @Sep <> '' AND @segType <> 3 SET @out = @out;
        FETCH NEXT FROM cur INTO @seq, @segType, @fmt, @len, @pad, @src;
    END
    CLOSE cur; DEALLOCATE cur;

    SET @DocNo = CONVERT(varchar(60), @out);
END
GO

/* --------------------------------------------------------------- 审计 */
CREATE OR ALTER PROCEDURE plat.usp_Audit_Write
    @TenantId   int,
    @UserId     bigint = NULL,
    @ActionType tinyint,
    @ObjectType varchar(60),
    @ObjectId   bigint = NULL,
    @ObjectNo   varchar(60) = NULL,
    @Changes    nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO plat.AuditLog(TenantId, UserId, UserName, ActionType, ObjectType, ObjectId, ObjectNo, FieldChanges)
    SELECT @TenantId, @UserId, ISNULL(u.DisplayName, u.UserName), @ActionType, @ObjectType, @ObjectId, @ObjectNo, @Changes
    FROM (SELECT 1 AS x) d
    LEFT JOIN plat.[User] u ON u.Id = @UserId;
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

    /* 数据权限（组织范围） */
    IF @orgField IS NOT NULL AND @orgField <> ''
    BEGIN
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

/* --------------------------------------------------------------- 单条读取 */
CREATE OR ALTER PROCEDURE plat.usp_Meta_Get
    @TenantId int, @ObjectCode varchar(60), @Id bigint
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @schema varchar(50), @table varchar(100), @pk varchar(100);
    SELECT @schema = SchemaName, @table = ObjectName, @pk = ISNULL(PrimaryKey,'Id')
    FROM plat.DataObject WHERE TenantId = @TenantId AND Code = @ObjectCode;
    IF @table IS NULL BEGIN RAISERROR(N'数据对象不存在',16,1); RETURN; END

    DECLARE @sql nvarchar(max) = N'SELECT * FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
        + N' WHERE ' + QUOTENAME(@pk) + N' = @pId;';
    EXEC sp_executesql @sql, N'@pId bigint', @pId = @Id;
END
GO

/* --------------------------------------------------------------- 保存 */
CREATE OR ALTER PROCEDURE plat.usp_Meta_Save
    @TenantId   int,
    @UserId     bigint,
    @ObjectCode varchar(60),
    @Json       nvarchar(max),          -- {"Id":1,"Name":"x"}  无 Id 则新增
    @Id         bigint OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @schema varchar(50), @table varchar(100), @pk varchar(100), @objId bigint;
    SELECT @schema = SchemaName, @table = ObjectName, @pk = ISNULL(PrimaryKey,'Id'), @objId = Id
    FROM plat.DataObject WHERE TenantId = @TenantId AND Code = @ObjectCode AND IsEnabled = 1;
    IF @table IS NULL BEGIN RAISERROR(N'数据对象不存在',16,1); RETURN; END
    IF EXISTS (SELECT 1 FROM plat.DataObject WHERE Id = @objId AND IsReadOnly = 1)
    BEGIN RAISERROR(N'只读对象不可保存',16,1); RETURN; END

    SELECT @Id = TRY_CAST(JSON_VALUE(@Json, '$.Id') AS bigint);
    DECLARE @isInsert bit = CASE WHEN @Id IS NULL THEN 1 ELSE 0 END;

    /* 值表：仅保留已注册且非计算/非主键字段 */
    CREATE TABLE #kv (FieldName varchar(100) COLLATE DATABASE_DEFAULT PRIMARY KEY, Value nvarchar(max) COLLATE DATABASE_DEFAULT);
    INSERT INTO #kv(FieldName, Value)
    SELECT f.FieldName, j.v
    FROM plat.DataObjectField f
    JOIN plat.DataObject o ON o.Id = f.DataObjectId AND o.Code = @ObjectCode
    CROSS APPLY (SELECT j2.[value] FROM OPENJSON(@Json) j2 WHERE j2.[key] COLLATE DATABASE_DEFAULT = f.FieldName) x
    CROSS APPLY (SELECT x.[value] AS v) j
    WHERE f.IsPrimaryKey = 0 AND ISNULL(f.IsComputed,0) = 0;

    /* 必填校验 */
    IF EXISTS (SELECT 1 FROM plat.DataObjectField f
               JOIN plat.DataObject o ON o.Id = f.DataObjectId AND o.Code = @ObjectCode
               WHERE f.IsRequired = 1 AND ISNULL(f.IsComputed,0) = 0
                 AND NOT EXISTS (SELECT 1 FROM #kv k WHERE k.FieldName = f.FieldName AND k.Value IS NOT NULL AND k.Value <> N''))
       AND @Id IS NULL
    BEGIN
        RAISERROR(N'必填字段缺失',16,1); RETURN;
    END

    /* 业务规则（保存前校验类） */
    IF EXISTS (
        SELECT 1 FROM plat.RuleBinding rb
        JOIN plat.BizRule r ON r.Id = rb.RuleId
        JOIN plat.DataObject o ON o.Id = rb.DataObjectId
        WHERE o.Code = @ObjectCode AND r.IsEnabled = 1 AND rb.IsEnabled = 1
          AND r.RuleType NOT IN (10) AND rb.TriggerEvent IN (1,5)
          AND r.Expression IS NOT NULL
    )
    BEGIN
        /* 规则表达式由 Rule.Expression 提供布尔判断，交由引擎执行；此处保留扩展点 */
        DECLARE @ruleCount int = (SELECT COUNT(1) FROM plat.RuleBinding rb
            JOIN plat.BizRule r ON r.Id = rb.RuleId JOIN plat.DataObject o ON o.Id = rb.DataObjectId
            WHERE o.Code = @ObjectCode AND r.IsEnabled = 1 AND rb.IsEnabled = 1);
        IF @ruleCount > 0 AND EXISTS (SELECT 1 FROM plat.Setting s WHERE s.TenantId=@TenantId AND s.[Key]='Meta.StrictRules' AND s.Value='1')
        BEGIN
            RAISERROR(N'存在未实现的服务端规则，已阻止保存',16,1); RETURN;
        END
    END

    BEGIN TRY
        BEGIN TRAN;

        IF @Id IS NULL
        BEGIN
            DECLARE @colList nvarchar(max) = N'', @valList nvarchar(max) = N'';
            DECLARE @f varchar(100), @v nvarchar(max), @typ varchar(30);
            DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
                SELECT k.FieldName, k.Value, f.DataType
                FROM #kv k JOIN plat.DataObjectField f ON f.FieldName = k.FieldName
                JOIN plat.DataObject o ON o.Id = f.DataObjectId AND o.Code = @ObjectCode;
            OPEN cur;
            FETCH NEXT FROM cur INTO @f, @v, @typ;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @colList += QUOTENAME(@f) + N',';
                SET @valList += N'TRY_CAST(@v_' + @f + N' AS ' + @typ + N'),';
                FETCH NEXT FROM cur INTO @f, @v, @typ;
            END
            CLOSE cur; DEALLOCATE cur;

            DECLARE @sql nvarchar(max) = N'INSERT INTO ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                + N' (' + LEFT(@colList, LEN(@colList)-1) + N') VALUES (' + LEFT(@valList, LEN(@valList)-1) + N');'
                + N' SET @pId = SCOPE_IDENTITY();';
            /* 参数化：把 #kv 的值转成 sp_executesql 参数 */
            DECLARE @params nvarchar(max) = N'@pId bigint OUTPUT', @decl nvarchar(max) = N'';
            SELECT @params += N', @v_' + k.FieldName + N' nvarchar(max)', @decl += N''
            FROM #kv k;
            /* 逐参数赋值：用一个动态语句块绑定 */
            DECLARE @setv nvarchar(max) = N'';
            SELECT @setv += N'SET @v_' + k.FieldName + N' = ' + N'N''' + REPLACE(k.Value, N'''', N'''''') + N''';' FROM #kv k;
            SET @sql = @setv + @sql;
            EXEC sp_executesql @sql, @params, @pId = @Id OUTPUT;
            SET @Id = @Id;
        END
        ELSE
        BEGIN
            DECLARE @setList nvarchar(max) = N'', @p2 nvarchar(max) = N'@pId bigint', @setv2 nvarchar(max) = N'';
            DECLARE @f2 varchar(100), @v2 nvarchar(max), @typ2 varchar(30);
            DECLARE cur2 CURSOR LOCAL FAST_FORWARD FOR
                SELECT k.FieldName, k.Value, f.DataType
                FROM #kv k JOIN plat.DataObjectField f ON f.FieldName = k.FieldName
                JOIN plat.DataObject o ON o.Id = f.DataObjectId AND o.Code = @ObjectCode;
            OPEN cur2;
            FETCH NEXT FROM cur2 INTO @f2, @v2, @typ2;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @setList += QUOTENAME(@f2) + N' = TRY_CAST(@v_' + @f2 + N' AS ' + @typ2 + N'),';
                SET @p2 += N', @v_' + @f2 + N' nvarchar(max)';
                SET @setv2 += N'SET @v_' + @f2 + N' = N''' + REPLACE(@v2, N'''', N'''''') + N''';';
                FETCH NEXT FROM cur2 INTO @f2, @v2, @typ2;
            END
            CLOSE cur2; DEALLOCATE cur2;

            DECLARE @sql2 nvarchar(max) = @setv2 + N'UPDATE ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                + N' SET ' + LEFT(@setList, LEN(@setList)-1) + N' WHERE ' + QUOTENAME(@pk) + N' = @pId;';
            EXEC sp_executesql @sql2, @p2, @pId = @Id;
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

/* --------------------------------------------------------------- 审批 */
CREATE OR ALTER PROCEDURE plat.usp_Wf_Submit
    @TenantId int, @UserId bigint, @ObjectCode varchar(60), @BusinessId bigint,
    @BusinessNo varchar(60), @Title nvarchar(200), @InstanceId bigint OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @defId bigint;
    SELECT TOP 1 @defId = Id FROM plat.WorkflowDef
    WHERE TenantId = @TenantId AND Status = 1
      AND (DataObjectId = (SELECT Id FROM plat.DataObject WHERE Code = @ObjectCode) OR DataObjectId IS NULL)
    ORDER BY ISNULL(DataObjectId,0) DESC, Version DESC;
    IF @defId IS NULL BEGIN RAISERROR(N'未找到已发布的审批流',16,1); RETURN; END

    INSERT INTO plat.WorkflowInstance(TenantId, WorkflowDefId, DataObjectCode, BusinessId, BusinessNo, Title, Status, StartedBy)
    VALUES(@TenantId, @defId, @ObjectCode, @BusinessId, @BusinessNo, @Title, 0, @UserId);
    SET @InstanceId = SCOPE_IDENTITY();

    /* 首个审批节点生成任务 */
    DECLARE @nodeId bigint;
    SELECT TOP 1 @nodeId = Id FROM plat.WorkflowNode
    WHERE WorkflowDefId = @defId AND NodeType = 2 ORDER BY Sort;
    IF @nodeId IS NOT NULL
        INSERT INTO plat.WorkflowTask(InstanceId, NodeId, NodeName, ApproverId, ApproveStatus)
        SELECT @InstanceId, @nodeId, n.Name, ap.ApproverId, 0
        FROM plat.WorkflowNode n
        CROSS APPLY (
            SELECT CASE a.ApproverType
                     WHEN 1 THEN a.ApproverId
                     WHEN 4 THEN (SELECT TOP 1 e.OrgId FROM plat.Employee e WHERE e.Id = (SELECT EmployeeId FROM plat.[User] WHERE Id = @UserId))
                     ELSE a.ApproverId END AS ApproverId
            FROM plat.WorkflowNodeApprover a WHERE a.WorkflowNodeId = n.Id
        ) ap
        WHERE n.Id = @nodeId;

    INSERT INTO plat.WorkflowActionLog(InstanceId, Action, OperatorId, Opinion)
    VALUES(@InstanceId, 'SUBMIT', @UserId, N'提交');
END
GO

CREATE OR ALTER PROCEDURE plat.usp_Wf_Approve
    @TenantId int, @UserId bigint, @TaskId bigint,
    @Approve bit, @Opinion nvarchar(500) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @instId bigint, @nodeId bigint, @status tinyint;
    SELECT @instId = t.InstanceId, @nodeId = t.NodeId, @status = t.ApproveStatus
    FROM plat.WorkflowTask t WHERE t.Id = @TaskId;
    IF @instId IS NULL BEGIN RAISERROR(N'任务不存在',16,1); RETURN; END
    IF @status <> 0 BEGIN RAISERROR(N'任务已处理',16,1); RETURN; END

    BEGIN TRAN;
    UPDATE plat.WorkflowTask SET ApproveStatus = CASE WHEN @Approve=1 THEN 1 ELSE 2 END,
           Opinion = @Opinion, HandledAt = sysutcdatetime()
    WHERE Id = @TaskId;

    INSERT INTO plat.WorkflowActionLog(InstanceId, TaskId, Action, OperatorId, Opinion)
    VALUES(@instId, @TaskId, CASE WHEN @Approve=1 THEN 'APPROVE' ELSE 'REJECT' END, @UserId, @Opinion);

    IF @Approve = 0
        UPDATE plat.WorkflowInstance SET Status = 2, FinishedAt = sysutcdatetime() WHERE Id = @instId;
    ELSE
    BEGIN
        IF EXISTS (SELECT 1 FROM plat.WorkflowTask WHERE InstanceId = @instId AND ApproveStatus = 0)
            UPDATE plat.WorkflowInstance SET CurrentNodeId = @nodeId WHERE Id = @instId;
        ELSE
            UPDATE plat.WorkflowInstance SET Status = 1, FinishedAt = sysutcdatetime() WHERE Id = @instId;
    END
    COMMIT;
END
GO

/* --------------------------------------------------------------- 视图 */
CREATE OR ALTER VIEW plat.vw_Meta_ModuleTree
AS
SELECT m.Id, m.TenantId, m.ParentId, m.Code, m.Name, m.EnCode, m.[Level], m.ModuleType,
       m.Sort, m.Icon, m.Description,
       (SELECT COUNT(1) FROM plat.ModuleFunction f WHERE f.ModuleId = m.Id AND f.IsEnabled = 1) AS FunctionCount,
       (SELECT COUNT(1) FROM plat.Menu mu WHERE mu.ModuleId = m.Id AND mu.IsEnabled = 1) AS MenuCount
FROM plat.Module m
WHERE m.IsEnabled = 1;
GO

CREATE OR ALTER VIEW plat.vw_Perm_UserFunction
AS
SELECT ur.UserId, p.ResourceKey, p.ResourceType, p.Name AS ResourceName,
       rp.CanRead, rp.CanWrite, rp.CanApprove, rp.CanExport, rp.CanDelete, rp.DataScope
FROM plat.UserRole ur
JOIN plat.RolePermission rp ON rp.RoleId = ur.RoleId AND rp.Allow = 1
JOIN plat.Permission p ON p.Id = rp.PermissionId AND p.IsEnabled = 1;
GO

CREATE OR ALTER VIEW inv.vw_Stock_Available
AS
SELECT s.TenantId, s.WarehouseId, s.SkuId, s.BatchId, s.StockStatus,
       SUM(s.Qty) AS Qty, SUM(s.ReservedQty) AS ReservedQty,
       SUM(s.FrozenQty) AS FrozenQty, SUM(s.InTransitQty) AS InTransitQty,
       SUM(s.Qty - s.ReservedQty - s.FrozenQty) AS AvailableQty,
       SUM(s.CostAmount) AS CostAmount
FROM inv.Stock s
GROUP BY s.TenantId, s.WarehouseId, s.SkuId, s.BatchId, s.StockStatus;
GO

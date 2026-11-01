/* =====================================================================
   租户开通：把模板租户的元数据完整克隆到新租户
   ---------------------------------------------------------------------
   设计要点：
   1) 全部在一个事务内完成，失败回滚，不留半套元数据
   2) 幂等：目标租户已有元数据直接拒绝，避免重复开通产生脏数据
   3) ID 重映射：所有父子引用都要换成新 ID，用 MERGE...OUTPUT 建立映射表
   4) 层级表（Module/Menu）按层插入，先父后子
   5) 不动用户/角色成员关系（账号开通是另一件事）
   ===================================================================== */
SET NOCOUNT ON;
GO
IF OBJECT_ID('plat.usp_Tenant_Provision') IS NOT NULL
    DROP PROCEDURE plat.usp_Tenant_Provision;
GO
CREATE PROCEDURE plat.usp_Tenant_Provision
    @TemplateTenantId int,
    @NewTenantId      int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @TemplateTenantId IS NULL OR @NewTenantId IS NULL
        THROW 50001, N'模板租户与新租户必须指定', 1;
    IF @TemplateTenantId = @NewTenantId
        THROW 50002, N'模板租户与新租户不能相同', 1;
    IF NOT EXISTS (SELECT 1 FROM plat.Tenant WHERE Id = @TemplateTenantId)
        THROW 50003, N'模板租户不存在', 1;
    IF NOT EXISTS (SELECT 1 FROM plat.Tenant WHERE Id = @NewTenantId)
        THROW 50004, N'目标租户不存在，请先创建租户', 1;
    IF EXISTS (SELECT 1 FROM plat.Module WHERE TenantId = @NewTenantId AND IsDeleted = 0)
        THROW 50005, N'目标租户已有元数据，禁止重复开通', 1;

    BEGIN TRY
        BEGIN TRAN;

        CREATE TABLE #mapModule   (OldId bigint PRIMARY KEY, NewId bigint NOT NULL);
        CREATE TABLE #mapNewMenu  (OldId bigint, NewId bigint);
        CREATE TABLE #mapFunction (OldId bigint PRIMARY KEY, NewId bigint NOT NULL);
        CREATE TABLE #mapPage     (OldId bigint PRIMARY KEY, NewId bigint NOT NULL);
        CREATE TABLE #mapMenu     (OldId bigint PRIMARY KEY, NewId bigint NOT NULL);
        CREATE TABLE #mapObj      (OldId bigint PRIMARY KEY, NewId bigint NOT NULL);
        CREATE TABLE #mapLV       (OldId bigint PRIMARY KEY, NewId bigint NOT NULL);
        CREATE TABLE #mapForm     (OldId bigint PRIMARY KEY, NewId bigint NOT NULL);
        CREATE TABLE #mapPerm     (OldId bigint PRIMARY KEY, NewId bigint NOT NULL);
        CREATE TABLE #mapRole     (OldId bigint PRIMARY KEY, NewId bigint NOT NULL);
        CREATE TABLE #mapRule     (OldId bigint PRIMARY KEY, NewId bigint NOT NULL);
        CREATE TABLE #mapDict     (OldId bigint PRIMARY KEY, NewId bigint NOT NULL);

        /* ---------- 1. 数据对象 ---------- */
        MERGE plat.DataObject AS tgt
        USING (SELECT * FROM plat.DataObject WHERE TenantId = @TemplateTenantId AND IsDeleted = 0) AS src
           ON 1 = 0
        WHEN NOT MATCHED THEN
            INSERT (TenantId, Code, Name, ObjectType, SchemaName, ObjectName, PrimaryKey, DocNoField,
                    OrgField, StatusField, TenantField, BaseWhere, DefaultOrder, IsReadOnly,
                    IsAuditEnabled, CacheSeconds, IsEnabled, Remark, ExtJson, IsDeleted, CreatedAt)
            VALUES (@NewTenantId, src.Code, src.Name, src.ObjectType, src.SchemaName, src.ObjectName,
                    src.PrimaryKey, src.DocNoField, src.OrgField, src.StatusField, src.TenantField,
                    src.BaseWhere, src.DefaultOrder, src.IsReadOnly, src.IsAuditEnabled,
                    src.CacheSeconds, src.IsEnabled, src.Remark, src.ExtJson, 0, sysutcdatetime())
        OUTPUT src.Id, inserted.Id INTO #mapObj;

        INSERT plat.DataObjectField (DataObjectId, FieldName, DisplayName, DataType, MaxLength, Precision,
                                     Scale, IsNullable, IsPrimaryKey, IsIdentity, IsRequired, DefaultValue,
                                     LookupType, LookupSource, LookupValueField, LookupDisplayField,
                                     LookupFilter, Format, Unit, IsVisible, Sort, IsComputed, ComputeExpr)
        SELECT m.NewId, f.FieldName, f.DisplayName, f.DataType, f.MaxLength, f.Precision, f.Scale,
               f.IsNullable, f.IsPrimaryKey, f.IsIdentity, f.IsRequired, f.DefaultValue, f.LookupType,
               f.LookupSource, f.LookupValueField, f.LookupDisplayField, f.LookupFilter, f.Format,
               f.Unit, f.IsVisible, f.Sort, f.IsComputed, f.ComputeExpr
        FROM plat.DataObjectField f
        JOIN plat.DataObject o ON o.Id = f.DataObjectId
        JOIN #mapObj m ON m.OldId = o.Id
        WHERE o.TenantId = @TemplateTenantId;

        /* ---------- 2. 列表视图 + 列 ---------- */
        MERGE plat.ListView AS tgt
        USING (SELECT v.* FROM plat.ListView v WHERE v.TenantId = @TemplateTenantId AND v.IsDeleted = 0) AS src
           ON 1 = 0
        WHEN NOT MATCHED THEN
            INSERT (TenantId, Code, Name, DataObjectId, PageSize, DefaultSort, FixedFilter, IsDefault,
                    RowActionStyle, IsEnabled, Remark, ExtJson, IsDeleted, CreatedAt)
            VALUES (@NewTenantId, src.Code, src.Name,
                    (SELECT m.NewId FROM #mapObj m WHERE m.OldId = src.DataObjectId),
                    src.PageSize, src.DefaultSort, src.FixedFilter, src.IsDefault, src.RowActionStyle,
                    src.IsEnabled, src.Remark, src.ExtJson, 0, sysutcdatetime())
        OUTPUT src.Id, inserted.Id INTO #mapLV;

        INSERT plat.ListViewColumn (ListViewId, FieldName, Title, Width, Align, Sort, IsVisible,
                                    IsFrozen, IsSum, Format, LinkPageId, ColorRule, IsDrill)
        SELECT m.NewId, c.FieldName, c.Title, c.Width, c.Align, c.Sort, c.IsVisible, c.IsFrozen,
               c.IsSum, c.Format, NULL, c.ColorRule, c.IsDrill
        FROM plat.ListViewColumn c
        JOIN plat.ListView v ON v.Id = c.ListViewId
        JOIN #mapLV m ON m.OldId = v.Id
        WHERE v.TenantId = @TemplateTenantId;

        /* ---------- 3. 表单布局 + 字段 ---------- */
        MERGE plat.FormLayout AS tgt
        USING (SELECT f.* FROM plat.FormLayout f WHERE f.TenantId = @TemplateTenantId AND f.IsDeleted = 0) AS src
           ON 1 = 0
        WHEN NOT MATCHED THEN
            INSERT (TenantId, Code, Name, DataObjectId, Mode, Columns, GroupsJson, IsDefault, IsEnabled,
                    Remark, ExtJson, IsDeleted, CreatedAt)
            VALUES (@NewTenantId, src.Code, src.Name,
                    (SELECT m.NewId FROM #mapObj m WHERE m.OldId = src.DataObjectId),
                    src.Mode, src.Columns, src.GroupsJson, src.IsDefault, src.IsEnabled, src.Remark,
                    src.ExtJson, 0, sysutcdatetime())
        OUTPUT src.Id, inserted.Id INTO #mapForm;

        INSERT plat.FormField (FormLayoutId, FieldName, Label, ControlType, Row, Col, Span, IsReadOnly,
                               IsRequired, IsHidden, DefaultExpr, Placeholder, HelpText, GroupName,
                               Sort, AccessExpr)
        SELECT m.NewId, ff.FieldName, ff.Label, ff.ControlType, ff.Row, ff.Col, ff.Span, ff.IsReadOnly,
               ff.IsRequired, ff.IsHidden, ff.DefaultExpr, ff.Placeholder, ff.HelpText, ff.GroupName,
               ff.Sort, ff.AccessExpr
        FROM plat.FormField ff
        JOIN plat.FormLayout fl ON fl.Id = ff.FormLayoutId
        JOIN #mapForm m ON m.OldId = fl.Id
        WHERE fl.TenantId = @TemplateTenantId;

        /* ---------- 4. 模块（按层级三次插入） ---------- */
        DECLARE @lvl tinyint = 1;
        WHILE @lvl <= 3
        BEGIN
            MERGE plat.Module AS tgt
            USING (
                SELECT * FROM plat.Module
                WHERE TenantId = @TemplateTenantId AND IsDeleted = 0 AND [Level] = @lvl
            ) AS src
               ON 1 = 0
            WHEN NOT MATCHED THEN
                INSERT (TenantId, ParentId, Code, Name, EnCode, [Level], ModuleType, Sort, Icon,
                        Description, DocType, IsEnabled, Version, Remark, ExtJson, IsDeleted, CreatedAt)
                VALUES (@NewTenantId,
                        CASE WHEN src.ParentId IS NULL THEN NULL
                             ELSE (SELECT m.NewId FROM #mapModule m WHERE m.OldId = src.ParentId) END,
                        src.Code, src.Name, src.EnCode, src.[Level], src.ModuleType, src.Sort, src.Icon,
                        src.Description, src.DocType, src.IsEnabled, src.Version, src.Remark,
                        src.ExtJson, 0, sysutcdatetime())
            OUTPUT src.Id, inserted.Id INTO #mapModule;
            SET @lvl += 1;
        END

        /* ---------- 5. 页面 ---------- */
        MERGE plat.Page AS tgt
        USING (SELECT p.* FROM plat.Page p WHERE p.TenantId = @TemplateTenantId AND p.IsDeleted = 0) AS src
           ON 1 = 0
        WHEN NOT MATCHED THEN
            INSERT (TenantId, Code, Name, PageType, ModuleId, Layout, Title, ParamsJson, IsEnabled,
                    Version, Remark, ExtJson, IsDeleted, CreatedAt)
            VALUES (@NewTenantId, src.Code, src.Name, src.PageType,
                    (SELECT m.NewId FROM #mapModule m WHERE m.OldId = src.ModuleId),
                    src.Layout, src.Title, src.ParamsJson, src.IsEnabled, src.Version, src.Remark,
                    src.ExtJson, 0, sysutcdatetime())
        OUTPUT src.Id, inserted.Id INTO #mapPage;

        INSERT plat.PageBlock (PageId, Code, BlockType, Title, DataObjectId, ListViewId, FormLayoutId,
                               ParentBlockId, LinkField, Span, Row, VisibleExpr, Sort)
        SELECT mp.NewId, b.Code, b.BlockType, b.Title,
               (SELECT o.NewId FROM #mapObj o WHERE o.OldId = b.DataObjectId),
               (SELECT v.NewId FROM #mapLV v WHERE v.OldId = b.ListViewId),
               (SELECT f.NewId FROM #mapForm f WHERE f.OldId = b.FormLayoutId),
               NULL, b.LinkField, b.Span, b.Row, b.VisibleExpr, b.Sort
        FROM plat.PageBlock b
        JOIN plat.Page p ON p.Id = b.PageId
        JOIN #mapPage mp ON mp.OldId = p.Id
        WHERE p.TenantId = @TemplateTenantId;

        /* ---------- 6. 功能点 ---------- */
        MERGE plat.ModuleFunction AS tgt
        USING (SELECT f.* FROM plat.ModuleFunction f WHERE f.TenantId = @TemplateTenantId AND f.IsDeleted = 0) AS src
           ON 1 = 0
        WHEN NOT MATCHED THEN
            INSERT (TenantId, ModuleId, Code, Name, FunType, Sort, IsPermissionPoint, ConfirmText,
                    SuccessMessage, Icon, HotKey, IsEnabled, Remark, ExtJson, IsDeleted, CreatedAt)
            VALUES (@NewTenantId,
                    (SELECT m.NewId FROM #mapModule m WHERE m.OldId = src.ModuleId),
                    src.Code, src.Name, src.FunType, src.Sort, src.IsPermissionPoint, src.ConfirmText,
                    src.SuccessMessage, src.Icon, src.HotKey, src.IsEnabled, src.Remark, src.ExtJson,
                    0, sysutcdatetime())
        OUTPUT src.Id, inserted.Id INTO #mapFunction;

        /* ---------- 7. 按钮 ---------- */
        INSERT plat.Button (TenantId, Code, Name, Text, Icon, ButtonType, FunctionId, Sort, IsVisible,
                            VisibleExpr, IsEnabledExpr, Style, Remark, ExtJson, IsDeleted, CreatedAt)
        SELECT @NewTenantId, b.Code, b.Name, b.Text, b.Icon, b.ButtonType,
               (SELECT f.NewId FROM #mapFunction f WHERE f.OldId = b.FunctionId),
               b.Sort, b.IsVisible, b.VisibleExpr, b.IsEnabledExpr, b.Style, b.Remark, b.ExtJson,
               0, sysutcdatetime()
        FROM plat.Button b
        WHERE b.TenantId = @TemplateTenantId AND b.IsDeleted = 0;

        /* ---------- 8. 权限点 ---------- */
        MERGE plat.Permission AS tgt
        USING (SELECT p.* FROM plat.Permission p WHERE p.TenantId = @TemplateTenantId) AS src
           ON 1 = 0
        WHEN NOT MATCHED THEN
            INSERT (TenantId, ResourceKey, ResourceType, Name, ParentKey, ModuleId, FunctionId, IsEnabled)
            VALUES (@NewTenantId, src.ResourceKey, src.ResourceType, src.Name, src.ParentKey,
                    (SELECT m.NewId FROM #mapModule m WHERE m.OldId = src.ModuleId),
                    (SELECT f.NewId FROM #mapFunction f WHERE f.OldId = src.FunctionId),
                    src.IsEnabled)
        OUTPUT src.Id, inserted.Id INTO #mapPerm;

        /* ---------- 9. 菜单（先根，再逐层展开） ---------- */
        MERGE plat.Menu AS tgt
        USING (
            SELECT m.* FROM plat.Menu m
            WHERE m.TenantId = @TemplateTenantId AND m.IsDeleted = 0
              AND (m.ParentId IS NULL
                   OR NOT EXISTS (SELECT 1 FROM plat.Menu p
                                  WHERE p.Id = m.ParentId AND p.TenantId = @TemplateTenantId AND p.IsDeleted = 0))
        ) AS src
           ON 1 = 0
        WHEN NOT MATCHED THEN
            INSERT (TenantId, ParentId, Code, Name, ModuleId, PageId, MenuType, Route, Icon, Sort,
                    IsVisible, OpenMode, BadgeExpr, IsEnabled, Remark, ExtJson, IsDeleted, CreatedAt)
            VALUES (@NewTenantId, NULL, src.Code, src.Name,
                    (SELECT m.NewId FROM #mapModule m WHERE m.OldId = src.ModuleId),
                    (SELECT p.NewId FROM #mapPage p WHERE p.OldId = src.PageId),
                    src.MenuType, src.Route, src.Icon, src.Sort, src.IsVisible, src.OpenMode,
                    src.BadgeExpr, src.IsEnabled, src.Remark, src.ExtJson, 0, sysutcdatetime())
        OUTPUT src.Id, inserted.Id INTO #mapNewMenu;
        INSERT INTO #mapMenu (OldId, NewId) SELECT OldId, NewId FROM #mapNewMenu;

        DECLARE @round int = 0, @inserted int = 1;
        WHILE @inserted > 0 AND @round < 20
        BEGIN
            SET @round += 1;
            TRUNCATE TABLE #mapNewMenu;
            MERGE plat.Menu AS tgt
            USING (
                SELECT m.* FROM plat.Menu m
                WHERE m.TenantId = @TemplateTenantId AND m.IsDeleted = 0
                  AND m.ParentId IS NOT NULL
                  AND EXISTS (SELECT 1 FROM #mapMenu p WHERE p.OldId = m.ParentId)
                  AND NOT EXISTS (SELECT 1 FROM #mapMenu x WHERE x.OldId = m.Id)
            ) AS src
               ON 1 = 0
            WHEN NOT MATCHED THEN
                INSERT (TenantId, ParentId, Code, Name, ModuleId, PageId, MenuType, Route, Icon, Sort,
                        IsVisible, OpenMode, BadgeExpr, IsEnabled, Remark, ExtJson, IsDeleted, CreatedAt)
                VALUES (@NewTenantId,
                        (SELECT p.NewId FROM #mapMenu p WHERE p.OldId = src.ParentId),
                        src.Code, src.Name,
                        (SELECT m.NewId FROM #mapModule m WHERE m.OldId = src.ModuleId),
                        (SELECT pg.NewId FROM #mapPage pg WHERE pg.OldId = src.PageId),
                        src.MenuType, src.Route, src.Icon, src.Sort, src.IsVisible, src.OpenMode,
                        src.BadgeExpr, src.IsEnabled, src.Remark, src.ExtJson, 0, sysutcdatetime())
            OUTPUT src.Id, inserted.Id INTO #mapNewMenu;
            SET @inserted = @@ROWCOUNT;
            INSERT INTO #mapMenu (OldId, NewId) SELECT OldId, NewId FROM #mapNewMenu;
        END

        /* ---------- 10. 菜单终端可见性 ---------- */
        INSERT plat.MenuTerminal (MenuId, TerminalType, IsVisible, Sort)
        SELECT mn.NewId, t.TerminalType, t.IsVisible, t.Sort
        FROM plat.MenuTerminal t
        JOIN plat.Menu m ON m.Id = t.MenuId
        JOIN #mapMenu mn ON mn.OldId = m.Id
        WHERE m.TenantId = @TemplateTenantId;

        /* ---------- 11. 角色 + 角色权限 ---------- */
        MERGE plat.Role AS tgt
        USING (SELECT r.* FROM plat.Role r WHERE r.TenantId = @TemplateTenantId AND r.IsDeleted = 0) AS src
           ON 1 = 0
        WHEN NOT MATCHED THEN
            INSERT (TenantId, Code, Name, RoleType, IsSystem, IsEnabled, Remark, IsDeleted, CreatedAt)
            VALUES (@NewTenantId, src.Code, src.Name, src.RoleType, src.IsSystem, src.IsEnabled,
                    src.Remark, 0, sysutcdatetime())
        OUTPUT src.Id, inserted.Id INTO #mapRole;

        INSERT plat.RolePermission (TenantId, RoleId, PermissionId, Allow, CanRead, CanWrite, CanApprove,
                                    CanExport, CanDelete, DataScope, ScopeOrgIds, GrantedAt)
        SELECT @NewTenantId, r.NewId, p.NewId, rp.Allow, rp.CanRead, rp.CanWrite, rp.CanApprove,
               rp.CanExport, rp.CanDelete, rp.DataScope, rp.ScopeOrgIds, sysutcdatetime()
        FROM plat.RolePermission rp
        JOIN #mapRole r ON r.OldId = rp.RoleId
        JOIN #mapPerm p ON p.OldId = rp.PermissionId
        WHERE rp.TenantId = @TemplateTenantId;

        /* ---------- 12. 编码规则 + 号段 ---------- */
        MERGE plat.CodeRule AS tgt
        USING (SELECT c.* FROM plat.CodeRule c WHERE c.TenantId = @TemplateTenantId AND c.IsDeleted = 0) AS src
           ON 1 = 0
        WHEN NOT MATCHED THEN
            INSERT (TenantId, Code, Name, ObjectType, Separator, ResetCycle, Sample, IsEnabled, Remark,
                    IsDeleted, CreatedAt)
            VALUES (@NewTenantId, src.Code, src.Name, src.ObjectType, src.Separator, src.ResetCycle,
                    src.Sample, src.IsEnabled, src.Remark, 0, sysutcdatetime())
        OUTPUT src.Id, inserted.Id INTO #mapRule;

        INSERT plat.CodeSeed (TenantId, CodeRuleId, PeriodKey, CurrentValue)
        SELECT @NewTenantId, m.NewId, '', 0
        FROM #mapRule m;

        /* ---------- 13. 字典 ---------- */
        MERGE plat.DictType AS tgt
        USING (SELECT d.* FROM plat.DictType d WHERE d.TenantId = @TemplateTenantId AND d.IsDeleted = 0) AS src
           ON 1 = 0
        WHEN NOT MATCHED THEN
            INSERT (TenantId, Code, Name, IsSystem, IsEnabled, Remark, IsDeleted, CreatedAt)
            VALUES (@NewTenantId, src.Code, src.Name, src.IsSystem, src.IsEnabled, src.Remark, 0, sysutcdatetime())
        OUTPUT src.Id, inserted.Id INTO #mapDict;

        INSERT plat.DictItem (DictTypeId, Code, Name, Value, ParentCode, Sort, IsDefault, ExtJson, IsEnabled)
        SELECT m.NewId, i.Code, i.Name, i.Value, i.ParentCode, i.Sort, i.IsDefault, i.ExtJson, i.IsEnabled
        FROM plat.DictItem i
        JOIN plat.DictType d ON d.Id = i.DictTypeId
        JOIN #mapDict m ON m.OldId = d.Id
        WHERE d.TenantId = @TemplateTenantId;

        /* ---------- 14. 参数与业务规则 ---------- */
        INSERT plat.Setting (TenantId, Category, [Key], Value, ValueType, Description, IsSystem)
        SELECT @NewTenantId, s.Category, s.[Key], s.Value, s.ValueType, s.Description, s.IsSystem
        FROM plat.Setting s WHERE s.TenantId = @TemplateTenantId;

        INSERT plat.BizRule (TenantId, Code, Name, RuleType, Expression, ErrorMessage, Severity, IsEnabled,
                             Remark, IsDeleted, CreatedAt)
        SELECT @NewTenantId, r.Code, r.Name, r.RuleType, r.Expression, r.ErrorMessage, r.Severity,
               r.IsEnabled, r.Remark, 0, sysutcdatetime()
        FROM plat.BizRule r WHERE r.TenantId = @TemplateTenantId AND r.IsDeleted = 0;

        COMMIT TRAN;

        /* ---------- 结果 ---------- */
        SELECT N'Module' AS TableName, COUNT(*) AS Copied FROM #mapModule
        UNION ALL SELECT N'ModuleFunction', COUNT(*) FROM #mapFunction
        UNION ALL SELECT N'Menu', COUNT(*) FROM #mapMenu
        UNION ALL SELECT N'Permission', COUNT(*) FROM #mapPerm
        UNION ALL SELECT N'Role', COUNT(*) FROM #mapRole
        UNION ALL SELECT N'DataObject', COUNT(*) FROM #mapObj
        UNION ALL SELECT N'ListView', COUNT(*) FROM #mapLV
        UNION ALL SELECT N'FormLayout', COUNT(*) FROM #mapForm
        UNION ALL SELECT N'Page', COUNT(*) FROM #mapPage
        UNION ALL SELECT N'CodeRule', COUNT(*) FROM #mapRule
        UNION ALL SELECT N'DictType', COUNT(*) FROM #mapDict;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END
GO

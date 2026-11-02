/* =====================================================================
   V38.1 · 平台管理菜单重新规划
   ---------------------------------------------------------------------
   背景：平台管理的入口（租户、组织/用户、角色、元数据、规则/审批、发布、
        字典/参数、审计、集成、运维）散在“平台与主数据”下，且大量是业务
        主数据；管理员没有一个独立的“平台管理”控制台菜单。

   本脚本只新增一棵独立的“平台管理”菜单树（租户 1 = 模板租户）：
     - 8 个模块：平台概览、租户与组织、元数据设计、规则与流程、
                  基础配置、安全与审计、集成与开放、运维与监控
     - 每个模块挂 3–6 个功能入口
     - 已有页面/设计器的直接指向真实路由（/admin*、/design?tab=*、
       /workflow、/todo）；尚未实现的走 /m/{code} 占位页
   不改动既有菜单，避免影响业务域清单；后续可把 01 下的系统/安全/集成
   模块迁入本树（另行评估）。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

DECLARE @t int = (SELECT TOP 1 Id FROM plat.Tenant WHERE Code = 'T001' AND IsDeleted = 0 ORDER BY Id);
IF @t IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '90')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Icon, Sort, IsVisible, IsEnabled)
        VALUES (@t, NULL, '90', N'平台管理', 1, '/admin', 'Setting', -10, 1, 1);

    DECLARE @root bigint = (SELECT Id FROM plat.Menu WHERE TenantId = @t AND Code = '90');

    /* ---------------------------------------------------------------- 9001 平台概览 */
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '9001')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @root, '9001', N'平台概览', 1, NULL, 10, 1, 1);
    DECLARE @m1 bigint = (SELECT Id FROM plat.Menu WHERE TenantId = @t AND Code = '9001');
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900101')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m1, '900101', N'概览面板', 2, '/admin', 10, 1, 1);

    /* ---------------------------------------------------------------- 9002 租户与组织 */
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '9002')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @root, '9002', N'租户与组织', 1, NULL, 20, 1, 1);
    DECLARE @m2 bigint = (SELECT Id FROM plat.Menu WHERE TenantId = @t AND Code = '9002');
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900201')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m2, '900201', N'租户管理', 2, '/admin/tenants', 10, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900202')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m2, '900202', N'组织架构', 2, '/m/900202', 20, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900203')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m2, '900203', N'用户管理', 2, '/m/900203', 30, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900204')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m2, '900204', N'角色与权限', 2, '/design?tab=permission', 40, 1, 1);

    /* ---------------------------------------------------------------- 9003 元数据设计 */
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '9003')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @root, '9003', N'元数据设计', 1, NULL, 30, 1, 1);
    DECLARE @m3 bigint = (SELECT Id FROM plat.Menu WHERE TenantId = @t AND Code = '9003');
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900301')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m3, '900301', N'数据对象与字段', 2, '/design?tab=field', 10, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900302')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m3, '900302', N'子表关系', 2, '/design?tab=relation', 20, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900303')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m3, '900303', N'页面与表单', 2, '/m/900303', 30, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900304')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m3, '900304', N'模块管理', 2, '/m/900304', 40, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900305')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m3, '900305', N'菜单管理', 2, '/admin/menus', 50, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900306')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m3, '900306', N'发布与回滚', 2, '/design?tab=publish', 60, 1, 1);

    /* ---------------------------------------------------------------- 9004 规则与流程 */
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '9004')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @root, '9004', N'规则与流程', 1, NULL, 40, 1, 1);
    DECLARE @m4 bigint = (SELECT Id FROM plat.Menu WHERE TenantId = @t AND Code = '9004');
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900401')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m4, '900401', N'规则设计', 2, '/design?tab=rule', 10, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900402')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m4, '900402', N'按钮与动作', 2, '/design?tab=button', 20, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900403')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m4, '900403', N'审批流设计', 2, '/design?tab=approval', 30, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900404')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m4, '900404', N'流程中心', 2, '/workflow', 40, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900405')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m4, '900405', N'我的待办', 2, '/todo', 50, 1, 1);

    /* ---------------------------------------------------------------- 9005 基础配置 */
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '9005')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @root, '9005', N'基础配置', 1, NULL, 50, 1, 1);
    DECLARE @m5 bigint = (SELECT Id FROM plat.Menu WHERE TenantId = @t AND Code = '9005');
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900501')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m5, '900501', N'数据字典', 2, '/m/900501', 10, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900502')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m5, '900502', N'编号规则', 2, '/m/900502', 20, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900503')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m5, '900503', N'业务参数', 2, '/m/900503', 30, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900504')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m5, '900504', N'消息模板', 2, '/m/900504', 40, 1, 1);

    /* ---------------------------------------------------------------- 9006 安全与审计 */
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '9006')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @root, '9006', N'安全与审计', 1, NULL, 60, 1, 1);
    DECLARE @m6 bigint = (SELECT Id FROM plat.Menu WHERE TenantId = @t AND Code = '9006');
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900601')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m6, '900601', N'操作日志', 2, '/m/900601', 10, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900602')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m6, '900602', N'登录日志', 2, '/m/900602', 20, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900603')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m6, '900603', N'导出审计', 2, '/m/900603', 30, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900604')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m6, '900604', N'数据备份', 2, '/m/900604', 40, 1, 1);

    /* ---------------------------------------------------------------- 9007 集成与开放 */
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '9007')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @root, '9007', N'集成与开放', 1, NULL, 70, 1, 1);
    DECLARE @m7 bigint = (SELECT Id FROM plat.Menu WHERE TenantId = @t AND Code = '9007');
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900701')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m7, '900701', N'OpenAPI', 2, '/m/900701', 10, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900702')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m7, '900702', N'Webhook 订阅', 2, '/m/900702', 20, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900703')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m7, '900703', N'单点登录', 2, '/m/900703', 30, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900704')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m7, '900704', N'第三方应用', 2, '/m/900704', 40, 1, 1);

    /* ---------------------------------------------------------------- 9008 运维与监控 */
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '9008')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @root, '9008', N'运维与监控', 1, NULL, 80, 1, 1);
    DECLARE @m8 bigint = (SELECT Id FROM plat.Menu WHERE TenantId = @t AND Code = '9008');
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900801')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m8, '900801', N'任务调度', 2, '/m/900801', 10, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900802')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m8, '900802', N'缓存管理', 2, '/m/900802', 20, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900803')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m8, '900803', N'附件管理', 2, '/m/900803', 30, 1, 1);
    IF NOT EXISTS (SELECT 1 FROM plat.Menu WHERE TenantId = @t AND Code = '900804')
        INSERT plat.Menu (TenantId, ParentId, Code, Name, MenuType, Route, Sort, IsVisible, IsEnabled)
        VALUES (@t, @m8, '900804', N'系统通知', 2, '/m/900804', 40, 1, 1);
END
GO

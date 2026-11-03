# 双入口：平台管理 / 业务管理

> 一句话：**登录时先选入口，进去就只看到那个入口的菜单和数据**。
> 平台管理管「系统怎么配」，业务管理管「生意怎么做」，两者不混在一个侧边栏里。

## 1. 两个入口分别在做什么

| 入口 | 面向 | 包含 | 首页 |
|---|---|---|---|
| **平台管理**（`AppType=1`） | 系统管理员 / 实施 | 平台概览、租户与组织、元数据设计（字段/子表/状态机/打印/编号/终端/菜单）、规则与流程、权限、发布与回滚、监控 | `/platform` |
| **业务管理**（`AppType=2`） | 业务用户 | 业务工作台、我的待办、流程中心、10 个业务域菜单、基础资料 | `/` |

## 2. 登录时怎么分

登录页默认是**租户登录**：

- 字段：租户名称（填名称或编码都认，如 `示例商贸有限公司` / `T001`）+ 用户名 + 口令；
- 接口 `POST /api/auth/login`，令牌入口 `app=2`（业务管理），**不带**平台作用域；
- 业务会话调 `/api/admin/**`、开通租户等跨租户接口一律 403。

租户登录按钮下面有一个小热区「平台管理员登录」：

- 点开后是**平台登录**：只有用户名 + 口令，**没有租户名**；
- 接口 `POST /api/auth/platform-login`，只认 `plat.User.IsPlatformAccount=1` 的账号；
- 登录时以平台作用域（`BypassRls=1`）跨租户找人，令牌带 `app=1` + `pf=true`；
- 因此平台登录能列出并管理**所有租户**（`/api/admin/tenants` 等）。

**平台作用域是硬边界**：租户登录的管理员（SYSADMIN）调平台接口会 403「仅平台管理员可访问平台管理，请使用平台登录」——「我在自己租户里是管理员」不等于「我能管所有租户」。

之后所有请求都按令牌里的入口工作：

- `/api/menu/tree` 只返回该入口的菜单；
- 前端路由按 `meta.app` 守卫，跨入口访问会被弹回本入口首页。

**入口不由前端参数决定**：菜单接口取令牌里的 `app`，否则改个 query 就能看到另一侧菜单，隔离等于没做。

## 2.1 首次登录改口令

开通/重置出来的管理员带 `MustChangePwd=1`，登录后：

- 后端拦截器会拦掉除改口令外的所有接口（`ErrorCode.MUST_CHANGE_PASSWORD`）；
- 前端识别 `mustChangePassword` 后弹**不可关闭**的改密框，改完自动换发令牌并重拉菜单；
- 改口令走 `POST /api/me/password {oldPassword,newPassword}`：只认令牌身份，
  不需要租户名/用户名，平台账号同样适用；
- 日常改口令：用户菜单 →「修改口令」。

顶栏的租户标签显示**租户名称**（`/api/perm/me` 返回 `tenantName`），悬停显示编码。

## 3. 菜单怎么分开

`plat.Menu.AppType`（V51）：

- `90` 子树（平台管理，43 条）→ `AppType=1`；
- `01..10` 业务域（1104 条 + 各终端克隆）→ `AppType=2`；
- 索引 `(TenantId, AppType, TerminalType, Sort)`，菜单树直接按入口查，不是「查全树再剪枝」。

改菜单时（`/#/system/menus`）改的就是同一张表；平台菜单只能挂在平台入口下，业务菜单挂业务入口下——两者在库里就分开了。

## 4. 切换入口

**必须重新登录**（令牌里固定了入口与平台作用域）。用户菜单里有「切换到业务管理 / 平台管理」，点了会清会话并回到登录页：切平台方向会直接进入平台登录表单。

不做「同一会话内两个入口来回切」：那等于把两个入口的权限边界做成摆设。

## 5. 代码落点

| 层 | 位置 |
|---|---|
| 库 | `V51__102_menu_app_type.sql`（`Menu.AppType` + 索引 + 回填）、`V53__104_platform_account.sql`（`User.IsPlatformAccount`） |
| 后端 | `TenantContext.APP_PLATFORM/APP_BUSINESS` + `isPlatformScope()`、`JwtService.CLAIM_APP/CLAIM_PLATFORM`、`AuthService.login(...,appType)` / `loginPlatform(user, pwd)`、`PlatformAdminService.requirePlatformAdmin()`（要求平台作用域）、`MenuService.tree(terminal, appType)`、`MenuController`（取令牌入口） |
| 前端 | `LoginView`（默认租户登录 + 平台登录热区）、`session.state.appType`（localStorage `aschain.app`）、`router` 的 `meta.app` 守卫、`MainLayout` 侧边栏按入口渲染、用户菜单「切换入口」 |

## 6. 边界

- 入口只决定「看到哪一侧的菜单与页面」，不替代权限点：平台入口里仍按 `DESIGN:*` 控制，业务入口仍按 `MOD/FUN/DATA` 控制；
- 平台作用域 = 令牌 `pf=true`，只有平台登录会签发；`pf` 一旦出现，RLS 对这条连接全面放开，所以它只能来自 `IsPlatformAccount=1` 的账号；
- 老令牌没有 `app` 声明时按**业务管理**处理、没有 `pf`（向后兼容，刷新即重建）；
- 定时任务/后台线程没有入口，`TenantContext.appType()` 默认业务管理，且不带平台作用域；
- 租户名称模糊匹配没做：填的名称必须与 `plat.Tenant.Name` 完全一致（或直接用编码）。

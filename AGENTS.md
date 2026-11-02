# AGENTS.md — AI 编码契约

> 本文件是每次生成任务的**第一段上下文**。任何与本文件冲突的实现，一律以本文件为准。
> 每周五由当周负责人更新「踩坑记录」一节，版本化保存。

## 0. 角色与边界

- 代码由 AI 生成，人不写代码。
- 人负责：规格、评审、验收、集成、数据与安全决策。
- AI 负责：实现、单测、重构、文档初稿。
- **任何代码都必须能被负责人在 3 分钟内讲清「做什么、边界在哪、错了会怎样」**，否则重写。

## 1. 技术栈（锁定 12 个月，不得更换）

| 层 | 选型 |
|---|---|
| JDK | 21（Adoptium） |
| 框架 | Spring Boot 3.3.x |
| 构建 | Maven |
| 数据访问 | JdbcTemplate / NamedParameterJdbcTemplate 为主；MyBatis-Plus 仅用于简单 CRUD |
| 数据库 | SQL Server 2022，库名 `APSErpV3` |
| 迁移 | Flyway（`src/main/resources/db/migration`） |
| 缓存 | Redis + Caffeine |
| 测试 | JUnit 5 + AssertJ + Mockito（单测）；集成测试连本机真库（IT_DB_PASSWORD 环境变量），CI 用 Testcontainers |
| 架构守护 | ArchUnit |
| 前端 | Vue 3 + TypeScript strict + Vite（web/ 子目录，第 1 周周四接入） |

## 2. 目录与分层

```
src/main/java/com/apserp/
  ApserpApplication.java
  common/            # 通用：结果体、异常、租户上下文、工具
  plat/              # 平台域：元数据引擎、权限、编号、审计
    meta/            # 数据对象、查询引擎、保存引擎、规则
    config/          # 配置
  md/ pur/ sal/ ret/ mkt/ omn/ inv/ tms/ fin/ pln/   # 业务域（后续按域新增）
src/main/resources/
  application.yml
  db/migration/      # Flyway，禁止修改已执行过的脚本，只能新增
src/test/java/com/apserp/
  arch/              # ArchUnit 规则
```

**分层规则（ArchUnit 会检查）**
1. `controller` 不得直接依赖 `repository`/`JdbcTemplate`，必须经 `service`。
2. 业务域之间只能通过 `*.api` 包（接口 + DTO）调用，不得直接访问对方的 `repository`。
3. `common` 不得依赖任何业务域。
4. 不得出现 `System.out` / `printStackTrace`。

## 3. 编码约定（强制）

- **SQL**：一律参数化；动态 SQL 只能由元数据白名单生成（`plat.DataObjectField`），禁止字符串拼接用户输入。
- **多租户**：上下文由 `TenantAwareDataSource` 在借出连接时注入 `SESSION_CONTEXT`；业务代码直接用 `JdbcTemplate`，**禁止手动设置租户上下文**。查询仍应显式带 `TenantId` 条件（走索引 + 便于排查）。
- **金额**：`BigDecimal`，禁止 `double`/`float`；比较用 `compareTo`。
- **时间**：`LocalDate` / `LocalDateTime`，禁止 `java.util.Date`。
- **主键**：`long`/`Long`，禁止自增语义外推到业务（业务唯一靠 `Code`/`DocNo`）。
- **异常**：业务异常继承 `ApiException`，必须带错误码；禁止吞异常。
- **日志**：`log.info("action={}, docNo={}", ...)`；禁止打印敏感字段（成本、底价、密码）。
- **事务**：只在 service 层开事务；跨域调用用领域事件，不共享事务。
- **命名**：类 `PascalCase`，方法 `camelCase`，常量 `UPPER_SNAKE`；测试类 `*Test`/`*IT`。

## 4. 七条红线（永不交给 AI 决定，只能按人给的规格实现）

1. 业务规则边界（税率、舍入、优惠叠加顺序、退货时限）
2. 金额与成本计算（加权平均、费用分摊、税额）
3. 状态机与幂等（重复提交、并发审核、冲红）
4. 权限与租户隔离（谁能看哪个组织/字段）
5. 数据库迁移与期初（不可逆操作）
6. 验收标准
7. 架构决策（模块边界、契约变更）

## 5. 提交要求

- 每个 MR 必须包含：实现、单元测试、受影响模块的集成测试。
- 改动数据库必须新增 Flyway 脚本（`V{n}__{描述}.sql`），**不得修改已有脚本**。
- 新增第三方依赖必须在本文件「依赖白名单」登记，否则 CI 失败。
- 若本次踩到坑，必须更新本文件「踩坑记录」。

## 6. 踩坑记录（每周五追加）

| 日期 | 坑 | 结论 |
|---|---|---|
| 2026-10-30 | `SESSION_CONTEXT` 与连接池：请求 A 设了租户上下文，请求 B 复用同一物理连接会串租户 | **已作废**，见 2026-11-01 条：不要在业务代码里设上下文 |
| 2026-11-01 | PowerShell 5.1 的 `Set-Content -Encoding UTF8` 会写 BOM，javac 报「非法字符」 | 一律用 Python 或 `UTF8Encoding($false)` 写文件；提交前检查 BOM |
| 2026-11-01 | Flyway 按「连接用户默认 schema」判断库是否为空；`apserp_dev` 默认 `dbo`，表都在业务 schema 下，被误判为空库并从 V1 重跑 | 既有库首次接入必须显式 `flyway:baseline -Dflyway.baselineVersion=18`；`baseline-on-migrate` 只适用于新库 |
| 2026-11-01 | 引入 `spring-boot-starter-data-redis` 但本机未装 Redis，Actuator health 直接 DOWN | 未使用的中间件先关健康检查：`management.health.redis.enabled=false` |
| 2026-11-01 | **写 `tenantSession.execute(con -> jdbcTemplate.query(...))` 完全无效**：`jdbcTemplate` 会从池里另取一条连接，上下文设在了 A 连接、查询跑在 B 连接，RLS 看不到租户 → 查询返回空。这是"能跑通演示、上线必炸"的典型缺陷，单测发现不了（有真库才暴露） | 上下文只在 **DataSource 层**注入：`TenantAwareDataSource` 在每次 `getConnection()` 时设置 `SESSION_CONTEXT`。**业务代码禁止手动设上下文，直接用 `JdbcTemplate` 即可**。`TenantSession` 类已删除 |
| 2026-11-01 | 把 SQL 异常一律翻译成「数据对象不存在」会掩盖真实故障（锁超时、权限不足都被说成对象不存在） | 只把 `RAISERROR('数据对象不存在')` 翻译成业务错误 `2001`，其余一律 `1999` + 完整堆栈进日志 |
| 2026-11-01 | 列表引擎只 SELECT `DataObjectField.IsVisible=1` 的列，而种子把主键 `Id` 标成不可见 → 前端拿到的行没有 `Id`，修改被保存引擎当成新增（撞唯一键 409） | 主键是行标识，必须随列表返回：`V26__075_list_primary_key.sql` 把所有主键字段置为可见（列表页仍只显示视图列） |
| 2026-11-01 | 前端按 Java 字段类型猜 JSON：`FormFieldDto.controlType` 实际是 **String**（`"6"`），`ListViewColumn.align` 也是字符串 | 前端 `src/api/types.ts` 以真实 JSON 为准；复杂控件比较前先 `Number(...)`，不要照着 record 的 `int` 猜 |
| 2026-11-01 | Windows 下 esbuild 压缩大 chunk 报 `remove C:\...\Temp\esbuild-...: Access is denied`，`vite build` 直接中断（沙箱/杀软占用临时文件） | 前端构建改用 `terser` + `target: esnext`（见 `web/vite.config.ts`）；不要改回 esbuild minify，除非换 Linux 构建机 |
| 2026-11-01 | Flyway 迁移脚本里的 `sp_set_session_context 'BypassRls', 1` 在连接归还 Hikari 后没有清除；复用该连接的请求会绕过 RLS，读到所有租户的元数据（列表排序时报「列名 'Sort' 不明确」） | **待修**：`TenantAwareDataSource` 每次借出连接时显式把 `BypassRls` 置 0/NULL；或让 Flyway 使用独立连接池 |
| 2026-11-02 | 用脚本 `-replace` 改含中文的 Java 源文件，注释行末尾被弄坏，**下一行代码被吞进注释**（`List<Long> delegated` 变成注释内容）：编译通过，但审批代理静默失效 | 改 Java 源码只用编辑器级精确替换；改完必须 `grep` 关键代码行，确认没被注释掉。这类缺陷只有集成测试能抓到 |
| 2026-11-02 | `DATEADD(hour, ?, ...)` 的参数传 `NULL`：SQL Server 推断不出类型，报 8116（nvarchar 与 dateadd 参数 2 冲突） | 时间在 Java 侧算好传 `Timestamp`；不要让同一个参数既做判空又做函数入参 |
| 2026-11-02 | 库里时间列都是 `sysutcdatetime()`（UTC），而 `LocalDateTime.now()` 是本地时间（+08） | 凡是「比较时间」的功能（代理有效期、任务到期）必须统一到 UTC：写入前 `toUtc()`、读出 `fromUtc()`。否则 +08 时区下代理永不生效、超时永不触发 |
| 2026-11-02 | 主子表「软删除」写库成功，但明细里仍能看到已删行 | 列表引擎只有当**字段元数据登记了 `IsDeleted`** 时才追加 `AND IsDeleted = 0`；任何要软删的表必须把该字段登记为隐藏字段（`IsVisible=0`） |
| 2026-11-02 | 明细表格里没填的数字列以 `null` 提交，顶掉列默认值 → 「不能将值 NULL 插入列 Sort」 | 服务端保存子行前剔除「非空字段上的 null」（视为没填，交给默认值）；只有可空字段才允许显式 null |
| 2026-11-02 | `sys.security_predicates` 没有 `security_policy_id` 列，按它 JOIN 判断「表是否已在 TenantPolicy 里」会报列名无效 | 用 `WHERE target_object_id = OBJECT_ID('schema.Table')` 判断即可 |
| 2026-11-02 | 往 `application.yml` 追加**第二个顶层 `spring:` 块**：YAML 后键覆盖前键，datasource/flyway 配置被整块吃掉（启动直接连不上库） | 只能往已有的 `spring:` 块里合并；改完用 `Select-String '^[a-z]+:'` 检查顶层键没有重复 |
| 2026-11-02 | SQL 里 `o.StatusField` 不写 `AS`：返回的列名就是 `StatusField`，前端按 `statusField` 取到 `undefined`（表格整列空白） | 给每个非直观别名显式写 `AS xxx`；前端拿到 JSON 先看键名大小写再写代码 |
| 2026-11-02 | Playwright 用 `innerText` 断言设计器表格内容：值都在 `<input>` 里，`innerText` 拿到的是空表格 → 误判失败 | 表单类断言用 `inputValue()` 或直接数行；表格里的文本只用于断言表头 |
| 2026-11-02 | 打印/导出的 HTML 直接插值单据字段：单据名里写 `<script>` 就能打穿打印页 | 模板占位符一律 HTML 转义（`PrintService.escape`），并加断言「不会输出 `<script>`」 |
| 2026-11-02 | 新增子表（DocStatus / DocTransition / PrintTemplate）后，发布回滚报外键冲突 `DELETE plat.DataObject` | 回滚顺序：先删所有指向 DataObject 的子表（关系、状态、流转、打印模板），再删对象；同时把这些表加入发布快照，否则回滚后配置丢失 |
| 2026-11-02 | 前端侧边栏按数据对象拼菜单，只有 3 个对象，563 项功能菜单完全不可见；其实 `plat.Menu` 已有 636 条（10 域 / 62 模块） | 新增 `GET /api/menu/tree` 按 ParentId 组树，做租户/终端（MenuTerminal）/权限过滤；侧边栏改菜单树，未绑 `PageId` 的菜单进 `/m/:code` 占位页。菜单与对象不是一一对应 |
| 2026-11-02 | `plat.Menu` 存在同名节点（「角色管理」「登录用户」重复），按原样渲染会出现重复菜单 | 前端不做隐式去重；菜单治理需按 ParentId+Code 清理/合并历史数据 |
| 2026-11-02 | 平台管理入口散落在「平台与主数据」里，管理员没有独立控制台；租户列表也没有查询接口 | 新增 `V38__089_platform_admin_menus.sql`（8 模块 / 32 入口）+ `/admin` 概览、`/admin/tenants`、`/admin/menus`；未实现页面走 `/m/:code` 占位；平台管理菜单仅平台管理员可见 |
| 2026-11-02 | 模块/功能点全是种子数据，没有管理界面；权限点 `MOD:`/`FUN:` 靠人肉与模块数据同步 | 新增「功能模块管理」窗口：保存模块/功能点自动补权限点，**删除时回收权限点与 RolePermission**（否则权限设计器留孤儿资源）；层级由父节点推导，父子成环在服务端拦 |
| 2026-11-02 | 改模块编码后权限点没跟着改：`UPDATE` 里用 `SELECT CONCAT('MOD:', Code)` 读的是**改后**的编码，永远匹配不到旧权限点 | 改名迁移必须先查旧编码再迁移；并且 `String.replace` 全局替换会把同样的补丁打进另一个方法（本次误插进 `saveFunction`），改完要 grep 确认只改到目标位置 |
| 2026-11-02 | Playwright 点保存后弹窗没关就去点树节点：`.el-dialog input` 命中的是**已隐藏**的上一个对话框（Element Plus 关闭后仍在 DOM），报 `not editable` / `intercepts pointer events` | 选择器一律加 `:visible`（`.el-dialog:visible ...`）；E2E 用时间戳做编码后缀，避免重复运行撞唯一键 |
| 2026-11-02 | 菜单「上移/下移」不是简单 `Sort-10`：并发或跳跃时会与兄弟重排、甚至把 Sort 算成负数 | 交换两个兄弟的 Sort（各发一次 move），服务端只校验父节点与成环；不要在前端推算排序值 |
| 2026-11-02 | 「模块 vs 菜单 vs 终端 vs 子系统」四者关系靠口口相传：模块 636 条与菜单 636 条 1:1 双写、`ModuleTerminal` 空表却有 1058 条菜单终端、41 条平台菜单不绑模块 | 关系与实测数字整理进 `docs/model-module-subsystem-menu-terminal.md`；新增 `GET /api/admin/modules/model-map` 暴露规模与「未接通」警告（未绑模块 / 占位页 / 空表），管理窗口顶部直接显示，避免再靠人查表 |
| 2026-11-02 | 侧边栏同时有硬编码「平台」组和「功能菜单 → 平台管理」，平台树根又和组标题重复，看起来像两套平台入口 | 重组为「工作台 / 平台管理 / 业务菜单 / 基础资料」四组；平台组直接渲染子模块；流程中心/待办归工作台；模块管理、菜单设置指向 `/system/modules`、`/system/menus`；01 根改名「主数据」（V39/V40） |
| 2026-11-02 | 用 PowerShell Get-Content -Raw + Set-Content 修改含中文的 Vue 文件，会把整文件按错误编码重写：中文乱码、BOM、模板字符串截断（MetaListView 被破坏，tsc 报 Unterminated string literal） | 改源码只用 read/edit/write 工具；已损坏文件可从 .git/index 找 blob（Python zlib 解压）恢复。不要用 PowerShell 文本管道改 Vue/TS 源码 |
| 2026-11-02 | keep-alive 下多个列表页实例同时存活，组件里直接读 route.params.code：切到新路由时隐藏的旧页签也跟着重新查询（/page/master-data 被当成数据对象，4 个 400） | 路由用 props 把 code 固定注入页面组件（ObjectPageView / PageView）；列表组件只认 prop，不读全局 route |
| 2026-11-02 | 页面组合全靠每个业务页手写，列表/主从/页签/看板各一套；菜单仍大量落 /m/:code 占位 | 新增前端 PageSchema（schema/types/registry/pages）+ PageView/PageTabs/Dashboard；V43 把基础资料中心、品牌、供应商、客户绑到真实路由；V44/V45 补品牌联系人 → 品牌参照选择（RecordPicker） |
| 2026-11-02 | 外观偏好只有 4 套主题 + 字号 + 明暗，「导航模式 / 标签栏形态 / 圆角 / 人民币色系」都缺；且主题色是手写 CSS 变量，加一套要改 9 个变量 | 主题只存「主色 + 名称」，色阶在 `stores/appearance.ts` 里由主色混合推导并写成内联 CSS 变量；导航/标签/圆角/字号全部落 `html[data-*]`，CSS 只认 data 属性 |
| 2026-11-02 | 梯形书签用 `::before { z-index: -1 }` 做背景，被父容器底色盖住，标签栏看起来完全没变化（截图对比才发现） | 伪元素做背景时 z-index 至少 0，并给子元素 `position: relative; z-index: 1`；样式改动必须截图对比，不能只看 class 是否存在 |
| 2026-11-02 | Vite dev 报「Failed to resolve import … Does the file exist?」，但 `npm run build` 通过、文件也真实存在 | 这是 dev server 在文件创建瞬间的**陈旧模块状态**，不是代码问题：重启 `npm run dev` 即可。判断标准是 build 是否通过 |
| 2026-11-02 | PageSchema 只有本地定义，远程编辑要发版；前后端两份定义容易漂移 | 新增 plat.PageSchema + /api/page-schema/{code} + 管理端页面编排（/system/pages）；保存时以表单 code/title/kind 覆盖 JSON，服务端二次校验；前端 30s 缓存、保存主动失效、远程失败回退本地 |



## 7. 术语表

| 缩写 | 含义 |
|---|---|
| 可用量 | 现存量 − 占用 − 冻结，唯一口径见 `inv.Stock.AvailableQty` |
| 单据 | 有单号、有状态机、有明细行的业务凭证（订单/入库/出库/调拨…） |
| 元数据 | 模块、菜单、页面、数据对象、字段、按钮、规则、审批的配置数据 |
| 引擎 | 按元数据动态生成界面与 CRUD 的运行时 |

## 8. 前端依赖白名单（web/）

> 只在 `web/` 内使用；新增依赖必须在此登记，否则 CI 失败。

| 依赖 | 版本 | 类型 | 用途 |
|---|---|---|---|
| vue | ^3.5.13 | runtime | 视图框架 |
| vue-router | ^4.5.0 | runtime | hash 路由 + 登录守卫 |
| element-plus | ^2.9.0 | runtime | 组件库（中文 locale） |
| @element-plus/icons-vue | ^2.3.1 | runtime | 图标 |
| vite | ^6.0.7 | dev | 开发服务器/构建 |
| @vitejs/plugin-vue | ^5.2.1 | dev | SFC 编译 |
| typescript | ~5.7.2 | dev | strict 类型 |
| vue-tsc | ^2.2.0 | dev | 模板类型检查 |
| terser | ^5 | dev | 生产压缩（替代 esbuild minify，见踩坑记录） |

# web/ — ASCHAIN 前端（Vue 3 + TypeScript strict + Vite）

列表、表单、权限全部由后端元数据驱动：**新增一个数据对象，前端不改一行代码**，路由 `/object/:code` 直接渲染。

## 技术栈与依赖

| 类别 | 选型 | 说明 |
|---|---|---|
| 框架 | Vue 3.5 | `<script setup>` + Composition API |
| 语言 | TypeScript 5.7（strict） | `noUnusedLocals`/`noUnusedParameters` 全开 |
| 构建 | Vite 6 + vue-tsc | `npm run build` = 类型检查 + 打包 |
| UI | Element Plus 2.x + @element-plus/icons-vue | 中文 locale，主色改为品牌绿 |
| 压缩 | terser | 见「已知限制」：Windows 下 esbuild 压缩大 chunk 会因临时文件删除失败中断 |

新增依赖必须先登记到 `../AGENTS.md` 的「前端依赖白名单」。

## 启动

```bash
cd web
npm install
npm run dev          # http://127.0.0.1:5200 ，/api 代理到 127.0.0.1:8080
npm run typecheck    # vue-tsc --noEmit
npm run build        # 产出 dist/（静态文件，交给 Nginx/网关托管）
```

后端需先启动（`mvn spring-boot:run`，:8080）。演示账号：租户 `T001` / `admin` / `Apserp@2026`（仅开发环境提示，生产构建不会显示）。

> 若执行环境禁止 npm 生命周期脚本，用 `npm install --ignore-scripts`：esbuild 走 `@esbuild/win32-x64` 预编译包，不需要 postinstall。

## 目录

```
web/
  index.html
  vite.config.ts        开发代理 / 端口 / 构建拆包
  src/
    api/                http 封装 + 后端 DTO 类型 + 各端点函数
    schema/             PageSchema 类型、注册表、workbench/master-data 页面定义与单测
    pickers/            参照选择器的业务映射（md.brand / md.partner / md.brandcontact）
    stores/             session、catalog、menus、tabs（keep-alive/affix）、appearance（主题/密度/字号）
    router/             hash 路由 + 登录守卫 + 路由 props 固定 code
    layouts/            主框架：侧边栏（工作台 / 平台管理 / 业务菜单 / 数据对象）、面包屑、多标签页
    views/              Login / Dashboard / PageView / ObjectPageView / MetaList / 设计器 / 平台页
    components/         MetaFormDialog、RecordPicker、PageTabs、AppearanceDrawer、MenuTree、CellValue
    utils/              format（日期/数字/布尔）、schema（业务域分组与图标）、menu（菜单过滤/查找）
    styles/base.css     设计变量 + 主题/暗色/密度/字号 + Element Plus 主题覆盖
```

## 元数据驱动能力

- **列表（C5）**：读取默认 `ListView` 的列（标题/宽度/对齐/是否合计/是否可见），没有视图时回退到字段定义并过滤系统列；`Id` 始终随行返回用于编辑。
- **查询**：关键字搜索（按名称/编码字段 `like`）、高级筛选（字段 + 操作符 + 值，AND 组合）、排序（表头点击，**引擎只支持升序**，降序会提示并清除）、分页（20/50/100/200，上限 500）。
- **字段权限**：`GET /api/perm/fields` 返回 `Access`（0 不可见/1 只读/2 可写）；不可见字段不渲染，只读字段禁用输入。
- **表单**：读取默认 `FormLayout`（控件类型、必填、只读、隐藏、列数、跨度）；控件映射 1 文本 / 2 整数 / 3 金额 / 4 日期 / 6 查找 / 8 开关；查找对象未配置时降级为手工输入 ID，并在占位符里说明。
- **保存**：`POST /api/meta/{objectCode}` 原样提交 JSON——新增不带 `Id`，修改带 `Id`；空的可选字段新增时不提交（交给数据库默认值），NOT NULL 数字默认 0，避免“空值写空”把 INSERT/UPDATE 打挂。
- **功能菜单（侧边栏）**：`GET /api/menu/tree` 把 `plat.Menu` 组树（10 个业务域 + 平台管理，约 679 个节点），按租户、终端（PC/PDA/POS…）与权限点过滤。侧边栏分为 **工作台**（我的待办/流程中心）、**平台管理**（仅管理员）、**业务菜单**（主数据/采购/销售/库存…）和 **数据对象**（快速入口）四组；支持逐级展开、业务菜单关键字搜索、折叠。叶子菜单进入 `/m/{code}`：已绑定页面/对象的走真实路由，未绑定的显示「菜单已登记 · 页面未绑定」占位页，并提供「去设计器绑定」入口。
- **多标签页 / 面包屑**：数据对象按 `md/pur/sal/inv/...` 前缀分组；标签页在 sessionStorage 内保持，首页 affix，支持关闭其他/全部；keep-alive 让切回页签时查询条件、滚动位置不丢。菜单页 tab 用菜单名作为标题。
- **导出**：当前筛选条件下最多 500 行 CSV（带 BOM，Excel 直接打开）。

## 页面组合（PageSchema）

后端元数据负责"字段/视图/表单/权限"，前端 `schema/` 负责"一个页面由哪些块组成"：

| 页面 code | 类型 | 组成 | 入口 |
|---|---|---|---|
| `workbench` | dashboard | KPI 卡片、基础资料列表、快捷入口、平台管理入口、数据规模条 | 工作台 `/`、`/page/workbench` |
| `master-data` | tabs | 品牌 / 品牌联系人 / 往来单位 三个真实对象页签，懒加载 + 保持挂载 | 菜单 010200 基础资料中心、`/page/master-data` |
| `object` | object | 一个数据对象 = 列表 + 筛选 + 列设置 + 新建/编辑 + 子表 + 审批 + 导出 | `/object/:code`、业务菜单绑定 |
| `placeholder` | placeholder | 已登记但未绑定页面的占位 | `/m/:code` |

实现要点：

- `schema/types.ts` 只允许可序列化描述（code/title/kind/objectCode/tabs/dashboard/permissions），函数与组件不进 schema；
- `assertPageSchema` 在注册时校验：object 必须有 objectCode、tabs 至少有页签且 key 不重复、dashboard 必须有 cards；
- 页面定义优先从后端 `plat.PageSchema`（`GET /api/page-schema/{code}`）读取；远程不存在/停用/JSON 不合法/网络失败时回退本地同构定义，前端不会因远程配置坏掉白屏；
- 平台管理 → 元数据设计 → **页面编排**（`/system/pages`）可新建/编辑/停用/删除页面，服务端做第二道 JSON 与结构校验；
- 路由用 `props` 把 code 固定进页面实例，keep-alive 下隐藏页签不会跟着新路由重新查询；
- PageView 校验页面入口权限；页面未配置给出明确错误与返回入口，不白屏。

### 页面编排（/system/pages）

- 列表：编码、标题、类型、版本、启用、更新时间；支持搜索、刷新、新建、编辑、预览、删除。
- 编辑器：表单字段 code/title/kind/enabled/remark 是权威值；保存时覆盖 JSON 中对应字段，避免两套值打架。
- 校验：JSON 语法 + PageSchema 结构 + kind 专属规则（objectCode / tabs key / dashboard cards），前后端各校验一次。
- 预览：打开 `#/page/{code}`；远程页面无需重新构建前端，保存后立即生效（前端缓存 30 秒，保存会主动失效）。
- 种子：`workbench`、`master-data` 与前端本地定义同构，便于灰度与回退。

### 参照选择（RecordPicker）

查找字段不再受"200 条下拉"限制：`RecordPicker` 走列表引擎，支持关键字、分页、默认视图列、双击选择；选中后按 `pickers/registry.ts` 的 `mapTo` 回填主键与名称/编码等便利字段。当前已接入品牌联系人 → 品牌（`V44`/`V45`）。

### 外观与偏好

右上角齿轮打开：主题配色、导航模式（侧栏 / 图标 / 顶栏）、标签栏样式、明暗、圆角、字号、界面密度。全部落到 CSS 变量与 `html[data-*]`，localStorage 持久化，刷新后保持；图标导航是“窄图标栏按域分组 + 点图标弹出叶子菜单”，不是把菜单整块隐藏。

### 生产脚本

- 首页/工作台：`aschain-dashboard-new.png`
- 基础资料中心：`aschain-master-data.png`
- 参照选择：`aschain-record-picker.png`
- 外观暗色：`aschain-dark.png`

## 平台管理（平台管理员）

侧边栏「平台管理」是独立的管理控制台（`V38__089_platform_admin_menus.sql` + `V39__090_platform_menu_cleanup.sql`，8 个模块，仅平台管理员可见）；流程中心/我的待办已归入「工作台」，平台管理树内不再重复：

| 模块 | 入口 | 状态 |
|---|---|---|
| 平台概览 | `/admin` | 可用：租户数、对象/菜单/版本统计、模块快捷入口 |
| 租户与组织 | `/admin/tenants` | 租户列表可用（只读）；组织架构、用户管理占位；角色与权限跳设计器 |
| 元数据设计 | `/design`、`/design?tab=*`、`/system/modules`、`/system/menus` | 设计器中心、字段、子表、状态机、打印、模块管理、菜单设置、发布回滚均可用；页面模板见「页面组合（PageSchema）」 |
| 规则与流程 | `/design?tab=rule/button/approval` | 可用（流程中心/待办在工作台） |
| 基础配置 | `/m/900501…` | 占位（字典/编号/参数/消息模板尚未实现） |
| 安全与审计 | `/m/900601…` | 占位（日志/导出审计/备份尚未实现） |
| 集成与开放 | `/m/900701…` | 占位（OpenAPI/Webhook/SSO 尚未实现） |
| 运维与监控 | `/m/900801…` | 占位（任务/缓存/附件/通知尚未实现） |

## 与后端的契约

| 端点 | 用途 |
|---|---|
| `POST /api/auth/login` | 登录，返回 JWT |
| `GET /api/perm/me` | 权限点、是否平台管理员 |
| `GET /api/perm/fields?objectCode=` | 字段级权限 `field -> 0/1/2` |
| `GET /api/meta/objects` | 数据对象目录 |
| `GET /api/menu/tree?terminal=1` | 功能模块菜单树（按租户/终端/权限过滤） |
| `GET /api/page-schema/{code}` | 远程页面定义；`data:null` 表示回退本地 |
| `GET /api/admin/page-schemas` | 页面编排列表（需 `DESIGN:publish`） |
| `POST /api/admin/page-schemas` | 新建/更新页面定义（服务端校验 JSON） |
| `DELETE /api/admin/page-schemas/{id}` | 软删页面定义 |
| `GET /api/admin/tenants` | 平台管理员：租户列表（只读） |
| `GET /api/meta/objects/{code}/{fields,views,forms}` | 渲染配置 |
| `GET /api/meta/{code}?filters=&sort=&page=&size=` | 列表（引擎内完成过滤/排序/分页） |
| `POST /api/meta/{code}` | 保存（新增/修改同一入口） |

契约里需要特别注意的几点（都是实际踩到的）：

1. **`FormFieldDto.controlType` 是字符串**（如 `"6"`），不是数字；`ListViewColumn.align` 同样是字符串（`"1"`/`"2"`/`"3"`）。前端类型已按实际 JSON 声明，复杂控件比较前先 `Number(...)`。
2. **修改必须带 `Id`**：列表引擎只返回 `DataObjectField.IsVisible = 1` 的列，种子数据把主键标成不可见，导致行里没有 `Id`、保存被当成新增（撞唯一键）。已在迁移 `V26__075_list_primary_key.sql` 中把主键统一置为可见（列表仍只显示视图列）。
3. **排序只升序**：`@Sort` 是逗号分隔字段名，引擎统一追加 `ASC`；传入 `desc` 不会生效。前端点击降序时提示并清除。
4. **`filters` 是 JSON 字符串**：`[{"f":"Name","op":"like","v":"农夫"}]`，字段名必须在 `DataObjectField` 白名单内。
5. **错误码**：`401` 统一回登录页；`403` 渲染无权限页；`404` 渲染对象不存在页；其余弹后端 `message`。
6. **菜单与对象不是一一对应**：菜单来自 `plat.Menu`（`MenuId → PageId / Route`），数据对象来自 `plat.DataObject`。当前只有极少数菜单绑定了 `PageId`，所以大多数菜单会落到 `/m/{code}` 占位页；等页面/对象绑定后自动变成真实页面。

## 已知限制 / 下一步

- **页面编排是“JSON 编辑器 + 校验 + 预览”**，不是拖拽式画布；页面版本历史、发布审批、灰度回滚还没做。页面 JSON 与字段元数据分属两层：页面管组合，字段/视图仍由设计器控制。
- **参照选择只做单选**；多选、按分类左树、跨对象批量回填还没做。当前唯一真实查找关系是「品牌联系人 → 品牌」；其它 lookup 字段缺 `lookupSource` 时降级为手工输入 ID。
- **工作台看板用 CSS 条形而不是图表库**：KPI 与数据规模是真实接口数据，趋势图/仪表盘/大屏（ECharts）未接；引入图表库需登记依赖白名单。
- **暗色模式覆盖主框架与常用组件**；打印、部分设计器内嵌 SVG/固定色需要逐页验收，暂不作为暗色验收范围。
- `/api/perm/me` 只返回权限点集合，不含 `CanWrite/CanDelete` 等动作位：写按钮按「有该数据对象权限」显示，实际由服务端拦截（403）。后端补动作位后按位控制即可。
- 功能菜单已接入：`plat.Menu` 当前 680 条（租户 1，含平台管理 42 条），10 个业务域 + 1 个平台管理域；已通过 `V43` 把品牌/供应商/客户/基础资料中心绑定到真实页面，其余业务菜单仍是占位页。
- 业务菜单根 `01` 已从「平台与主数据」改名为「主数据」，但其中仍保留历史的系统平台/安全与审计/集成与开放子模块；它们与平台管理里的同名模块存在重叠，下一步应做菜单迁移/下线（需确认清单）。
- 平台管理的租户列表只读；开通租户后端已有 `POST /api/admin/tenants/{id}/provision`，前端开通向导与停用/到期管理尚未接入；组织/用户/字典/审计/集成/运维页面仍是占位。
- `plat.Menu` 里存在同名节点（如「角色管理」「登录用户」重复出现），属于历史菜单数据，需要菜单治理/去重，前端目前按原样展示。
- 登录返回 `mustChangePassword`，但后端暂无改密接口，界面先不强制。
- 导出为前端 CSV（≤500 行）；大数据量导出应走后端 `export` 权限 + 异步任务。
- **安全项（后端待修）**：Flyway 迁移连接会设置 `SESSION_CONTEXT('BypassRls', 1)`，连接归还 Hikari 后未清除；后续请求若复用该连接会绕过 RLS，看到其它租户的元数据（表现为列表排序时报「列名 'Sort' 不明确」）。建议 `TenantAwareDataSource` 在每次借出连接时显式把 `BypassRls` 置 0/NULL，或让 Flyway 使用独立连接池。

## 验收

- `npm run test`：`vue-tsc` + PageSchema/参照映射单测（5 项）全绿；单测用 Vite SSR 直接加载 TS，Node 20 的 CI 不依赖 tsx/ts-node。
- `npm run build` 全绿。
- 生产验收脚本：`tools/shot/aschain-prod-check.mjs`，覆盖登录 → 工作台 → 基础资料中心（3 页签）→ 品牌联系人 → 品牌参照选择（搜索“农夫”/分页）→ 页签 keep-alive（关键字保留）→ 暗色切换 → 关闭其他 → 菜单搜索打开真实对象 → 顶层页签 keep-alive，控制台 0 错误。
- 页面编排脚本：`tools/shot/aschain-page-schema-check.mjs`，覆盖远程 PageSchema 列表 → 新建 → 远程页面打开 → 删除，控制台 0 错误。
- 外观持久化脚本：`tools/shot/aschain-appearance-check.mjs`，覆盖主题/密度/字号刷新后保持与恢复默认。
- 端到端脚本：`tools/shot/aschain-web-check.mjs`，覆盖登录 → 列表 → 关键字筛选 → 新建 → 编辑 → 导出 → 切换对象 → 刷新保持会话，控制台 0 错误。
- 菜单脚本：`tools/shot/aschain-menu-check.mjs`；平台管理脚本：`tools/shot/aschain-admin-check.mjs`；侧边栏脚本：`tools/shot/aschain-nav-check.mjs`。
- 展示截图：`tools/shot/aschain-dashboard-new.png`、`aschain-master-data.png`、`aschain-record-picker.png`、`aschain-dark.png`、`aschain-dark-dashboard.png`、`aschain-tree-rail.png`、`aschain-page-schema.png`、`aschain-remote-page.png` 等。

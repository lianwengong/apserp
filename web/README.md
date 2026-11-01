# web/ — APSERP 前端（Vue 3 + TypeScript strict + Vite）

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
    stores/             session（token/权限点）、catalog（数据对象目录）
    router/             hash 路由 + 登录守卫
    layouts/            主框架：侧边栏对象菜单、面包屑、多标签页
    views/              Login / Home / MetaList / 403 / 404
    components/         MetaFormDialog（保存引擎表单）、CellValue（单元格渲染）
    utils/              format（日期/数字/布尔）、schema（业务域分组与图标）
    styles/base.css     设计变量 + Element Plus 主题覆盖
```

## 元数据驱动能力

- **列表（C5）**：读取默认 `ListView` 的列（标题/宽度/对齐/是否合计/是否可见），没有视图时回退到字段定义并过滤系统列；`Id` 始终随行返回用于编辑。
- **查询**：关键字搜索（按名称/编码字段 `like`）、高级筛选（字段 + 操作符 + 值，AND 组合）、排序（表头点击，**引擎只支持升序**，降序会提示并清除）、分页（20/50/100/200，上限 500）。
- **字段权限**：`GET /api/perm/fields` 返回 `Access`（0 不可见/1 只读/2 可写）；不可见字段不渲染，只读字段禁用输入。
- **表单**：读取默认 `FormLayout`（控件类型、必填、只读、隐藏、列数、跨度）；控件映射 1 文本 / 2 整数 / 3 金额 / 4 日期 / 6 查找 / 8 开关；查找对象未配置时降级为手工输入 ID，并在占位符里说明。
- **保存**：`POST /api/meta/{objectCode}` 原样提交 JSON——新增不带 `Id`，修改带 `Id`；空的可选字段新增时不提交（交给数据库默认值），NOT NULL 数字默认 0，避免“空值写空”把 INSERT/UPDATE 打挂。
- **多标签页 / 面包屑 / 侧边栏**：数据对象按 `md/pur/sal/inv/...` 前缀分组，标签页在 sessionStorage 内保持，刷新后仍停留原对象。
- **导出**：当前筛选条件下最多 500 行 CSV（带 BOM，Excel 直接打开）。

## 与后端的契约

| 端点 | 用途 |
|---|---|
| `POST /api/auth/login` | 登录，返回 JWT |
| `GET /api/perm/me` | 权限点、是否平台管理员 |
| `GET /api/perm/fields?objectCode=` | 字段级权限 `field -> 0/1/2` |
| `GET /api/meta/objects` | 数据对象目录 |
| `GET /api/meta/objects/{code}/{fields,views,forms}` | 渲染配置 |
| `GET /api/meta/{code}?filters=&sort=&page=&size=` | 列表（引擎内完成过滤/排序/分页） |
| `POST /api/meta/{code}` | 保存（新增/修改同一入口） |

契约里需要特别注意的几点（都是实际踩到的）：

1. **`FormFieldDto.controlType` 是字符串**（如 `"6"`），不是数字；`ListViewColumn.align` 同样是字符串（`"1"`/`"2"`/`"3"`）。前端类型已按实际 JSON 声明，复杂控件比较前先 `Number(...)`。
2. **修改必须带 `Id`**：列表引擎只返回 `DataObjectField.IsVisible = 1` 的列，种子数据把主键标成不可见，导致行里没有 `Id`、保存被当成新增（撞唯一键）。已在迁移 `V26__075_list_primary_key.sql` 中把主键统一置为可见（列表仍只显示视图列）。
3. **排序只升序**：`@Sort` 是逗号分隔字段名，引擎统一追加 `ASC`；传入 `desc` 不会生效。前端点击降序时提示并清除。
4. **`filters` 是 JSON 字符串**：`[{"f":"Name","op":"like","v":"农夫"}]`，字段名必须在 `DataObjectField` 白名单内。
5. **错误码**：`401` 统一回登录页；`403` 渲染无权限页；`404` 渲染对象不存在页；其余弹后端 `message`。

## 已知限制 / 下一步

- `/api/perm/me` 只返回权限点集合，不含 `CanWrite/CanDelete` 等动作位：写按钮按「有该数据对象权限」显示，实际由服务端拦截（403）。后端补动作位后按位控制即可。
- 暂无删除/审批/附件/子表控件；`MetaFormDialog` 的控件映射预留了扩展位。
- 菜单来自数据对象目录（尚无 `plat.Menu` 查询接口）；菜单设计器/页面设计器未迁入本周范围。
- 登录返回 `mustChangePassword`，但后端暂无改密接口，界面先不强制。
- 导出为前端 CSV（≤500 行）；大数据量导出应走后端 `export` 权限 + 异步任务。
- **安全项（后端待修）**：Flyway 迁移连接会设置 `SESSION_CONTEXT('BypassRls', 1)`，连接归还 Hikari 后未清除；后续请求若复用该连接会绕过 RLS，看到其它租户的元数据（表现为列表排序时报「列名 'Sort' 不明确」）。建议 `TenantAwareDataSource` 在每次借出连接时显式把 `BypassRls` 置 0/NULL，或让 Flyway 使用独立连接池。

## 验收

- `npm run typecheck`、`npm run build` 全绿（当前产物 gzip ≈ 390 KB）。
- 端到端脚本：`tools/shot/apserp-web-check.mjs`（Playwright + 本机 Edge），覆盖登录 → 列表 → 关键字筛选 → 新建 → 编辑 → 导出 → 切换对象 → 刷新保持会话，当前 10/10 通过、控制台 0 错误。
- 展示截图：`tools/shot/apserp-final-*.png`。

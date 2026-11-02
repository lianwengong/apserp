# APSERP（进销存 V3 · 引擎驱动）

[![CI](https://github.com/lianwengong/apserp/actions/workflows/ci.yml/badge.svg)](https://github.com/lianwengong/apserp/actions/workflows/ci.yml)

AI 全量编码模式下的项目骨架。规范见 `AGENTS.md`，架构决策见 `docs/adr/`。

## 仓库与 CI

| 平台 | 地址 | 用途 | 能跑到 |
|---|---|---|---|
| GitHub | https://github.com/lianwengong/apserp | **主 CI** | 编译 / 42 个测试（含 SQL Server 集成测试）/ 架构守护 / 前端构建 |
| Gitee | https://gitee.com/a-shen/apserp | 镜像 + Gitee Go | 编译 / 单测 / 架构守护（云端无 SQL Server、Node 版本低） |

- `git push` 默认推 GitHub（`branch.master.remote=github`）；推 Gitee 用 `git push origin master`。
- 本地跑同一套四段：`powershell -ExecutionPolicy Bypass -File tools\ci-local.ps1`
- CI 结构与平台差异见 `docs/git-and-ci.md`；自建主机跑全量见 `docs/ci-gitee-host.md`。

## 环境要求

| 组件 | 版本 | 本机状态 |
|---|---|---|
| JDK | 21 | 已装（Adoptium 21.0.12） |
| Maven | 3.9+ | 已装 3.9.16（C:\Users\59714\tools\maven） |
| Git | 2.4x | 已装 2.56.0（PortableGit） |
| SQL Server | 2022 | 已装；库 `APSErpV3` 已就绪（225 表/792 外键/RLS） |
| Docker | 可选（Testcontainers 用） | 未装（CI 上跑） |

## 快速开始

```sql
-- 1. 先由 DBA 建一个空库（Flyway 不负责建库）
CREATE DATABASE [APSErpV3] COLLATE Chinese_PRC_CI_AS;
```

```bash
# 2. 执行迁移（建架构、表、外键、RLS、引擎、演示数据）
mvn flyway:migrate -Dflyway.url="jdbc:sqlserver://localhost:1433;databaseName=APSErpV3;encrypt=false" \
                   -Dflyway.user=sa -Dflyway.password=***

# 2. 启动
mvn spring-boot:run

# 3. 冒烟：查询品牌列表（需要先执行 seed 里的演示数据）
curl -H "X-Tenant-Id: 1" -H "X-User-Id: 1" \
     "http://localhost:8080/api/meta/md.brand?page=1&size=10"
```

## 前端（web/）

Vue 3 + TypeScript strict + Vite，页面由元数据驱动（`/object/:code`），不写业务页面代码。

```bash
cd web
npm install
npm run dev        # http://127.0.0.1:5200 ，/api 代理到 127.0.0.1:8080
npm run build      # 类型检查 + 产物 dist/
```

演示账号：租户 `T001` / `admin` / `Apserp@2026`。目录、契约、已知限制见 [`web/README.md`](web/README.md)。

## 目录

```
apserp/
  AGENTS.md               AI 编码契约（最重要）
  docs/adr/               架构决策记录
  docs/week1/             第一周任务卡
  src/main/java/com/apserp
  src/main/resources/db/migration   Flyway 迁移（S1 已含建库脚本）
  web/                    前端（Vue 3 + TS strict + Vite）
```

## 已实现的引擎能力

引擎不是「脚手架」，下面这些能力已经能用配置驱动，且都有集成测试兜底（`mvn test -Dit.db=true`，129 个用例）：

| 能力 | 入口 | 说明 |
|---|---|---|
| 列表/表单/字段权限 | `GET /api/meta/{objectCode}` | 视图列、表单布局、字段级 可写/只读/不可见 全部来自元数据 |
| 保存引擎 | `POST /api/meta/{objectCode}` | 一次事务内保存主表 + 明细；租户字段、外键由服务端强制写入 |
| 主子表 | `plat.DataObjectRelation` | 别名即 JSON 键（如 `Contacts`）；未提交的子行软删除；行数上限保护 |
| 规则引擎 | `/api/design/rules`、`/api/runtime/...` | 自研表达式（无 SpEL/JS），保存前校验，错误阻断/警告放行，带测试台 |
| 动作/按钮 | `POST /api/runtime/action/execute` | 内置/导航/命令/脚本四类动作，服务端命令注册表：`export.csv` `copy.record` `audit.log` `workflow.submit` |
| 审批流 | `/api/runtime/workflow/**` | 条件分支、或签/会签/顺签、退回、加签、撤回、抄送、节点超时催办、审批代理 |
| 发布与回滚 | `/api/design/versions/**` | 全量快照 + diff + 整体回滚 + **灰度发布**（指定用户先吃新版本）|
| 元数据缓存 | `MetaCache` | 60 秒 TTL + 发布/回滚/激活显式失效，key 带租户 |
| 设计器中心 | `/#/design` | 字段 / 子表 / 规则 / 按钮 / 审批 / 权限 / 发布 七个页签 |

## 已知限制（第一周内解决）

- Flyway 脚本含 `GO` 批次分隔，需 Flyway ≥ 9.16（SQL Server 支持 GO）；若用旧版，执行 `tools/strip_go.py` 预转换。
- `V20__dev_seed_meta.sql` 是开发/演示数据，生产环境由初始化向导生成，不随迁移发布。
- 灰度名单目前只做「谁先吃到新版」的标记与展示，运行时读元数据仍按租户统一读取（要按用户分版本读，需要把快照做成可查询的物化结构，属于下一阶段）。

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

## 已知限制（第一周内解决）

- Flyway 脚本含 `GO` 批次分隔，需 Flyway ≥ 9.16（SQL Server 支持 GO）；若用旧版，执行 `tools/strip_go.py` 预转换。
- `V20__dev_seed_meta.sql` 是开发/演示数据，生产环境由初始化向导生成，不随迁移发布。

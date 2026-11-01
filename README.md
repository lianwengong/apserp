# APSERP（进销存 V3 · 引擎驱动）

AI 全量编码模式下的项目骨架。规范见 `AGENTS.md`，架构决策见 `docs/adr/`。

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

## 目录

```
apserp/
  AGENTS.md               AI 编码契约（最重要）
  docs/adr/               架构决策记录
  docs/week1/             第一周任务卡
  src/main/java/com/apserp
  src/main/resources/db/migration   Flyway 迁移（S1 已含建库脚本）
```

## 已知限制（第一周内解决）

- Flyway 脚本含 `GO` 批次分隔，需 Flyway ≥ 9.16（SQL Server 支持 GO）；若用旧版，执行 `tools/strip_go.py` 预转换。
- `V20__dev_seed_meta.sql` 是开发/演示数据，生产环境由初始化向导生成，不随迁移发布。

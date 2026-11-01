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
| 测试 | JUnit 5 + AssertJ + Testcontainers（真 SQL Server） |
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
- **多租户**：所有查询经 `TenantSession` 执行，自动注入 `TenantId`；业务代码不得自行拼租户条件。
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
| 2026-10-30 | `SESSION_CONTEXT` 与连接池：请求 A 设了租户上下文，请求 B 复用同一物理连接会串租户 | 统一经 `TenantSession.execute()`，在同一条连接上先设上下文再执行 SQL |
| 2026-11-01 | PowerShell 5.1 的 `Set-Content -Encoding UTF8` 会写 BOM，javac 报「非法字符」 | 一律用 Python 或 `UTF8Encoding($false)` 写文件；提交前检查 BOM |
| 2026-11-01 | Flyway 按「连接用户默认 schema」判断库是否为空；`apserp_dev` 默认 `dbo`，表都在业务 schema 下，被误判为空库并从 V1 重跑 | 既有库首次接入必须显式 `flyway:baseline -Dflyway.baselineVersion=18`；`baseline-on-migrate` 只适用于新库 |
| 2026-11-01 | 引入 `spring-boot-starter-data-redis` 但本机未装 Redis，Actuator health 直接 DOWN | 未使用的中间件先关健康检查：`management.health.redis.enabled=false` |

## 7. 术语表

| 缩写 | 含义 |
|---|---|
| 可用量 | 现存量 − 占用 − 冻结，唯一口径见 `inv.Stock.AvailableQty` |
| 单据 | 有单号、有状态机、有明细行的业务凭证（订单/入库/出库/调拨…） |
| 元数据 | 模块、菜单、页面、数据对象、字段、按钮、规则、审批的配置数据 |
| 引擎 | 按元数据动态生成界面与 CRUD 的运行时 |

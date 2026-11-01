# 本地开发环境（已就绪）

> 记录时间：2026-11-01 · 由 AI 安装并验证

## 1. 已安装组件

| 组件 | 版本 | 安装路径 | 状态 |
|---|---|---|---|
| JDK | 21.0.12.1 (Adoptium) | `C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot` | 原有，已验证 |
| Maven | 3.9.16 | `C:\Users\59714\tools\maven` | **本次安装** |
| Git | 2.56.0 (PortableGit) | `C:\Users\59714\tools\git` | **本次安装** |
| SQL Server | 2022 (16.0.1000.6) | 实例 `.`（默认实例） | 原有 |
| Docker | 未安装 | — | 非必需；Testcontainers 在 CI 跑 |
| Redis | 未安装 | — | 一期未使用，健康检查已关闭 |

## 2. 环境变量（用户级，已写入）

```
JAVA_HOME   = C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot
MAVEN_HOME  = C:\Users\59714\tools\maven
PATH       += %MAVEN_HOME%\bin
PATH       += C:\Users\59714\tools\git\cmd
PATH       += C:\Users\59714\tools\git\bin
```

验证（新开终端）：

```bash
mvn -v        # Apache Maven 3.9.16 / Java 21.0.12.1
git --version # git version 2.56.0.windows.4
```

## 3. Maven 镜像

`C:\Users\59714\.m2\settings.xml` 已配置阿里云中央仓库镜像，依赖下载走国内源。

## 4. 数据库

| 项 | 值 |
|---|---|
| 库名 | `APSErpV3` |
| 排序规则 | `Chinese_PRC_CI_AS` |
| 兼容级别 | 160（SQL Server 2022） |
| 恢复模式 | FULL |
| 表数 | 225（设计值）+ 22（`exp` 导出测试残留） |
| 外键 | 792 |
| RLS | 策略 `plat.TenantPolicy`，180 个谓词，已启用 |
| 引擎对象 | 10 个存储过程 + 3 个函数 + 3 个视图 |

### 开发账号

应用连接用专用登录，不使用 `sa`：

```
login:    apserp_dev
password: Apserp#2026Dev        （仅本地开发，生产用密钥管理）
权限:     APSErpV3 db_owner
```

`application.yml` 默认值已指向该账号，可用环境变量覆盖：

```
DB_USER / DB_PASSWORD
```

### Flyway 基线

库是由脚本手工建的，没有 Flyway 历史。首次接入已执行：

```bash
mvn flyway:baseline -Dflyway.baselineVersion=18 \
    "-Dflyway.url=jdbc:sqlserver://localhost:1433;databaseName=APSErpV3;encrypt=false;trustServerCertificate=true" \
    -Dflyway.user=apserp_dev -Dflyway.password='Apserp#2026Dev'
```

历史表现状：`installed_rank=1, version=18, type=BASELINE, success=true`。
**含义：V1–V18 视为已应用，后续新增脚本从 V19 开始。**

> 踩坑：Flyway 用「当前用户的默认 schema」判断库是否为空。`apserp_dev` 默认 schema 是 `dbo`，
> 而所有表都在 `plat/md/...` 下，`dbo` 为空 → Flyway 误判为全新库并从 V1 重跑，
> 撞上「对象已存在」。解决办法就是显式 baseline。

## 5. 启动与冒烟

```bash
cd F:\harness\apserp
mvn spring-boot:run
```

```bash
curl http://localhost:8080/actuator/health
# {"status":"UP"}

curl -H "X-Tenant-Id: 1" -H "X-User-Id: 1" \
     "http://localhost:8080/api/meta/md.brand?page=1&size=2"
# {"code":0,...,"total":4,"rows":[{"Code":"B004","Name":"元气森林",...}]}

curl -o /dev/null -w "%{http_code}" http://localhost:8080/api/meta/md.brand
# 401
```

## 6. 已知问题

| # | 问题 | 影响 | 处理 |
|---|---|---|---|
| 1 | 数据库中有 22 张 `exp.*` 表（租户导出测试残留） | 干扰表数统计 | 建议执行 `DROP SCHEMA`（需人工确认） |
| 2 | 租户 2 没有元数据，查询报「数据对象不存在」 | 无法验证租户 2 的业务数据隔离 | 需要「租户开通时克隆标准元数据」的能力（第 2 周做） |
| 3 | Redis 未安装 | 缓存相关功能不可用 | 一期不用；`management.health.redis.enabled=false` |
| 4 | 前端未初始化 | 无法验证页面渲染 | 第 1 周周四开始 |

## 7. 清理 exp 残留（待人工确认）

```sql
-- 注意：这是删除操作，属于「红线 5：数据库迁移与不可逆操作」，需人工确认后执行
DECLARE @sql nvarchar(max) = N'';
SELECT @sql += N'DROP TABLE [exp].' + QUOTENAME(name) + N';'
FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = 'exp';
EXEC sp_executesql @sql;
DROP SCHEMA [exp];
```

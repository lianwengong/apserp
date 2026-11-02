# 编号引擎

> 入口：`/#/system/code-rules`（平台管理 → 元数据设计 → 编号规则）。
> 数据：`plat.CodeRule`（规则）+ `plat.CodeSerial`（流水，V49）。

## 1. 单号构成

```
前缀 + 日期 + 分隔符 + 补零流水
 PO    20261102    -      0001
```

| 字段 | 说明 | 例 |
|---|---|---|
| `Prefix` | 业务前缀，≤20 字符 | `PO` `CT` `PS` |
| `DatePattern` | `yyyyMMdd` / `yyyyMM` / `yyyy` / `yyMMdd` / `yyyyMMddHHmmss`，留空则不带日期 | `yyyyMMdd` |
| `Separator` | 日期与流水之间，≤5 字符 | `-` |
| `DigitCount` | 流水位数 1..12 | `4` |
| `ResetCycle` | 0 不重置 / 1 按年 / 2 按月 / 3 按日 | `3` |

种子 `plat.CodeRule` 20 条（10 类单据 × 2 租户），V49 从 `Sample` 反解出前缀/日期格式/位数，
解析不出的用默认值兜底。

## 2. 为什么并发不会重号

```
UPDATE plat.CodeSerial WITH (UPDLOCK, ROWLOCK)
SET CurrentValue = CurrentValue + 1
OUTPUT inserted.CurrentValue
WHERE TenantId=? AND RuleCode=? AND Period=?
```

- **一行一次原子自增**：SQL Server 在行上持 X 锁，两个请求串行拿到 1、2…；
- 行不存在时插入初始值 1，撞唯一键说明别人先建了行 → 直接重试自增；
- **不开 Spring 事务**：开事务会把行锁持有到方法返回，8 线程下容易与插入路径互等成死锁；
  单条语句本身是原子的，语句结束即释放锁；
- 死锁受害者（`CannotAcquireLockException`）当作正常并发结果，退避重试最多 6 次。

实测：8 线程 × 5 次取号 → 40 个号互不重复，第 41 次拿到 `-041`（见 `CodeRuleIT.concurrent_unique`）。

## 3. 期间与重置

`Period` 由 `ResetCycle` 生成：

| ResetCycle | Period | 换期效果 |
|---|---|---|
| 0 不重置 | `''` | 永远同一行流水，跨年继续 |
| 1 按年 | `2026` | 新年第一单从 1 开始 |
| 2 按月 | `202611` | 每月 1 号从 1 开始 |
| 3 按日 | `20261102` | 每天从 1 开始 |

**重置不需要定时任务**：换期间就是换一行流水，老期间的记录保留（管理窗口能看到历史期间流水）。

日期一律取**业务时区**（JVM 时区，本机 +08），不用 UTC —— 单号上的日期是给人看的，
跨零点按 UTC 会生成「昨天」的号。

## 4. 接口

| 用途 | 接口 | 权限 |
|---|---|---|
| 预览（不消耗） | `GET /api/runtime/code/preview?code=PO` | 登录即可 |
| 取号（消耗 +1） | `POST /api/runtime/code/next?code=PO` | 登录即可 |
| 规则列表 | `GET /api/admin/code-rules` | `DESIGN:module` |
| 保存规则 | `POST /api/admin/code-rules` | `DESIGN:module` |
| 流水统计 | `GET /api/admin/code-rules/{code}/statistics` | `DESIGN:module` |

返回示例：`{"code":0,"data":{"docNo":"PO20261102-0001"}}`

## 5. 界面

- 左：规则列表（编码 / 名称 / **示例号（实时拼）** / 重置周期 / 状态），点行即编辑；
- 右：试算面板 —— 选规则后显示「下一个号」，可「预览」（不消耗）或「真实取号」（消耗 +1）；
  下方按规则展示当前期间、当前值与各期间流水。

## 6. 边界（明确不做）

- 不做「跨规则共享流水」（每个规则独立计数）；
- 不做「跳过已占用号」（流水只增不减；若有作废单据，号不回收）；
- 业务表单自动填单号还没接：等单据类数据对象（采购订单等）落地后，在保存前调用 `POST /api/runtime/code/next` 即可，
  不要在前端拼号（并发会重号）。

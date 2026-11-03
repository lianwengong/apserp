# 通知中心与平台用户管理

> 平台入口（无租户名登录）的两个配套能力：**站内通知**与**跨租户用户治理**。
> 通知解决「事情变了没人知道」，用户治理解决「谁来管这些账号」。

## 1. 通知中心

表是既有的 `plat.Notification`（V2 建表、V14 已纳入 RLS），字段含义：

| 字段 | 用途 |
|---|---|
| `RecipientId` | 收件人（非空，只支持「发给具体某个人」，没有全员广播） |
| `MsgType` | 1 提示 / 2 警告 / 3 错误，前端用不同颜色标签 |
| `BusinessType` / `BusinessId` | 业务关联（如 `TENANT` + 租户 Id），便于排查 |
| `LinkUrl` | 点击跳转的前端路由 |
| `IsRead` / `ReadAt` | 已读状态 |

接口：

```
GET  /api/notification?limit=50      当前用户的通知（时间倒序）
GET  /api/notification/unread-count  未读数
POST /api/notification/{id}/read     标记已读（幂等）
POST /api/notification/read-all      全部已读
```

边界：**按 `RecipientId` 收口**——别人的通知读不到、也改不动；标记别人的通知返回「通知不存在」而不是「无权限」，避免探测。

前端：顶栏铃铛（未读角标，60s 轮询）+ 右侧抽屉（分级标签、点击已读并跳转、全部已读）。

## 2. 租户到期自动停用

`TenantExpiryJob`（每天 01:10，`app.tenant.expiry-cron` 可覆盖）：

1. 找 `ExpireAt < now()` 且 `IsEnabled=1` 的租户；
2. 逐个置为停用（只改标志，不删数据）；
3. 给**每个平台账号**发一条 `MsgType=2` 的通知，标题带租户名，正文带编码与到期时间，链接到 `/admin/tenants`。

要点：

- 任务没有请求上下文，方法内自己 `TenantContext.set(null, null, false, APP_PLATFORM, true)` 打开平台作用域，finally 恢复——否则 RLS 把租户表挡成空集，任务「成功但什么都没做」。
- 幂等：只处理仍启用的租户，第二次扫描不会重复发通知。
- 手动触发：`POST /api/admin/tenants/expire-scan`（运维用，返回本次停用数）。

## 3. 平台账号（`/admin/users`）

**只管平台账号**（`plat.User.IsPlatformAccount=1`，挂在保留租户 `Id=0/T000 平台运营` 下）。
租户里的账号不在这里出现——那是租户自己的用户管理，平台管理员不该顺手改客户账号。

```
GET  /api/admin/users?keyword=            平台账号列表
POST /api/admin/users                     新增平台账号 {userName, displayName, password}
PUT  /api/admin/users/{id}/enabled        启用/停用
POST /api/admin/users/{id}/reset-password 重置口令（强制改密 + 解锁）
```

- 新增账号自动 `MustChangePwd=1`，首次登录必须改密；账号名限字母开头的 2-50 位；
- 停用立刻生效：登录平台入口返回「账号已停用」；已登录会话在令牌过期前仍有效（无主动踢下线）；
- 重置口令：写新哈希 + `MustChangePwd=1` + 清 `FailCount/LockedUntil`；
- 护栏：不能停用自己；至少保留一个可用平台账号；对租户账号调用这些接口会明确报「请到租户自己的用户管理里维护」；
- 租户管理员的日常口令维护在「租户管理 → 管理员口令」里（见 `docs/tenant-lifecycle.md`）。

## 3.1 平台角色与权限（`/admin/roles`）

平台入口的「角色与权限」**不再是**元数据设计器的租户权限页，而是平台运营权限：

| 权限点 | 管什么 |
|---|---|
| `PLAT:TENANT` | 租户开通/停用/编辑/管理员口令 |
| `PLAT:ACCOUNT` | 平台账号新增/启停/重置口令 |
| `PLAT:ROLE` | 平台角色与成员 |
| `PLAT:MENU` / `PLAT:MODULE` | 菜单总览 / 模块与终端 |
| `PLAT:MONITOR` | 到期扫描、通知 |
| `PLAT:AUDIT` | 审计与日志 |

种子角色（V58）：`PLAT_ADMIN`（内置全权）、`PLAT_OPS`（运维，无角色/审计）、
`PLAT_AUDIT`（只读审计）。升级时已有平台账号统一绑定 `PLAT_ADMIN`，不降权。

判定方式：

- 平台登录时，`adm` 声明 = 该账号**是否持有 `PLAT_ADMIN`**；
- 持有者直通；其余平台账号走数据库函数 `plat.ufn_Perm_Check`，按 `PLAT:*` 逐项判定；
- 平台接口用 `@RequiresPermission("PLAT:...")` 标注（租户管理/平台账号/平台角色），
  权限不足返回 403「没有权限：PLAT:xxx」；
- 平台入口的侧边栏不做权限过滤（菜单是控制台入口，权限在接口层把关），
  否则无权限账号会看到空白侧边栏。

## 4. 权限边界

| 调用方 | 通知 | 到期扫描 | 平台账号接口 |
|---|---|---|---|
| 平台登录（`app=1` + `pf=true`） | 自己的 | 允许 | 允许 |
| 租户登录 | 自己的 | 403 | 403 |

## 5. 后续

- 通知目前只有「租户到期」一个来源；审批到达/驳回等需要业务侧调用 `NotificationService.record(...)`。
- 停用账号不会踢掉已登录会话（JWT 无状态），如需立即失效要加令牌黑名单或短 TTL。
- 到期扫描可以再加「临期 7 天提醒」，目前只在过期时通知一次。

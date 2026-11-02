# 用自建主机跑 Gitee Go 流水线（可选方案）

> 用途：Gitee Go 的**云端**环境只给 JDK 17 / Node 15 / 没有 SQL Server，所以前端构建与集成测试跑不了。
> 把流水线派到**你自己的 Windows 机器**上执行，就能四段全跑（编译 → 测试含真库 → 架构守护 → 前端）。
> 不需要 GitHub，也不需要任何令牌。

## 一、前提

| 项 | 要求 | 本机现状 |
|---|---|---|
| 操作系统 | Windows 10/11 | ✅ |
| JDK | 21 | ✅ `C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot` |
| Maven | 3.9+ | ✅ `C:\Users\59714\tools\maven` |
| Node | 18+ | ✅ v24 |
| SQL Server | 2022，本机实例，Windows 账号为 sysadmin | ✅ 实例 `.` |
| 主机在线 | 构建时开机联网 | 需要你自己确认 |

## 二、在 Gitee Go 里建主机组

1. 打开 https://gitee.com/a-shen/aschain/gitee_go
2. 左侧 **主机组** → **新建主机组**，名称填 `aschain-win`
3. 按页面提示安装 agent（Windows 版），安装命令里会带一个 `--token=xxx`
4. 装完回到主机组页面，状态变为「在线」即成功
5. 记下这个主机组的 **ID**（页面上的 `hostGroupID`，形如 `5fxxxxxx`）

## 三、把流水线切到主机模式

1. Gitee Go → **流水线** → **新建流水线** → 选「自定义」→ 它会读取仓库里的 `.workflow/*.yml`
2. 选择 `.workflow/GiteeHostPipeline.yml`（或把其内容粘进编辑器）
3. 把 `hostGroupID: gitee-go` 改成你的主机组 ID
4. 保存并执行

流水线只做一件事：在主机上执行 `tools\ci-local.ps1`，也就是：

| 段 | 内容 |
|---|---|
| build | `mvn compile` |
| test | 重建空测试库 → 重放 V1–V28 迁移 → 42 个用例（含真库集成测试） |
| quality | ArchUnit 架构规则 |
| web | `npm ci` + `npm run build` |

> `ci-local.ps1` 会自动处理：找 JDK/Maven、跳过不可用的 `.m2` 目录、杀残留 esbuild 进程、重建测试库。

## 四、注意

- **构建时主机必须在开机联网状态**；关机或休眠时触发会失败。
- 首次执行前，确认该机器 Windows 账号能连本机 SQL Server（`sqlcmd -S . -E` 能进即可）。
- 测试库 `ASChain_TEST` 会被反复重建，**不要**把手工数据放进去。
- 主机 agent 以当前 Windows 账号运行，能访问本机数据库与文件；不要把它装在生产服务器上。

## 五、和云端流水线的关系

| 流水线文件 | 跑在哪 | 能跑什么 |
|---|---|---|
| `.workflow/MasterPipeline.yml` | Gitee 云端 | 编译、单测、架构守护（JDK 17 降级；无前端、无集成测试） |
| `.workflow/GiteeHostPipeline.yml` | 你的 Windows 主机 | **全部四段** |

建议：云端那条留作「每次 push 的快速闸门」，主机那条留作「合并前/发布前全量」。

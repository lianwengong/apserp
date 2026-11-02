# 仓库与 CI 接入（从零开始）

> 面向第一次建仓库的人。照做即可，不需要事先懂 git 服务器。
> 前置：本机已装 Git（`C:\Users\59714\tools\git`）、JDK 21、Maven、SQL Server。

## 一、先把话说清：什么是“仓库地址”

**仓库（repository）** = 一个放在服务器上的项目文件夹，专门用来存代码和它的全部历史版本。
**仓库地址** = 访问它的网址，两种形式：

| 形式 | 例子 | 用途 |
|---|---|---|
| HTTPS | `https://gitee.com/你的用户名/aschain.git` | 最省事，输入账号密码或令牌即可 |
| SSH | `git@gitee.com:你的用户名/aschain.git` | 免密，需先配公钥，适合天天提交 |

地址由托管平台在“新建仓库”成功后生成，**不是自己编的**。

## 二、选一个平台（三选一）

| 平台 | 免费私有仓库 | 免费 CI | 国内速度 | 适合 |
|---|---|---|---|---|
| **Gitee（码云）** | 有 | 有（Gitee Go，需申请/额度） | 快 | 团队在国内、要私有 |
| **GitHub** | 有 | Actions 每月 2000 分钟 | 一般（需代理） | 要生态、开源、海外协作 |
| **自建 GitLab** | 有 | 有（自带 Runner） | 看机房 | 公司已有服务器、要数据自持 |

**建议**：先用 **Gitee 私有仓库**把流程跑通（最快、不需要代理）；以后要接公司 GitLab，只要换一次远程地址，代码与 CI 文件不用改。

> 注意：本项目的 `.gitlab-ci.yml` 是 **GitLab 格式**。
> - 用 Gitee：需要在 Gitee Go 里建流水线（或把 CI 脚本改成 Gitee Go 的 YAML）。
> - 用 GitHub：需要把 `.gitlab-ci.yml` 转成 `.github/workflows/ci.yml`（可让我转）。
> - 用自建 GitLab：**开箱即用**，`.gitlab-ci.yml` 直接被识别。

## 三、建仓库的 5 步（以 Gitee 为例）

1. 打开 https://gitee.com ，用手机号注册并登录。
2. 右上角 **+** → **新建仓库**。
3. 填写：
   - 仓库名称：`aschain`
   - 路径：`aschain`（地址会变成 `https://gitee.com/你的用户名/aschain.git`）
   - 是否开源：**私有**
   - **不要**勾选“使用 Readme 初始化”“初始化 .gitignore”“初始化开源许可证”——本地已有代码，勾了会冲突。
4. 点 **创建**。页面会显示仓库地址，复制它。
5. 把地址发给我，或自己在本机执行：

```powershell
cd F:\harness\aschain
git remote add origin https://gitee.com/你的用户名/aschain.git
git push -u origin master
```

首次推送会要求输入 Gitee 账号密码；如果提示不支持密码，用 **私人令牌**（Gitee：设置 → 私人令牌 → 生成，勾选 projects 权限），密码处填令牌。

## 四、CI 是怎么被触发的

```
本地 git push  →  平台收到推送  →  按仓库里的 CI 配置文件执行  →  结果出现在网页上（通过/失败）
```

本项目的 CI 分四段（`.gitlab-ci.yml` / `.github/workflows/ci.yml`）：

| 段 | 做什么 | 依赖 |
|---|---|---|
| build | `mvn compile` | 无 |
| test | `mvn verify`：单测 + 集成测试（真 SQL Server） | 平台需支持 service 容器（GitLab Runner / Docker） |
| quality | 架构守护 `ArchitectureTest` | 无 |
| web | `npm ci` + `npm run build` | Node 18+（Vite 6 要求） |

集成测试的环境变量已在 CI 配置里配好（`IT_ENABLED`、`IT_DB_URL` 等），**不需要手工建测试库**——流水线里的 `CiDbInit` 会建。

### 三个平台能跑到什么程度（已实测）

| 平台 | 配置文件 | 能跑 | 跑不了 |
|---|---|---|---|
| 自建 GitLab + Runner | `.gitlab-ci.yml` | 四段全跑（service 容器起 SQL Server） | 无 |
| GitHub | `.github/workflows/ci.yml` | 四段全跑 | 无 |
| **Gitee Go（当前）** | `.workflow/MasterPipeline.yml` | 编译、单测、架构守护 | **集成测试**（无 SQL Server）、**前端构建**（云端 Node 最高 15，Vite 6 要 18+） |

Gitee Go 的补偿办法（按推荐顺序）：

1. **代码留在 Gitee，流水线挪到 GitHub**：Gitee 做镜像推送或手动 `git remote add github`，全量四段在 GitHub Actions 跑（免费 2000 分钟/月）。
2. **给 Gitee Go 挂自建主机**：`shell@agent` 插件把流水线跑在你这台机器上（已装 JDK 21 + SQL Server），可跑全量；代价是机器要在构建时开机。
3. **只把 Gitee Go 当“编译闸门”**：够了就够，前端与集成测试本地用 `tools/ci-local.ps1` 兜住。

## 五、不想等平台，先在本地跑一遍 CI

```powershell
cd F:\harness\aschain
powershell -ExecutionPolicy Bypass -File tools\ci-local.ps1
```

它按 CI 的四段依次执行：编译 → 测试（自动重建空测试库并重放 V1–V28 迁移）→ 架构守护 → 前端构建。
加 `-SkipIt` 可跳过数据库集成测试。

若第一次跑报“测试库不存在/无权限”，先执行一次：

```powershell
powershell -ExecutionPolicy Bypass -File tools\ci-db-reset.ps1 -Drop
```

（需要本机 Windows 账号是 SQL Server 的 sysadmin；脚本只动 `ASChain_TEST`，不碰 `ASChain`。）

## 六、Gitee Go 开通步骤

1. 打开仓库页 → 顶部 **服务** → **Gitee Go**（或访问 `https://gitee.com/a-shen/aschain/gitee_go`）；
2. 首次会要求 **绑定手机号**（账号设置里绑）；
3. 选择「自定义流水线」→ 它会读取仓库里的 `.workflow/MasterPipeline.yml`；
4. 保存后自动生成一次构建；以后 push 到 master 自动触发；
5. 免费额度：单仓库 200 分钟 + 账号每月 500 分钟。

## 六、常见问题

| 现象 | 原因 | 处理 |
|---|---|---|
| `remote: Permission denied` | 账号/令牌无该仓库权限 | 确认仓库路径、令牌勾选 projects |
| `failed to push some refs` | 远程仓库已有提交（初始化了 README） | 新建空仓库，或 `git pull --rebase` 后再推 |
| CI 里 test 段红 | 集成测试失败 | 看 job 日志的 `target/surefire-reports`，或本地跑 `ci-local.ps1` 复现 |
| CI 里 web 段红 | 依赖锁文件与 package.json 不一致 | 本地 `npm install` 后提交 `package-lock.json` |
| 本机 Mockito 报 `拒绝访问`/agent 加载失败 | 沙箱或杀软拦截 JVM 动态挂载 | 已用 `mock-maker-subclass` 规避；如仍报错，在普通终端（非沙箱）重跑 |

## 七、提交规范（最少要知道的三条）

1. 不直接推 `master` 的功能代码：先 `git checkout -b feat/xxx`，推分支，提 PR/MR。
2. 提交信息写清“做了什么”，例：`feat(engine): 列表查询支持数据范围`。
3. 改数据库只能**新增** `V{序号}__{描述}.sql`，已执行的脚本不许改。

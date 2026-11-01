# 安装 Docker Desktop（Windows 10 家庭版 · 装到 F 盘）

> 本机现状：Windows 10 家庭中文版 build 19045 · 用户 `lwg` **无管理员权限** · C 盘仅剩 8.3 GB · F 盘剩 89.4 GB
> 结论：**必须用管理员账户执行一次，且必须重启**；安装体积全部放 F 盘。

## 为什么家庭版必须走 WSL2

Docker Desktop 在 Windows 上有两个后端：

| 后端 | 适用版本 | 本机 |
|---|---|---|
| Hyper-V | 专业版 / 企业版 / 教育版 | ❌ 家庭版没有 Hyper-V |
| WSL2 | Windows 10 2004+ (build 19041+) 全版本 | ✅ build 19045 满足 |

CPU 虚拟化已在 BIOS 开启（`VirtualizationFirmwareEnabled=True`），但 `HypervisorPresent=False`，
说明 WSL2 尚未启用。启用需要 **管理员 + 重启**。

## 步骤一：启用 WSL2（管理员 PowerShell，复制粘贴执行）

```powershell
# 1) 启用两个必需功能（不会立即重启）
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# 2) 重启（必须）
Restart-Computer
```

重启后继续（仍是管理员）：

```powershell
# 3) 装 WSL2 内核并设为默认版本
wsl --update
wsl --set-default-version 2

# 4) 验证：应输出 2
wsl --status
```

## 步骤二：把 Docker 的数据目录指到 F 盘（关键）

C 盘只剩 8.3 GB，而 Docker Desktop 自带 WSL 发行版 + 镜像最少要 15–20 GB，
**不指定目录一定会把 C 盘撑爆**。

先把全局 WSL 默认存储位置改到 F 盘：

```powershell
# 创建目录
mkdir F:\Docker\wsl -Force

# 全局默认（新导入的发行版都放 F 盘）
# 写入 C:\Users\<你>\.wslconfig
@"
[wsl2]
# 内存上限，避免吃满 16G
memory=6GB
# 交换文件也放 F 盘
swap=4GB
swapFile=F:\\Docker\\wsl\\swap.vhdx
"@ | Set-Content "$env:USERPROFILE\.wslconfig" -Encoding UTF8
```

> `.wslconfig` 只管内存/CPU/swap；发行版磁盘的位置由 Docker Desktop 自己的设置决定，
> 见步骤四。

## 步骤三：安装 Docker Desktop 到 F 盘

安装包已下载到 `F:\installers\DockerDesktopInstaller.exe`（约 550 MB）。

```powershell
# 以管理员身份运行命令行，指定安装目录到 F 盘
& "F:\installers\DockerDesktopInstaller.exe" install --quiet `
    --installation-dir="F:\Docker\DockerDesktop" `
    --wsl-default-data-root="F:\Docker\wsl" `
    --accept-license
```

参数说明：
- `--installation-dir` 程序本体目录
- `--wsl-default-data-root` Docker 的两个 WSL 发行版（`docker-desktop`、`docker-desktop-data`）落盘位置
- `--accept-license` 跳过协议确认（**仅在你已确认许可证合规时使用**）

若命令行参数被忽略，用 GUI 兜底：

1. 开始菜单 → Docker Desktop → 首次启动会提示接受协议
2. **Settings → Resources → Advanced → Disk image location** 改成 `F:\Docker\wsl`
3. 点 **Apply & restart**

## 步骤四：验证安装

```powershell
docker version          # Client 与 Server 都要有输出
docker run --rm hello-world
```

再跑一条真实用例（顺便验证 F 盘落盘）：

```powershell
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Apserp#2026Dev" `
  -p 1434:1433 -d --name apserp-mssql-test `
  mcr.microsoft.com/mssql/server:2022-latest
docker ps
```

## 步骤五：切换项目到 Docker 模式（可选）

本机已有 SQL Server，Docker 不是必需的。装好后可以让集成测试走容器：

```bash
# 用 docker-compose 起全套（SQL Server + Redis）
docker compose -f F:\harness\apserp\docker-compose.yml up -d

# 集成测试走 Testcontainers（把 CI 变量打开即可）
set CI=true
mvn test
```

## 许可证注意（重要）

| 场景 | 是否需要付费 |
|---|---|
| 个人学习、非商业 | 免费 |
| 公司规模 < 250 人 且 年收入 < 1000 万美元 | 免费（Docker Personal） |
| 公司规模 ≥ 250 人 或 年收入 ≥ 1000 万美元 | **需付费订阅**（Pro/Team/Business，约 $9–15/人/月） |

如果公司规模超过门槛，"申请"指的是**走采购流程买订阅**，而不是找免费安装包。
不想买的话有两条替代路线：

1. **Podman Desktop**（免费，同样基于 WSL2）
2. **只在 CI 上用容器**：GitHub Actions / GitLab CI 的 runner 自带 Docker，本地完全不装

## 本项目的实际需要

Docker 在本项目里**只有两个用途**，都不影响开发：

| 用途 | 本地是否需要 | CI |
|---|---|---|
| Testcontainers 集成测试 | 不需要（已改为直连本机 `APSErpV3_TEST`） | 需要 |
| 起 Redis / 消息队列 | 一期不用 | — |

已经做好的替代方案：

- `APSErpV3_TEST` 空库 + 18 个 Flyway 迁移从零跑通（225 表 / 792 外键 / 180 RLS 谓词）
- `MetaQueryLocalIT` 直连该库，覆盖建表完整性、RLS 默认拒绝、按租户过滤三个断言

所以：**装 Docker 是"锦上添花"，不装也能把 G0.1 全部走完。**

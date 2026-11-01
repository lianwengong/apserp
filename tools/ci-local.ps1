# 本地复现 CI：提交前跑一遍，与 .gitlab-ci.yml 的四段一致
# 用法：powershell -ExecutionPolicy Bypass -File tools\ci-local.ps1
#       加 -SkipIt 可跳过集成测试（不需要 SQL Server）
param([switch]$SkipIt)

$ErrorActionPreference = 'Continue'  # 外部命令的 stderr 不能被当成终止错误
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
Set-Location $root

function Resolve-Tool($name, $candidates) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
    throw "找不到 $name，请先安装或修改本脚本"
}

# JDK 21
if (-not $env:JAVA_HOME) {
    foreach ($j in @('C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot',
                     "$env:USERPROFILE\tools\jdk\jdk-21.0.2",
                     'F:\harness\tools\jdk\jdk-21.0.2')) {
        if (Test-Path "$j\bin\java.exe") { $env:JAVA_HOME = $j; break }
    }
}
if (-not $env:JAVA_HOME) { throw '未设置 JAVA_HOME（需要 JDK 21）' }
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

$mvn = Resolve-Tool 'mvn' @("$env:USERPROFILE\tools\maven\bin\mvn.cmd",
                            'C:\Users\59714\tools\maven\bin\mvn.cmd')

# 本沙箱/受控环境下 ~/.m2 部分目录不可写，改用工作区仓库 + blocked 标记
$mvnArgs = @('-B', '-ntp')
$localRepo = 'F:\harness\.m2repo'
if (Test-Path $localRepo) {
    $mvnArgs += @("-Dmaven.repo.local=$localRepo", '-Dmaven.repo.local.blocked=true')
}

$itUrl  = 'jdbc:sqlserver://localhost:1433;databaseName=APSErpV3_TEST;encrypt=false;trustServerCertificate=true'
$itUser = 'apserp_dev'
$itPass = 'Apserp#2026Dev'

$script:step = 0
function Step($name, [scriptblock]$action) {
    $global:LASTEXITCODE = 0
    $script:step++
    Write-Host "`n=== [$script:step/4] $name ===" -ForegroundColor Cyan
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & $action
    if ($LASTEXITCODE -ne 0) { throw "$name 失败（退出码 $LASTEXITCODE）" }
    $sw.Stop()
    Write-Host ("--- $name 通过（{0:N1}s）" -f $sw.Elapsed.TotalSeconds) -ForegroundColor Green
}

Write-Host "JAVA_HOME = $env:JAVA_HOME"
& $mvn -v | Select-Object -First 1

Step 'build：编译' {
    & $mvn @mvnArgs -DskipTests compile
}

Step 'test：单元测试 + 集成测试（-SkipIt 可跳过 IT）' {
    if ($SkipIt) {
        $env:IT_ENABLED = 'false'
        & $mvn @mvnArgs test
    } else {
        # 每次重建空测试库，验证 V1..V28 可全量重放
        & "$root\tools\ci-db-reset.ps1" -Drop
        $env:IT_ENABLED = 'true'
        $env:IT_DB_URL = $itUrl
        $env:IT_DB_USER = $itUser
        $env:IT_DB_PASSWORD = $itPass
        & $mvn @mvnArgs test '-Dit.db=true'
    }
}

Step 'quality：架构守护' {
    & $mvn @mvnArgs test '-Dtest=ArchitectureTest' '-DfailIfNoTests=false'
}

Step 'web：前端依赖与构建' {
    Push-Location web
    try {
        # 本地用 npm install（CI 用 npm ci 全新装）；Windows 下 esbuild.exe 常被占用导致删目录失败
        Get-Process esbuild -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        if (Test-Path node_modules) {
            cmd /c "npm install --no-audit --no-fund"
        } else {
            cmd /c "npm ci --no-audit --no-fund"
        }
        if ($LASTEXITCODE -ne 0) { throw 'npm 安装依赖失败' }
        cmd /c "npm run build"
        if ($LASTEXITCODE -ne 0) { throw 'npm run build 失败' }
    } finally { Pop-Location }
}

Write-Host "`n四段全部通过，可以提交 / 推送触发远程 CI。" -ForegroundColor Green

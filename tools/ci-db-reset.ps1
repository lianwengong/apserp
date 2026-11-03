# 本地准备 CI 用的测试库（只在本地跑；CI 由 service 容器 + CiDbInit 负责）
# 前置：以 Windows 身份（sysadmin）能连本机 SQL Server；应用账号 aschain_dev 已存在。
# 注意：本文件必须保存为 UTF-8 with BOM，否则 Windows PowerShell 5.1 按 GBK 解析会报错。
param(
    [string]$Server = '.',
    [string]$TestDb = 'ASChain_TEST',
    [string]$AppUser = 'aschain_dev',
    [switch]$Drop
)
$ErrorActionPreference = 'Stop'

$sqlcmd = @(
    'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE',
    'C:\Program Files (x86)\Microsoft SQL Server\90\Tools\binn\SQLCMD.EXE'
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $sqlcmd) { throw 'sqlcmd not found' }

if ($Drop) {
    Write-Host "drop $TestDb ..."
    & $sqlcmd -S $Server -E -b -Q "IF DB_ID(N'$TestDb') IS NOT NULL BEGIN ALTER DATABASE [$TestDb] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$TestDb]; END"
    if ($LASTEXITCODE -ne 0) { throw 'drop test db failed' }
}

Write-Host "create $TestDb ..."
# 用「临时名建库 → 改名」而不是直接 CREATE DATABASE [$TestDb]：
# 有些机器上客户端自己的 DATA 目录里残留着同名的 .mdf/.ldf（旧快照、权限又读不到），
# 直接建会报「文件已存在」，临时名建库用的是新文件名，不撞车。
$staging = "${TestDb}_init$([DateTime]::UtcNow.ToString('HHmmss'))"
& $sqlcmd -S $Server -E -b -Q "IF DB_ID(N'$staging') IS NOT NULL DROP DATABASE [$staging]"
& $sqlcmd -S $Server -E -b -Q "CREATE DATABASE [$staging] COLLATE Chinese_PRC_CI_AS"
if ($LASTEXITCODE -ne 0) { throw 'create test db failed' }
& $sqlcmd -S $Server -E -b -Q "ALTER DATABASE [$staging] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; ALTER DATABASE [$staging] MODIFY NAME = [$TestDb]; ALTER DATABASE [$TestDb] SET MULTI_USER"
if ($LASTEXITCODE -ne 0) { throw 'rename test db failed' }

Write-Host "grant $AppUser ..."
$grant = "IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '$AppUser') CREATE USER [$AppUser] FOR LOGIN [$AppUser]; " +
         "IF NOT EXISTS (SELECT 1 FROM sys.database_role_members rm JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id JOIN sys.database_principals m ON m.principal_id = rm.member_principal_id WHERE r.name = 'db_owner' AND m.name = '$AppUser') ALTER ROLE db_owner ADD MEMBER [$AppUser]; " +
         "ALTER USER [$AppUser] WITH DEFAULT_SCHEMA = dbo;"
& $sqlcmd -S $Server -E -b -d $TestDb -Q $grant
if ($LASTEXITCODE -ne 0) { throw 'grant failed' }

Write-Host "test db ready: $TestDb (empty; Flyway will replay all migrations on next start)" -ForegroundColor Green
Write-Host "url: jdbc:sqlserver://localhost:1433;databaseName=$TestDb;encrypt=false;trustServerCertificate=true"

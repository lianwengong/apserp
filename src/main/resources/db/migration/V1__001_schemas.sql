/* 说明：本脚本假设目标空库已由 DBA 创建（Flyway 不负责建库）。
   建库语句：CREATE DATABASE [APSErpV3] COLLATE Chinese_PRC_CI_AS;
   =====================================================================
   进销存管理系统 V3 · 建库与架构
   数据库：APSErpV3   生成器：db/emit.py（请勿手改，改规格文件后重新生成）
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF SCHEMA_ID(N'plat') IS NULL EXEC(N'CREATE SCHEMA [plat]');
IF SCHEMA_ID(N'md') IS NULL EXEC(N'CREATE SCHEMA [md]');
IF SCHEMA_ID(N'pur') IS NULL EXEC(N'CREATE SCHEMA [pur]');
IF SCHEMA_ID(N'sal') IS NULL EXEC(N'CREATE SCHEMA [sal]');
IF SCHEMA_ID(N'ret') IS NULL EXEC(N'CREATE SCHEMA [ret]');
IF SCHEMA_ID(N'mkt') IS NULL EXEC(N'CREATE SCHEMA [mkt]');
IF SCHEMA_ID(N'omn') IS NULL EXEC(N'CREATE SCHEMA [omn]');
IF SCHEMA_ID(N'inv') IS NULL EXEC(N'CREATE SCHEMA [inv]');
IF SCHEMA_ID(N'tms') IS NULL EXEC(N'CREATE SCHEMA [tms]');
IF SCHEMA_ID(N'fin') IS NULL EXEC(N'CREATE SCHEMA [fin]');
IF SCHEMA_ID(N'pln') IS NULL EXEC(N'CREATE SCHEMA [pln]');
IF SCHEMA_ID(N'rpt') IS NULL EXEC(N'CREATE SCHEMA [rpt]');
GO
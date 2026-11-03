/* 区分「平台功能模块」与「租户功能模块」
   ------------------------------------------------------------------
   概念：
   · 平台功能模块 = 平台租户（TenantId = 0）下的 plat.Module 树，即**产品目录**：
     商链这个产品总共提供哪些模块/功能点，唯一来源。
   · 租户功能模块 = 各业务租户自己的 plat.Module 副本（开通时从目录克隆），
     不同租户购买/开通的模块集合可以不同，差异体现在 IsEnabled。

   本次新增：IsDefault —— 平台目录上标记「新租户默认开通」，
   后续开通租户时可按它决定克隆后默认启用哪些模块（当前全部默认开通）。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO
IF COL_LENGTH('plat.Module', 'IsDefault') IS NULL
    ALTER TABLE plat.Module ADD IsDefault bit NOT NULL
        CONSTRAINT DF_Module_IsDefault DEFAULT (0);
GO
/* 存量平台目录按「目前启用」标记为默认开通 */
UPDATE plat.Module
SET IsDefault = 1
WHERE TenantId = 0
  AND IsDeleted = 0
  AND IsEnabled = 1
  AND IsDefault = 0;
GO

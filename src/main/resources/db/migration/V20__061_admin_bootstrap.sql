/* 管理员初始口令（仅首次安装使用，首次登录强制改密）
   口令算法：PBKDF2-HMAC-SHA256 / 120000 次 / 32 字节
   初始口令：Apserp@2026   —— 上线前必须修改；MustChangePwd=1 会强制改 */
SET NOCOUNT ON;
GO
-- 迁移以运维身份执行，必须绕过 RLS，否则 UPDATE 会命中 0 行
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO
UPDATE plat.[User]
SET PasswordHash = 'BUiHQ9klRWk5zliqai6kcf6n4VK9DAbIUfCyeSXx3BU=',
    PasswordSalt = 'mH87uCBXyyWol8vyyAiSbg==',
    PasswordUpdatedAt = sysutcdatetime(),
    MustChangePwd = 1,
    FailCount = 0,
    LockedUntil = NULL
WHERE UserName = 'admin';
GO

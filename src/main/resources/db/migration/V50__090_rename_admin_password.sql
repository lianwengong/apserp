/* 更名后重置演示管理员口令：AsChain@2026（首次登录强制改密）
   算法：PBKDF2-HMAC-SHA256 / 120000 次 / 32 字节 */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO
UPDATE plat.[User]
SET PasswordHash = 'aAFYmgxZqeEZfVb3BWklksetxQAOT8C8wpG0hWkm1x0=',
    PasswordSalt = 'Aeeawby1MJ/B1WVLHguAIw==',
    PasswordUpdatedAt = sysutcdatetime(),
    MustChangePwd = 1,
    FailCount = 0,
    LockedUntil = NULL
WHERE UserName = 'admin';
GO

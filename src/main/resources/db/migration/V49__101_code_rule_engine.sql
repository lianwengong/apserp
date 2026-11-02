/* =====================================================================
   V49 · 编号引擎（规则 + 流水）
   ---------------------------------------------------------------------
   背景：plat.CodeRule 有 20 条规则（前缀+日期+流水），但没有任何取号实现，
        单据号一直靠手填；并发下必然重号。
   做法：
     1) CodeRule 补三列：Prefix（业务前缀）、DatePattern（日期格式）、DigitCount（流水位数）；
        原来只有 Sample 字符串，机器无法据此取号。
     2) 新增 plat.CodeSerial：按（租户, 规则, 期间）保存当前流水，
        UPDATE ... WITH (UPDLOCK) 原子自增，期间由 ResetCycle 决定。
     3) 回填：从 Sample 里解析出前缀、日期格式与流水位数（解析不出就用默认值）。
   幂等。
   ===================================================================== */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO

/* ---------------------------------------------------------------- 1. CodeRule 补列 */
IF COL_LENGTH('plat.CodeRule', 'Prefix') IS NULL
    ALTER TABLE plat.[CodeRule] ADD [Prefix] varchar(20) NULL;
GO
IF COL_LENGTH('plat.CodeRule', 'DatePattern') IS NULL
    ALTER TABLE plat.[CodeRule] ADD [DatePattern] varchar(20) NULL;
GO
IF COL_LENGTH('plat.CodeRule', 'DigitCount') IS NULL
    ALTER TABLE plat.[CodeRule] ADD [DigitCount] tinyint NOT NULL
        CONSTRAINT [DF_CodeRule_DigitCount] DEFAULT (4);
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE name = 'CK_CodeRule_DigitCount' AND parent_object_id = OBJECT_ID('plat.CodeRule'))
    ALTER TABLE plat.[CodeRule]
        ADD CONSTRAINT [CK_CodeRule_DigitCount] CHECK ([DigitCount] BETWEEN 1 AND 12);
GO

/* ---------------------------------------------------------------- 2. 流水表 */
IF OBJECT_ID('plat.CodeSerial', 'U') IS NULL
BEGIN
    CREATE TABLE [plat].[CodeSerial] (
        [Id] bigint IDENTITY(1,1) NOT NULL,
        [TenantId] int NOT NULL CONSTRAINT [DF_CodeSerial_TenantId] DEFAULT (1),
        [RuleCode] varchar(60) NOT NULL,
        -- 期间键：不重置=''；按年=2026；按月=202601；按日=20260101
        [Period] varchar(8) NOT NULL CONSTRAINT [DF_CodeSerial_Period] DEFAULT (''),
        [CurrentValue] bigint NOT NULL CONSTRAINT [DF_CodeSerial_CurrentValue] DEFAULT (0),
        [RowVersion] rowversion NOT NULL,
        [ModifiedAt] datetime2(3) NULL,
        CONSTRAINT [PK_CodeSerial] PRIMARY KEY CLUSTERED ([Id])
    );
    CREATE UNIQUE INDEX [UQ_CodeSerial_Rule_Period]
        ON [plat].[CodeSerial] ([TenantId], [RuleCode], [Period]);

    EXEC sp_addextendedproperty N'MS_Description', N'编号流水（每个规则每个期间一行，取号时原子自增）',
        N'SCHEMA', N'plat', N'TABLE', N'CodeSerial';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.security_predicates
               WHERE target_object_id = OBJECT_ID('plat.CodeSerial'))
    ALTER SECURITY POLICY plat.TenantPolicy
        ADD FILTER PREDICATE plat.fn_TenantFilter(TenantId) ON [plat].[CodeSerial];
GO

/* ---------------------------------------------------------------- 3. 回填前缀/日期格式/位数 */
/* Sample 形如 CT20260101-0001 / PO20260101-0001：前缀=开头字母，日期=随后 8 位数字，流水=分隔符后的位数 */
UPDATE r
SET Prefix = LEFT(r.Sample, p.alphaLen),
    DatePattern = CASE
        WHEN p.digitLen - p.alphaLen >= 8 THEN 'yyyyMMdd'
        WHEN p.digitLen - p.alphaLen >= 6 THEN 'yyyyMM'
        WHEN p.digitLen - p.alphaLen >= 4 THEN 'yyyy'
        ELSE ''
    END,
    DigitCount = CASE
        WHEN p.serialLen BETWEEN 1 AND 12 THEN p.serialLen ELSE 4
    END
FROM plat.[CodeRule] r
CROSS APPLY (
    SELECT
        alphaLen = PATINDEX('%[^A-Za-z]%', r.Sample) - 1,
        digitLen = PATINDEX('%[^A-Za-z0-9]%', r.Sample) - 1,
        serialLen = LEN(r.Sample) - CHARINDEX('-', r.Sample)
) p
WHERE r.Sample IS NOT NULL AND r.Sample <> '' AND p.alphaLen >= 0;
GO

/* 解析失败的给默认值，保证取号不落空 */
UPDATE plat.[CodeRule]
SET Prefix = ISNULL(NULLIF(Prefix, ''), UPPER(LEFT(Code, 2))),
    DatePattern = ISNULL(DatePattern, 'yyyyMMdd'),
    Separator = ISNULL(NULLIF(Separator, ''), '-'),
    DigitCount = CASE WHEN ISNULL(DigitCount, 0) BETWEEN 1 AND 12 THEN DigitCount ELSE 4 END;
GO

/* ---------------------------------------------------------------- 4. 编号规则入口菜单 */
DECLARE @parent bigint = (SELECT Id FROM plat.[Menu]
                          WHERE TenantId = 1 AND Code = '9003' AND IsDeleted = 0);
IF @parent IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM plat.[Menu] WHERE TenantId = 1 AND Code = '900310' AND IsDeleted = 0)
BEGIN
    INSERT plat.[Menu] (TenantId, ParentId, Code, Name, MenuType, Route, Icon, Sort, IsVisible,
                        OpenMode, IsEnabled, TerminalType, CreatedAt)
    VALUES (1, @parent, '900310', N'编号规则', 2, '/system/code-rules', 'Tickets', 46, 1, 1, 1, 1,
            sysutcdatetime());
END
GO

INSERT plat.MenuTerminal (MenuId, TerminalType, IsVisible, Sort)
SELECT m.Id, m.TerminalType, 1, m.Sort
FROM plat.[Menu] m
WHERE m.TenantId = 1 AND m.Code = '900310' AND m.IsDeleted = 0
  AND NOT EXISTS (SELECT 1 FROM plat.MenuTerminal mt WHERE mt.MenuId = m.Id);
GO

package com.aschain.plat.code;

import com.aschain.common.ApiException;
import com.aschain.common.ErrorCode;
import com.aschain.common.tenant.TenantContext;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.CannotAcquireLockException;
import org.springframework.dao.DeadlockLoserDataAccessException;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 编号引擎：按规则生成业务单号（前缀 + 日期 + 流水），并发安全。
 *
 * <p>为什么不能「查询最大号 + 1」：两个人同时保存必然拿到同一个号，
 * 而单号是唯一索引，最终表现为随机一个人保存失败。这里的做法是
 * <b>一条 UPDATE … WITH (UPDLOCK, ROWLOCK) … OUTPUT</b> 原子自增</b>，
 * 行不存在时插入初始值，插入撞唯一键就重试一次。</p>
 *
 * <p>期间（Period）由 ResetCycle 决定：0 不重置、1 按年、2 按月、3 按日。
 * 日期一律取**业务时区**（默认 JVM 时区），不用 UTC —— 单号上的日期是给人看的，
 * 跨零点时若按 UTC 会生成「昨天」的号。</p>
 */
@Service
public class CodeRuleService {

    private static final Logger log = LoggerFactory.getLogger(CodeRuleService.class);

    /** 允许的日期格式：为空表示不带日期 */
    private static final Map<String, String> DATE_PATTERNS = Map.of(
            "yyyyMMdd", "yyyyMMdd",
            "yyyyMM", "yyyyMM",
            "yyyyMMddHHmmss", "yyyyMMddHHmmss",
            "yyyy", "yyyy",
            "yyMMdd", "yyMMdd");

    private final JdbcTemplate jdbc;

    public CodeRuleService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public record RuleDto(long id, String code, String name, String objectType, String prefix,
                          String datePattern, String separator, int digitCount, int resetCycle,
                          boolean enabled, String sample, String remark) {
    }

    public record RuleSaveRequest(Long id, String code, String name, String objectType,
                                  String prefix, String datePattern, String separator,
                                  Integer digitCount, Integer resetCycle, Boolean enabled,
                                  String remark) {
    }

    // ---------------------------------------------------------------- 规则查询与维护

    public List<RuleDto> list() {
        long tenantId = TenantContext.requireTenantId();
        return jdbc.query("""
                        SELECT Id, Code, Name, ObjectType, Prefix, DatePattern, Separator, DigitCount,
                               ResetCycle, IsEnabled, Sample, Remark
                        FROM plat.[CodeRule] WHERE TenantId = ? AND IsDeleted = 0 ORDER BY Code
                        """,
                (rs, i) -> {
                    RuleDto base = new RuleDto(rs.getLong("Id"), rs.getString("Code"),
                            rs.getString("Name"), rs.getString("ObjectType"), rs.getString("Prefix"),
                            rs.getString("DatePattern"), rs.getString("Separator"),
                            rs.getInt("DigitCount"), rs.getInt("ResetCycle"), rs.getBoolean("IsEnabled"),
                            rs.getString("Sample"), rs.getString("Remark"));
                    // 示例用「今天 + 流水 1」实时拼，避免种子数据里的旧日期让人误以为规则没生效
                    return new RuleDto(base.id(), base.code(), base.name(), base.objectType(),
                            base.prefix(), base.datePattern(), base.separator(), base.digitCount(),
                            base.resetCycle(), base.enabled(),
                            formatRule(base, LocalDate.now(), 1L), base.remark());
                },
                tenantId);
    }

    public RuleDto get(String code) {
        return list().stream().filter(r -> r.code().equals(code)).findFirst()
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "编号规则不存在：" + code));
    }

    @Transactional
    public long save(RuleSaveRequest req) {
        long tenantId = TenantContext.requireTenantId();
        String code = req.code() == null ? "" : req.code().trim();
        if (!code.matches("[A-Za-z][A-Za-z0-9_]{0,59}")) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "规则编码只能是字母/数字/下划线，字母开头");
        }
        String prefix = req.prefix() == null ? "" : req.prefix().trim();
        if (prefix.length() > 20) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "前缀最多 20 个字符");
        }
        String datePattern = req.datePattern() == null ? "" : req.datePattern().trim();
        if (!datePattern.isEmpty() && !DATE_PATTERNS.containsKey(datePattern)) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                    "日期格式只支持：" + String.join("、", DATE_PATTERNS.keySet()) + "，或留空不生成日期");
        }
        int digits = req.digitCount() == null ? 4 : req.digitCount();
        if (digits < 1 || digits > 12) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "流水位数只能是 1..12");
        }
        int cycle = req.resetCycle() == null ? 0 : req.resetCycle();
        if (cycle < 0 || cycle > 3) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "重置周期只能是 0不重置/1按年/2按月/3按日");
        }
        String separator = req.separator() == null || req.separator().isEmpty() ? "-" : req.separator();
        if (separator.length() > 5) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "分隔符最多 5 个字符");
        }
        Integer dup = jdbc.queryForObject("""
                SELECT COUNT(*) FROM plat.[CodeRule]
                WHERE TenantId = ? AND Code = ? AND IsDeleted = 0 AND Id <> ISNULL(?, -1)
                """, Integer.class, tenantId, code, req.id());
        if (dup != null && dup > 0) {
            throw new ApiException(ErrorCode.DUPLICATE_KEY, "规则编码已存在：" + code);
        }
        String sample = format(prefix, datePattern, separator, digits, 1L, LocalDate.now());
        long id;
        if (req.id() != null) {
            int n = jdbc.update("""
                    UPDATE plat.[CodeRule]
                    SET Code = ?, Name = ?, ObjectType = ?, Prefix = ?, DatePattern = ?, Separator = ?,
                        DigitCount = ?, ResetCycle = ?, IsEnabled = ?, Sample = ?, Remark = ?,
                        ModifiedAt = sysutcdatetime()
                    WHERE Id = ? AND TenantId = ?
                    """, code, req.name(), req.objectType(), prefix, datePattern, separator, digits,
                    cycle, Boolean.FALSE.equals(req.enabled()) ? 0 : 1, sample, req.remark(),
                    req.id(), tenantId);
            if (n == 0) {
                throw new ApiException(ErrorCode.NOT_FOUND, "编号规则不存在：" + req.id());
            }
            id = req.id();
        } else {
            jdbc.update("""
                    INSERT plat.[CodeRule] (TenantId, Code, Name, ObjectType, Prefix, DatePattern,
                                            Separator, DigitCount, ResetCycle, IsEnabled, Sample,
                                            Remark, CreatedAt)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, sysutcdatetime())
                    """, tenantId, code, req.name(), req.objectType(), prefix, datePattern, separator,
                    digits, cycle, Boolean.FALSE.equals(req.enabled()) ? 0 : 1, sample, req.remark());
            id = jdbc.queryForObject("""
                    SELECT MAX(Id) FROM plat.[CodeRule] WHERE TenantId = ? AND Code = ?
                    """, Long.class, tenantId, code);
        }
        log.info("code_rule_save tenant={} id={} code={} prefix={} date={} digits={} cycle={}",
                tenantId, id, code, prefix, datePattern, digits, cycle);
        return id;
    }

    // ---------------------------------------------------------------- 取号

    /** 预览下一个号（不消耗流水）。 */
    public String preview(String code) {
        RuleDto rule = requireEnabled(code);
        long periodValue = currentValue(rule);
        return formatRule(rule, LocalDate.now(), periodValue + 1);
    }

    /**
     * 取号：返回格式化后的单号，并把流水推进 1。
     *
     * <p>并发安全靠 `UPDATE ... WITH (UPDLOCK) ... OUTPUT`：同一规则同一期间的行被锁住，
     * 两个请求会串行拿到 1、2…；行不存在时插入初始值，插入撞唯一键说明别人抢先建了行，重试即可。</p>
     */
    public String next(String code) {
        RuleDto rule = requireEnabled(code);
        LocalDate today = LocalDate.now();
        String period = periodOf(rule.resetCycle(), today);
        long tenantId = TenantContext.requireTenantId();

        // 刻意不开事务：取号只依赖「单条 UPDATE 的原子性」，语句结束即释放行锁。
        // 开事务会把锁持有到方法返回，8 个并发请求下容易与插入路径互相等成死锁。
        for (int attempt = 0; attempt < 6; attempt++) {
            try {
                Long value = tryIncrement(tenantId, rule.code(), period);
                if (value != null) {
                    String docNo = formatRule(rule, today, value);
                    log.info("code_next tenant={} rule={} period={} value={} docNo={}",
                            tenantId, rule.code(), period, value, docNo);
                    return docNo;
                }
                try {
                    jdbc.update("""
                            INSERT plat.CodeSerial (TenantId, RuleCode, Period, CurrentValue, ModifiedAt)
                            VALUES (?, ?, ?, 1, sysutcdatetime())
                            """, tenantId, rule.code(), period);
                    String docNo = formatRule(rule, today, 1L);
                    log.info("code_next tenant={} rule={} period={} value=1 docNo={}",
                            tenantId, rule.code(), period, docNo);
                    return docNo;
                } catch (DuplicateKeyException race) {
                    // 别人刚建好这一期间的行，下一轮直接自增
                    log.debug("code_serial_race tenant={} rule={} period={} retry={}",
                            tenantId, rule.code(), period, attempt + 1);
                }
            } catch (CannotAcquireLockException | DeadlockLoserDataAccessException lock) {
                // 死锁受害者是并发取号的正常结果：语句级失败、无副作用，退避后重试
                log.debug("code_serial_deadlock tenant={} rule={} period={} retry={}",
                        tenantId, rule.code(), period, attempt + 1);
                sleepQuietly(5L * (attempt + 1));
            }
        }
        throw new ApiException(ErrorCode.DUPLICATE_KEY, "取号失败（并发冲突），请重试");
    }

    private static void sleepQuietly(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
        }
    }

    private Long tryIncrement(long tenantId, String ruleCode, String period) {
        List<Long> out = jdbc.query("""
                UPDATE plat.CodeSerial WITH (UPDLOCK, ROWLOCK)
                SET CurrentValue = CurrentValue + 1, ModifiedAt = sysutcdatetime()
                OUTPUT inserted.CurrentValue
                WHERE TenantId = ? AND RuleCode = ? AND Period = ?
                """, (rs, i) -> rs.getLong(1), tenantId, ruleCode, period);
        return out.isEmpty() ? null : out.get(0);
    }

    private long currentValue(RuleDto rule) {
        long tenantId = TenantContext.requireTenantId();
        String period = periodOf(rule.resetCycle(), LocalDate.now());
        Long value = jdbc.query("""
                        SELECT CurrentValue FROM plat.CodeSerial
                        WHERE TenantId = ? AND RuleCode = ? AND Period = ?
                        """, rs -> rs.next() ? rs.getLong(1) : 0L, tenantId, rule.code(), period);
        return value == null ? 0L : value;
    }

    private RuleDto requireEnabled(String code) {
        RuleDto rule = get(code);
        if (!rule.enabled()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "编号规则已停用：" + code);
        }
        return rule;
    }

    /**
     * 期间键：不重置用空串；按年/月/日各取对应前缀。
     * 这样换一个期间就是换一行流水，天然重置，不需要定时任务。
     */
    static String periodOf(int resetCycle, LocalDate date) {
        return switch (resetCycle) {
            case 1 -> date.format(DateTimeFormatter.ofPattern("yyyy"));
            case 2 -> date.format(DateTimeFormatter.ofPattern("yyyyMM"));
            case 3 -> date.format(DateTimeFormatter.ofPattern("yyyyMMdd"));
            default -> "";
        };
    }

    private static String formatRule(RuleDto rule, LocalDate date, long value) {
        return format(rule.prefix(), rule.datePattern(), rule.separator(), rule.digitCount(), value, date);
    }

    /** 前缀 + 日期(pattern 为空则跳过) + 分隔符 + 补零流水 */
    static String format(String prefix, String datePattern, String separator, int digits,
                         long value, LocalDate date) {
        StringBuilder sb = new StringBuilder();
        if (prefix != null) {
            sb.append(prefix);
        }
        if (datePattern != null && !datePattern.isEmpty()) {
            sb.append(date.format(DateTimeFormatter.ofPattern(datePattern)));
        }
        sb.append(separator == null ? "" : separator);
        sb.append(String.format("%0" + digits + "d", value));
        return sb.toString();
    }

    /** 流水现状（管理窗口展示「当前值」用）。 */
    public Map<String, Object> statistics(String code) {
        RuleDto rule = get(code);
        long tenantId = TenantContext.requireTenantId();
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", rule.code());
        m.put("sample", rule.sample());
        m.put("period", periodOf(rule.resetCycle(), LocalDate.now()));
        m.put("currentValue", currentValue(rule));
        m.put("next", preview(code));
        List<Map<String, Object>> periods = new ArrayList<>(jdbc.queryForList("""
                SELECT Period, CurrentValue, ModifiedAt FROM plat.CodeSerial
                WHERE TenantId = ? AND RuleCode = ? ORDER BY Period DESC
                """, tenantId, code));
        m.put("periods", periods);
        return m;
    }
}

package com.apserp.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;

import com.apserp.common.ApiException;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

/**
 * 纯单元测试：不连数据库，验证入参校验与边界处理。
 *
 * <p>生产代码里「先校验、再访问数据库」的顺序，就是靠这类测试守住的。</p>
 */
class MetaQueryServiceTest {

    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final com.apserp.plat.perm.PermissionService perm = mock(com.apserp.plat.perm.PermissionService.class);
    private final MetaQueryService service = new MetaQueryService(jdbc, perm);

    @Test
    void should_reject_sql_injection_attempt_in_object_code() {
        assertThat(catchType(() -> service.query("md.brand'; DROP TABLE x--", null, null, 1, 10)))
                .startsWith("非法的数据对象编码");
        verifyNoInteractions(jdbc);
    }

    @Test
    void should_reject_empty_object_code() {
        assertThat(catchType(() -> service.query("", null, null, 1, 10)))
                .startsWith("非法的数据对象编码");
    }

    @Test
    void should_reject_uppercase_schema_to_keep_codes_canonical() {
        assertThat(catchType(() -> service.query("MD.brand", null, null, 1, 10)))
                .startsWith("非法的数据对象编码");
    }

    @Test
    void page_size_should_be_clamped_to_1_500() {
        assertThat(MetaQueryService.resolvePageSize(0)).isEqualTo(1);
        assertThat(MetaQueryService.resolvePageSize(-5)).isEqualTo(1);
        assertThat(MetaQueryService.resolvePageSize(50)).isEqualTo(50);
        assertThat(MetaQueryService.resolvePageSize(10_000)).isEqualTo(500);
    }

    private String catchType(Runnable action) {
        try {
            action.run();
        } catch (ApiException ex) {
            return ex.getMessage();
        }
        throw new AssertionError("预期抛出 ApiException");
    }
}

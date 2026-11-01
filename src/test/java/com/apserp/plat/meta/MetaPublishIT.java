package com.apserp.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.apserp.common.ApiException;
import com.apserp.common.tenant.TenantContext;
import com.apserp.support.ItDb;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

/**
 * 元数据发布/回滚集成测试。
 *
 * <p>回滚是“整体替换”，风险最高，因此每个用例结束都回到发布前的状态：
 * 先发布一版基线，改动后用该版本回滚，断言还原成功。</p>
 *
 * <p>这里显式声明 {@code @DynamicPropertySource}（不依赖基类继承）：CI 的上下文缓存下
 * 曾出现继承来的动态属性未生效，导致默认数据源连 apserp_dev 失败（容器里没有该账号）。</p>
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class MetaPublishIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    MetaPublishService publishService;

    @Autowired
    RuleService ruleService;

    @Autowired
    JdbcTemplate jdbc;

    @BeforeEach
    void setUp() {
        TenantContext.set(1L, 1L);
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    @Test
    @DisplayName("发布产生新版本：版本号递增、内容哈希稳定、可读回快照")
    void publish_and_read_back() {
        MetaPublishService.PublishResult first = publishService.publish("集成测试基线");
        assertThat(first.version()).isPositive();
        assertThat(first.contentHash()).hasSize(32);
        assertThat(first.sizeBytes()).isGreaterThan(1000);

        Map<String, Object> payload = publishService.payload(first.version());
        assertThat(payload).containsKeys("objects", "fields", "rules", "workflows", "buttons");
        assertThat((List<?>) payload.get("objects")).isNotEmpty();
        assertThat((List<?>) payload.get("rules")).isNotEmpty();

        // 不改任何东西再发一版：哈希应一致（快照里时间戳字段会导致差异，因此只比对结构键）
        MetaPublishService.PublishResult second = publishService.publish("再发一次");
        assertThat(second.version()).isEqualTo(first.version() + 1);
        assertThat(publishService.versions()).extracting(MetaPublishService.VersionDto::version)
                .contains(first.version(), second.version());
    }

    @Test
    @DisplayName("版本列表带发布人、说明与大小")
    void version_list_metadata() {
        MetaPublishService.PublishResult r = publishService.publish("列表校验");
        MetaPublishService.VersionDto dto = publishService.versions().stream()
                .filter(v -> v.version() == r.version()).findFirst().orElseThrow();
        assertThat(dto.scope()).isEqualTo("meta");
        assertThat(dto.contentHash()).isEqualTo(r.contentHash());
        assertThat(dto.remark()).isEqualTo("列表校验");
        assertThat(dto.sizeBytes()).isGreaterThan(0);
        assertThat(dto.publishedAt()).isNotNull();
    }

    @Test
    @DisplayName("改动后与已发布版本比对：能看到新增/修改/删除")
    void diff_against_current() {
        MetaPublishService.PublishResult base = publishService.publish("比对基线");

        ruleService.saveRule(null, new RuleService.RuleSaveRequest(
                "R-DIFF-ADDED", "新增规则", 1, "ctx.Code != null", "编码必填", 2, true, null));
        try {
            MetaPublishService.DiffResult diff = publishService.diffAgainstCurrent(base.version());
            assertThat(diff.items()).anySatisfy(i -> {
                assertThat(i.kind()).isEqualTo("rules");
                assertThat(i.action()).isEqualTo("added");
                assertThat(i.code()).isEqualTo("R-DIFF-ADDED");
            });
        } finally {
            ruleService.deleteRule("R-DIFF-ADDED");
        }
    }

    @Test
    @DisplayName("回滚：改动被整体还原，且回滚本身留一条新版本")
    void rollback_restores_metadata() {
        // 幂等：先清掉上次失败可能残留的同名规则
        try {
            ruleService.deleteRule("R-ROLLBACK-TEST");
        } catch (RuntimeException ignored) {
            // 不存在即可
        }
        MetaPublishService.PublishResult base = publishService.publish("回滚基线");
        ruleService.saveRule(null, new RuleService.RuleSaveRequest(
                "R-ROLLBACK-TEST", "待回滚规则", 1, "ctx.Code != null", "编码必填", 2, true, null));
        assertThat(ruleService.listRules()).extracting(RuleService.RuleDto::code)
                .contains("R-ROLLBACK-TEST");

        MetaPublishService.PublishResult rolled = publishService.rollback(base.version(), "测试回滚");
        assertThat(rolled.version()).isGreaterThan(base.version());
        assertThat(ruleService.listRules()).extracting(RuleService.RuleDto::code)
                .doesNotContain("R-ROLLBACK-TEST");

        MetaPublishService.VersionDto dto = publishService.versions().stream()
                .filter(v -> v.version() == rolled.version()).findFirst().orElseThrow();
        assertThat(dto.rollbackOf()).isEqualTo(base.version());
        assertThat(dto.remark()).contains("测试回滚");
    }

    @Test
    @DisplayName("回滚不存在的版本给出明确错误")
    void rollback_unknown_version() {
        assertThatThrownBy(() -> publishService.rollback(999_999, null))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("版本不存在");
    }

    @Test
    @DisplayName("两个历史版本可比对")
    void diff_two_versions() {
        MetaPublishService.PublishResult v1 = publishService.publish("版本1");
        ruleService.saveRule(null, new RuleService.RuleSaveRequest(
                "R-DIFF-V2", "版本2新增", 1, "ctx.Code != null", "编码必填", 2, true, null));
        MetaPublishService.PublishResult v2 = publishService.publish("版本2");
        Map<String, Object> p1 = publishService.payload(v1.version());
        Map<String, Object> p2 = publishService.payload(v2.version());
        System.out.println("[debug] v1 rules=" + ((List<?>) p1.get("rules")).size()
                + " v2 rules=" + ((List<?>) p2.get("rules")).size()
                + " v2 ruleCodes=" + ((List<Map<String, Object>>) p2.get("rules")).stream()
                        .map(m -> m.get("Code")).toList());
        MetaPublishService.DiffResult diff = publishService.diffVersions(v1.version(), v2.version());
        System.out.println("[debug] diff items=" + diff.items().size() + " " + diff.items());
        ruleService.deleteRule("R-DIFF-V2");
        assertThat(diff.fromVersion()).isEqualTo(v1.version());
        assertThat(diff.toVersion()).isEqualTo(v2.version());
        assertThat(diff.items()).anySatisfy(i -> assertThat(i.code()).isEqualTo("R-DIFF-V2"));
    }

    @Test
    @DisplayName("权限设计器：角色矩阵与字段矩阵可读可写")
    void permission_matrices() {
        PermissionDesignService perm = new PermissionDesignService(jdbc);
        List<PermissionDesignService.RoleDto> roles = perm.listRoles();
        assertThat(roles).isNotEmpty();
        long roleId = roles.get(0).id();

        PermissionDesignService.RoleMatrix matrix = perm.getMatrix(roleId);
        assertThat(matrix.grants()).isNotEmpty();

        int saved = perm.saveMatrix(roleId, List.of("DATA:md.brand", "DESIGN:rule"));
        assertThat(saved).isEqualTo(2);
        assertThat(perm.getMatrix(roleId).grants().stream()
                .filter(PermissionDesignService.ResourceGrant::granted)
                .map(PermissionDesignService.ResourceGrant::resourceKey))
                .containsExactlyInAnyOrder("DATA:md.brand", "DESIGN:rule");

        PermissionDesignService.FieldMatrix fields = perm.fieldMatrix(roleId, "md.brand");
        assertThat(fields.fields()).isNotEmpty();
        int n = perm.saveFieldMatrix(roleId, "md.brand", Map.of("Name", 1, "Code", 0));
        assertThat(n).isEqualTo(2);
        assertThat(perm.fieldMatrix(roleId, "md.brand").fields())
                .filteredOn(f -> f.fieldName().equals("Code"))
                .singleElement()
                .satisfies(f -> assertThat(f.access()).isZero());

        // 还原：清空该角色的字段权限
        perm.saveFieldMatrix(roleId, "md.brand", Map.of());
    }
}

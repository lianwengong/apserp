package com.aschain.plat.meta;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.aschain.common.ApiException;
import com.aschain.common.tenant.TenantContext;
import com.aschain.support.ItDb;
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
 * 主子表（明细）级联保存集成测试。
 *
 * <p>覆盖：关系元数据、主表+子表一次事务保存、未提交子行软删除、
 * 外键与租户强制写入（前端伪造无效）、子行规则校验、子表行数上限、关系 CRUD 校验。</p>
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "IT_ENABLED", matches = "true")
@EnabledIfSystemProperty(named = "it.db", matches = "true")
class MasterDetailIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", ItDb::url);
        registry.add("spring.datasource.username", ItDb::user);
        registry.add("spring.datasource.password", ItDb::password);
        registry.add("spring.flyway.enabled", () -> "false");
    }

    @Autowired
    MetaSaveService saveService;

    @Autowired
    MetaChildService childService;

    @Autowired
    JdbcTemplate jdbc;

    private static final String CODE = "IT_MD_01";

    @BeforeEach
    void setUp() {
        TenantContext.set(1L, 1L);
        cleanUp();
    }

    @AfterEach
    void tearDown() {
        cleanUp();
        TenantContext.clear();
    }

    private void cleanUp() {
        jdbc.update("DELETE FROM md.BrandContact WHERE BrandId IN "
                + "(SELECT Id FROM md.Brand WHERE Code = ?)", CODE);
        jdbc.update("DELETE FROM md.Brand WHERE Code = ?", CODE);
    }

    @Test
    @DisplayName("关系元数据：brand → brandcontact，别名 Contacts，外键 BrandId")
    void seed_relation() {
        List<MetaChildService.RelationDto> relations = childService.relationsOf("md.brand");
        assertThat(relations).isNotEmpty();
        MetaChildService.RelationDto rel = relations.stream()
                .filter(r -> r.alias().equals("Contacts")).findFirst().orElseThrow();
        assertThat(rel.childObjectCode()).isEqualTo("md.brandcontact");
        assertThat(rel.foreignKeyField()).isEqualTo("BrandId");
        assertThat(rel.cascadeDelete()).isEqualTo(1);
        assertThat(rel.displayName()).isEqualTo("联系人");
    }

    @Test
    @DisplayName("新增主表时一次提交子行：子行落库且自动绑定父 Id")
    void create_master_with_children() {
        long id = saveService.save("md.brand", """
                {"Code":"%s","Name":"主子表测试品牌","Sort":10,"Contacts":[
                  {"ContactName":"王五","Mobile":"13900000001","IsPrimary":true},
                  {"ContactName":"赵六","Email":"zhaoliu@example.com"}
                ]}
                """.formatted(CODE));

        List<Map<String, Object>> rows = childService.childrenOf("md.brand", id).get(0).rows();
        assertThat(rows).hasSize(2);
        assertThat(rows).extracting(r -> String.valueOf(r.get("ContactName")))
                .containsExactlyInAnyOrder("王五", "赵六");
        assertThat(rows).allSatisfy(r -> assertThat(((Number) r.get("BrandId")).longValue()).isEqualTo(id));
    }

    @Test
    @DisplayName("修改主表：未提交的子行被软删除，提交的保留")
    void update_soft_deletes_missing_children() {
        long id = saveService.save("md.brand", """
                {"Code":"%s","Name":"主子表测试品牌","Sort":10,"Contacts":[
                  {"ContactName":"A"},{"ContactName":"B"},{"ContactName":"C"}
                ]}
                """.formatted(CODE));
        assertThat(childService.childrenOf("md.brand", id).get(0).rows()).hasSize(3);

        // 已存在的子行带自己的 Id 提交（就地更新），只去掉 B
        Map<String, Long> ids = new java.util.HashMap<>();
        for (Map<String, Object> row : childService.childrenOf("md.brand", id).get(0).rows()) {
            ids.put(String.valueOf(row.get("ContactName")), ((Number) row.get("Id")).longValue());
        }
        saveService.save("md.brand", """
                {"Id":%d,"Code":"%s","Name":"主子表测试品牌","Sort":10,"Contacts":[
                  {"Id":%d,"ContactName":"A"},{"Id":%d,"ContactName":"C"}
                ]}
                """.formatted(id, CODE, ids.get("A"), ids.get("C")));

        List<Map<String, Object>> rows = childService.childrenOf("md.brand", id).get(0).rows();
        assertThat(rows).extracting(r -> String.valueOf(r.get("ContactName")))
                .containsExactlyInAnyOrder("A", "C");
        // 就地更新不新增行；只有被省略的 B 被软删除
        assertThat(rows).extracting(r -> ((Number) r.get("Id")).longValue())
                .containsExactlyInAnyOrder(ids.get("A"), ids.get("C"));
        Integer softDeleted = jdbc.queryForObject(
                "SELECT COUNT(*) FROM md.BrandContact WHERE BrandId = ? AND IsDeleted = 1", Integer.class, id);
        assertThat(softDeleted).isEqualTo(1);
    }

    @Test
    @DisplayName("请求里不含子表别名时不动子表（局部更新语义）")
    void absent_alias_keeps_children() {
        long id = saveService.save("md.brand", """
                {"Code":"%s","Name":"主子表测试品牌","Sort":10,"Contacts":[{"ContactName":"保留我"}]}
                """.formatted(CODE));
        saveService.save("md.brand", """
                {"Id":%d,"Code":"%s","Name":"改名了","Sort":10}
                """.formatted(id, CODE));
        assertThat(childService.childrenOf("md.brand", id).get(0).rows()).hasSize(1);
    }

    @Test
    @DisplayName("前端伪造外键无效：子行总是挂到当前主表")
    void forged_foreign_key_is_ignored() {
        long other = saveService.save("md.brand", """
                {"Code":"%s_OTHER","Name":"另一品牌","Sort":20}
                """.formatted(CODE));
        long id = saveService.save("md.brand", """
                {"Code":"%s","Name":"主子表测试品牌","Sort":10,"Contacts":[
                  {"ContactName":"伪造","BrandId":%d}
                ]}
                """.formatted(CODE, other));

        List<Map<String, Object>> mine = childService.childrenOf("md.brand", id).get(0).rows();
        assertThat(mine).hasSize(1);
        assertThat(((Number) mine.get(0).get("BrandId")).longValue()).isEqualTo(id);
        assertThat(childService.childrenOf("md.brand", other).get(0).rows()).isEmpty();
        jdbc.update("DELETE FROM md.Brand WHERE Code = ?", CODE + "_OTHER");
    }

    @Test
    @DisplayName("子行同样走规则引擎：联系人姓名必填由子对象自己的规则负责")
    void child_rules_are_applied() {
        // 先给子对象挂一条“联系人不能为空”的规则（规则引擎按对象编码查绑定）
        RuleService.RuleDto rule = null;
        try {
            long ruleId = ruleService().saveRule(null, new RuleService.RuleSaveRequest(
                    "R-IT-CONTACT-NAME", "联系人必填", 1,
                    "ctx.ContactName != null && ctx.ContactName != ''", "联系人不能为空", 2, true, null));
            rule = ruleService().listRules().stream()
                    .filter(r -> r.code().equals("R-IT-CONTACT-NAME")).findFirst().orElseThrow();
            ruleService().bind(new RuleService.BindingSaveRequest(
                    rule.id(), "md.brandcontact", null, 1, 900, true));

            assertThatThrownBy(() -> saveService.save("md.brand", """
                    {"Code":"%s","Name":"主子表测试品牌","Sort":10,"Contacts":[{"Mobile":"139"}]}
                    """.formatted(CODE)))
                    .isInstanceOf(ApiException.class)
                    .hasMessageContaining("联系人不能为空");
            // 事务回滚：主表也不该残留
            Integer masters = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM md.Brand WHERE Code = ?", Integer.class, CODE);
            assertThat(masters).isZero();
        } finally {
            if (rule != null) {
                for (var b : ruleService().listBindings("md.brandcontact")) {
                    if (b.ruleId() == rule.id()) {
                        ruleService().unbind(b.id());
                    }
                }
                ruleService().deleteRule("R-IT-CONTACT-NAME");
            }
        }
    }

    @Test
    @DisplayName("子表行数超过 MaxRows 直接拒绝")
    void too_many_children_rejected() {
        StringBuilder items = new StringBuilder();
        for (int i = 0; i < 5; i++) {
            items.append(i > 0 ? "," : "").append("{\"ContactName\":\"C").append(i).append("\"}");
        }
        // 把上限临时调到 3
        jdbc.update("""
                UPDATE plat.DataObjectRelation SET MaxRows = 3
                WHERE ChildAlias = 'Contacts' AND ParentObjectId =
                      (SELECT Id FROM plat.DataObject WHERE TenantId = 1 AND Code = 'md.brand')
                """);
        try {
            assertThatThrownBy(() -> saveService.save("md.brand", """
                    {"Code":"%s","Name":"主子表测试品牌","Sort":10,"Contacts":[%s]}
                    """.formatted(CODE, items)))
                    .isInstanceOf(ApiException.class)
                    .hasMessageContaining("行数上限");
        } finally {
            jdbc.update("""
                    UPDATE plat.DataObjectRelation SET MaxRows = 200
                    WHERE ChildAlias = 'Contacts' AND ParentObjectId =
                          (SELECT Id FROM plat.DataObject WHERE TenantId = 1 AND Code = 'md.brand')
                    """);
        }
    }

    @Test
    @DisplayName("子表保存失败时主表一起回滚（同一事务）")
    void child_failure_rolls_back_master() {
        // ContactName 在库里 NOT NULL；这里传 null 让子表插入失败
        assertThatThrownBy(() -> saveService.save("md.brand", """
                {"Code":"%s","Name":"主子表测试品牌","Sort":10,"Contacts":[{"ContactName":null}]}
                """.formatted(CODE)))
                .isInstanceOf(ApiException.class);
        Integer masters = jdbc.queryForObject(
                "SELECT COUNT(*) FROM md.Brand WHERE Code = ?", Integer.class, CODE);
        assertThat(masters).isZero();
    }

    @Test
    @DisplayName("关系设计器：新增/更新/删除 + 校验（别名重复、外键字段不存在）")
    void relation_crud_and_validation() {
        long brandId = objectId("md.brand");
        long partnerId = objectId("md.partner");

        // 外键字段在子对象里不存在 → 拒绝
        assertThatThrownBy(() -> childService.saveRelation(new MetaChildService.RelationSaveRequest(
                null, "md.partner", "md.brandcontact", "Contacts2", "NoSuchField",
                "测试", 10, 1, 50, true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("没有字段");

        long id = childService.saveRelation(new MetaChildService.RelationSaveRequest(
                null, "md.brand", "md.partner", "Partners", "Id", "关联往来", 20, 2, 50, true, "测试"));
        assertThat(id).isPositive();

        // 同一父对象同一别名重复 → 拒绝
        assertThatThrownBy(() -> childService.saveRelation(new MetaChildService.RelationSaveRequest(
                null, "md.brand", "md.brandcontact", "Partners", "BrandId",
                "重复", 30, 1, 50, true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("已有别名");

        childService.saveRelation(new MetaChildService.RelationSaveRequest(
                id, "md.brand", "md.partner", "Partners", "Id", "关联往来(改)", 25, 2, 80, true, "改过"));
        MetaChildService.RelationDto dto = childService.listRelations("md.brand").stream()
                .filter(r -> r.id() == id).findFirst().orElseThrow();
        assertThat(dto.displayName()).isEqualTo("关联往来(改)");
        assertThat(dto.maxRows()).isEqualTo(80);

        childService.deleteRelation(id);
        assertThat(childService.listRelations("md.brand")).extracting(MetaChildService.RelationDto::id)
                .doesNotContain(id);
        assertThat(brandId).isPositive();
        assertThat(partnerId).isPositive();
    }

    @Test
    @DisplayName("别名必须是合法标识符（会被当成 JSON 键与块名）")
    void alias_must_be_identifier() {
        assertThatThrownBy(() -> childService.saveRelation(new MetaChildService.RelationSaveRequest(
                null, "md.brand", "md.brandcontact", "1 bad alias;", "BrandId",
                null, 10, 1, 50, true, null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("别名");
    }

    private long objectId(String code) {
        Long id = jdbc.queryForObject(
                "SELECT Id FROM plat.DataObject WHERE TenantId = 1 AND Code = ?", Long.class, code);
        return id == null ? 0 : id;
    }

    @Autowired
    RuleService ruleServiceBean;

    private RuleService ruleService() {
        return ruleServiceBean;
    }
}

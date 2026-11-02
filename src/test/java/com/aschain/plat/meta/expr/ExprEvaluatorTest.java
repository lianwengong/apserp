package com.aschain.plat.meta.expr;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * 表达式引擎单测：规则、按钮可见性、审批条件都靠它，必须逐条钉住语义。
 */
class ExprEvaluatorTest {

    private static Map<String, Object> ctx(Object... kv) {
        java.util.LinkedHashMap<String, Object> m = new java.util.LinkedHashMap<>();
        for (int i = 0; i < kv.length; i += 2) {
            m.put((String) kv[i], kv[i + 1]);
        }
        return Map.of("ctx", m);
    }

    /** 规则里写 ctx.X，求值上下文必须是 {ctx: 数据}。 */
    private static Map<String, Object> data(java.util.Map<String, Object> m) {
        return Map.of("ctx", m);
    }

    @Nested
    @DisplayName("字面量与引用")
    class Literals {

        @Test
        void numbers_strings_booleans_null() {
            assertThat(ExprEvaluator.eval("12", Map.of())).isEqualTo(new java.math.BigDecimal("12"));
            assertThat(ExprEvaluator.eval("'abc'", Map.of())).isEqualTo("abc");
            assertThat(ExprEvaluator.eval("true", Map.of())).isEqualTo(true);
            assertThat(ExprEvaluator.eval("null", Map.of())).isNull();
        }

        @Test
        void reads_context_fields() {
            assertThat(ExprEvaluator.eval("ctx.Code", ctx("Code", "B001"))).isEqualTo("B001");
            assertThat(ExprEvaluator.eval("ctx.Sort", ctx("Sort", 10))).isEqualTo(10);
        }

        @Test
        void missing_field_is_null_not_error() {
            assertThat(ExprEvaluator.eval("ctx.NotExist", ctx("Code", "X"))).isNull();
            assertThat(ExprEvaluator.test("ctx.NotExist == null", ctx())).isTrue();
        }

        @Test
        void field_name_is_case_and_underscore_insensitive() {
            // 前端可能传 logo_url，规则里写 LogoUrl —— 必须都能命中
            assertThat(ExprEvaluator.eval("ctx.LogoUrl", ctx("logo_url", "/a.png"))).isEqualTo("/a.png");
            assertThat(ExprEvaluator.eval("ctx.code", ctx("Code", "B1"))).isEqualTo("B1");
        }

        @Test
        void array_index_and_nested() {
            Map<String, Object> items = Map.of("Items", List.of(
                    Map.of("Code", "A"), Map.of("Code", "B")));
            assertThat(ExprEvaluator.eval("ctx.Items[1].Code", Map.of("ctx", items))).isEqualTo("B");
        }
    }

    @Nested
    @DisplayName("比较与逻辑")
    class CompareLogic {

        @Test
        void number_comparison() {
            assertThat(ExprEvaluator.test("ctx.Sort >= 0 && ctx.Sort <= 999", ctx("Sort", 10))).isTrue();
            assertThat(ExprEvaluator.test("ctx.Sort > 999", ctx("Sort", 10))).isFalse();
            assertThat(ExprEvaluator.test("ctx.Price == 9.9", ctx("Price", 9.90))).isTrue();
        }

        @Test
        void string_compare_uses_lexical_order() {
            assertThat(ExprEvaluator.test("ctx.Code > 'A'", ctx("Code", "B001"))).isTrue();
            assertThat(ExprEvaluator.eval("ctx.Name + '-' + ctx.Code", ctx("Name", "品牌", "Code", "B1")))
                    .isEqualTo("品牌-B1");
        }

        @Test
        void keywords_and_symbols_are_equivalent() {
            assertThat(ExprEvaluator.test("ctx.A == 1 and ctx.B != 2", ctx("A", 1, "B", 3))).isTrue();
            assertThat(ExprEvaluator.test("ctx.A eq 1 or ctx.B eq 2", ctx("A", 1, "B", 3))).isTrue();
            assertThat(ExprEvaluator.test("not (ctx.A == 1)", ctx("A", 1))).isFalse();
        }

        @Test
        void short_circuit_avoids_null_dereference() {
            // 前半段为 false 时，后半段不应求值（否则 ctx.Name.length() 在 null 上会抛错）
            assertThat(ExprEvaluator.test("ctx.Code != null && ctx.Code.length() > 2", ctx())).isFalse();
        }

        @Test
        void null_in_ordering_comparison_is_false() {
            assertThat(ExprEvaluator.test("ctx.Sort > 0", ctx())).isFalse();
            assertThat(ExprEvaluator.test("ctx.Sort < 0", ctx())).isFalse();
            assertThat(ExprEvaluator.test("ctx.Sort >= 0", ctx())).isFalse();
            assertThat(ExprEvaluator.test("ctx.Sort <= 0", ctx())).isFalse();
        }

        @Test
        void arithmetic() {
            assertThat(ExprEvaluator.eval("(1 + 2) * 3 - 4 / 2", Map.of())).isEqualTo(7.0);
            assertThatThrownBy(() -> ExprEvaluator.eval("1 / 0", Map.of()))
                    .isInstanceOf(ExprException.class);
        }
    }

    @Nested
    @DisplayName("函数")
    class Functions {

        @Test
        void string_functions() {
            assertThat(ExprEvaluator.eval("len(ctx.Code)", ctx("Code", "B001"))).isEqualTo(4);
            assertThat(ExprEvaluator.test("isEmpty('')", Map.of())).isTrue();
            assertThat(ExprEvaluator.test("contains(ctx.Name, '品')", ctx("Name", "品牌"))).isTrue();
            assertThat(ExprEvaluator.eval("upper('ab')", Map.of())).isEqualTo("AB");
            assertThat(ExprEvaluator.eval("coalesce(null, '', 3)", Map.of())).isEqualTo("");
        }

        @Test
        void len_on_null_is_zero() {
            assertThat(ExprEvaluator.eval("len(ctx.X)", ctx())).isEqualTo(0);
        }

        @Test
        void unknown_function_is_rejected() {
            assertThatThrownBy(() -> ExprEvaluator.compile("exec('x')").eval(Map.of("ctx", Map.of())))
                    .isInstanceOf(ExprException.class)
                    .hasMessageContaining("不支持的函数");
        }
    }

    @Nested
    @DisplayName("语法错误")
    class Syntax {

        @Test
        void empty_expression() {
            assertThatThrownBy(() -> ExprEvaluator.compile("  "))
                    .isInstanceOf(ExprException.class)
                    .hasMessageContaining("为空");
        }

        @Test
        void unbalanced_parenthesis() {
            assertThatThrownBy(() -> ExprEvaluator.compile("(ctx.A == 1"))
                    .isInstanceOf(ExprException.class)
                    .hasMessageContaining("右括号");
        }

        @Test
        void trailing_garbage() {
            assertThatThrownBy(() -> ExprEvaluator.compile("1 2"))
                    .isInstanceOf(ExprException.class)
                    .hasMessageContaining("多余内容");
        }

        @Test
        void single_ampersand_is_rejected() {
            assertThatThrownBy(() -> ExprEvaluator.compile("ctx.A & ctx.B"))
                    .isInstanceOf(ExprException.class)
                    .hasMessageContaining("&");
        }

        @Test
        void message_contains_position_for_designers() {
            try {
                ExprEvaluator.compile("ctx.A == ");
                throw new AssertionError("应当抛异常");
            } catch (ExprException e) {
                assertThat(e.getMessage()).contains("位置");
            }
        }
    }
}

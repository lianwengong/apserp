package com.apserp.plat.meta.expr;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * 轻量表达式引擎：给规则、按钮可见性、审批节点条件使用。
 *
 * <p>设计取舍：</p>
 * <ul>
 *   <li>**不用脚本引擎**（JS/SpEL）：沙箱风险与启动成本都不值得，元数据表达式只需要比较与逻辑。</li>
 *   <li>**只读上下文**：表达式只能读 {@code ctx.字段}，不能调用任意方法、不能写、不能查库。</li>
 *   <li>**失败即异常**：解析错误抛 {@link ExprException}，由调用方决定是拒绝保存还是跳过规则。</li>
 * </ul>
 *
 * <p>支持语法：</p>
 * <pre>
 *   字面量：12  12.5  'abc'  "abc"  true  false  null
 *   引用  ：ctx.Code   ctx.Sort   ctx.Enabled
 *   比较  ：== != &gt; &gt;= &lt; &lt;= ; 关键字 eq ne gt ge lt le
 *   逻辑  ：&amp;&amp; || ! ; 关键字 and or not
 *   算术  ：+ - * / % 与括号
 *   函数  ：len(x) isEmpty(x) contains(x,y) startsWith(x,y) endsWith(x,y)
 *           upper(x) lower(x) abs(x) coalesce(a,b,...) number(x) bool(x)
 *   访问  ：ctx.Items[0].Code（数组下标）
 * </pre>
 *
 * <p>空值语义：null 参与比较时，只有 {@code ==} 与 {@code !=} 有意义；
 * 其余比较一律返回 false（而不是抛错），避免规则因缺字段整体失效。</p>
 */
public final class ExprEvaluator {

    private ExprEvaluator() {
    }

    /** 编译一次，可重复求值（规则热路径用）。 */
    public static Compiled compile(String source) {
        if (source == null || source.isBlank()) {
            throw new ExprException("表达式为空");
        }
        List<Token> tokens = new Lexer(source).scan();
        Node root = new Parser(tokens, source).parseAll();
        return new Compiled(source, root);
    }

    /** 一次性求值。 */
    public static Object eval(String source, Map<String, Object> ctx) {
        return compile(source).eval(ctx);
    }

    /** 一次性求布尔。 */
    public static boolean test(String source, Map<String, Object> ctx) {
        return truthy(compile(source).eval(ctx));
    }

    public static boolean truthy(Object v) {
        if (v == null) {
            return false;
        }
        if (v instanceof Boolean b) {
            return b;
        }
        if (v instanceof Number n) {
            return n.doubleValue() != 0d;
        }
        if (v instanceof String s) {
            return !s.isEmpty() && !"false".equalsIgnoreCase(s) && !"0".equals(s);
        }
        if (v instanceof java.util.Collection<?> c) {
            return !c.isEmpty();
        }
        return true;
    }

    /** 编译结果。 */
    public static final class Compiled {
        private final String source;
        private final Node root;

        Compiled(String source, Node root) {
            this.source = source;
            this.root = root;
        }

        public String source() {
            return source;
        }

        public Object eval(Map<String, Object> ctx) {
            try {
                return root.eval(ctx);
            } catch (ExprException e) {
                throw e;
            } catch (RuntimeException e) {
                throw new ExprException("表达式求值失败：" + source + " -> " + e.getMessage(), e);
            }
        }

        public boolean test(Map<String, Object> ctx) {
            return truthy(eval(ctx));
        }
    }

    // ============================================================ 词法

    enum T { NUM, STR, IDENT, OP, LPAREN, RPAREN, LBRACK, RBRACK, COMMA, DOT, END }

    record Token(T type, String text, int pos) {
    }

    static final class Lexer {
        private final String s;
        private int i;

        Lexer(String s) {
            this.s = s;
        }

        List<Token> scan() {
            List<Token> out = new ArrayList<>();
            while (true) {
                skipWs();
                if (i >= s.length()) {
                    out.add(new Token(T.END, "", i));
                    return out;
                }
                char c = s.charAt(i);
                int start = i;
                if (Character.isDigit(c)) {
                    i++;
                    while (i < s.length() && (Character.isDigit(s.charAt(i)) || s.charAt(i) == '.')) {
                        i++;
                    }
                    out.add(new Token(T.NUM, s.substring(start, i), start));
                    continue;
                }
                if (c == '\'' || c == '"') {
                    char quote = c;
                    i++;
                    StringBuilder sb = new StringBuilder();
                    while (i < s.length() && s.charAt(i) != quote) {
                        char ch = s.charAt(i++);
                        if (ch == '\\' && i < s.length()) {
                            char n = s.charAt(i++);
                            sb.append(switch (n) {
                                case 'n' -> '\n';
                                case 't' -> '\t';
                                case 'r' -> '\r';
                                default -> n;
                            });
                        } else {
                            sb.append(ch);
                        }
                    }
                    if (i >= s.length()) {
                        throw new ExprException("字符串未闭合（位置 " + start + "）");
                    }
                    i++;
                    out.add(new Token(T.STR, sb.toString(), start));
                    continue;
                }
                if (Character.isLetter(c) || c == '_' || c == '$') {
                    i++;
                    while (i < s.length()) {
                        char n = s.charAt(i);
                        if (Character.isLetterOrDigit(n) || n == '_' || n == '$') {
                            i++;
                        } else {
                            break;
                        }
                    }
                    out.add(new Token(T.IDENT, s.substring(start, i), start));
                    continue;
                }
                switch (c) {
                    case '(' -> { i++; out.add(new Token(T.LPAREN, "(", start)); }
                    case ')' -> { i++; out.add(new Token(T.RPAREN, ")", start)); }
                    case '[' -> { i++; out.add(new Token(T.LBRACK, "[", start)); }
                    case ']' -> { i++; out.add(new Token(T.RBRACK, "]", start)); }
                    case ',' -> { i++; out.add(new Token(T.COMMA, ",", start)); }
                    case '.' -> { i++; out.add(new Token(T.DOT, ".", start)); }
                    case '&' -> {
                        if (i + 1 < s.length() && s.charAt(i + 1) == '&') {
                            i += 2;
                            out.add(new Token(T.OP, "&&", start));
                        } else {
                            throw new ExprException("不支持的单字符 &（位置 " + start + "）");
                        }
                    }
                    case '|' -> {
                        if (i + 1 < s.length() && s.charAt(i + 1) == '|') {
                            i += 2;
                            out.add(new Token(T.OP, "||", start));
                        } else {
                            throw new ExprException("不支持的单字符 |（位置 " + start + "）");
                        }
                    }
                    case '=', '!', '>', '<' -> {
                        if (i + 1 < s.length() && s.charAt(i + 1) == '=') {
                            i += 2;
                            out.add(new Token(T.OP, s.substring(start, i), start));
                        } else if (c == '!') {
                            i++;
                            out.add(new Token(T.OP, "!", start));
                        } else {
                            i++;
                            out.add(new Token(T.OP, String.valueOf(c), start));
                        }
                    }
                    case '+', '-', '*', '/', '%' -> {
                        i++;
                        out.add(new Token(T.OP, String.valueOf(c), start));
                    }
                    default -> throw new ExprException("无法识别的字符 '" + c + "'（位置 " + start + "）");
                }
            }
        }

        private void skipWs() {
            while (i < s.length() && Character.isWhitespace(s.charAt(i))) {
                i++;
            }
        }
    }

    // ============================================================ 语法

    interface Node {
        Object eval(Map<String, Object> ctx);
    }

    record Lit(Object v) implements Node {
        public Object eval(Map<String, Object> ctx) {
            return v;
        }
    }

    record Ref(String root, List<Object> path) implements Node {
        public Object eval(Map<String, Object> ctx) {
            Object cur = "ctx".equals(root) ? ctx.getOrDefault("ctx", ctx) : ctx.get(root);
            for (Object seg : path) {
                if (cur == null) {
                    return null;
                }
                if (seg instanceof Integer idx) {
                    cur = index(cur, idx);
                } else {
                    cur = property(cur, (String) seg);
                }
            }
            return cur;
        }
    }

    /** {@code base.prop}：属性访问（大小写/下划线容错）。 */
    record Chain(Node base, String name) implements Node {
        public Object eval(Map<String, Object> ctx) {
            Object target = base.eval(ctx);
            if (target == null) {
                return null;
            }
            return property(target, name);
        }
    }

    /** {@code base[i]}：下标访问。 */
    record Index(Node base, int idx) implements Node {
        public Object eval(Map<String, Object> ctx) {
            return index(base.eval(ctx), idx);
        }
    }

    record Unary(String op, Node a) implements Node {
        public Object eval(Map<String, Object> ctx) {
            Object v = a.eval(ctx);
            return switch (op) {
                case "!" -> !truthy(v);
                case "-" -> -toNumber(v);
                case "+" -> toNumber(v);
                default -> throw new ExprException("未知一元运算 " + op);
            };
        }
    }

    record Binary(String op, Node a, Node b) implements Node {
        public Object eval(Map<String, Object> ctx) {
            if ("&&".equals(op)) {
                return truthy(a.eval(ctx)) && truthy(b.eval(ctx));
            }
            if ("||".equals(op)) {
                return truthy(a.eval(ctx)) || truthy(b.eval(ctx));
            }
            Object l = a.eval(ctx);
            Object r = b.eval(ctx);
            return switch (op) {
                case "==", "eq" -> equalsLoose(l, r);
                case "!=", "ne" -> !equalsLoose(l, r);
                // 任一侧为 null 时四种大小比较统一为 false（需要判空请显式写 == null）
                case ">", "gt" -> l != null && r != null && compare(l, r) > 0;
                case ">=", "ge" -> l != null && r != null && compare(l, r) >= 0;
                case "<", "lt" -> l != null && r != null && compare(l, r) < 0;
                case "<=", "le" -> l != null && r != null && compare(l, r) <= 0;
                case "+" -> plus(l, r);
                case "-" -> toNumber(l) - toNumber(r);
                case "*" -> toNumber(l) * toNumber(r);
                case "/" -> {
                    double d = toNumber(r);
                    if (d == 0d) {
                        throw new ExprException("除以零");
                    }
                    yield toNumber(l) / d;
                }
                case "%" -> {
                    double d = toNumber(r);
                    if (d == 0d) {
                        throw new ExprException("取模零");
                    }
                    yield toNumber(l) % d;
                }
                default -> throw new ExprException("未知运算符 " + op);
            };
        }
    }

    record Call(String name, List<Node> args) implements Node {
        public Object eval(Map<String, Object> ctx) {
            String fn = name.toLowerCase(Locale.ROOT);
            List<Object> a = args.stream().map(n -> n.eval(ctx)).toList();
            return switch (fn) {
                case "len" -> length(a.get(0));
                case "isempty" -> a.get(0) == null || length(a.get(0)) == 0;
                case "isnotempty" -> !(a.get(0) == null || length(a.get(0)) == 0);
                case "contains" -> str(a.get(0)).contains(str(a.get(1)));
                case "startswith" -> str(a.get(0)).startsWith(str(a.get(1)));
                case "endswith" -> str(a.get(0)).endsWith(str(a.get(1)));
                case "upper" -> str(a.get(0)).toUpperCase(Locale.ROOT);
                case "lower" -> str(a.get(0)).toLowerCase(Locale.ROOT);
                case "abs" -> Math.abs(toNumber(a.get(0)));
                case "number" -> toNumber(a.get(0));
                case "bool" -> truthy(a.get(0));
                case "coalesce" -> a.stream().filter(java.util.Objects::nonNull).findFirst().orElse(null);
                default -> throw new ExprException("不支持的函数 " + name);
            };
        }
    }

    /** 链式调用：{@code ctx.Code.length()}、{@code ctx.Name.trim().isEmpty()}、{@code ctx.Code.contains('B')}。 */
    record MethodCall(Node target, String name, List<Node> args) implements Node {
        public Object eval(Map<String, Object> ctx) {
            Object v = target.eval(ctx);
            String fn = name.toLowerCase(Locale.ROOT);
            List<Object> a = args.stream().map(n -> n.eval(ctx)).toList();
            return switch (fn) {
                case "length", "size" -> length(v);
                case "isempty" -> v == null || length(v) == 0;
                case "contains" -> str(v).contains(str(a.get(0)));
                case "startswith" -> str(v).startsWith(str(a.get(0)));
                case "endswith" -> str(v).endsWith(str(a.get(0)));
                case "trim" -> str(v).trim();
                case "upper", "touppercase" -> str(v).toUpperCase(Locale.ROOT);
                case "lower", "tolowercase" -> str(v).toLowerCase(Locale.ROOT);
                case "equals" -> equalsLoose(v, a.get(0));
                case "indexof" -> str(v).indexOf(str(a.get(0)));
                case "tostring" -> str(v);
                default -> throw new ExprException("不支持的方法 ." + name + "()");
            };
        }
    }

    static final class Parser {
        private final List<Token> ts;
        private final String source;
        private int p;

        Parser(List<Token> ts, String source) {
            this.ts = ts;
            this.source = source;
        }

        Node parseAll() {
            Node n = parseOr();
            expect(T.END, "表达式尾部存在多余内容");
            return n;
        }

        private Node parseOr() {
            Node left = parseAnd();
            while (matchOp("||") || matchKw("or")) {
                left = new Binary("||", left, parseAnd());
            }
            return left;
        }

        private Node parseAnd() {
            Node left = parseNot();
            while (matchOp("&&") || matchKw("and")) {
                left = new Binary("&&", left, parseNot());
            }
            return left;
        }

        private Node parseNot() {
            if (matchOp("!") || matchKw("not")) {
                return new Unary("!", parseNot());
            }
            return parseCompare();
        }

        private Node parseCompare() {
            Node left = parseAdd();
            while (true) {
                Token t = peek();
                if (t.type() == T.OP && List.of("==", "!=", ">", ">=", "<", "<=").contains(t.text())) {
                    p++;
                    left = new Binary(t.text(), left, parseAdd());
                    continue;
                }
                if (t.type() == T.IDENT && List.of("eq", "ne", "gt", "ge", "lt", "le")
                        .contains(t.text().toLowerCase(Locale.ROOT))) {
                    p++;
                    left = new Binary(t.text().toLowerCase(Locale.ROOT), left, parseAdd());
                    continue;
                }
                return left;
            }
        }

        private Node parseAdd() {
            Node left = parseMul();
            while (true) {
                Token t = peek();
                if (t.type() == T.OP && ("+".equals(t.text()) || "-".equals(t.text()))) {
                    p++;
                    left = new Binary(t.text(), left, parseMul());
                } else {
                    return left;
                }
            }
        }

        private Node parseMul() {
            Node left = parseUnary();
            while (true) {
                Token t = peek();
                if (t.type() == T.OP && ("*".equals(t.text()) || "/".equals(t.text()) || "%".equals(t.text()))) {
                    p++;
                    left = new Binary(t.text(), left, parseUnary());
                } else {
                    return left;
                }
            }
        }

        private Node parseUnary() {
            Token t = peek();
            if (t.type() == T.OP && ("-".equals(t.text()) || "+".equals(t.text()))) {
                p++;
                return new Unary(t.text(), parseUnary());
            }
            return parsePrimary();
        }

        private Node parsePrimary() {
            Token t = peek();
            switch (t.type()) {
                case NUM -> {
                    p++;
                    return new Lit(new BigDecimal(t.text()));
                }
                case STR -> {
                    p++;
                    return new Lit(t.text());
                }
                case LPAREN -> {
                    p++;
                    Node inner = parseOr();
                    expect(T.RPAREN, "缺少右括号");
                    return inner;
                }
                case IDENT -> {
                    p++;
                    String word = t.text();
                    if ("true".equalsIgnoreCase(word)) {
                        return new Lit(Boolean.TRUE);
                    }
                    if ("false".equalsIgnoreCase(word)) {
                        return new Lit(Boolean.FALSE);
                    }
                    if ("null".equalsIgnoreCase(word)) {
                        return new Lit(null);
                    }
                    if (peek().type() == T.LPAREN) {
                        p++;
                        List<Node> args = new ArrayList<>();
                        if (peek().type() != T.RPAREN) {
                            args.add(parseOr());
                            while (peek().type() == T.COMMA) {
                                p++;
                                args.add(parseOr());
                            }
                        }
                        expect(T.RPAREN, "函数缺少右括号");
                        return new Call(word, args);
                    }
                    return parsePostfix(new Ref(word, new ArrayList<>()));
                }
                default -> throw new ExprException("无法解析的标记 '" + t.text() + "'（位置 " + t.pos() + "，表达式：" + source + "）");
            }
        }

        /**
         * 统一处理后缀：{@code .prop}、{@code [i]}、{@code .method(...)}。
         * 这样 {@code ctx.Items[0].Code.length()} 也能正确解析。
         */
        private Node parsePostfix(Node base) {
            while (true) {
                Token n = peek();
                if (n.type() == T.DOT) {
                    p++;
                    Token f = expect(T.IDENT, "属性名缺失");
                    if (peek().type() == T.LPAREN) {
                        p++;
                        List<Node> args = new ArrayList<>();
                        if (peek().type() != T.RPAREN) {
                            args.add(parseOr());
                            while (peek().type() == T.COMMA) {
                                p++;
                                args.add(parseOr());
                            }
                        }
                        expect(T.RPAREN, "方法缺少右括号");
                        base = new MethodCall(base, f.text(), args);
                    } else {
                        base = new Chain(base, f.text());
                    }
                } else if (n.type() == T.LBRACK) {
                    p++;
                    Token idx = expect(T.NUM, "下标必须是数字");
                    expect(T.RBRACK, "缺少右方括号");
                    base = new Index(base, Integer.parseInt(idx.text()));
                } else {
                    return base;
                }
            }
        }

        private boolean matchOp(String op) {
            Token t = peek();
            if (t.type() == T.OP && op.equals(t.text())) {
                p++;
                return true;
            }
            return false;
        }

        private boolean matchKw(String kw) {
            Token t = peek();
            if (t.type() == T.IDENT && kw.equalsIgnoreCase(t.text())) {
                p++;
                return true;
            }
            return false;
        }

        private Token peek() {
            return ts.get(p);
        }

        private Token expect(T type, String msg) {
            Token t = peek();
            if (t.type() != type) {
                throw new ExprException(msg + "（位置 " + t.pos() + "，表达式：" + source + "）");
            }
            p++;
            return t;
        }
    }

    // ============================================================ 值语义

    static Object property(Object target, String name) {
        if (target == null) {
            return null;
        }
        if (target instanceof Map<?, ?> m) {
            if (m.containsKey(name)) {
                return m.get(name);
            }
            // 容错：忽略大小写与下划线（前端字段名可能是 code / Code / CODE）
            for (Map.Entry<?, ?> e : m.entrySet()) {
                if (e.getKey() != null && normalize(e.getKey().toString()).equals(normalize(name))) {
                    return e.getValue();
                }
            }
            return null;
        }
        if (target instanceof java.util.List<?> list) {
            for (Object o : list) {
                if (o instanceof Map<?, ?> m && m.get("name") != null && name.equals(m.get("name"))) {
                    return m.get("value");
                }
            }
            return null;
        }
        return null;
    }

    static Object index(Object target, int idx) {
        if (target == null) {
            return null;
        }
        if (target instanceof java.util.List<?> list) {
            return idx >= 0 && idx < list.size() ? list.get(idx) : null;
        }
        if (target instanceof Object[] arr) {
            return idx >= 0 && idx < arr.length ? arr[idx] : null;
        }
        if (target instanceof String s) {
            return idx >= 0 && idx < s.length() ? String.valueOf(s.charAt(idx)) : null;
        }
        return null;
    }

    static String normalize(String s) {
        return s.replace("_", "").toLowerCase(Locale.ROOT);
    }

    static String str(Object v) {
        return v == null ? "" : String.valueOf(v);
    }

    static double toNumber(Object v) {
        if (v == null) {
            return 0d;
        }
        if (v instanceof Number n) {
            return n.doubleValue();
        }
        String s = String.valueOf(v).trim();
        if (s.isEmpty()) {
            return 0d;
        }
        try {
            return Double.parseDouble(s);
        } catch (NumberFormatException e) {
            throw new ExprException("无法转为数字：" + v);
        }
    }

    static int length(Object v) {
        if (v == null) {
            return 0;
        }
        if (v instanceof CharSequence cs) {
            return cs.length();
        }
        if (v instanceof java.util.Collection<?> c) {
            return c.size();
        }
        if (v instanceof Map<?, ?> m) {
            return m.size();
        }
        return String.valueOf(v).length();
    }

    static boolean equalsLoose(Object l, Object r) {
        if (l == null || r == null) {
            return l == r;
        }
        if (l instanceof Number || r instanceof Number) {
            try {
                return Double.compare(toNumber(l), toNumber(r)) == 0;
            } catch (ExprException e) {
                return false;
            }
        }
        if (l instanceof Boolean || r instanceof Boolean) {
            return truthy(l) == truthy(r);
        }
        return str(l).equals(str(r));
    }


    static int compare(Object l, Object r) {
        if (l == null || r == null) {
            return 0;
        }
        if (l instanceof String ls && r instanceof String rs) {
            return ls.compareTo(rs);
        }
        if (l instanceof Boolean || r instanceof Boolean) {
            return Boolean.compare(truthy(l), truthy(r));
        }
        return Double.compare(toNumber(l), toNumber(r));
    }

    static Object plus(Object l, Object r) {
        if (l instanceof Number && r instanceof Number) {
            return toNumber(l) + toNumber(r);
        }
        if (l == null) {
            return r;
        }
        if (r == null) {
            return l;
        }
        return str(l) + str(r);
    }
}

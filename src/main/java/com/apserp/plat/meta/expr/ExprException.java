package com.apserp.plat.meta.expr;

/** 表达式解析/求值错误。属于“配置错误”，应当以 400 类错误返回给设计器。 */
public class ExprException extends RuntimeException {

    public ExprException(String message) {
        super(message);
    }

    public ExprException(String message, Throwable cause) {
        super(message, cause);
    }
}

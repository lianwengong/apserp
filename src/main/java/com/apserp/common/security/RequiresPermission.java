package com.apserp.common.security;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 功能点权限声明。
 *
 * <p>用法：</p>
 * <pre>
 * &#64;RequiresPermission("DATA:{objectCode}")                     // 读
 * &#64;RequiresPermission(value = "DATA:{objectCode}", action = "write")
 * </pre>
 *
 * <p>{@code {name}} 占位符会从请求路径变量中取值，未取到则拒绝（fail-closed）。</p>
 */
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
public @interface RequiresPermission {

    /** 权限点，形如 DATA:md.brand / FUN:030101.ADD / MOD:03。 */
    String value();

    /** read / write / approve / export / delete。 */
    String action() default "read";
}

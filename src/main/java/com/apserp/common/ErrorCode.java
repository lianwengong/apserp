package com.apserp.common;

/** 错误码：1xxx 通用 / 2xxx 元数据 / 3xxx 权限 / 4xxx 业务域。 */
public final class ErrorCode {

    public static final int BAD_REQUEST = 1001;
    public static final int NOT_FOUND = 1002;
    public static final int INTERNAL = 1999;
    public static final int DUPLICATE_KEY = 1003;

    public static final int META_OBJECT_NOT_FOUND = 2001;
    public static final int META_FIELD_NOT_ALLOWED = 2002;

    public static final int UNAUTHORIZED = 3000;
    public static final int TENANT_MISSING = 3001;
    public static final int FORBIDDEN = 3002;

    private ErrorCode() {
    }
}

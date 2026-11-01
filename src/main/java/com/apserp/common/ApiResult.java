package com.apserp.common;

/**
 * 统一返回体。成功 code=0；失败 code 见 ErrorCode。
 */
public record ApiResult<T>(int code, String message, T data) {

    public static <T> ApiResult<T> ok(T data) {
        return new ApiResult<>(0, "ok", data);
    }

    public static <T> ApiResult<T> fail(int code, String message) {
        return new ApiResult<>(code, message, null);
    }
}

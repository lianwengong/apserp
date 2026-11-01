package com.apserp.common;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * 全局异常处理：把异常翻译成稳定的错误码 + HTTP 状态，避免把堆栈或 SQL 细节暴露给前端。
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ApiResult<Void>> handleApi(ApiException ex) {
        HttpStatus status = switch (ex.getCode()) {
            case ErrorCode.FORBIDDEN -> HttpStatus.FORBIDDEN;
            case ErrorCode.NOT_FOUND, ErrorCode.META_OBJECT_NOT_FOUND -> HttpStatus.NOT_FOUND;
            case ErrorCode.INTERNAL -> HttpStatus.INTERNAL_SERVER_ERROR;
            case ErrorCode.DUPLICATE_KEY -> HttpStatus.CONFLICT;
            default -> HttpStatus.BAD_REQUEST;
        };
        if (status.is5xxServerError()) {
            log.error("api_error code={} msg={}", ex.getCode(), ex.getMessage(), ex);
        } else {
            log.warn("api_error code={} msg={}", ex.getCode(), ex.getMessage());
        }
        return ResponseEntity.status(status).body(ApiResult.fail(ex.getCode(), ex.getMessage()));
    }

    @ExceptionHandler(MissingRequestHeaderException.class)
    public ResponseEntity<ApiResult<Void>> handleMissingHeader(MissingRequestHeaderException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResult.fail(ErrorCode.TENANT_MISSING, "缺少必需的请求头：" + ex.getHeaderName()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResult<Void>> handleOther(Exception ex) {
        log.error("unexpected_error", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResult.fail(ErrorCode.INTERNAL, "系统异常，请联系管理员"));
    }
}

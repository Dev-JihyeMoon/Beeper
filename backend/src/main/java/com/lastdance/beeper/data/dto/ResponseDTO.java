package com.lastdance.beeper.data.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * ResponseDTO 는 ResponseEntity 의 GenericType 안에 넣어서 사용합니다.
 * <pre class="code">
 *     public ResponseEntity&lt;ResponseDTO&gt; saveUser(...) {
 *         // code
 *         return ResponseEntity.ok(
 *             ResponseDTO.ofSuccess("Success to save a new user")
 *         );
 *     }
 * </pre>
 */
@Getter
@AllArgsConstructor
public class ResponseDTO<T> {
    private ResponseCode resultCode;
    private String msg;
    private T data;

    /**
     * 메시지와 함께 성공 객체를 반환하는 함수입니다.
     * data 는 null 입니다.
     *
     * @param msg 함께 보낼 메시지
     * @return ResponseDTO 객체
     */
    public static ResponseDTO<Object> ofSuccess(String msg) {
        return new ResponseDTO<>(ResponseCode.SUCCESS, msg, null);
    }

    /**
     * 성공 객체를 반환합니다.
     * msg 와 data 는 null 입니다.
     *
     * @return ResponseDTO 객체
     */
    public static ResponseDTO<Object> ofSuccess() {
        return ofSuccess(null);
    }

    public static <T> ResponseDTO<T> ofSuccessWithData(T data) {
        return new ResponseDTO<>(ResponseCode.SUCCESS, null, data);
    }

    /**
     * 메시지와 함께 실패 객체를 반환합니다. msg 와 data 는 null 입니다.
     * @param msg 함께 보낼 메시지
     * @return ResponseDTO 객체
     */
    public static ResponseDTO<Object> ofFailure(String msg) {
        return new ResponseDTO<>(ResponseCode.FAILURE, msg, null);
    }

    /**
     * 실패 객체를 반환합니다. msg 와 data 는 null 입니다.
     * @return ResponseDTO 객체
     */
    public static ResponseDTO<Object> ofFailure() {
        return ofFailure(null);
    }

    /**
     * 메시지와 함계 비권한 객체를 반환합니다. data 는 null 입니다.
     * @param msg 함께 보낼 메시지
     * @return ResponseDTO 객체
     */
    public static ResponseDTO<Object> ofUnauthorized(String msg) {
        return new ResponseDTO<>(ResponseCode.UNAUTHORIZED, msg, null);
    }

    /**
     * 비권한 객체를 반환합니다. msg 와 data 는 null 입니다.
     * @return ResponseDTO 객체
     */
    public static ResponseDTO<Object> ofUnauthorized() {
        return ofUnauthorized(null);
    }
}

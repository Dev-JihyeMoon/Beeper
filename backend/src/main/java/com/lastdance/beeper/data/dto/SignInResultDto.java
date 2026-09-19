package com.lastdance.beeper.data.dto;

import lombok.*;

@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
@ToString
public class SignInResultDto extends SignUpResultDto {

    private String token;
    private Long userId;
    private String userType;

    @Builder
    public SignInResultDto(boolean success, int code, String msg, String token, Long userId, String userType) {
        super(success, code, msg);
        this.token = token;
        this.userId = userId;
        this.userType = userType;
    }

}
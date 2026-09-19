package com.lastdance.beeper.data.dto;

import com.lastdance.beeper.data.domain.User;
import lombok.*;

import java.util.Date;
import java.util.UUID;

public class UserDTO {

    @Data
    @ToString
    public static class Info{
        private Long id;
        private String nickname;
        private Date birthday;
        private String phoneNumber;
        private String image;
        private Long point;
        private String roles;
        private String userType;

        public Info(User user) {
            this.id = user.getId();
            this.nickname = user.getNickname();
            this.birthday = user.getBirthDate();
            this.phoneNumber = user.getPhoneNumber();
            this.image = user.getImage();
            this.point = user.getPoint();
            this.roles = user.getRoles().toString();
            this.userType = user.getRole() != null ? user.getRole().name() : null;
        }

    }

    @Data
    @NoArgsConstructor(force = true)
    @AllArgsConstructor
    @Builder
    public static class RequestForSignUp{
        private String nickname;
        private Date birthday;
        private String phoneNumber;
        private String passwordKey;
        private String userType; // SENIOR, HELPER (미입력 시 SENIOR)
    }

    @Data
    @NoArgsConstructor(force = true)
    @AllArgsConstructor
    @Builder
    public static class RequestForUpdate{
        private String nickname;
        private Date birthday;
        private String phoneNumber;
        private String passwordKey;
    }
}

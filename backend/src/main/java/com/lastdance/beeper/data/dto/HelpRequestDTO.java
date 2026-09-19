package com.lastdance.beeper.data.dto;

import com.lastdance.beeper.data.domain.HelpRequest;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

public class HelpRequestDTO {

    @Getter
    @NoArgsConstructor(force = true)
    @AllArgsConstructor
    @Builder
    public static class CreateRequest {
        private String title;
        private String description;
        private List<String> tags;
        private Double latitude;
        private Double longitude;
        //로그인하지 않은 시니어가 수락 알림을 받기 위해 전달하는 FCM 토큰 (선택)
        private String fcmToken;
    }

    @Getter
    @NoArgsConstructor(force = true)
    @AllArgsConstructor
    @Builder
    public static class CompleteRequest {
        private Long durationSeconds;
        private String summary;
    }

    @Getter
    public static class Info {
        private String id;
        private String roomId;
        private String title;
        private String description;
        private List<String> tags;
        private Double latitude;
        private Double longitude;
        private String status;
        private Long helperId;
        private LocalDateTime createdAt;

        public Info(HelpRequest helpRequest) {
            this.id = helpRequest.getId();
            this.roomId = helpRequest.getRoomId();
            this.title = helpRequest.getTitle();
            this.description = helpRequest.getDescription();
            this.tags = helpRequest.getTags();
            this.latitude = helpRequest.getLatitude();
            this.longitude = helpRequest.getLongitude();
            this.status = helpRequest.getStatus().name();
            this.helperId = helpRequest.getHelper() != null ? helpRequest.getHelper().getId() : null;
            this.createdAt = helpRequest.getCreatedAt();
        }
    }
}

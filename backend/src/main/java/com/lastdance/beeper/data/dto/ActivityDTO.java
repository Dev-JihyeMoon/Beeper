package com.lastdance.beeper.data.dto;

import com.lastdance.beeper.data.domain.Activity;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

public class ActivityDTO {

    @Getter
    public static class Info {
        private String id;
        private String requestId;
        private LocalDateTime date;
        private Long durationSeconds;
        private String title;
        private String summary;
        private String seniorName;
        private List<String> tags;

        public Info(Activity activity) {
            this.id = activity.getId();
            this.requestId = activity.getRequestId();
            this.date = activity.getDate();
            this.durationSeconds = activity.getDurationSeconds();
            this.title = activity.getTitle();
            this.summary = activity.getSummary();
            this.seniorName = activity.getSeniorName();
            this.tags = activity.getTags();
        }
    }
}

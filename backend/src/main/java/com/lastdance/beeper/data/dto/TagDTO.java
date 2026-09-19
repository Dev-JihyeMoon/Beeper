package com.lastdance.beeper.data.dto;

import com.lastdance.beeper.data.domain.Tag;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

public class TagDTO {

    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Info {
        private Long id;
        private String name;

        public Info(Tag tag) {
            this.id = tag.getId();
            this.name = tag.getName();
        }
    }

    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class requestList {
        private Long id;
    }

    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class request {
        private String name;
    }


}

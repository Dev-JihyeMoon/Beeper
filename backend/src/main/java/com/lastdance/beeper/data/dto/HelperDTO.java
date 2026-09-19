package com.lastdance.beeper.data.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

public class HelperDTO {

    @Getter
    @NoArgsConstructor(force = true)
    @AllArgsConstructor
    @Builder
    public static class Availability {
        private Boolean available;
    }
}

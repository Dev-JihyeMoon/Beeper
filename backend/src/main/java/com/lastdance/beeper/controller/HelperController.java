package com.lastdance.beeper.controller;

import com.lastdance.beeper.data.domain.User;
import com.lastdance.beeper.data.dto.HelperDTO;
import com.lastdance.beeper.data.dto.ResponseDTO;
import com.lastdance.beeper.service.UserService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/helpers")
@Slf4j
public class HelperController {
    private final UserService userService;

    public HelperController(UserService userService) {
        this.userService = userService;
    }

    @PutMapping("/me/availability")
    public ResponseEntity<ResponseDTO<HelperDTO.Availability>> updateAvailability(
            @RequestBody HelperDTO.Availability requestDTO) {
        Boolean available = userService.updateAvailability(currentUserId(), requestDTO.getAvailable());

        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(
                HelperDTO.Availability.builder().available(available).build()));
    }

    //인증 토큰의 사용자 id 추출
    private Long currentUserId() {
        User user = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return user.getId();
    }
}

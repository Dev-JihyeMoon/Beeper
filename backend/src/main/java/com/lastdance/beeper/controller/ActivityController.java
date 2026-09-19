package com.lastdance.beeper.controller;

import com.lastdance.beeper.data.domain.User;
import com.lastdance.beeper.data.dto.ActivityDTO;
import com.lastdance.beeper.data.dto.ResponseDTO;
import com.lastdance.beeper.service.ActivityService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/activities")
@Slf4j
public class ActivityController {
    private final ActivityService activityService;

    public ActivityController(ActivityService activityService) {
        this.activityService = activityService;
    }

    @GetMapping("/me")
    public ResponseEntity<ResponseDTO<List<ActivityDTO.Info>>> findMyActivities(Pageable pageable) {
        List<ActivityDTO.Info> infos = activityService.findMyActivities(currentUserId(), pageable);
        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(infos));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO<ActivityDTO.Info>> findOne(@PathVariable String id) {
        ActivityDTO.Info info = activityService.findOne(id);
        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(info));
    }

    //인증 토큰의 사용자 id 추출
    private Long currentUserId() {
        User user = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return user.getId();
    }
}

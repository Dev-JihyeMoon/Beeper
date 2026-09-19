package com.lastdance.beeper.controller;

import com.lastdance.beeper.data.dto.PostTokenRequest;
import com.lastdance.beeper.service.FCMService;
import com.lastdance.beeper.service.impl.FCMServiceImpl;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/fcm")
@Slf4j
public class FCMController {
    private FCMServiceImpl fcmServiceimpl;
    public FCMController(FCMServiceImpl fcmServiceimpl) {
        this.fcmServiceimpl = fcmServiceimpl;
    }

    @PostMapping("/{userId}/token")
    public ResponseEntity<String> getToken(@PathVariable Long userId, @Valid @RequestBody PostTokenRequest postTokenReq) {
        try {
            // fcmServiceimpl.getToken 호출
            String token = fcmServiceimpl.getToken(userId, postTokenReq.getToken());

            // ResponseEntity를 사용하여 결과와 상태 코드를 반환
            return ResponseEntity.ok(token);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
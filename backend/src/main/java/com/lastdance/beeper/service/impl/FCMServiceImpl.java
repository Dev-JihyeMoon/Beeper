package com.lastdance.beeper.service.impl;

import com.google.firebase.messaging.BatchResponse;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.MulticastMessage;
import com.lastdance.beeper.data.domain.User;
import com.lastdance.beeper.data.dto.HelpRequestDTO;
import com.lastdance.beeper.data.repository.UserRepository;
import com.lastdance.beeper.data.util.Role;
import com.lastdance.beeper.service.FCMService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
public class FCMServiceImpl implements FCMService {
    private final UserRepository userRepository;

    public FCMServiceImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public String getToken(Long userId, String token) {
        // 사용자 조회 후 FCM 토큰 저장
        User user = userRepository.findById(userId).orElseThrow(()->new RuntimeException("User가 존재하지 않습니다."));

        user.updateFcmToken(token);
        userRepository.save(user);

        return token;
    }

    @Override
    public void notifyHelpRequestCreated(HelpRequestDTO.Info helpRequestInfo) {
        List<String> tokens = userRepository
                .findByRoleAndAlarmStatusTrueAndAvailableTrueAndFcmTokenIsNotNull(Role.HELPER)
                .stream()
                .map(User::getFcmToken)
                .collect(Collectors.toList());

        if (tokens.isEmpty()) {
            log.info("[notifyHelpRequestCreated] 알림을 받을 활성 도우미가 없습니다. requestId : {}", helpRequestInfo.getId());
            return;
        }

        Map<String, String> data = new HashMap<>();
        data.put("type", "HELP_REQUEST_CREATED");
        data.put("id", helpRequestInfo.getId());
        data.put("roomId", helpRequestInfo.getRoomId());
        data.put("title", helpRequestInfo.getTitle());
        data.put("description", helpRequestInfo.getDescription() != null ? helpRequestInfo.getDescription() : "");
        data.put("status", helpRequestInfo.getStatus());

        MulticastMessage message = MulticastMessage.builder()
                .addAllTokens(tokens)
                .putAllData(data)
                .build();

        try {
            // sendMulticast()가 쓰던 FCM 배치 엔드포인트는 구글에서 폐기되어 sendEachForMulticast()로 대체
            BatchResponse response = FirebaseMessaging.getInstance().sendEachForMulticast(message);
            log.info("[notifyHelpRequestCreated] 도움 요청 알림 발송 완료. requestId : {}, 대상 인원 : {}, 성공 : {}, 실패 : {}",
                    helpRequestInfo.getId(), tokens.size(), response.getSuccessCount(), response.getFailureCount());
        } catch (FirebaseMessagingException e) {
            log.error("[notifyHelpRequestCreated] 도움 요청 알림 발송 실패. requestId : {}", helpRequestInfo.getId(), e);
        }
    }

    @Override
    public void notifyHelpRequestClosed(HelpRequestDTO.Info helpRequestInfo) {
        List<String> tokens = userRepository
                .findByRoleAndAlarmStatusTrueAndAvailableTrueAndFcmTokenIsNotNull(Role.HELPER)
                .stream()
                .map(User::getFcmToken)
                .collect(Collectors.toList());

        if (tokens.isEmpty()) {
            log.info("[notifyHelpRequestClosed] 알림을 받을 활성 도우미가 없습니다. requestId : {}", helpRequestInfo.getId());
            return;
        }

        Map<String, String> data = new HashMap<>();
        data.put("type", "HELP_REQUEST_CLOSED");
        data.put("id", helpRequestInfo.getId());
        data.put("status", helpRequestInfo.getStatus());

        MulticastMessage message = MulticastMessage.builder()
                .addAllTokens(tokens)
                .putAllData(data)
                .build();

        try {
            BatchResponse response = FirebaseMessaging.getInstance().sendEachForMulticast(message);
            log.info("[notifyHelpRequestClosed] 도움 요청 종료 알림 발송 완료. requestId : {}, 대상 인원 : {}, 성공 : {}, 실패 : {}",
                    helpRequestInfo.getId(), tokens.size(), response.getSuccessCount(), response.getFailureCount());
        } catch (FirebaseMessagingException e) {
            log.error("[notifyHelpRequestClosed] 도움 요청 종료 알림 발송 실패. requestId : {}", helpRequestInfo.getId(), e);
        }
    }

    @Override
    public void notifyHelpRequestAccepted(HelpRequestDTO.Info helpRequestInfo, String targetToken, String helperName) {
        if (targetToken == null || targetToken.isBlank()) {
            log.info("[notifyHelpRequestAccepted] 알림을 받을 FCM 토큰이 없습니다. requestId : {}", helpRequestInfo.getId());
            return;
        }

        Map<String, String> data = new HashMap<>();
        data.put("type", "HELP_REQUEST_ACCEPTED");
        data.put("id", helpRequestInfo.getId());
        data.put("roomId", helpRequestInfo.getRoomId());
        data.put("title", helpRequestInfo.getTitle());
        data.put("helperId", String.valueOf(helpRequestInfo.getHelperId()));
        data.put("helperName", helperName != null ? helperName : "");
        data.put("status", helpRequestInfo.getStatus());

        Message message = Message.builder()
                .setToken(targetToken)
                .putAllData(data)
                .build();

        try {
            FirebaseMessaging.getInstance().send(message);
            log.info("[notifyHelpRequestAccepted] 도움 요청 수락 알림 발송 완료. requestId : {}", helpRequestInfo.getId());
        } catch (FirebaseMessagingException e) {
            log.error("[notifyHelpRequestAccepted] 도움 요청 수락 알림 발송 실패. requestId : {}", helpRequestInfo.getId(), e);
        }
    }
}

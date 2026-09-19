package com.lastdance.beeper.service.impl;

import com.lastdance.beeper.data.domain.Activity;
import com.lastdance.beeper.data.domain.HelpRequest;
import com.lastdance.beeper.data.domain.User;
import com.lastdance.beeper.data.dto.HelpRequestDTO;
import com.lastdance.beeper.data.repository.ActivityRepository;
import com.lastdance.beeper.data.repository.HelpRequestRepository;
import com.lastdance.beeper.data.repository.UserRepository;
import com.lastdance.beeper.data.util.HelpRequestStatus;
import com.lastdance.beeper.service.FCMService;
import com.lastdance.beeper.service.HelpRequestService;
import jakarta.transaction.Transactional;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@Transactional
public class HelpRequestServiceImpl implements HelpRequestService {
    private final HelpRequestRepository helpRequestRepository;
    private final ActivityRepository activityRepository;
    private final UserRepository userRepository;
    private final FCMService fcmService;

    public HelpRequestServiceImpl(HelpRequestRepository helpRequestRepository,
                                   ActivityRepository activityRepository,
                                   UserRepository userRepository,
                                   FCMService fcmService) {
        this.helpRequestRepository = helpRequestRepository;
        this.activityRepository = activityRepository;
        this.userRepository = userRepository;
        this.fcmService = fcmService;
    }

    @Override
    public HelpRequestDTO.Info create(Long requesterId, HelpRequestDTO.CreateRequest requestDTO) {
        // 시니어는 로그인 없이 요청하므로 requesterId가 없을 수 있음
        User requester = requesterId != null
                ? userRepository.findById(requesterId).orElseThrow(()->new RuntimeException("User가 존재하지 않습니다."))
                : null;

        HelpRequest helpRequest = HelpRequest.builder()
                .id(UUID.randomUUID().toString())
                .roomId(UUID.randomUUID().toString())
                .title(requestDTO.getTitle())
                .description(requestDTO.getDescription())
                .tags(requestDTO.getTags())
                .latitude(requestDTO.getLatitude())
                .longitude(requestDTO.getLongitude())
                .status(HelpRequestStatus.WAITING)
                .requester(requester)
                .fcmToken(requestDTO.getFcmToken())
                .build();

        helpRequestRepository.save(helpRequest);
        log.info("[create] 도움 요청 생성 완료. id : {}", helpRequest.getId());

        HelpRequestDTO.Info info = new HelpRequestDTO.Info(helpRequest);
        fcmService.notifyHelpRequestCreated(info); // 활성 도우미에게 생성 알림 발송 (요청당 1회)

        return info;
    }

    @Override
    public List<HelpRequestDTO.Info> findAll(HelpRequestStatus status) {
        List<HelpRequest> helpRequests = status != null
                ? helpRequestRepository.findByStatus(status)
                : helpRequestRepository.findAll();

        return helpRequests.stream().map(HelpRequestDTO.Info::new).collect(Collectors.toList());
    }

    @Override
    public HelpRequestDTO.Info findOne(String id) {
        HelpRequest helpRequest = helpRequestRepository.findById(id).orElseThrow(()->new RuntimeException("도움 요청이 존재하지 않습니다."));
        return new HelpRequestDTO.Info(helpRequest);
    }

    @Override
    public HelpRequestDTO.Info accept(String id, Long helperId) {
        HelpRequest helpRequest = helpRequestRepository.findById(id).orElseThrow(()->new RuntimeException("도움 요청이 존재하지 않습니다."));
        User helper = userRepository.findById(helperId).orElseThrow(()->new RuntimeException("User가 존재하지 않습니다."));

        if (helpRequest.getStatus() != HelpRequestStatus.WAITING) {
            throw new RuntimeException("대기 중인 요청만 수락할 수 있습니다.");
        }

        helpRequest.accept(helper);
        helpRequestRepository.save(helpRequest);
        log.info("[accept] 도움 요청 수락 완료. id : {}, helperId : {}", id, helperId);

        HelpRequestDTO.Info info = new HelpRequestDTO.Info(helpRequest);

        // 로그인한 시니어면 User의 토큰을, 비로그인 시니어면 요청 생성 시 전달받은 토큰을 사용
        String targetToken = helpRequest.getRequester() != null
                ? helpRequest.getRequester().getFcmToken()
                : helpRequest.getFcmToken();
        fcmService.notifyHelpRequestAccepted(info, targetToken, helper.getNickname());
        fcmService.notifyHelpRequestClosed(info); // 다른 도우미의 대기 목록에서 제거하도록 알림

        return info;
    }

    @Override
    public HelpRequestDTO.Info cancel(String id) {
        HelpRequest helpRequest = helpRequestRepository.findById(id).orElseThrow(()->new RuntimeException("도움 요청이 존재하지 않습니다."));

        helpRequest.cancel();
        helpRequestRepository.save(helpRequest);
        log.info("[cancel] 도움 요청 취소 완료. id : {}", id);

        HelpRequestDTO.Info info = new HelpRequestDTO.Info(helpRequest);
        fcmService.notifyHelpRequestClosed(info); // 도우미의 대기 목록에서 제거하도록 알림

        return info;
    }

    @Override
    public HelpRequestDTO.Info complete(String id, HelpRequestDTO.CompleteRequest requestDTO) {
        HelpRequest helpRequest = helpRequestRepository.findById(id).orElseThrow(()->new RuntimeException("도움 요청이 존재하지 않습니다."));

        helpRequest.complete(requestDTO.getDurationSeconds(), requestDTO.getSummary());
        helpRequestRepository.save(helpRequest);

        Activity activity = Activity.builder()
                .id(UUID.randomUUID().toString())
                .requestId(helpRequest.getId())
                .date(LocalDateTime.now())
                .durationSeconds(helpRequest.getDurationSeconds())
                .title(helpRequest.getTitle())
                .summary(helpRequest.getSummary())
                .seniorName(helpRequest.getRequester() != null ? helpRequest.getRequester().getNickname() : "익명")
                .tags(helpRequest.getTags())
                .helper(helpRequest.getHelper())
                .build();

        activityRepository.save(activity);
        log.info("[complete] 통화 종료 및 활동 기록 생성 완료. id : {}, activityId : {}", id, activity.getId());

        return new HelpRequestDTO.Info(helpRequest);
    }
}

package com.lastdance.beeper.service;

import com.lastdance.beeper.data.dto.HelpRequestDTO;

public interface FCMService {
    String getToken(Long userId, String token);

    //대기 중인 활성 도우미에게 도움 요청 생성 알림 발송
    void notifyHelpRequestCreated(HelpRequestDTO.Info helpRequestInfo);

    //대기 목록에서 사라져야 하는 요청(수락/취소)을 활성 도우미에게 알려 목록을 갱신하도록 알림 발송
    void notifyHelpRequestClosed(HelpRequestDTO.Info helpRequestInfo);

    //요청을 보낸 시니어에게 도움 요청 수락 알림 발송
    void notifyHelpRequestAccepted(HelpRequestDTO.Info helpRequestInfo, String targetToken, String helperName);
 }

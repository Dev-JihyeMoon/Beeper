package com.lastdance.beeper.service;

import com.lastdance.beeper.data.dto.HelpRequestDTO;
import com.lastdance.beeper.data.util.HelpRequestStatus;

import java.util.List;

public interface HelpRequestService {
    HelpRequestDTO.Info create(Long requesterId, HelpRequestDTO.CreateRequest requestDTO);
    List<HelpRequestDTO.Info> findAll(HelpRequestStatus status);
    HelpRequestDTO.Info findOne(String id);
    HelpRequestDTO.Info accept(String id, Long helperId);
    HelpRequestDTO.Info cancel(String id);
    HelpRequestDTO.Info complete(String id, HelpRequestDTO.CompleteRequest requestDTO);
}

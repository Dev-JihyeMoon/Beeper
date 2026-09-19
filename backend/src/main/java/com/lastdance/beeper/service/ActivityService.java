package com.lastdance.beeper.service;

import com.lastdance.beeper.data.dto.ActivityDTO;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface ActivityService {
    List<ActivityDTO.Info> findMyActivities(Long helperId, Pageable pageable);
    ActivityDTO.Info findOne(String id);
}

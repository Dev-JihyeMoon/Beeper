package com.lastdance.beeper.service.impl;

import com.lastdance.beeper.data.domain.Activity;
import com.lastdance.beeper.data.domain.User;
import com.lastdance.beeper.data.dto.ActivityDTO;
import com.lastdance.beeper.data.repository.ActivityRepository;
import com.lastdance.beeper.data.repository.UserRepository;
import com.lastdance.beeper.service.ActivityService;
import jakarta.transaction.Transactional;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class ActivityServiceImpl implements ActivityService {
    private final ActivityRepository activityRepository;
    private final UserRepository userRepository;

    public ActivityServiceImpl(ActivityRepository activityRepository, UserRepository userRepository) {
        this.activityRepository = activityRepository;
        this.userRepository = userRepository;
    }

    @Override
    public List<ActivityDTO.Info> findMyActivities(Long helperId, Pageable pageable) {
        User helper = userRepository.findById(helperId).orElseThrow(()->new RuntimeException("User가 존재하지 않습니다."));

        return activityRepository.findByHelper(helper, pageable)
                .stream().map(ActivityDTO.Info::new).collect(Collectors.toList());
    }

    @Override
    public ActivityDTO.Info findOne(String id) {
        Activity activity = activityRepository.findById(id).orElseThrow(()->new RuntimeException("활동 이력이 존재하지 않습니다."));
        return new ActivityDTO.Info(activity);
    }
}

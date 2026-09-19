package com.lastdance.beeper.data.repository;


import com.lastdance.beeper.data.domain.User;
import com.lastdance.beeper.data.util.Role;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UserRepository extends JpaRepository<User, Long> {
    User getByPhoneNumber(String phoneNumber);
    User findByPhoneNumber(String phoneNumber);

    //FCM 알림 발송 대상 조회 (알람 동의 + 대기 가능 + 토큰 등록된 도우미)
    List<User> findByRoleAndAlarmStatusTrueAndAvailableTrueAndFcmTokenIsNotNull(Role role);

}
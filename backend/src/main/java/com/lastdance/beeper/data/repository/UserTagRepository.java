package com.lastdance.beeper.data.repository;

import com.lastdance.beeper.data.domain.User;
import com.lastdance.beeper.data.domain.UserTag;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UserTagRepository extends JpaRepository<UserTag, Long> {
    List<UserTag> findByUser(User user);
    void deleteByUser(User user);
}

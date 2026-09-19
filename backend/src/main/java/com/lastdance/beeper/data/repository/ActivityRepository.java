package com.lastdance.beeper.data.repository;

import com.lastdance.beeper.data.domain.Activity;
import com.lastdance.beeper.data.domain.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ActivityRepository extends JpaRepository<Activity, String> {
    Page<Activity> findByHelper(User helper, Pageable pageable);
}

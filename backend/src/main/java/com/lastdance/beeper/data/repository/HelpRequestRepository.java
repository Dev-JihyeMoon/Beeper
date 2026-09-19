package com.lastdance.beeper.data.repository;

import com.lastdance.beeper.data.domain.HelpRequest;
import com.lastdance.beeper.data.util.HelpRequestStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HelpRequestRepository extends JpaRepository<HelpRequest, String> {
    List<HelpRequest> findByStatus(HelpRequestStatus status);
}

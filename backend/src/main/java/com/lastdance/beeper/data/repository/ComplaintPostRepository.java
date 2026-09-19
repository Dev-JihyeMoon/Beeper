package com.lastdance.beeper.data.repository;

import com.lastdance.beeper.data.domain.ComplaintPost;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ComplaintPostRepository extends JpaRepository<ComplaintPost, Long> {
}

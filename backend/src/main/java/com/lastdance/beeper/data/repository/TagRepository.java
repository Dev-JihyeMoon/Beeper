package com.lastdance.beeper.data.repository;

import com.lastdance.beeper.data.domain.Tag;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TagRepository extends JpaRepository<Tag, Long> {
    List<Tag> findByNameContaining(String name);
    Tag findByName(String name);
}

package com.lastdance.beeper.data.domain;

import jakarta.persistence.*;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.ToString;

import java.util.ArrayList;
import java.util.List;

@Getter
@NoArgsConstructor(force = true)
@ToString
@Entity(name = "tag")
public class Tag extends Base{
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "tag_id")
    private long id;

    @Column(nullable = false)
    private String name;

    @Builder
    public Tag(String name) {
        this.name = name;
    }
}

package com.lastdance.beeper.data.domain;

import jakarta.persistence.*;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.ToString;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@NoArgsConstructor(force = true)
@ToString
@Entity(name = "activity")
public class Activity extends Base {
    @Id
    @Column(name = "activity_id")
    private String id;

    //완료된 도움 요청 id
    @Column(name = "request_id", nullable = false)
    private String requestId;

    @Column(nullable = false)
    private LocalDateTime date;

    @Column(name = "duration_seconds")
    private Long durationSeconds;

    @Column(columnDefinition = "TEXT")
    private String title;

    @Column(columnDefinition = "TEXT")
    private String summary;

    @Column(name = "senior_name")
    private String seniorName;

    @ElementCollection(fetch = FetchType.EAGER)
    private List<String> tags;

    //활동을 수행한 도우미
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "helper_id")
    private User helper;

    @Builder
    public Activity(String id, String requestId, LocalDateTime date, Long durationSeconds, String title,
                     String summary, String seniorName, List<String> tags, User helper) {
        this.id = id;
        this.requestId = requestId;
        this.date = date;
        this.durationSeconds = durationSeconds;
        this.title = title;
        this.summary = summary;
        this.seniorName = seniorName;
        this.tags = tags;
        this.helper = helper;
    }
}

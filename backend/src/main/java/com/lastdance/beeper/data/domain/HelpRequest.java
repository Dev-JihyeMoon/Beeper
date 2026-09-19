package com.lastdance.beeper.data.domain;

import com.lastdance.beeper.data.util.HelpRequestStatus;
import jakarta.persistence.*;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.ToString;

import java.util.List;

@Getter
@NoArgsConstructor(force = true)
@ToString
@Entity(name = "help_request")
public class HelpRequest extends Base {
    @Id
    @Column(name = "help_request_id")
    private String id;

    @Column(name = "room_id", nullable = false)
    private String roomId;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @ElementCollection(fetch = FetchType.EAGER)
    private List<String> tags;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    //진행상태
    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private HelpRequestStatus status;

    //도움을 요청한 시니어
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "requester_id")
    private User requester;

    //요청을 수락한 도우미
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "helper_id")
    private User helper;

    @Column(name = "duration_seconds")
    private Long durationSeconds;

    @Column(columnDefinition = "TEXT")
    private String summary;

    //로그인하지 않은 시니어의 FCM 토큰 (수락 알림 발송용, requester가 있으면 미사용)
    @Column(name = "fcm_token", columnDefinition = "TEXT")
    private String fcmToken;

    @Builder
    public HelpRequest(String id, String roomId, String title, String description, List<String> tags,
                        Double latitude, Double longitude, HelpRequestStatus status, User requester, String fcmToken) {
        this.id = id;
        this.roomId = roomId;
        this.title = title;
        this.description = description;
        this.tags = tags;
        this.latitude = latitude;
        this.longitude = longitude;
        this.status = status;
        this.requester = requester;
        this.fcmToken = fcmToken;
    }

    public void accept(User helper) {
        this.helper = helper;
        this.status = HelpRequestStatus.ACCEPTED;
    }

    public void cancel() {
        this.status = HelpRequestStatus.CANCELLED;
    }

    public void complete(Long durationSeconds, String summary) {
        this.status = HelpRequestStatus.COMPLETED;
        this.durationSeconds = durationSeconds;
        this.summary = summary;
    }
}

package com.lastdance.beeper.data.domain;

import com.lastdance.beeper.data.util.Status;
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
@Entity(name = "complaint_post")
public class ComplaintPost extends Base{
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "complaint_post_id")
    private long id;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;

    @Column(name = "record_file_url", columnDefinition = "TEXT")
    private String recordFileUrl;

    //통화시간(분으로 환산)
    @Column(name = "call_time")
    private Long callTime;

    //진행상태
    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private Status status;

    //도우미 유저
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Builder
    public ComplaintPost(String title, String content, String recordFileUrl, Long callTime, User user, Status status) {
        this.title = title;
        this.content = content;
        this.recordFileUrl = recordFileUrl;
        this.callTime = callTime;
        this.user = user;
        this.status = status;
    }
}

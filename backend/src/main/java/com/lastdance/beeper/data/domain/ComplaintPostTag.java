package com.lastdance.beeper.data.domain;

import jakarta.persistence.*;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.ToString;

@Getter
@NoArgsConstructor(force = true)
@ToString
@Entity(name = "complaint_post_tag")
public class ComplaintPostTag extends Base{
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "complaint_post_tag_id")
    private long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "complaint_post_id")
    private ComplaintPost complaintPost;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tag_id")
    private Tag tag;

    @Builder
    public ComplaintPostTag(ComplaintPost complaintPost, Tag tag) {

    }
}

package com.lastdance.beeper.service.impl;

import com.lastdance.beeper.data.domain.Tag;
import com.lastdance.beeper.data.domain.User;
import com.lastdance.beeper.data.domain.UserTag;
import com.lastdance.beeper.data.dto.TagDTO;
import com.lastdance.beeper.data.repository.TagRepository;
import com.lastdance.beeper.data.repository.UserRepository;
import com.lastdance.beeper.data.repository.UserTagRepository;
import com.lastdance.beeper.service.TagService;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class TagServiceImpl implements TagService {
    private TagRepository tagRepository;
    private UserTagRepository userTagRepository;
    private UserRepository userRepository;

    public TagServiceImpl(TagRepository tagRepository, UserTagRepository userTagRepository, UserRepository userRepository) {
        this.tagRepository = tagRepository;
        this.userTagRepository = userTagRepository;
        this.userRepository = userRepository;
    }

    @Override
    public List<TagDTO.Info> searchByName(String keyword) {
        List<Tag> tagList = tagRepository.findByNameContaining(keyword);

        List<TagDTO.Info> tagDTOList = new ArrayList<>();
        for (Tag tag : tagList) {
            TagDTO.Info tagDTO = new TagDTO.Info(tag); // 태그 정보 매핑
            tagDTOList.add(tagDTO);
        }

        return tagDTOList;
    }

    @Override
    public List<TagDTO.Info> findAll() {
        List<Tag> tagList = tagRepository.findAll();
        List<TagDTO.Info> tagDTOList = new ArrayList<>();
        for (Tag tag : tagList) {
            TagDTO.Info tagDTO = new TagDTO.Info(tag); // 태그 정보 매핑
            tagDTOList.add(tagDTO);
        }
        return tagDTOList;
    }

    @Override
    public List<TagDTO.Info> saveList(List<TagDTO.requestList> tagList, Long userId) {
        User user = userRepository.findById(userId).orElseThrow(()->new RuntimeException("User가 존재하지 않습니다."));

        userTagRepository.deleteByUser(user); // 기존 선택 태그 초기화 후 재저장

        List<TagDTO.Info> tagDTOList = new ArrayList<>();

        for(TagDTO.requestList tagDTO : tagList) {
            Tag tag = tagRepository.getById(tagDTO.getId());

            userTagRepository.save(UserTag.builder().user(user).tag(tag).build());

            tagDTOList.add(new TagDTO.Info(tag));
        }

        return tagDTOList;
    }

    @Override
    public List<TagDTO.Info> findMyTags(Long userId) {
        User user = userRepository.findById(userId).orElseThrow(()->new RuntimeException("User가 존재하지 않습니다."));

        return userTagRepository.findByUser(user).stream()
                .map(userTag -> new TagDTO.Info(userTag.getTag()))
                .collect(Collectors.toList());
    }

    @Override
    public TagDTO.Info save(TagDTO.request request) {
        Tag tag = Tag.builder().name(request.getName()).build();

        TagDTO.Info tagDTOInfo = new TagDTO.Info(tagRepository.save(tag));
        return tagDTOInfo;
    }
}

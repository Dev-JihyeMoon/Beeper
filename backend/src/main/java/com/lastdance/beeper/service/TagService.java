package com.lastdance.beeper.service;

import com.lastdance.beeper.data.dto.TagDTO;

import java.util.List;

public interface TagService {
    //web api
    List<TagDTO.Info> searchByName(String keyword);
    List<TagDTO.Info> findAll();
    List<TagDTO.Info> saveList(List<TagDTO.requestList> tagList, Long userId);
    List<TagDTO.Info> findMyTags(Long userId);

    //service api
    TagDTO.Info save(TagDTO.request request);
}

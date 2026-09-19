package com.lastdance.beeper.controller;

import com.lastdance.beeper.data.dto.ResponseDTO;
import com.lastdance.beeper.data.dto.TagDTO;
import com.lastdance.beeper.service.TagService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/admin")
@Slf4j
public class AdminController {

    TagService tagService;

    public AdminController(TagService tagService) {
        this.tagService = tagService;
    }

    @PostMapping("/tag/save")
    public ResponseEntity<ResponseDTO<TagDTO.Info>> saveTag(@RequestBody TagDTO.request request){
        TagDTO.Info info = tagService.save(request);
        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(info));
    }
}

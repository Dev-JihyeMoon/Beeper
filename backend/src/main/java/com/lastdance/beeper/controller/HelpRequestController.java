package com.lastdance.beeper.controller;

import com.lastdance.beeper.data.domain.User;
import com.lastdance.beeper.data.dto.HelpRequestDTO;
import com.lastdance.beeper.data.dto.ResponseDTO;
import com.lastdance.beeper.data.util.HelpRequestStatus;
import com.lastdance.beeper.service.HelpRequestService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/help-requests")
@Slf4j
public class HelpRequestController {
    private final HelpRequestService helpRequestService;

    public HelpRequestController(HelpRequestService helpRequestService) {
        this.helpRequestService = helpRequestService;
    }

    @PostMapping
    public ResponseEntity<ResponseDTO<HelpRequestDTO.Info>> create(
            @RequestBody HelpRequestDTO.CreateRequest requestDTO) {
        HelpRequestDTO.Info info = helpRequestService.create(currentUserIdOrNull(), requestDTO);
        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(info));
    }

    @GetMapping
    public ResponseEntity<ResponseDTO<List<HelpRequestDTO.Info>>> findAll(
            @RequestParam(required = false) HelpRequestStatus status) {
        List<HelpRequestDTO.Info> infos = helpRequestService.findAll(status);
        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(infos));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO<HelpRequestDTO.Info>> findOne(@PathVariable String id) {
        HelpRequestDTO.Info info = helpRequestService.findOne(id);
        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(info));
    }

    @PostMapping("/{id}/accept")
    public ResponseEntity<ResponseDTO<HelpRequestDTO.Info>> accept(@PathVariable String id) {
        HelpRequestDTO.Info info = helpRequestService.accept(id, currentUserId());
        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(info));
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<ResponseDTO<HelpRequestDTO.Info>> cancel(@PathVariable String id) {
        HelpRequestDTO.Info info = helpRequestService.cancel(id);
        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(info));
    }

    @PostMapping("/{id}/complete")
    public ResponseEntity<ResponseDTO<HelpRequestDTO.Info>> complete(
            @PathVariable String id,
            @RequestBody HelpRequestDTO.CompleteRequest requestDTO) {
        HelpRequestDTO.Info info = helpRequestService.complete(id, requestDTO);
        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(info));
    }

    //인증 토큰의 사용자 id 추출
    private Long currentUserId() {
        User user = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return user.getId();
    }

    //시니어는 로그인 없이 호출하므로, 인증된 사용자일 때만 id를 추출
    private Long currentUserIdOrNull() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return principal instanceof User ? ((User) principal).getId() : null;
    }
}

package com.lastdance.beeper.controller;

import com.lastdance.beeper.data.domain.User;
import com.lastdance.beeper.data.dto.ResponseDTO;
import com.lastdance.beeper.data.dto.UserDTO;
import com.lastdance.beeper.service.UserService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/users")
@Slf4j
public class UserMeController {
    private final UserService userService;

    public UserMeController(UserService userService) {
        this.userService = userService;
    }

    @PutMapping("/me")
    public ResponseEntity<ResponseDTO<UserDTO.Info>> updateMe(
            @RequestBody UserDTO.RequestForUpdate requestDTO) throws Exception {
        User user = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        UserDTO.Info info = userService.update(user.getId(), requestDTO, null);

        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(info));
    }
}

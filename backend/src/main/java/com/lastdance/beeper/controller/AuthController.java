package com.lastdance.beeper.controller;

import com.lastdance.beeper.data.dto.ResponseDTO;
import com.lastdance.beeper.data.dto.SignInResultDto;
import com.lastdance.beeper.data.dto.SignUpResultDto;
import com.lastdance.beeper.data.dto.UserDTO;
import com.lastdance.beeper.service.UserService;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@Slf4j
public class AuthController {
    private final Logger LOGGER = LoggerFactory.getLogger(UserController.class);
    final private UserService userService;

    public AuthController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping(value = "/sign-in")
    public ResponseEntity<ResponseDTO<SignInResultDto>> signIn(
            @RequestParam String id,
            @RequestParam String password)
            throws RuntimeException {
        LOGGER.info("[signIn] 로그인을 시도하고 있습니다. id : {}, pw : ****", id);
        SignInResultDto signInResultDto = userService.signIn(id, password);

        if (signInResultDto.getCode() == 0) {
            LOGGER.info("[signIn] 정상적으로 로그인되었습니다. id : {}", id);
        }

        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(signInResultDto));
    }

    @PostMapping(value = "/sign-up")
    public ResponseEntity<ResponseDTO<SignUpResultDto>> signUp(@RequestBody UserDTO.RequestForSignUp requestDTO) {
        LOGGER.info("[signUp] 회원가입을 수행합니다. ");
        SignUpResultDto signUpResultDto = userService.signUp(requestDTO);

        LOGGER.info("[signUp] 회원가입을 완료했습니다. id : {}", requestDTO.getPhoneNumber());

        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(signUpResultDto));
    }
}
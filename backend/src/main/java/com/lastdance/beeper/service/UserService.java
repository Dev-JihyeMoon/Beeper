package com.lastdance.beeper.service;


import com.lastdance.beeper.data.dto.SignInResultDto;
import com.lastdance.beeper.data.dto.SignUpResultDto;
import com.lastdance.beeper.data.dto.UserDTO;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

public interface UserService {

    SignUpResultDto signUp(UserDTO.RequestForSignUp requestDTO);
    SignInResultDto signIn(String id, String password) throws RuntimeException;

    UserDTO.Info findOne(String phoneNumber);
    void delete(Long userId) throws Exception;

    UserDTO.Info updateFlag(Long userId);
    UserDTO.Info update(Long userId, UserDTO.RequestForUpdate requestDTO, MultipartFile multipartFile) throws Exception;
    UserDTO.Info updatePasswordKey(Long userId, String PasswordKey);

    Boolean verifyPasswordKey(Long userId, String PasswordKey);

    Boolean updateAvailability(Long userId, Boolean available);

}
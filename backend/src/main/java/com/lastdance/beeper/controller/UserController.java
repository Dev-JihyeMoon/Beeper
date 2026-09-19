package com.lastdance.beeper.controller;

import com.lastdance.beeper.data.domain.User;
import com.lastdance.beeper.data.dto.ResponseDTO;
import com.lastdance.beeper.data.dto.UserDTO;
import com.lastdance.beeper.service.UserService;
import com.lastdance.beeper.service.impl.S3Uploader;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

//TODO: HttpServletRequest 으로 받아서 처리하도록 리팩 예정

@RestController
@RequestMapping("/user")
@Slf4j
public class UserController {
    final private UserService userService;
    final private S3Uploader s3Uploader;

    public UserController(UserService userService, S3Uploader s3Uploader) {
        this.userService = userService;
        this.s3Uploader = s3Uploader;
    }

    @GetMapping("/{phoneNumber}")
    public ResponseEntity<ResponseDTO<?>> getUser(@PathVariable String phoneNumber){
        User currentUser = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        if (!currentUser.getPhoneNumber().equals(phoneNumber)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ResponseDTO.ofUnauthorized("본인 정보만 조회할 수 있습니다."));
        }

        UserDTO.Info getUserDTO = userService.findOne(phoneNumber);

        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(getUserDTO));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ResponseDTO<Object>> deleteUser(
            @PathVariable Long id) throws Exception {
        userService.delete(id);

        return ResponseEntity.ok(ResponseDTO.ofSuccess("탈퇴가 완료되었습니다."));
    }

    @PutMapping(value="/alarm-status/user-id/{id}")
    public ResponseEntity<ResponseDTO<UserDTO.Info>>updateStatus(@PathVariable Long id)throws Exception{
       UserDTO.Info getUserDTO = userService.updateFlag(id);
       return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(getUserDTO));
    }

    @PutMapping(value = "/update/{id}")
    public ResponseEntity<ResponseDTO<UserDTO.Info>> update(
            @PathVariable Long id,
            UserDTO.RequestForUpdate requestDTO,
            @RequestPart(value="file") MultipartFile multipartFile
            ) throws Exception {

        UserDTO.Info getUserDTO = userService.update(id, requestDTO, multipartFile);

        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(getUserDTO));
    }

    @PutMapping(value = "/update/non-image/{id}")
    public ResponseEntity<ResponseDTO<UserDTO.Info>> update(
            @PathVariable Long id,
            UserDTO.RequestForUpdate requestDTO
    ) throws Exception {

        UserDTO.Info getUserDTO = userService.update(id, requestDTO, null);

        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(getUserDTO));
    }

    @PutMapping(value = "/update/{id}/passwordKey/{passwordKey}")
    public ResponseEntity<ResponseDTO<UserDTO.Info>> updatePasswordKey(
            @PathVariable Long id,
            @PathVariable String passwordKey
    ) {
        UserDTO.Info getUserDTO = userService.updatePasswordKey(id, passwordKey);

        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(getUserDTO));
    }

    @GetMapping(value = "/verify/user/{id}/passwordkey")
    public ResponseEntity<ResponseDTO<Boolean>> verifyPasswordKey(
            @PathVariable Long id,
            @RequestParam String password)
            throws RuntimeException {
        Boolean check = userService.verifyPasswordKey(id, password);

        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(check));
    }

    @PutMapping(value = "/image-test")
    public ResponseEntity<ResponseDTO<String>> imageTest(
            @RequestPart(value="file") MultipartFile multipartFile
    ) throws Exception {

        String url = s3Uploader.upload(multipartFile);
        return ResponseEntity.ok(ResponseDTO.ofSuccessWithData(url));
    }
}

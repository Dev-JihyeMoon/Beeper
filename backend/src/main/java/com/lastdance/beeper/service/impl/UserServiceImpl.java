package com.lastdance.beeper.service.impl;

import com.lastdance.beeper.common.CommonResponse;
import com.lastdance.beeper.config.security.JwtTTokenProvider;
import com.lastdance.beeper.data.domain.User;
import com.lastdance.beeper.data.dto.SignInResultDto;
import com.lastdance.beeper.data.dto.SignUpResultDto;
import com.lastdance.beeper.data.dto.UserDTO;
import com.lastdance.beeper.data.repository.UserRepository;
import com.lastdance.beeper.data.util.Role;
import com.lastdance.beeper.service.UserService;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.Collections;

@Service
@Transactional
public class UserServiceImpl implements UserService {

    private final Logger LOGGER = LoggerFactory.getLogger(UserServiceImpl.class);
    private final UserRepository userRepository;
    private final JwtTTokenProvider jwtTTokenProvider;
    private final PasswordEncoder passwordEncoder;
    private final S3Uploader s3Uploader;

    public UserServiceImpl(UserRepository userRepository, JwtTTokenProvider jwtTTokenProvider, PasswordEncoder passwordEncoder, S3Uploader s3Uploader){
        this.userRepository = userRepository;
        this.jwtTTokenProvider = jwtTTokenProvider;
        this.passwordEncoder = passwordEncoder;
        this.s3Uploader = s3Uploader;
    }

    @Override
    public UserDTO.Info findOne(String phoneNumber) {
        User user = userRepository.getByPhoneNumber(phoneNumber);
        UserDTO.Info findUserDTO = new UserDTO.Info(user);

        return findUserDTO;
    }

    @Override
    public UserDTO.Info update(Long userId, UserDTO.RequestForUpdate requestDTO, MultipartFile multipartFile) throws Exception {
        User user = userRepository.findById(userId).orElseThrow(()->new RuntimeException("User가 존재하지 않습니다."));

        if (multipartFile == null){
            user.update(requestDTO, null);
        }else {
            user.update(requestDTO, s3Uploader.upload(multipartFile));
        }

        // 비밀번호는 요청에 포함된 경우에만 암호화하여 변경
        if (requestDTO.getPasswordKey() != null && !requestDTO.getPasswordKey().isBlank()) {
            user.updatePasswordKey(passwordEncoder.encode(requestDTO.getPasswordKey()));
        }

        userRepository.save(user);

        return new UserDTO.Info(user);
    }

    @Override
    public UserDTO.Info updateFlag(Long userId){
        User user = userRepository.findById(userId).orElseThrow(()->new RuntimeException("User가 존재하지 않습니다."));

        user.updateFlag(!user.getAlarmStatus()); // 현재 상태를 반전시켜 토글
        userRepository.save(user);
        return new UserDTO.Info(user);
    }

    @Override
    public UserDTO.Info updatePasswordKey(Long userId, String passwordKey) {
        User user = userRepository.findById(userId).orElseThrow(()->new RuntimeException("User가 존재하지 않습니다."));

        user.updatePasswordKey(passwordEncoder.encode(passwordKey));

        userRepository.save(user);

        return new UserDTO.Info(user);
    }

    @Override
    public Boolean verifyPasswordKey(Long userId, String password) {
        LOGGER.info("[getSignInResult] signDataHandler 로 회원 정보 요청");
        User user = userRepository.findById(userId).orElseThrow();
        LOGGER.info("[getSignInResult] Id : {}", userId);

        LOGGER.info("[getSignInResult] 패스워드 비교 수행");
        if (!passwordEncoder.matches(password, user.getPassword())) {
            return false;
        }
        LOGGER.info("[getSignInResult] 패스워드 일치");

        return true;
    }

    @Override
    public void delete(Long userId) throws Exception {
        userRepository.deleteById(userId);
    }

    @Override
    public Boolean updateAvailability(Long userId, Boolean available) {
        User user = userRepository.findById(userId).orElseThrow(()->new RuntimeException("User가 존재하지 않습니다."));

        user.updateAvailability(available);
        userRepository.save(user);

        return user.getAvailable();
    }

    @Override
    public SignUpResultDto signUp(UserDTO.RequestForSignUp requestDTO) {
        LOGGER.info("[getSignUpResult] 회원 가입 정보 전달");

        User user = User.builder()
                .nickname(requestDTO.getNickname())
                .birthDate(requestDTO.getBirthday())
                .phoneNumber(requestDTO.getPhoneNumber())
                .password(passwordEncoder.encode(requestDTO.getPasswordKey()))
                .roles(Collections.singletonList("ROLE_ADMIN"))
                .point(0L)
                .image(null)
                .alarmStatus(true)
                .role(requestDTO.getUserType() != null ? Role.valueOf(requestDTO.getUserType()) : Role.SENIOR)
                .build();

        User savedUser = userRepository.save(user);

        SignUpResultDto signUpResultDto = new SignInResultDto();

        LOGGER.info("[getSignUpResult] userEntity 값이 들어왔는지 확인 후 결과값 주입");

        Long id = savedUser.getId();
        if (id != null) {
            LOGGER.info("[getSignUpResult] 정상 처리 완료");
            setSuccessResult(signUpResultDto);
        } else {
            LOGGER.info("[getSignUpResult] 실패 처리 완료");
            setFailResult(signUpResultDto);
        }
        return signUpResultDto;
    }
    @Override
    public SignInResultDto signIn(String phoneNumber, String password) throws RuntimeException {
        LOGGER.info("[getSignInResult] signDataHandler 로 회원 정보 요청");
        User user = userRepository.getByPhoneNumber(phoneNumber);
        LOGGER.info("[getSignInResult] Id : {}", phoneNumber);

        LOGGER.info("[getSignInResult] 패스워드 비교 수행");
        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new RuntimeException();
        }
        LOGGER.info("[getSignInResult] 패스워드 일치");

        UserDTO.Info userDTO = new UserDTO.Info(user);

        LOGGER.info("[getSignInResult] SignInResultDto 객체 생성");
        SignInResultDto signInResultDto = SignInResultDto.builder()
                .token(
                        jwtTTokenProvider.createToken(
                                String.valueOf(user.getPhoneNumber()),
                                user.getRoles(),
                                userDTO
                        )
                )
                .userId(user.getId())
                .userType(user.getRole() != null ? user.getRole().name() : null)
                .build();

        LOGGER.info("[getSignInResult] SignInResultDto 객체에 값 주입");
        setSuccessResult(signInResultDto);

        return signInResultDto;
    }

    // 결과 모델에 api 요청 성공 데이터를 세팅해주는 메소드
    private void setSuccessResult(SignUpResultDto result) {
        result.setSuccess(true);
        result.setCode(CommonResponse.SUCCESS.getCode());
        result.setMsg(CommonResponse.SUCCESS.getMsg());
    }
    // 결과 모델에 api 요청 실패 데이터를 세팅해주는 메소드
    private void setFailResult(SignUpResultDto result) {
        result.setSuccess(false);
        result.setCode(CommonResponse.FAIL.getCode());
        result.setMsg(CommonResponse.FAIL.getMsg());
    }

}


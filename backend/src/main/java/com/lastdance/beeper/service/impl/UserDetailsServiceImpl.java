package com.lastdance.beeper.service.impl;


import com.lastdance.beeper.data.domain.User;
import com.lastdance.beeper.data.repository.UserRepository;
import com.lastdance.beeper.service.UserDetailsService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.stereotype.Service;
import jakarta.transaction.Transactional;



@Service
@Transactional
public class UserDetailsServiceImpl implements UserDetailsService {
    private final Logger logger = LoggerFactory.getLogger(UserDetailsServiceImpl.class);
    private final UserRepository userRepository;

    public UserDetailsServiceImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public User loadUserByPhoneNumber(String phoneNumber) {
        logger.info("[loadUserByUsername] loadUserByUsername 수행. UserPhoneNumber : {}", phoneNumber);
        return userRepository.getByPhoneNumber(phoneNumber);
    }

}

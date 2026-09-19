package com.lastdance.beeper.service;


import com.lastdance.beeper.data.domain.User;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

public interface UserDetailsService {
    User loadUserByPhoneNumber(String phoneNumber) throws UsernameNotFoundException;
}

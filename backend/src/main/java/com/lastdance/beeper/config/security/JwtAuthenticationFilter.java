package com.lastdance.beeper.config.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpMethod;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Enumeration;

public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final Logger LOGGER = LoggerFactory.getLogger(JwtAuthenticationFilter.class);
    private final JwtTTokenProvider jwtTTokenProvider;

    public JwtAuthenticationFilter(JwtTTokenProvider jwtTTokenProvider) {
        this.jwtTTokenProvider = jwtTTokenProvider;
    }

    //CORS preflight(OPTIONS) 요청은 인증 대상이 아니므로 필터를 타지 않게 해서 요청 1건당 로그가 중복 출력되지 않도록 함
    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return HttpMethod.OPTIONS.matches(request.getMethod());
    }

    @Override
    protected void doFilterInternal(HttpServletRequest servletRequest,
                                    HttpServletResponse servletResponse,
                                    FilterChain filterChain) throws ServletException, IOException {
        String token = null;
        String requestInfo = servletRequest.getMethod() + " " + servletRequest.getRequestURI();

        //헤더에서 Authorization에 해당하는 값 추출
        Enumeration<String> headers = servletRequest.getHeaders("Authorization");

        if (headers.hasMoreElements()) {
            String authorizationHeader = headers.nextElement();
            token = authorizationHeader.replace("Bearer ", "");
        }
        LOGGER.debug("[doFilterInternal] {} - token 추출 {}", requestInfo, token != null ? "완료" : "불가");

        //유효성 검사
        boolean authenticated = false;
        if (token != null && jwtTTokenProvider.validateToken(token)) {
            Authentication authentication = jwtTTokenProvider.getAuthentication(token); //사용자 존재 여부 확인
            SecurityContextHolder.getContext().setAuthentication(authentication);
            authenticated = true;
        }
        // 요청 1건당 한 줄로 요약. 같은 timestamp에 서로 다른 스레드(exec-N)로 동일 요청이 두 번 찍히면
        // 백엔드 중복 처리가 아니라 클라이언트가 같은 요청을 동시에 두 번 보낸 것이므로 프론트엔드를 확인할 것.
        LOGGER.info("[doFilterInternal] {} - 인증 처리 완료, authenticated : {}", requestInfo, authenticated);

        //HttpServletRequest, servletResponse를 chain으로 넘김.
        filterChain.doFilter(servletRequest, servletResponse);
    }
}
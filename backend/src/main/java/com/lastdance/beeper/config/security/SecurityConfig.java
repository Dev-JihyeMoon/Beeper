package com.lastdance.beeper.config.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityCustomizer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.firewall.DefaultHttpFirewall;
import org.springframework.security.web.firewall.HttpFirewall;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtTTokenProvider jwtTTokenProvider;

    // 프론트 배포 주소 등 CORS 허용 Origin 목록을 properties(application-local.properties)에서 주입받음
    @Value("${beeper.cors.allowed-origins}")
    private List<String> allowedOrigins;

    public SecurityConfig(JwtTTokenProvider jwtTTokenProvider) {
        this.jwtTTokenProvider = jwtTTokenProvider;
    }


    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity httpSecurity) throws Exception {
        httpSecurity
                .httpBasic(customizer -> customizer.disable()) // REST API는 UI를 사용하지 않으므로 기본설정을 비활성화
                .csrf(csrf -> csrf.disable()) // REST API는 csrf 보안이 필요 없으므로 비활성화
                .cors(cors -> cors.configurationSource(corsConfigurationSource())) // 프론트(Flutter Web) CORS 허용
                .sessionManagement(sessionManagement ->
                        sessionManagement.sessionCreationPolicy(SessionCreationPolicy.STATELESS)) // JWT Token 인증방식으로 세션은 필요 없으므로 비활성화
                .authorizeHttpRequests(auth ->
                        auth.requestMatchers(HttpMethod.OPTIONS, "/**").permitAll() // CORS preflight 요청은 인증 없이 통과
                                // 요청 처리 중 예외(404 포함)가 발생하면 서블릿 컨테이너가 /error로 다시
                                // 포워딩하는데, 이 경로가 permitAll이 아니면 실제 원인과 무관하게 항상
                                // CustomAuthenticationEntryPoint가 응답해 "인증 실패"로 보이는 문제가 있었다.
                                .requestMatchers("/error").permitAll()
                                .requestMatchers("/auth/**", "/exception/**", "/swagger-ui/**", "/signal").permitAll()
                                // 시니어(도움 요청자)는 로그인 없이 도움 요청 생성/조회/취소/종료가 가능해야 함
                                .requestMatchers(HttpMethod.POST, "/help-requests").permitAll()
                                .requestMatchers(HttpMethod.GET, "/help-requests", "/help-requests/*").permitAll()
                                .requestMatchers(HttpMethod.POST, "/help-requests/*/cancel", "/help-requests/*/complete").permitAll()
                                .requestMatchers("/admin/**").hasRole("ADMIN") // 관리자 전용 기능만 ADMIN 권한 필요
                                .anyRequest().authenticated()) // 나머지는 로그인한 사용자(HELPER 등)면 접근 가능
                .exceptionHandling(exceptions ->
                        exceptions.accessDeniedHandler(new CustomAccessDeniedHandler())
                                .authenticationEntryPoint(new CustomAuthenticationEntryPoint())) // 예외 처리 핸들러 설정
                .addFilterBefore(new JwtAuthenticationFilter(jwtTTokenProvider),
                        UsernamePasswordAuthenticationFilter.class); // JWT Token 필터를 id/password 인증 필터 이전에 추가

        return httpSecurity.build();
    }

    //Flutter Web CORS 허용 설정 (허용 Origin은 properties에서 관리)
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(allowedOrigins);
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("Content-Type", "Authorization"));
        configuration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public WebSecurityCustomizer webSecurityCustomizer() {
        return web -> web.ignoring()
                .requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/swagger-resources/**");
    }

    @Bean
    public HttpFirewall defaultHttpFirewall() {
        return new DefaultHttpFirewall();
    }
}
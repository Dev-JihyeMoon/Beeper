package com.lastdance.beeper.config;

import com.lastdance.beeper.Socket.SignalingSocketHandler;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
@EnableWebSocket
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer, WebSocketConfigurer {

    // 프론트 배포 주소 등 WebSocket 허용 Origin 목록을 properties(application-local.properties)에서 주입받음
    @Value("${beeper.cors.allowed-origins}")
    private String[] allowedOrigins;

    // Configuration for STOMP over WebSocket (Firebase setup)
    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic");    // broker URL 설정
        config.setApplicationDestinationPrefixes("/app");   // send URL 설정
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/signaling")  // WebSocket 접속 시 endpoint 설정
                .setAllowedOriginPatterns(allowedOrigins)  // CORS 설정
                .withSockJS();  // WebSocket을 지원하지 않는 경우를 위한 대체 설정
    }

    // Configuration for native WebSocket (Video call setup)
    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(new SignalingSocketHandler(), "/signal")
                .setAllowedOriginPatterns(allowedOrigins);
    }
}

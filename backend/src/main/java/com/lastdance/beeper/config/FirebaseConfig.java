package com.lastdance.beeper.config;

import com.google.auth.oauth2.ServiceAccountCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import javax.annotation.PostConstruct;

@Slf4j
@Configuration
public class FirebaseConfig {
    // Firebase 콘솔 > 프로젝트 설정 > 서비스 계정에서 발급받은 값을 properties(비공개)에서 주입받음
    @Value("${firebase.project-id}")
    private String projectId;

    @Value("${firebase.private-key-id}")
    private String privateKeyId;

    @Value("${firebase.private-key}")
    private String privateKey;

    @Value("${firebase.client-email}")
    private String clientEmail;

    @Value("${firebase.client-id}")
    private String clientId;

    @PostConstruct
    public void init() {
        try {
            if (FirebaseApp.getApps().isEmpty()) { // FirebaseApp이 이미 초기화되어 있지 않은 경우에만 초기화 실행
                ServiceAccountCredentials credentials = ServiceAccountCredentials.newBuilder()
                        .setClientId(clientId)
                        .setClientEmail(clientEmail)
                        .setPrivateKeyId(privateKeyId)
                        .setPrivateKeyString(normalizePrivateKey())
                        .setProjectId(projectId)
                        .build();

                FirebaseOptions options = new FirebaseOptions.Builder()
                        .setCredentials(credentials)
                        .build();

                FirebaseApp.initializeApp(options);
            }

            log.info("[init] Firebase 초기화 완료");
        } catch (Exception e) {
            // 개인 키 등 민감정보가 노출되지 않도록 예외 메시지만 남김
            log.error("[init] Firebase 초기화 실패", e);
        }
    }

    // properties는 값에 실제 개행이 들어오면 파싱이 깨질 수 있어, private key는 개행이 "\n" 이스케이프 문자로 입력되는 것을 기본으로 하되
    // 실제 개행이나 \r\n 으로 들어온 경우까지 모두 표준 PEM 개행("\n")으로 정규화해 PKCS8 파싱 오류를 방지한다.
    private String normalizePrivateKey() {
        if (privateKey == null || privateKey.isBlank()) {
            throw new IllegalStateException("firebase.private-key 값이 비어 있습니다.");
        }

        String key = privateKey.trim();
        if (key.startsWith("\"") && key.endsWith("\"")) {
            key = key.substring(1, key.length() - 1);
        }

        return key.replace("\\r\\n", "\n")
                .replace("\\n", "\n")
                .replace("\r\n", "\n");
    }
}

# Beeper

도움이 필요한 사용자(시니어)와 봉사자를 연결하는 서비스. 시니어는 음성으로 도움을 요청하고, 봉사자가 수락하면 영상통화로 연결됩니다.

## 실행 방법

### 사전 준비

1. Flutter SDK 설치
2. 백엔드 서버 실행 (기본 포트 5500)
3. 푸시 알림(FCM)을 사용하려면 Firebase 설정 파일을 준비합니다. 설정하지 않아도 앱은 실행되며 푸시 알림 기능만 비활성화됩니다.
   - `lib/config/secrets.dart.example`을 `lib/config/secrets.dart`로 복사한 뒤 API 주소와 Firebase 콘솔의 Web 앱 config 값, 웹 푸시 인증서(VAPID) 키를 채웁니다.
   - `web/firebase-messaging-sw.js.example`을 `web/firebase-messaging-sw.js`로 복사한 뒤 `secrets.dart`와 동일한 값으로 채웁니다.
   - 두 파일은 `.gitignore`에 등록되어 있으므로 커밋하지 않습니다.

### API 서버 주소

`lib/config/secrets.dart`의 `apiBaseUrl` 하나만 수정하면 API와 시그널링(WebSocket) 주소가 함께 바뀝니다.
- 로컬 개발: `http://localhost:5500`
- 배포: `https://your-server.com` (시그널링은 `wss://your-server.com/signal`로 자동 설정)
- Android 기기에서 실행할 때는 기기에서 접근 가능한 주소(예: 같은 네트워크의 PC IP)를 입력합니다.

### 실행

```bash
flutter pub get
flutter run -d chrome
```

### 빌드

```bash
flutter build web
flutter build apk
```

## 폴더 구조

```
lib/
├── main.dart                 # 앱 진입점 (Firebase 초기화)
├── app.dart                  # 루트 위젯 (Provider, 라우터, FCM 알림 라우팅)
├── config/                   # 테마, 라우트, 상수, 시크릿
├── core/
│   ├── api/                  # dio 기반 API 클라이언트, 응답/예외 모델
│   ├── auth/                 # 로그인, 회원가입, 세션 관리
│   ├── models/               # 도메인 모델
│   ├── storage/              # 보안 저장소 래퍼
│   └── services/             # 음성 인식, WebRTC, 시그널링, FCM, 각 API 서비스
├── features/
│   ├── user_select/          # 사용자 유형 선택
│   ├── auth/                 # 봉사자 로그인, 회원가입
│   ├── senior/               # 도움 요청, 대기
│   ├── helper/               # 봉사자 대시보드, 요청 상세
│   ├── video_call/           # 영상통화
│   ├── profile/              # 프로필 조회, 수정
│   ├── tags/                 # 알림 태그 편집
│   └── activities/           # 활동 내역, 상세
└── shared/                   # 공통 위젯, 유틸
```

## 기능 목록

**시니어 (도움 요청자)**
- 음성 인식으로 도움 요청 작성 및 제출
- 요청 대기 화면, 요청 취소
- 봉사자 수락 알림 수신 후 영상통화 연결

**봉사자**
- 회원가입, 로그인, 자동 로그인
- 대기 중인 도움 요청 목록 조회 (푸시 알림, 주기 갱신, 당겨서 새로고침)
- 요청 상세 확인 및 수락, 영상통화 진행
- 활동 상태(활동 가능/중지) 전환
- 알림 태그 선택 및 편집
- 프로필 조회, 수정 (닉네임, 전화번호, 생년월일, 비밀번호)
- 활동 내역 목록, 상세 조회

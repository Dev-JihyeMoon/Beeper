// 앱 진입점 (Firebase 초기화 후 BeeperApp 실행, 초기화 실패해도 앱은 실행)
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'config/secrets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();
  runApp(const BeeperApp());
}

// 앱이 백그라운드/종료 상태일 때 FCM 데이터 메시지 수신 시 호출
// 별도 isolate에서 실행될 수 있어 최상위 함수 + @pragma 필요
// 백엔드가 data-only 메시지만 보내므로 이 핸들러가 없으면 Android 백그라운드 수신이 보장되지 않음
// 시스템 알림을 직접 그리려면 flutter_local_notifications 필요 (현재는 로그만 남김)
// 웹은 firebase-messaging-sw.js가 처리
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[Beeper] 백그라운드 FCM 메시지 수신');
}

// secrets.dart 값이 비어 있으면 Firebase 초기화를 건너뛰고 로그만 남김
// Firebase 없이도 나머지 기능은 정상 동작해야 함
Future<void> _initFirebase() async {
  if (!BeeperSecrets.isFirebaseConfigured) {
    debugPrint('[Beeper] Firebase 설정값이 비어 있어 초기화를 건너뜁니다. (config/secrets.dart 확인)');
    return;
  }

  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: BeeperSecrets.firebaseApiKey,
        authDomain: BeeperSecrets.firebaseAuthDomain,
        projectId: BeeperSecrets.firebaseProjectId,
        storageBucket: BeeperSecrets.firebaseStorageBucket,
        messagingSenderId: BeeperSecrets.firebaseMessagingSenderId,
        appId: BeeperSecrets.firebaseAppId,
      ),
    );
    // 웹에서는 효과 없음 (웹 백그라운드는 서비스 워커 담당), 호출은 안전하므로 플랫폼 분기 없이 항상 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[Beeper] Firebase 초기화 실패: $e');
  }
}

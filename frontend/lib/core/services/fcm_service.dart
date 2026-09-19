// FCM 토큰 등록/갱신, 알림 수신 서비스
// Firebase 미초기화 상태에서는 모든 메서드가 예외 없이 아무 동작도 하지 않음
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../config/secrets.dart';
import '../api/api_client.dart';
import '../api/api_exceptions.dart';

class FcmService {
  FcmService({required this._apiClient});

  final ApiClient _apiClient;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  // 동일 이벤트 중복 수신 방지용 캐시 (type+id, 마지막 수신 시각)
  String? _lastEventKey;
  DateTime? _lastEventAt;

  // Firebase.initializeApp() 성공 여부
  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  // Firebase 초기화 이후 호출 (실제 초기화는 main.dart 책임)
  Future<void> initialize() async {
    if (!_isFirebaseReady) {
      debugPrint('[FcmService] Firebase가 초기화되지 않아 FCM 기능을 건너뜁니다.');
    }
  }

  Future<bool> requestPermission() async {
    if (!_isFirebaseReady) return false;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('[FcmService] 알림 권한 요청 실패: $e');
      return false;
    }
  }

  // 웹은 vapidKey가 없으면 토큰 발급 실패함 (Android/iOS는 무관)
  // secrets.dart의 firebaseVapidKey가 비어 있으면 null 전달
  Future<String?> getToken() async {
    if (!_isFirebaseReady) return null;
    try {
      final vapidKey = BeeperSecrets.firebaseVapidKey;
      return await FirebaseMessaging.instance.getToken(
        vapidKey: vapidKey.isNotEmpty ? vapidKey : null,
      );
    } catch (e) {
      debugPrint('[FcmService] 토큰 조회 실패: $e');
      return null;
    }
  }

  // POST /fcm/{userId}/token (순수 문자열 응답이라 postRaw 사용)
  // 실패 시 1회 재시도 후 로그만 남김
  Future<void> registerToken(int userId, String token) async {
    if (!_isFirebaseReady) return;

    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        final success = await _apiClient.postRaw('/fcm/$userId/token', data: {'token': token});
        if (success) return;
      } on ApiException catch (e) {
        debugPrint('[FcmService] 토큰 등록 실패(시도 $attempt/2): ${e.message}');
      } catch (e) {
        debugPrint('[FcmService] 토큰 등록 실패(시도 $attempt/2): ${e.runtimeType}');
      }
    }
  }

  // 토큰이 갱신될 때마다 서버에 다시 등록
  void listenTokenRefresh(int userId) {
    if (!_isFirebaseReady) return;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) => registerToken(userId, token),
      onError: (e) => debugPrint('[FcmService] 토큰 갱신 스트림 오류: $e'),
    );
  }

  // 앱이 포그라운드일 때 수신되는 메시지를 [onMessage]에 전달
  // 같은 이벤트가 3초 이내 중복 수신되면 무시
  void listenForegroundMessages(void Function(Map<String, dynamic>) onMessage) {
    if (!_isFirebaseReady) return;
    _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen(
      (message) {
        if (_isDuplicate(message.data)) return;
        onMessage(message.data);
      },
      onError: (e) => debugPrint('[FcmService] 포그라운드 메시지 스트림 오류: $e'),
    );
  }

  // 알림을 탭해 앱이 열렸을 때 호출 (백그라운드 복귀 또는 종료 상태에서 실행)
  void handleBackgroundMessageTap(void Function(Map<String, dynamic>) onTap) {
    if (!_isFirebaseReady) return;

    _openedAppSub?.cancel();
    _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => onTap(message.data),
      onError: (e) => debugPrint('[FcmService] 알림 탭 스트림 오류: $e'),
    );

    // 종료 상태에서 알림 탭으로 실행된 경우, 시작 시 1회만 확인
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) onTap(message.data);
    });
  }

  bool _isDuplicate(Map<String, dynamic> data) {
    final requestId = data['id']?.toString();
    if (requestId == null) return false;

    final key = '${data['type']}_$requestId';
    final now = DateTime.now();
    final isDuplicate =
        key == _lastEventKey &&
        _lastEventAt != null &&
        now.difference(_lastEventAt!) < const Duration(seconds: 3);

    _lastEventKey = key;
    _lastEventAt = now;
    return isDuplicate;
  }

  // 로그아웃 시 토큰 갱신 리스너만 해제
  // 포그라운드/알림 탭 리스너는 시니어도 써야 하므로 app.dart에서 한 번만 등록하고 유지
  void stopTokenRefreshListener() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }

  // 전체 리스너 해제 (현재 호출부 없음, 필요 시 사용)
  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedAppSub?.cancel();
    _tokenRefreshSub = null;
    _foregroundSub = null;
    _openedAppSub = null;
  }
}

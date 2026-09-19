// 인증 상태 공유 ChangeNotifier (로그인, 회원가입, 자동 로그인, 로그아웃)
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/fcm_service.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService, this._fcmService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  // 로그인 성공/세션 복원 후 FCM 토큰 등록에 사용
  // 주입하지 않으면 FCM 관련 처리는 전부 건너뜀
  // 포그라운드 수신, 알림 탭 처리는 app.dart에서 한 번만 등록하므로 여기서 다루지 않음
  final FcmService? _fcmService;

  String? _accessToken;
  int? _userId;
  String? _phoneNumber;
  String? _userType;
  bool _isLoading = false;

  String? get accessToken => _accessToken;
  int? get userId => _userId;
  String? get phoneNumber => _phoneNumber;
  String? get userType => _userType;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _accessToken != null;

  bool _submitting = false;

  // 전화번호/비밀번호로 로그인 (중복 제출 방지)
  Future<bool> login(String phoneNumber, String password) async {
    if (_submitting) return false;
    _submitting = true;
    _setLoading(true);
    try {
      final result = await _authService.login(phoneNumber, password);
      _accessToken = result.token;
      _userId = result.userId;
      _phoneNumber = phoneNumber;
      _userType = result.userType;
      notifyListeners();
      unawaited(_setupFcm());
      return true;
    } finally {
      _submitting = false;
      _setLoading(false);
    }
  }

  // 회원가입 (중복 제출 방지, 성공 후 별도 로그인 필요)
  Future<bool> signUp({
    required String nickname,
    required DateTime birthday,
    required String phoneNumber,
    required String password,
    required String userType,
  }) async {
    if (_submitting) return false;
    _submitting = true;
    _setLoading(true);
    try {
      await _authService.signUp(
        nickname: nickname,
        birthday: birthday,
        phoneNumber: phoneNumber,
        password: password,
        userType: userType,
      );
      return true;
    } finally {
      _submitting = false;
      _setLoading(false);
    }
  }

  // 저장된 세션이 있으면 복원 (앱 시작 시 1회 호출)
  Future<void> tryAutoLogin() async {
    _setLoading(true);
    try {
      final session = await _authService.restoreSession();
      if (session == null) return;
      _accessToken = session.accessToken;
      _userId = session.userId;
      _phoneNumber = session.phoneNumber;
      _userType = session.userType;
      notifyListeners();
      unawaited(_setupFcm());
    } finally {
      _setLoading(false);
    }
  }

  // 알림 권한 요청, 토큰 조회, 서버 등록, 갱신 리스너 등록
  // FcmService 미주입 또는 Firebase 미초기화 시 각 단계는 아무 동작 없이 반환됨
  Future<void> _setupFcm() async {
    final fcm = _fcmService;
    final userId = _userId;
    if (fcm == null || userId == null) return;

    final granted = await fcm.requestPermission();
    if (!granted) return;

    final token = await fcm.getToken();
    if (token != null) {
      await fcm.registerToken(userId, token);
    }
    fcm.listenTokenRefresh(userId);
  }

  // 사용자가 직접 로그아웃
  Future<void> logout() async {
    await _authService.clearSession();
    _fcmService?.stopTokenRefreshListener();
    _clearState();
  }

  // 인증 실패(401 등)로 세션 강제 초기화 시 호출
  Future<void> clearSession() async {
    await _authService.clearSession();
    _fcmService?.stopTokenRefreshListener();
    _clearState();
  }

  void _clearState() {
    _accessToken = null;
    _userId = null;
    _phoneNumber = null;
    _userType = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

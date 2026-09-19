// 앱 루트 위젯 (Provider 등록, 테마, 라우터 연결, 자동 로그인, FCM 트리거)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/constants.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'core/api/api_client.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/auth_service.dart';
import 'core/services/analysis_service.dart';
import 'core/services/fcm_event_bus.dart';
import 'core/services/fcm_service.dart';
import 'core/services/help_request_service.dart';

class BeeperApp extends StatefulWidget {
  const BeeperApp({super.key});

  @override
  State<BeeperApp> createState() => _BeeperAppState();
}

class _BeeperAppState extends State<BeeperApp> {
  late final ApiClient _apiClient;
  late final FcmService _fcmService;
  late final HelpRequestService _helpRequestService;
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _fcmService = FcmService(apiClient: _apiClient);
    _helpRequestService = HelpRequestService(apiClient: _apiClient);
    _authProvider = AuthProvider(
      authService: AuthService(apiClient: _apiClient),
      fcmService: _fcmService,
    );
    _router = createRouter(_authProvider);

    // 401 수신 시 세션 초기화 후 로그인 화면으로 이동
    _apiClient.onUnauthorized = () async {
      await _authProvider.clearSession();
      _router.go(BeeperRoutes.userSelect);
    };

    // 포그라운드 메시지 라우팅, 알림 탭 처리는 앱 시작 시 한 번만 등록함
    // 시니어는 로그인을 안 하므로 로그인 이벤트에 묶지 않음
    _fcmService.listenForegroundMessages(FcmEventBus.routeForegroundMessage);
    _fcmService.handleBackgroundMessageTap(_handleNotificationTap);

    // 저장된 세션이 있으면 자동 로그인 시도
    _authProvider.tryAutoLogin();
  }

  // 알림을 탭해 앱이 열렸을 때 처리
  // 봉사자는 바로 수락 후 통화 화면, 시니어는 바로 통화 화면으로 이동 (roomId를 payload에서 알고 있음)
  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    final type = data['type']?.toString();
    final requestId = data['id']?.toString();
    final userType = _authProvider.userType;

    if (userType == BeeperConstants.userTypeHelper &&
        type == 'HELP_REQUEST_CREATED' &&
        requestId != null) {
      try {
        final result = await _helpRequestService.accept(requestId);
        _router.go('/video-call/helper/${result.roomId}', extra: result.id);
      } catch (_) {
        // 이미 수락됐거나 네트워크 오류면 대시보드에서 최신 상태 확인
        _router.go(BeeperRoutes.helperDashboard);
      }
      return;
    }

    if (userType == BeeperConstants.userTypeSenior && type == 'HELP_REQUEST_ACCEPTED') {
      final roomId = data['roomId']?.toString();
      if (roomId != null) {
        _router.go('/video-call/senior/$roomId');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 화면들이 ApiClient를 공유해서 사용
        Provider<ApiClient>.value(value: _apiClient),
        // 시니어가 요청 생성 시 FCM 토큰을 함께 보내기 위해 공유
        Provider<FcmService>.value(value: _fcmService),
        // 분석 API가 준비되면 ApiAnalysisService로 교체
        Provider<AnalysisService>(create: (_) => PassthroughAnalysisService()),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
      ],
      child: MaterialApp.router(
        title: 'Beeper',
        debugShowCheckedModeBanner: false,
        theme: BeeperTheme.light,
        scrollBehavior: BeeperTheme.scrollBehavior,
        routerConfig: _router,
      ),
    );
  }
}

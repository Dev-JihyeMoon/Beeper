// 도움 요청 상세 페이지 상태 관리 (상세 조회, 수락)
import 'package:flutter/foundation.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/models/help_request.dart';
import '../../core/services/fcm_event_bus.dart';
import '../../core/services/help_request_service.dart';

enum HelpRequestDetailStatus { loading, loaded, error }

class HelpRequestDetailProvider extends ChangeNotifier {
  HelpRequestDetailProvider({
    required this.requestId,
    required this._helpRequestService,
  }) {
    // 상세 페이지를 보는 동안 요청이 마감(HELP_REQUEST_CLOSED)되면 안내
    FcmEventBus.instance.addHelpRequestClosedListener(_onFcmHelpRequestClosed);
    _loadDetail();
  }

  final String requestId;
  final HelpRequestService _helpRequestService;

  bool _disposed = false;

  HelpRequestDetailStatus status = HelpRequestDetailStatus.loading;
  HelpRequest? request;
  String? loadError;

  bool isAccepting = false;
  String? acceptError;
  HelpRequestAcceptResult? acceptResult;

  // 푸시가 서버 커밋보다 먼저 도착하면 상세 조회가 일시적으로 404일 수 있음
  // 실패 시 짧게 재시도한 뒤 에러로 확정
  static const int _maxLoadAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  Future<void> _loadDetail() async {
    status = HelpRequestDetailStatus.loading;
    loadError = null;
    _safeNotify();

    try {
      for (var attempt = 1; ; attempt++) {
        try {
          request = await _helpRequestService.detail(requestId);
          break;
        } on UnauthorizedException {
          rethrow; // 인증 만료는 재시도 무의미
        } on ApiException {
          if (attempt >= _maxLoadAttempts) rethrow;
          await Future<void>.delayed(_retryDelay);
          if (_disposed) return;
        }
      }
      status = HelpRequestDetailStatus.loaded;
    } on ApiException catch (e) {
      loadError = e.message;
      status = HelpRequestDetailStatus.error;
    } catch (_) {
      loadError = '알 수 없는 오류가 발생했습니다.';
      status = HelpRequestDetailStatus.error;
    }
    _safeNotify();
  }

  Future<void> retryLoad() => _loadDetail();

  // 확인 다이얼로그에서 "수락" 클릭 시 호출
  Future<void> accept() async {
    if (isAccepting) return; // 중복 제출 방지

    isAccepting = true;
    acceptError = null;
    _safeNotify();

    try {
      acceptResult = await _helpRequestService.accept(requestId);
    } on ApiException catch (e) {
      // 이미 다른 봉사자가 수락한 경우도 FAILURE로 응답하므로 msg 그대로 노출
      acceptError = e.message;
    } catch (_) {
      acceptError = '알 수 없는 오류가 발생했습니다.';
    } finally {
      isAccepting = false;
      _safeNotify();
    }
  }

  void _onFcmHelpRequestClosed(Map<String, dynamic> data) {
    if (data['id']?.toString() != requestId) return;
    // 내가 수락 중이거나 수락에 성공한 경우의 마감 알림은 무시
    if (isAccepting || acceptResult != null) return;
    acceptError = '이미 마감된 요청입니다.';
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    FcmEventBus.instance.removeHelpRequestClosedListener(_onFcmHelpRequestClosed);
    super.dispose();
  }
}

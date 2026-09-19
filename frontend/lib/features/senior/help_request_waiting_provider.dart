// 도움 요청 대기 페이지 상태 관리 (취소 API 호출, 수락 이벤트 수신)
import 'package:flutter/foundation.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/services/fcm_event_bus.dart';
import '../../core/services/help_request_service.dart';

class HelpRequestWaitingProvider extends ChangeNotifier {
  HelpRequestWaitingProvider({
    required this.requestId,
    required this.roomId,
    required this._helpRequestService,
  }) {
    // 대기 페이지가 떠 있는 동안 FCM 포그라운드 메시지(HELP_REQUEST_ACCEPTED)를 직접 받음
    // 대기 페이지가 없으면 app.dart가 브라우저/시스템 알림을 띄움
    FcmEventBus.instance.onHelpRequestAccepted = _onFcmHelpRequestAccepted;
  }

  final String requestId;
  final String roomId;
  final HelpRequestService _helpRequestService;

  bool _disposed = false;
  bool isCancelling = false;
  bool isCancelled = false;
  String? errorMessage;

  // 봉사자가 수락하면 채워짐 (채워지는 즉시 영상통화로 이동)
  String? acceptedRoomId;

  // 취소 확인 다이얼로그에서 "확인" 클릭 시 호출
  // 성공하면 true 반환 (화면은 /senior-main으로 이동)
  Future<bool> cancelRequest() async {
    if (isCancelling) return false; // 중복 제출 방지

    isCancelling = true;
    errorMessage = null;
    _safeNotify();

    try {
      await _helpRequestService.cancel(requestId);
      isCancelled = true;
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (_) {
      errorMessage = '알 수 없는 오류가 발생했습니다.';
      return false;
    } finally {
      isCancelling = false;
      _safeNotify();
    }
  }

  // 봉사자 수락 알림(FCM) 수신 시 호출
  // 타이머 등으로 임의 호출 금지, 실제 수락 이벤트에서만 호출
  void onRequestAccepted(String roomId) {
    acceptedRoomId = roomId;
    _safeNotify();
  }

  void _onFcmHelpRequestAccepted(Map<String, dynamic> data) {
    // 다른 요청에 대한 이벤트는 무시 (이 화면이 기다리는 요청인지 확인)
    if (data['id']?.toString() != requestId) return;
    final acceptedRoomId = data['roomId']?.toString();
    if (acceptedRoomId == null) return;
    onRequestAccepted(acceptedRoomId);
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (identical(FcmEventBus.instance.onHelpRequestAccepted, _onFcmHelpRequestAccepted)) {
      FcmEventBus.instance.onHelpRequestAccepted = null;
    }
    super.dispose();
  }
}

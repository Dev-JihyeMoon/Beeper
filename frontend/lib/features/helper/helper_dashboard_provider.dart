// 봉사자 대시보드 상태 관리 (활동 상태 토글, 태그 요약, 대기 요청 목록)
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/models/help_request.dart';
import '../../core/services/fcm_event_bus.dart';
import '../../core/services/help_request_service.dart';
import '../../core/services/helper_service.dart';
import '../../core/services/tag_service.dart';

class HelperDashboardProvider extends ChangeNotifier {
  HelperDashboardProvider({
    required this._helperService,
    required this._helpRequestService,
    required this._tagService,
  }) {
    // 대시보드가 떠 있는 동안 FCM 포그라운드 메시지(HELP_REQUEST_CREATED)를 직접 받음
    // 대시보드가 없으면 app.dart가 브라우저/시스템 알림을 띄움
    FcmEventBus.instance.onHelpRequestCreated = _onFcmHelpRequestCreated;
    FcmEventBus.instance.addHelpRequestClosedListener(_onFcmHelpRequestClosed);

    // 푸시 유실, 알림 권한 거부 대비 주기 폴링으로 목록 보조 갱신
    _pollingTimer = Timer.periodic(_pollingInterval, (_) => loadRequests(silent: true));
  }

  // 폴링 주기 (30~60초 권장 범위의 중간값)
  static const Duration _pollingInterval = Duration(seconds: 45);

  final HelperService _helperService;
  final HelpRequestService _helpRequestService;
  final TagService _tagService;

  bool _disposed = false;
  Timer? _pollingTimer;

  // 활동 상태 조회 API가 없어 기본값은 false(활동 중지)
  bool isAvailable = false;
  bool isTogglingAvailability = false;
  String? toggleErrorMessage;
  int toggleErrorVersion = 0;

  // 대기 중인 도움 요청 목록
  List<HelpRequest> requests = [];
  bool isLoadingRequests = false;
  String? requestsError;
  bool _isFetchingRequests = false;

  // 내 알림 태그 요약
  List<String> tags = [];
  bool isLoadingTags = false;
  String? tagsError;

  // 활동 상태 스위치 클릭 시 호출 (즉시 반영 후 서버 응답으로 확정)
  Future<void> toggleAvailability() async {
    if (isTogglingAvailability) return;

    final previous = isAvailable;
    isAvailable = !previous;
    isTogglingAvailability = true;
    _safeNotify();

    try {
      isAvailable = await _helperService.updateAvailability(isAvailable);
    } on ApiException catch (e) {
      isAvailable = previous; // 롤백
      toggleErrorMessage = e.message;
      toggleErrorVersion++;
    } catch (_) {
      isAvailable = previous; // 롤백
      toggleErrorMessage = '알 수 없는 오류가 발생했습니다.';
      toggleErrorVersion++;
    } finally {
      isTogglingAvailability = false;
      _safeNotify();
    }
  }

  // 대기 요청 목록 조회 (진입, 새로고침, 새 요청 알림 시 사용)
  // [silent]가 true면(폴링, 앱 복귀) 로딩/에러 표시 없이 조용히 갱신
  Future<void> loadRequests({bool silent = false}) async {
    if (_isFetchingRequests) return; // 중복 조회 방지
    _isFetchingRequests = true;
    if (!silent) {
      isLoadingRequests = true;
      requestsError = null;
      _safeNotify();
    }

    try {
      requests = await _helpRequestService.listWaiting();
      requestsError = null;
    } on ApiException catch (e) {
      if (!silent) requestsError = e.message;
    } catch (_) {
      if (!silent) requestsError = '알 수 없는 오류가 발생했습니다.';
    } finally {
      isLoadingRequests = false;
      _isFetchingRequests = false;
      _safeNotify();
    }
  }

  // 사용자가 직접 누른 새로고침 (당겨서 새로고침 포함)
  Future<void> refreshRequests() => loadRequests();

  // FCM 새 요청 알림 수신 시 호출되어 목록 갱신
  Future<void> onNewHelpRequest() => loadRequests();

  void _onFcmHelpRequestCreated(Map<String, dynamic> data) => onNewHelpRequest();

  // 마감된 요청은 목록에서 즉시 제거 후 서버 기준으로 다시 맞춤
  void _onFcmHelpRequestClosed(Map<String, dynamic> data) {
    final closedId = data['id']?.toString();
    if (closedId != null) {
      requests = requests.where((request) => request.id.toString() != closedId).toList();
      _safeNotify();
    }
    loadRequests(silent: true);
  }

  Future<void> loadTags() async {
    isLoadingTags = true;
    tagsError = null;
    _safeNotify();

    try {
      final myTags = await _tagService.fetchMyTags();
      tags = myTags.map((tag) => tag.name).toList();
    } on ApiException catch (e) {
      tagsError = e.message;
    } catch (_) {
      tagsError = '알 수 없는 오류가 발생했습니다.';
    } finally {
      isLoadingTags = false;
      _safeNotify();
    }
  }

  // /tags 페이지에서 돌아왔을 때 최신 태그 반영용
  Future<void> refreshTags() => loadTags();

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _pollingTimer?.cancel();
    FcmEventBus.instance.removeHelpRequestClosedListener(_onFcmHelpRequestClosed);
    // 더 최근 인스턴스가 등록한 콜백을 지우지 않도록 자기 자신일 때만 해제
    if (identical(FcmEventBus.instance.onHelpRequestCreated, _onFcmHelpRequestCreated)) {
      FcmEventBus.instance.onHelpRequestCreated = null;
    }
    super.dispose();
  }
}

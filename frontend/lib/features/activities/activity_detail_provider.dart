// 활동 상세 페이지 상태 관리 (단건 조회)
import 'package:flutter/foundation.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/models/activity.dart';
import '../../core/services/activity_service.dart';

enum ActivityDetailStatus { loading, loaded, error }

class ActivityDetailProvider extends ChangeNotifier {
  ActivityDetailProvider({required this.activityId, required this._activityService}) {
    _load();
  }

  final String activityId;
  final ActivityService _activityService;

  bool _disposed = false;

  ActivityDetailStatus status = ActivityDetailStatus.loading;
  Activity? activity;
  String? errorMessage;

  Future<void> _load() async {
    status = ActivityDetailStatus.loading;
    errorMessage = null;
    _safeNotify();

    try {
      activity = await _activityService.fetchDetail(activityId);
      status = ActivityDetailStatus.loaded;
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = ActivityDetailStatus.error;
    } catch (_) {
      errorMessage = '알 수 없는 오류가 발생했습니다.';
      status = ActivityDetailStatus.error;
    }
    _safeNotify();
  }

  Future<void> retryLoad() => _load();

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

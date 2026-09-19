// 활동 내역 목록 상태 관리 (무한 스크롤, 반환 개수가 페이지 크기보다 적으면 마지막 페이지)
import 'package:flutter/foundation.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/models/activity.dart';
import '../../core/services/activity_service.dart';

class ActivitiesProvider extends ChangeNotifier {
  ActivitiesProvider({required this._activityService}) {
    _loadFirstPage();
  }

  static const int _pageSize = 20;

  final ActivityService _activityService;
  bool _disposed = false;
  int _nextPage = 0;

  List<Activity> activities = [];
  bool isLoading = false;
  String? error;

  bool isLoadingMore = false;
  String? loadMoreError;
  bool hasMore = true;

  Future<void> _loadFirstPage() async {
    isLoading = true;
    error = null;
    _nextPage = 0;
    hasMore = true;
    _safeNotify();

    try {
      final page = await _activityService.fetchMyActivities(page: 0, size: _pageSize);
      activities = page;
      hasMore = page.length >= _pageSize;
      _nextPage = 1;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = '알 수 없는 오류가 발생했습니다.';
    } finally {
      isLoading = false;
      _safeNotify();
    }
  }

  // 당겨서 새로고침, 초기 로드 실패 후 재시도에 사용
  Future<void> refresh() => _loadFirstPage();

  // 스크롤이 끝에 도달했을 때 호출 (중복, 마지막 페이지 이후 호출 방지)
  Future<void> loadMore() async {
    if (isLoadingMore || isLoading || !hasMore) return;

    isLoadingMore = true;
    loadMoreError = null;
    _safeNotify();

    try {
      final page = await _activityService.fetchMyActivities(page: _nextPage, size: _pageSize);
      activities = [...activities, ...page];
      hasMore = page.length >= _pageSize;
      _nextPage++;
    } on ApiException catch (e) {
      loadMoreError = e.message;
    } catch (_) {
      loadMoreError = '알 수 없는 오류가 발생했습니다.';
    } finally {
      isLoadingMore = false;
      _safeNotify();
    }
  }

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

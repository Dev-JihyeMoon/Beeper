// 알림 태그 편집 상태 관리 (전체/내 태그 병렬 조회, 로컬 검색, 최대 개수 제한, 저장)
import 'package:flutter/foundation.dart';

import '../../config/constants.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/models/tag.dart';
import '../../core/services/tag_service.dart';

enum TagEditStatus { loading, loaded, error }

class TagEditProvider extends ChangeNotifier {
  TagEditProvider({required this._tagService}) {
    _load();
  }

  final TagService _tagService;
  bool _disposed = false;

  TagEditStatus status = TagEditStatus.loading;
  String? loadError;

  List<Tag> allTags = [];
  Set<int> selectedIds = {};
  String searchQuery = '';

  bool isSaving = false;
  String? saveError;

  // 검색어로 로컬 필터링한 목록 (서버 재호출 없음)
  List<Tag> get filteredTags {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return allTags;
    return allTags.where((tag) => tag.name.toLowerCase().contains(query)).toList();
  }

  Future<void> _load() async {
    status = TagEditStatus.loading;
    loadError = null;
    _safeNotify();

    try {
      // 전체 태그와 내 태그를 병렬로 조회
      final results = await Future.wait([_tagService.fetchAllTags(), _tagService.fetchMyTags()]);
      allTags = results[0];
      selectedIds = results[1].map((tag) => tag.id).toSet();
      status = TagEditStatus.loaded;
    } on ApiException catch (e) {
      loadError = e.message;
      status = TagEditStatus.error;
    } catch (_) {
      loadError = '알 수 없는 오류가 발생했습니다.';
      status = TagEditStatus.error;
    }
    _safeNotify();
  }

  Future<void> retryLoad() => _load();

  void updateSearch(String value) {
    searchQuery = value;
    _safeNotify();
  }

  // 태그 탭 시 선택/해제 토글 (최대 개수 초과로 거부되면 false 반환)
  bool toggleTag(int tagId) {
    if (selectedIds.contains(tagId)) {
      selectedIds = {...selectedIds}..remove(tagId);
      _safeNotify();
      return true;
    }
    if (selectedIds.length >= BeeperConstants.maxSelectableTags) {
      return false;
    }
    selectedIds = {...selectedIds, tagId};
    _safeNotify();
    return true;
  }

  Future<bool> save() async {
    if (isSaving) return false;

    isSaving = true;
    saveError = null;
    _safeNotify();

    try {
      await _tagService.saveSelectedTags(selectedIds.toList());
      return true;
    } on ApiException catch (e) {
      saveError = e.message;
      return false;
    } catch (_) {
      saveError = '알 수 없는 오류가 발생했습니다.';
      return false;
    } finally {
      isSaving = false;
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

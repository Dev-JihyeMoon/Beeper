// 알림 태그 조회/저장 (대시보드 요약 카드, 태그 편집 페이지 공용)
import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../models/tag.dart';

class TagService {
  TagService({required this._apiClient});

  final ApiClient _apiClient;

  // GET /tag-select/all (선택 가능한 전체 태그)
  Future<List<Tag>> fetchAllTags() async {
    final response = await _apiClient.get<List<Tag>>(
      '/tag-select/all',
      fromData: (json) => _parseTags(json),
    );

    if (!response.isSuccess || response.data == null) {
      throw ServerFailureException(
        response.msg.isNotEmpty ? response.msg : '전체 태그를 불러오지 못했습니다.',
      );
    }
    return response.data!;
  }

  // GET /tag-select/me (내가 선택한 태그)
  Future<List<Tag>> fetchMyTags() async {
    final response = await _apiClient.get<List<Tag>>(
      '/tag-select/me',
      fromData: (json) => _parseTags(json),
    );

    if (!response.isSuccess || response.data == null) {
      throw ServerFailureException(
        response.msg.isNotEmpty ? response.msg : '알림 태그를 불러오지 못했습니다.',
      );
    }
    return response.data!;
  }

  // POST /tag-select/save/list (선택된 태그 ID로 통째로 치환 저장)
  Future<void> saveSelectedTags(List<int> tagIds) async {
    final response = await _apiClient.post(
      '/tag-select/save/list',
      data: tagIds.map((id) => {'id': id}).toList(),
    );

    if (!response.isSuccess) {
      throw ServerFailureException(
        response.msg.isNotEmpty ? response.msg : '알림 태그 저장에 실패했습니다.',
      );
    }
  }

  static List<Tag> _parseTags(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Tag.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}

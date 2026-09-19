// 활동 내역 조회 API 호출
import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../models/activity.dart';

class ActivityService {
  ActivityService({required this._apiClient});

  final ApiClient _apiClient;

  // GET /activities/me?page=&size=
  // 페이지 메타데이터가 없어 반환 개수가 size보다 적으면 마지막 페이지로 간주
  Future<List<Activity>> fetchMyActivities({required int page, required int size}) async {
    final response = await _apiClient.get<List<Activity>>(
      '/activities/me',
      queryParameters: {'page': page, 'size': size},
      fromData: (json) =>
          (json as List).map((e) => Activity.fromJson(e as Map<String, dynamic>)).toList(),
    );

    if (!response.isSuccess || response.data == null) {
      throw ServerFailureException(
        response.msg.isNotEmpty ? response.msg : '활동 내역을 불러오지 못했습니다.',
      );
    }
    return response.data!;
  }

  // GET /activities/{activityId}
  Future<Activity> fetchDetail(String activityId) async {
    final response = await _apiClient.get<Activity>(
      '/activities/$activityId',
      fromData: (json) => Activity.fromJson(json as Map<String, dynamic>),
    );

    if (!response.isSuccess || response.data == null) {
      throw ServerFailureException(
        response.msg.isNotEmpty ? response.msg : '활동 상세 정보를 불러오지 못했습니다.',
      );
    }
    return response.data!;
  }
}

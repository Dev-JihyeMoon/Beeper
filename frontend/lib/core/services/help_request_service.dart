// 도움 요청 생성/취소/목록/수락/완료 API 호출 (시니어, 봉사자 공용)
import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../models/help_request.dart';

class HelpRequestService {
  HelpRequestService({required this._apiClient});

  final ApiClient _apiClient;

  // POST /help-requests
  // [fcmToken]은 비로그인 시니어가 수락 알림을 받기 위한 토큰 (선택)
  // 로그인 사용자는 서버가 User에 등록된 토큰을 사용하므로 불필요
  Future<HelpRequest> create({
    required String title,
    required String description,
    required List<String> tags,
    required double latitude,
    required double longitude,
    String? fcmToken,
  }) async {
    final response = await _apiClient.post<HelpRequest>(
      '/help-requests',
      data: {
        'title': title,
        'description': description,
        'tags': tags,
        'latitude': latitude,
        'longitude': longitude,
        'fcmToken': fcmToken,
      },
      fromData: (json) => HelpRequest.fromJson(json as Map<String, dynamic>),
    );

    if (!response.isSuccess || response.data == null) {
      throw ServerFailureException(
        response.msg.isNotEmpty ? response.msg : '도움 요청 생성에 실패했습니다.',
      );
    }
    return response.data!;
  }

  // POST /help-requests/{id}/cancel
  Future<void> cancel(String requestId) async {
    final response = await _apiClient.post('/help-requests/$requestId/cancel');
    if (!response.isSuccess) {
      throw ServerFailureException(
        response.msg.isNotEmpty ? response.msg : '도움 요청 취소에 실패했습니다.',
      );
    }
  }

  // GET /help-requests?status=WAITING
  Future<List<HelpRequest>> listWaiting() async {
    final response = await _apiClient.get<List<HelpRequest>>(
      '/help-requests',
      queryParameters: const {'status': 'WAITING'},
      fromData: (json) => (json as List)
          .map((e) => HelpRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    if (!response.isSuccess || response.data == null) {
      throw ServerFailureException(
        response.msg.isNotEmpty ? response.msg : '대기 중인 요청 목록을 불러오지 못했습니다.',
      );
    }
    return response.data!;
  }

  // GET /help-requests/{id}
  Future<HelpRequest> detail(String requestId) async {
    final response = await _apiClient.get<HelpRequest>(
      '/help-requests/$requestId',
      fromData: (json) => HelpRequest.fromJson(json as Map<String, dynamic>),
    );

    if (!response.isSuccess || response.data == null) {
      throw ServerFailureException(
        response.msg.isNotEmpty ? response.msg : '요청 상세 정보를 불러오지 못했습니다.',
      );
    }
    return response.data!;
  }

  // POST /help-requests/{id}/accept
  Future<HelpRequestAcceptResult> accept(String requestId) async {
    final response = await _apiClient.post<HelpRequestAcceptResult>(
      '/help-requests/$requestId/accept',
      fromData: (json) => HelpRequestAcceptResult.fromJson(json as Map<String, dynamic>),
    );

    if (!response.isSuccess || response.data == null) {
      throw ServerFailureException(
        response.msg.isNotEmpty ? response.msg : '요청 수락에 실패했습니다.',
      );
    }
    return response.data!;
  }

  // POST /help-requests/{id}/complete
  // 통화 종료 시 호출해 요청을 완료 처리하고 활동 기록(Activity) 생성
  // 호출하지 않으면 요청이 계속 ACCEPTED 상태로 남음
  Future<void> complete(String requestId, {required int durationSeconds, String? summary}) async {
    final response = await _apiClient.post(
      '/help-requests/$requestId/complete',
      data: {'durationSeconds': durationSeconds, 'summary': summary},
    );

    if (!response.isSuccess) {
      throw ServerFailureException(
        response.msg.isNotEmpty ? response.msg : '통화 완료 처리에 실패했습니다.',
      );
    }
  }
}

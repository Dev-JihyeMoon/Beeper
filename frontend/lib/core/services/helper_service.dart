// 봉사자 활동 상태(활동 가능/중지) API 호출
import '../api/api_client.dart';
import '../api/api_exceptions.dart';

class HelperService {
  HelperService({required this._apiClient});

  final ApiClient _apiClient;

  // PUT /helpers/me/availability (서버가 확정한 값 반환, 낙관적 업데이트 롤백 판단용)
  Future<bool> updateAvailability(bool available) async {
    final response = await _apiClient.put<bool>(
      '/helpers/me/availability',
      data: {'available': available},
      fromData: (json) => (json as Map<String, dynamic>)['available'] as bool,
    );

    if (!response.isSuccess || response.data == null) {
      throw ServerFailureException(
        response.msg.isNotEmpty ? response.msg : '활동 상태 변경에 실패했습니다.',
      );
    }
    return response.data!;
  }
}

// 회원 프로필 조회/수정 API 호출
import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../models/user_profile.dart';

class UserService {
  UserService({required this._apiClient});

  final ApiClient _apiClient;

  // GET /user/{phoneNumber}
  Future<UserProfile> fetchProfile(String phoneNumber) async {
    final response = await _apiClient.get<UserProfile>(
      '/user/$phoneNumber',
      fromData: (json) => UserProfile.fromJson(json as Map<String, dynamic>),
    );

    if (!response.isSuccess || response.data == null) {
      throw ServerFailureException(
        response.msg.isNotEmpty ? response.msg : '프로필 정보를 불러오지 못했습니다.',
      );
    }
    return response.data!;
  }

  // PUT /users/me (닉네임, 전화번호, 생년월일, 비밀번호 전송)
  // [password]가 null이면 바디에서 제외해 기존 값 유지
  Future<UserProfile> updateProfile({
    required String nickname,
    required String phoneNumber,
    required DateTime birthday,
    String? password,
  }) async {
    final response = await _apiClient.put<UserProfile>(
      '/users/me',
      data: {
        'nickname': nickname,
        'phoneNumber': phoneNumber,
        'birthday': birthday.toUtc().toIso8601String(),
        'passwordKey': ?password,
      },
      fromData: (json) => UserProfile.fromJson(json as Map<String, dynamic>),
    );

    if (!response.isSuccess || response.data == null) {
      throw ServerFailureException(
        response.msg.isNotEmpty ? response.msg : '프로필 수정에 실패했습니다.',
      );
    }
    return response.data!;
  }
}

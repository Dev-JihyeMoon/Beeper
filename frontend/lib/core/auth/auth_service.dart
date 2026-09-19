// 로그인/회원가입 API 호출, 세션 저장/복원 서비스
import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../storage/secure_storage.dart';

// 로그인 성공 시 서버가 내려주는 데이터
class LoginResult {
  final String token;
  final int userId;
  final String userType;

  const LoginResult({
    required this.token,
    required this.userId,
    required this.userType,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final token = json['token']?.toString();
    final userId = json['userId'];
    final userType = json['userType']?.toString();
    if (token == null || userId == null || userType == null) {
      throw const ParsingException('로그인 응답 형식이 올바르지 않습니다.');
    }
    return LoginResult(
      token: token,
      userId: userId is int ? userId : int.parse(userId.toString()),
      userType: userType,
    );
  }
}

// 세션 정보 (앱 시작 시 저장소에서 복원)
class StoredSession {
  final String accessToken;
  final int userId;
  final String phoneNumber;
  final String userType;

  const StoredSession({
    required this.accessToken,
    required this.userId,
    required this.phoneNumber,
    required this.userType,
  });
}

class AuthService {
  AuthService({ApiClient? apiClient, BeeperSecureStorage? storage})
    : _apiClient = apiClient ?? ApiClient(),
      _storage = storage ?? BeeperSecureStorage();

  final ApiClient _apiClient;
  final BeeperSecureStorage _storage;

  // POST /auth/sign-in?id={phone}&password={pw}
  Future<LoginResult> login(String phoneNumber, String password) async {
    final response = await _apiClient.post<LoginResult>(
      '/auth/sign-in',
      queryParameters: {'id': phoneNumber, 'password': password},
      fromData: (json) => LoginResult.fromJson(json as Map<String, dynamic>),
    );

    if (!response.isSuccess || response.data == null) {
      throw ServerFailureException(response.msg.isNotEmpty ? response.msg : '로그인에 실패했습니다.');
    }

    final result = response.data!;
    await _storage.saveSession(
      accessToken: result.token,
      userId: result.userId,
      phoneNumber: phoneNumber,
      userType: result.userType,
    );
    return result;
  }

  // POST /auth/sign-up
  Future<void> signUp({
    required String nickname,
    required DateTime birthday,
    required String phoneNumber,
    required String password,
    required String userType,
  }) async {
    final response = await _apiClient.post(
      '/auth/sign-up',
      data: {
        'nickname': nickname,
        'birthday': birthday.toUtc().toIso8601String(),
        'phoneNumber': phoneNumber,
        'passwordKey': password,
        'userType': userType,
      },
    );

    if (!response.isSuccess) {
      throw ServerFailureException(response.msg.isNotEmpty ? response.msg : '회원가입에 실패했습니다.');
    }
  }

  // 저장된 세션 복원 (자동 로그인)
  Future<StoredSession?> restoreSession() async {
    final token = await _storage.read(SecureStorageKeys.accessToken);
    final userIdRaw = await _storage.read(SecureStorageKeys.userId);
    final phoneNumber = await _storage.read(SecureStorageKeys.phoneNumber);
    final userType = await _storage.read(SecureStorageKeys.userType);

    if (token == null || userIdRaw == null || phoneNumber == null || userType == null) {
      return null;
    }

    final userId = int.tryParse(userIdRaw);
    if (userId == null) return null;

    return StoredSession(
      accessToken: token,
      userId: userId,
      phoneNumber: phoneNumber,
      userType: userType,
    );
  }

  Future<void> clearSession() => _storage.clearSession();
}

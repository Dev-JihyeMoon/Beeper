// flutter_secure_storage 래퍼 (인증 토큰, 세션 정보의 유일한 저장 창구)
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 저장 키 이름 (한곳에서만 정의)
class SecureStorageKeys {
  SecureStorageKeys._();

  static const String accessToken = 'access_token';
  static const String userId = 'user_id';
  static const String phoneNumber = 'phone_number';
  static const String userType = 'user_type';
}

// 보안 저장소 래퍼 (인증 관련 값의 저장/조회/삭제 전담)
class BeeperSecureStorage {
  BeeperSecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> write(String key, String? value) async {
    if (value == null) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  // 로그인 세션 전체 저장
  // 반드시 순차 저장: 웹 구현은 최초 저장 시 암호화 키를 지연 생성하므로 동시 write 시 키가 꼬여 복호화가 영구 실패함
  Future<void> saveSession({
    required String accessToken,
    required int userId,
    required String phoneNumber,
    required String userType,
  }) async {
    await write(SecureStorageKeys.accessToken, accessToken);
    await write(SecureStorageKeys.userId, userId.toString());
    await write(SecureStorageKeys.phoneNumber, phoneNumber);
    await write(SecureStorageKeys.userType, userType);
  }

  // 세션 관련 저장값 모두 삭제 (로그아웃, 인증 실패 시)
  Future<void> clearSession() async {
    await Future.wait([
      delete(SecureStorageKeys.accessToken),
      delete(SecureStorageKeys.userId),
      delete(SecureStorageKeys.phoneNumber),
      delete(SecureStorageKeys.userType),
    ]);
  }

  Future<String?> get accessToken => read(SecureStorageKeys.accessToken);
}

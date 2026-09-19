// 프로필 조회/수정 상태 관리
import 'package:flutter/foundation.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/user_service.dart';

enum ProfileStatus { loading, loaded, error }

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required this._userService, required this._phoneNumber}) {
    _loadProfile(_phoneNumber);
  }

  final UserService _userService;
  String _phoneNumber;

  bool _disposed = false;

  ProfileStatus status = ProfileStatus.loading;
  UserProfile? profile;
  String? loadError;

  bool isUpdating = false;
  String? updateError;

  // 수정 후 전화번호가 바뀌었는지 여부
  // 바뀌면 JWT(전화번호 기준)가 무효화되므로 재로그인 필요
  bool phoneNumberChanged = false;

  Future<void> _loadProfile(String phoneNumber) async {
    status = ProfileStatus.loading;
    loadError = null;
    _safeNotify();

    try {
      final result = await _userService.fetchProfile(phoneNumber);
      profile = result;
      _phoneNumber = phoneNumber;
      status = ProfileStatus.loaded;
    } on ApiException catch (e) {
      loadError = e.message;
      status = ProfileStatus.error;
    } catch (_) {
      loadError = '프로필 정보를 불러올 수 없습니다.';
      status = ProfileStatus.error;
    }
    _safeNotify();
  }

  Future<void> retryLoad() => _loadProfile(_phoneNumber);

  // 수정 페이지 저장 버튼에서 호출 (성공 시 서버에서 최신 프로필 재조회)
  // [password]가 null이면 비밀번호는 변경하지 않음
  Future<bool> updateProfile({
    required String nickname,
    required String phoneNumber,
    required DateTime birthday,
    String? password,
  }) async {
    if (isUpdating) return false;

    isUpdating = true;
    updateError = null;
    _safeNotify();

    try {
      await _userService.updateProfile(
        nickname: nickname,
        phoneNumber: phoneNumber,
        birthday: birthday,
        password: password,
      );
      phoneNumberChanged = phoneNumber != _phoneNumber;
      await _loadProfile(phoneNumber);
      return true;
    } on ApiException catch (e) {
      updateError = e.message;
      return false;
    } catch (_) {
      updateError = '알 수 없는 오류가 발생했습니다.';
      return false;
    } finally {
      isUpdating = false;
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

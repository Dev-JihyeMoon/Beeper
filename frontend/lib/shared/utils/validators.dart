// 로그인/회원가입/프로필 폼 공용 입력값 검증
class BeeperValidators {
  BeeperValidators._();

  // 숫자만 10~11자리인지 확인 (통과 시 null, 실패 시 에러 메시지)
  static String? phoneNumber(String value) {
    if (value.isEmpty) return '전화번호를 입력해 주세요.';
    final digitsOnly = RegExp(r'^[0-9]+$').hasMatch(value);
    if (!digitsOnly) return '전화번호는 숫자만 입력해 주세요.';
    if (value.length < 10 || value.length > 11) {
      return '전화번호는 10~11자리로 입력해 주세요.';
    }
    return null;
  }

  static String? password(String value, {int minLength = 1}) {
    if (value.isEmpty) return '비밀번호를 입력해 주세요.';
    if (value.length < minLength) return '비밀번호는 $minLength자 이상이어야 합니다.';
    return null;
  }

  static String? nickname(String value, {int minLength = 2}) {
    if (value.isEmpty) return '닉네임을 입력해 주세요.';
    if (value.length < minLength) return '닉네임은 $minLength자 이상이어야 합니다.';
    return null;
  }

  // 생년월일이 유효한 날짜인지 확인
  static String? birthday(DateTime? value) {
    if (value == null) return '생년월일을 선택해 주세요.';
    if (value.isAfter(DateTime.now())) return '생년월일이 올바르지 않습니다.';
    return null;
  }
}

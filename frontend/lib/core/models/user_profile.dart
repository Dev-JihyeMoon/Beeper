// 회원 프로필 도메인 모델 (GET /user/{phoneNumber}, PUT /users/me 공통 응답)
class UserProfile {
  const UserProfile({
    required this.id,
    required this.nickname,
    required this.phoneNumber,
    this.birthday,
    this.point,
    this.userType,
  });

  final int id;
  final String nickname;
  final String phoneNumber;
  final DateTime? birthday;
  final int? point;

  // HELPER 또는 SENIOR (서버가 안 내려주면 null)
  final String? userType;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nickname = json['nickname']?.toString();
    final phoneNumber = json['phoneNumber']?.toString();

    final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '');
    if (parsedId == null || nickname == null || phoneNumber == null) {
      throw const FormatException('프로필 응답 형식이 올바르지 않습니다.');
    }

    final pointRaw = json['point'];

    // roles는 Spring Security 내부 권한 문자열이라 파싱하지 않음
    return UserProfile(
      id: parsedId,
      nickname: nickname,
      phoneNumber: phoneNumber,
      birthday: DateTime.tryParse(json['birthday']?.toString() ?? ''),
      point: pointRaw is int ? pointRaw : int.tryParse(pointRaw?.toString() ?? ''),
      userType: json['userType']?.toString(),
    );
  }
}

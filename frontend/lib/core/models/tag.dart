// 알림 태그 도메인 모델 (GET /tag-select/all, /tag-select/me 공통 응답)
class Tag {
  const Tag({required this.id, required this.name});

  final int id;
  final String name;

  factory Tag.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name']?.toString();
    final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '');

    if (parsedId == null || name == null) {
      throw const FormatException('태그 응답 형식이 올바르지 않습니다.');
    }
    return Tag(id: parsedId, name: name);
  }
}

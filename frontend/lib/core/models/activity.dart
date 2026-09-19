// 활동 내역 도메인 모델 (GET /activities/me, GET /activities/{id} 공통 응답)
// 주의: 백엔드 ActivityDTO.Info에는 description 필드가 없음
class Activity {
  const Activity({
    required this.id,
    required this.title,
    this.requestId,
    this.date,
    this.durationSeconds = 0,
    this.summary,
    this.seniorName,
    this.tags = const [],
  });

  final String id;
  final String? requestId;
  final DateTime? date;
  final int durationSeconds;
  final String title;
  final String? summary;

  // 서버가 채워준 경우에만 표시
  final String? seniorName;
  final List<String> tags;

  factory Activity.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final title = json['title']?.toString();

    if (id == null || title == null) {
      throw const FormatException('활동 내역 응답 형식이 올바르지 않습니다.');
    }

    final durationRaw = json['durationSeconds'];
    return Activity(
      id: id,
      title: title,
      requestId: json['requestId']?.toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
      durationSeconds: durationRaw is int
          ? durationRaw
          : int.tryParse(durationRaw?.toString() ?? '') ?? 0,
      summary: json['summary']?.toString(),
      seniorName: json['seniorName']?.toString(),
      tags: _parseTags(json['tags']),
    );
  }

  static List<String> _parseTags(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e is String ? e : (e is Map ? e['name']?.toString() : null))
        .whereType<String>()
        .toList();
  }
}

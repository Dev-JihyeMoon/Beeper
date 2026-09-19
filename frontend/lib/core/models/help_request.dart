// 도움 요청 도메인 모델 (생성/목록/상세/취소 응답 공통)
class HelpRequest {
  const HelpRequest({
    required this.id,
    required this.roomId,
    required this.title,
    required this.description,
    required this.status,
    this.createdAt,
    this.tags = const [],
    this.requesterNickname,
  });

  final String id;
  final String roomId;
  final String title;
  final String description;
  final String status;
  final DateTime? createdAt;
  final List<String> tags;

  // 서버가 채워준 경우에만 표시
  final String? requesterNickname;

  factory HelpRequest.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final roomId = json['roomId']?.toString();
    final title = json['title']?.toString();
    final description = json['description']?.toString();
    final status = json['status']?.toString();

    if (id == null || roomId == null || title == null || description == null || status == null) {
      throw const FormatException('도움 요청 응답 형식이 올바르지 않습니다.');
    }

    return HelpRequest(
      id: id,
      roomId: roomId,
      title: title,
      description: description,
      status: status,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      tags: _parseTags(json['tags']),
      requesterNickname: json['requesterNickname']?.toString(),
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

// POST /help-requests/{id}/accept 응답 (title/description 없음)
class HelpRequestAcceptResult {
  const HelpRequestAcceptResult({
    required this.id,
    required this.roomId,
    required this.status,
    this.helperId,
  });

  final String id;
  final String roomId;
  final String status;
  final int? helperId;

  factory HelpRequestAcceptResult.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final roomId = json['roomId']?.toString();
    final status = json['status']?.toString();

    if (id == null || roomId == null || status == null) {
      throw const FormatException('도움 요청 수락 응답 형식이 올바르지 않습니다.');
    }

    final helperId = json['helperId'];
    return HelpRequestAcceptResult(
      id: id,
      roomId: roomId,
      status: status,
      helperId: helperId is int ? helperId : int.tryParse(helperId?.toString() ?? ''),
    );
  }
}

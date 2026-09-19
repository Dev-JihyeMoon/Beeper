// 음성 인식 텍스트를 도움 요청 구조(title/description/tags)로 변환하는 서비스 인터페이스
// TODO: 분석 API 제공 시 ApiAnalysisService 구현 후 app.dart의 Provider 교체
abstract class AnalysisService {
  Future<AnalysisResult> analyze(String rawText);
}

// 분석 결과 (도움 요청 생성 API에 그대로 전달)
class AnalysisResult {
  const AnalysisResult({
    required this.title,
    required this.description,
    required this.tags,
    required this.isPassthrough,
  });

  final String title;
  final String description;
  final List<String> tags;

  // true면 분석 없이 음성 인식 원문을 그대로 사용한 결과
  // 확인 화면에서 사용자에게 안내하는 데 사용
  final bool isPassthrough;
}

// 현재 구현: 분석 API가 없어 원문을 description에 담고 title은 "도움 요청"으로 고정
class PassthroughAnalysisService implements AnalysisService {
  @override
  Future<AnalysisResult> analyze(String rawText) async {
    return AnalysisResult(
      title: '도움 요청',
      description: rawText,
      tags: const [],
      isPassthrough: true,
    );
  }
}

// speech_to_text 래핑 음성 인식 서비스 (한국어 ko_KR, 권한/미지원 오류 구분)
import 'package:speech_to_text/speech_to_text.dart' as stt;

// 마이크 권한 거부, 미지원 기기, 인식 실패 등을 전달하는 예외
class SpeechRecognitionException implements Exception {
  const SpeechRecognitionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  void Function(String message)? _onError;

  bool get isListening => _isListening;

  // 초기화 + 마이크 권한 요청 (실패 시 SpeechRecognitionException)
  // 이미 초기화됐으면 아무 동작 없음
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 초기화 시점 오류도 이 콜백으로 오므로 코드로 원인 구분
    String? initErrorCode;
    final available = await _speech.initialize(
      onError: (error) {
        initErrorCode ??= error.errorMsg;
        _handleRuntimeError(error.errorMsg);
      },
      onStatus: _handleStatus,
    );

    if (!available) {
      final isPermissionIssue = (initErrorCode ?? '').contains('permission');
      throw SpeechRecognitionException(
        isPermissionIssue
            ? '마이크 사용 권한이 필요합니다. 설정에서 허용해주세요.'
            : '이 기기에서는 음성 입력을 사용할 수 없습니다.',
      );
    }
    _isInitialized = true;
  }

  void _handleStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  void _handleRuntimeError(String errorCode) {
    _isListening = false;
    _onError?.call('음성을 인식하지 못했습니다. 다시 시도해주세요.');
  }

  // 음성 인식 시작 ([onResult]는 중간 결과마다, 최종 결과는 isFinal=true)
  Future<void> startListening({
    required void Function(String recognizedText, bool isFinal) onResult,
    required void Function(String message) onError,
  }) async {
    _onError = onError;

    try {
      await initialize();
    } on SpeechRecognitionException catch (e) {
      onError(e.message);
      return;
    }

    if (_isListening) return; // 중복 시작 방지

    _isListening = true;
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: 'ko_KR',
        partialResults: true,
      ),
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
        if (result.finalResult) _isListening = false;
      },
    );
  }

  // 사용자가 중지 버튼을 눌렀을 때 호출 (인식된 텍스트는 유지)
  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    _isListening = false;
  }

  // 화면 이탈 시 호출 (인식 중지, 콜백 참조 해제)
  void dispose() {
    _onError = null;
    if (_speech.isListening) {
      _speech.stop();
    }
    _isListening = false;
  }
}

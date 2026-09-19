// 도움 요청 메인 페이지 상태 머신 (idle > listening > processing > confirmation > submitting > submitted)
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../config/constants.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/models/help_request.dart';
import '../../core/services/analysis_service.dart';
import '../../core/services/fcm_service.dart';
import '../../core/services/help_request_service.dart';
import '../../core/services/speech_service.dart';

enum SeniorMainStatus {
  idle,
  listening,
  processing,
  confirmation,
  submitting,
  submitted,
  error,
}

class SeniorMainProvider extends ChangeNotifier {
  SeniorMainProvider({
    required this._speechService,
    required this._analysisService,
    required this._helpRequestService,
    required this._fcmService,
  }) {
    // 웹은 서비스 워커 등록이 늦어 제출 시점에 처음 토큰을 요청하면 실패할 수 있음
    // 화면 진입 시 미리 한 번 요청해 둠 (실패해도 submitRequest()에서 재시도하므로 무해)
    unawaited(_fcmService.requestPermission());
  }

  final SpeechService _speechService;
  final AnalysisService _analysisService;
  final HelpRequestService _helpRequestService;

  // 시니어는 로그인을 안 하므로 사용자 단위로 FCM 토큰을 등록할 수 없음
  // 요청 생성 시 기기 토큰을 본문에 함께 보내 서버가 수락 알림을 직접 보내게 함
  final FcmService _fcmService;

  SeniorMainStatus _status = SeniorMainStatus.idle;
  String _recognizedText = '';
  AnalysisResult? _analysisResult;
  String? _errorMessage;
  HelpRequest? _createdRequest;
  bool _disposed = false;

  SeniorMainStatus get status => _status;
  String get recognizedText => _recognizedText;
  AnalysisResult? get analysisResult => _analysisResult;
  String? get errorMessage => _errorMessage;
  HelpRequest? get createdRequest => _createdRequest;

  // idle 상태에서 음성 버튼을 눌렀을 때 호출
  Future<void> startListening() async {
    if (_status == SeniorMainStatus.listening) return; // 중복 시작 방지

    _recognizedText = '';
    _errorMessage = null;
    _status = SeniorMainStatus.listening;
    _safeNotify();

    await _speechService.startListening(
      onResult: (text, isFinal) {
        _recognizedText = text;
        _safeNotify();
        if (isFinal) _processRecognizedText();
      },
      onError: (message) {
        _status = SeniorMainStatus.error;
        _errorMessage = message;
        _safeNotify();
      },
    );
  }

  // listening 중 중지 버튼을 눌렀을 때 호출
  Future<void> stopListeningManually() async {
    if (_status != SeniorMainStatus.listening) return;
    await _speechService.stopListening();
    await _processRecognizedText();
  }

  Future<void> _processRecognizedText() async {
    if (_status != SeniorMainStatus.listening) return; // 자동 종료 + 수동 중지 중복 호출 방지

    final text = _recognizedText.trim();
    if (text.isEmpty) {
      _status = SeniorMainStatus.error;
      _errorMessage = '음성을 인식하지 못했습니다. 다시 시도해주세요.';
      _safeNotify();
      return;
    }

    _status = SeniorMainStatus.processing;
    _safeNotify();

    try {
      _analysisResult = await _analysisService.analyze(text);
      _status = SeniorMainStatus.confirmation;
    } catch (_) {
      _status = SeniorMainStatus.error;
      _errorMessage = '요청 내용을 정리하는 중 문제가 발생했습니다.';
    }
    _safeNotify();
  }

  // confirmation 화면의 "다시 말하기" (idle로 복귀)
  void reset() {
    _status = SeniorMainStatus.idle;
    _recognizedText = '';
    _analysisResult = null;
    _errorMessage = null;
    _safeNotify();
  }

  // confirmation 화면에서 사용자가 직접 수정한 내용 반영 (태그는 유지)
  void updateRequestContent({required String title, required String description}) {
    final result = _analysisResult;
    if (_status != SeniorMainStatus.confirmation || result == null) return;

    _analysisResult = AnalysisResult(
      title: title.trim(),
      description: description.trim(),
      tags: result.tags,
      isPassthrough: false,
    );
    _safeNotify();
  }

  // confirmation 화면의 "이대로 요청" (도움 요청 생성 API 호출)
  Future<void> submitRequest() async {
    final result = _analysisResult;
    if (_status != SeniorMainStatus.confirmation || result == null) return;

    _status = SeniorMainStatus.submitting;
    _errorMessage = null;
    _safeNotify();

    try {
      // Firebase 미설정, 권한 거부 시 토큰은 null이며 서버는 알림 없이 요청만 처리함 (예외 없음)
      final fcmToken = await _obtainFcmToken();

      _createdRequest = await _helpRequestService.create(
        title: result.title,
        description: result.description,
        tags: result.tags,
        latitude: BeeperConstants.defaultLatitude,
        longitude: BeeperConstants.defaultLongitude,
        fcmToken: fcmToken,
      );
      _status = SeniorMainStatus.submitted;
    } on ApiException catch (e) {
      _status = SeniorMainStatus.error;
      _errorMessage = e.message;
    } catch (_) {
      _status = SeniorMainStatus.error;
      _errorMessage = '알 수 없는 오류가 발생했습니다.';
    }
    _safeNotify();
  }

  // 알림 권한 요청 후 FCM 토큰 조회
  // 웹은 첫 시도에 null일 수 있어 한 번 더 시도하고, 그래도 실패하면 알림 없이 요청 진행
  Future<String?> _obtainFcmToken() async {
    final granted = await _fcmService.requestPermission();
    if (!granted) {
      debugPrint('[SeniorMainProvider] FCM 권한이 거부되어 토큰을 요청하지 않습니다.');
      return null;
    }

    var token = await _fcmService.getToken();
    if (token == null) {
      debugPrint('[SeniorMainProvider] 첫 토큰 조회 실패 — 1초 후 재시도합니다.');
      await Future.delayed(const Duration(seconds: 1));
      token = await _fcmService.getToken();
    }

    debugPrint(
      token == null
          ? '[SeniorMainProvider] FCM 토큰 발급 최종 실패 — 알림 없이 요청을 진행합니다.'
          : '[SeniorMainProvider] FCM 토큰 발급 성공',
    );
    return token;
  }

  // error 상태에서 재시도 (idle로 복귀)
  void retry() => reset();

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _speechService.dispose();
    super.dispose();
  }
}

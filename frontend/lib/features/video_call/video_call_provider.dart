// 영상통화 화면 공용 상태 관리 (signaling + WebRTC 연결, 통화 시간, 컨트롤 토글)
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../../core/services/help_request_service.dart';
import '../../core/services/signaling_service.dart';
import '../../core/services/webrtc_service.dart';

// 먼저 입장하는 쪽(caller)이 offer, 나중에 입장하는 쪽(callee)이 answer 생성
// 참가자 순서를 알려주는 메시지가 없어 역할은 진입 경로로 고정
// 봉사자는 수락 직후 진입하므로 caller, 시니어는 수락 알림 후 진입하므로 callee
enum VideoCallRole { caller, callee }

enum VideoCallStatus { connecting, connected, disconnected, ended, failed }

class VideoCallProvider extends ChangeNotifier {
  VideoCallProvider({
    required this.role,
    WebRTCService? webrtcService,
    SignalingService? signalingService,
    this.requestId,
    this._helpRequestService,
  }) : _webrtcService = webrtcService ?? WebRTCService(),
       _signalingService = signalingService ?? SignalingService();

  final VideoCallRole role;
  final WebRTCService _webrtcService;
  final SignalingService _signalingService;

  // 통화 종료 시 complete API 호출용 도움 요청 ID
  // [_helpRequestService]와 함께 주어질 때만(봉사자 화면) 완료 처리 시도
  // 양쪽 모두 호출하면 활동 기록이 중복되므로 한쪽에서만 담당
  final String? requestId;
  final HelpRequestService? _helpRequestService;

  final rtc.RTCVideoRenderer localRenderer = rtc.RTCVideoRenderer();
  final rtc.RTCVideoRenderer remoteRenderer = rtc.RTCVideoRenderer();

  VideoCallStatus status = VideoCallStatus.connecting;
  bool isMuted = false;
  bool isCameraOff = false;
  String? errorMessage;
  Duration callDuration = Duration.zero;

  // 상대방이 통화를 종료(bye 수신)했는지 (안내 문구 구분용)
  bool endedByRemote = false;

  String? _roomId;
  StreamSubscription<SignalingMessage>? _messageSub;
  StreamSubscription<String>? _errorSub;
  Timer? _callTimer;
  Timer? _offerRetryTimer;
  bool _answerReceived = false;
  bool _disposed = false;
  bool _cleanedUp = false;
  bool _renderersInitialized = false;

  Future<void> initializeCall(String roomId) async {
    _roomId = roomId;
    status = VideoCallStatus.connecting;
    errorMessage = null;
    _safeNotify();

    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
      _renderersInitialized = true;

      final localStream = await _webrtcService.initialize();
      localRenderer.srcObject = localStream;
      _safeNotify();

      _webrtcService.onRemoteStream = (stream) {
        remoteRenderer.srcObject = stream;
        _safeNotify();
      };
      _webrtcService.onIceCandidate = (candidate) {
        final currentRoomId = _roomId;
        if (currentRoomId == null) return;
        _signalingService.sendCandidate(currentRoomId, {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      };
      _webrtcService.onConnectionStateChange = _handleConnectionStateChange;

      await _webrtcService.createPeerConnection();
      await _webrtcService.addLocalStream();

      _messageSub = _signalingService.onMessage.listen(_handleSignalingMessage);
      _errorSub = _signalingService.onError.listen(_handleSignalingError);

      await _signalingService.connect(roomId);

      // 서버는 메시지를 보낸 클라이언트만 방에 등록하므로,
      // 연결 직후 역할과 무관하게 join을 보내 방에 등록 (callee가 offer를 받을 수 있게 함)
      _signalingService.sendJoin(roomId);

      if (role == VideoCallRole.caller) {
        final offer = await _webrtcService.createOffer();
        _signalingService.sendOffer(roomId, offer);
        // 시니어가 더 늦게 접속하므로 offer가 먼저 도착하면 서버가 버림
        // answer를 받을 때까지 주기적으로 다시 전송
        _startOfferRetry(roomId, offer);
      }
    } on WebRTCConnectionException catch (e) {
      status = VideoCallStatus.failed;
      errorMessage = e.message;
    } catch (_) {
      status = VideoCallStatus.failed;
      errorMessage = '영상 연결을 시작하지 못했습니다.';
    }
    _safeNotify();
  }

  Future<void> _handleSignalingMessage(SignalingMessage message) async {
    switch (message.type) {
      case SignalingMessageType.offer:
        if (role != VideoCallRole.callee) return; // 잘못된 역할로 온 offer는 무시
        final answer = await _webrtcService.createAnswer(message.data);
        final roomId = _roomId;
        if (roomId != null) {
          _signalingService.sendAnswer(roomId, answer);
        }
        break;
      case SignalingMessageType.answer:
        if (role != VideoCallRole.caller) return;
        _answerReceived = true;
        _offerRetryTimer?.cancel();
        await _webrtcService.setRemoteDescription(message.data);
        break;
      case SignalingMessageType.candidate:
        await _webrtcService.addIceCandidate(message.data);
        break;
      case SignalingMessageType.bye:
        endedByRemote = true;
        status = VideoCallStatus.ended;
        _stopTimer();
        _safeNotify();
        await _cleanup();
        break;
      case SignalingMessageType.join:
        break; // 상대방 접속 알림일 뿐 별도 처리 없음
    }
  }

  // answer를 받을 때까지 최대 10회, 2초 간격으로 같은 offer 재전송
  // 이미 만든 SDP를 재전송할 뿐 새로 협상하지 않아 여러 번 받아도 안전
  void _startOfferRetry(String roomId, Map<String, dynamic> offer) {
    var attempts = 0;
    _offerRetryTimer?.cancel();
    _offerRetryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      attempts++;
      if (_answerReceived || _disposed || _cleanedUp) {
        timer.cancel();
        return;
      }
      if (attempts > 10) {
        timer.cancel();
        if (status == VideoCallStatus.connecting) {
          status = VideoCallStatus.failed;
          errorMessage = '상대방과 연결할 수 없습니다. 네트워크 상태를 확인하고 다시 시도해 주세요.';
          _safeNotify();
        }
        return;
      }
      _signalingService.sendOffer(roomId, offer);
    });
  }

  void _handleSignalingError(String message) {
    // P2P 연결 후에는 시그널링 재연결 실패가 통화를 끊지 않으므로 상태는 유지하고 안내 문구만 노출
    errorMessage = message;
    if (status == VideoCallStatus.connecting) {
      status = VideoCallStatus.failed;
    }
    _safeNotify();
  }

  void _handleConnectionStateChange(rtc.RTCPeerConnectionState state) {
    switch (state) {
      case rtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        if (status != VideoCallStatus.connected) {
          status = VideoCallStatus.connected;
          _startTimer();
        }
        break;
      case rtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case rtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed:
      case rtc.RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        if (status != VideoCallStatus.ended) {
          status = VideoCallStatus.disconnected;
          _stopTimer();
        }
        break;
      default:
        break;
    }
    _safeNotify();
  }

  void _startTimer() {
    _callTimer?.cancel();
    callDuration = Duration.zero;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDuration += const Duration(seconds: 1);
      _safeNotify();
    });
  }

  void _stopTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  void toggleMute() {
    isMuted = !_webrtcService.toggleMute();
    _safeNotify();
  }

  void toggleCamera() {
    isCameraOff = !_webrtcService.toggleCamera();
    _safeNotify();
  }

  // 전면/후면 카메라 전환 (시니어 화면 전용)
  Future<void> switchCamera() => _webrtcService.switchCamera();

  // 사용자가 통화 종료 버튼을 눌렀을 때 호출
  Future<void> endCall() async {
    final roomId = _roomId;
    if (roomId != null) {
      _signalingService.sendBye(roomId);
    }
    status = VideoCallStatus.ended;
    _safeNotify();
    await _cleanup();
  }

  Future<void> _cleanup() async {
    if (_cleanedUp) return;
    _cleanedUp = true;

    final duration = callDuration;
    _stopTimer();
    _offerRetryTimer?.cancel();
    _offerRetryTimer = null;
    await _messageSub?.cancel();
    await _errorSub?.cancel();
    _messageSub = null;
    _errorSub = null;

    await _webrtcService.dispose();
    await _signalingService.dispose();

    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;

    await _notifyCompletion(duration);
  }

  // 통화 종료 경로와 무관하게 한 번 호출되어 요청이 ACCEPTED에 머물지 않게 함
  // 실패해도 통화가 끝난 뒤라 에러 표시 없이 로그만 남김
  Future<void> _notifyCompletion(Duration duration) async {
    final service = _helpRequestService;
    final id = requestId;
    if (service == null || id == null) return;

    try {
      await service.complete(id, durationSeconds: duration.inSeconds);
    } catch (e) {
      debugPrint('[VideoCallProvider] 통화 완료 처리 실패 (requestId: $id): $e');
    }
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cleanup();
    if (_renderersInitialized) {
      localRenderer.dispose();
      remoteRenderer.dispose();
    }
    super.dispose();
  }
}

// flutter_webrtc 기반 P2P 영상/음성 통화 서비스
// 시그널링은 다루지 않고 미디어/PeerConnection 생성, SDP/ICE 처리만 담당
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

// 카메라/마이크 권한 거부, PeerConnection 생성 실패 등 WebRTC 오류
class WebRTCConnectionException implements Exception {
  const WebRTCConnectionException([this.message = '영상 연결에 실패했습니다.']);

  final String message;

  @override
  String toString() => message;
}

class WebRTCService {
  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      // TODO: TURN 서버 도입 시 secrets.dart에서 credential을 읽어 추가
    ],
  };

  static const Map<String, dynamic> _mediaConstraints = {
    'audio': true,
    'video': {'facingMode': 'user'},
  };

  rtc.MediaStream? _localStream;
  rtc.RTCPeerConnection? _peerConnection;

  bool _audioEnabled = true;
  bool _videoEnabled = true;

  rtc.MediaStream? get localStream => _localStream;

  // 원격 스트림 수신 시 호출
  void Function(rtc.MediaStream stream)? onRemoteStream;

  // 로컬 ICE candidate 생성 시 호출 (시그널링 서버로 전송 필요)
  void Function(rtc.RTCIceCandidate candidate)? onIceCandidate;

  // PeerConnection 연결 상태 변경 시 호출
  void Function(rtc.RTCPeerConnectionState state)? onConnectionStateChange;

  // 카메라/마이크 권한 요청 후 로컬 스트림 생성
  Future<rtc.MediaStream> initialize() async {
    try {
      final stream = await rtc.navigator.mediaDevices.getUserMedia(_mediaConstraints);
      _localStream = stream;
      return stream;
    } catch (e) {
      // 원인을 항상 "권한 필요"로 뭉뚱그리지 않음 (카메라 사용 중, 장치 없음 등도 흔함)
      // 콘솔에는 원본 예외를 남김
      debugPrint('[WebRTCService] getUserMedia 실패: $e');
      throw WebRTCConnectionException(_describeMediaError(e));
    }
  }

  String _describeMediaError(Object error) {
    final message = error.toString();
    if (message.contains('NotAllowedError') ||
        message.contains('PermissionDenied') ||
        message.contains('Permission denied')) {
      return '카메라와 마이크 권한이 필요합니다. 브라우저 주소창의 권한 아이콘 또는 기기 설정에서 '
          '허용되어 있는지 확인해 주세요.';
    }
    if (message.contains('NotFoundError') || message.contains('DevicesNotFound')) {
      return '카메라 또는 마이크 장치를 찾을 수 없습니다.';
    }
    if (message.contains('NotReadableError') || message.contains('TrackStartError')) {
      return '카메라 또는 마이크가 다른 프로그램(다른 탭 포함)에서 사용 중입니다. 종료 후 다시 시도해 주세요.';
    }
    if (message.contains('OverconstrainedError')) {
      return '이 기기가 지원하지 않는 카메라 설정을 요청했습니다.';
    }
    return '카메라/마이크를 시작하지 못했습니다. ($message)';
  }

  Future<rtc.RTCPeerConnection> createPeerConnection() async {
    final rtc.RTCPeerConnection pc;
    try {
      pc = await rtc.createPeerConnection(_iceServers);
    } catch (e) {
      debugPrint('[WebRTCService] createPeerConnection 실패: $e');
      throw const WebRTCConnectionException();
    }

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        onRemoteStream?.call(event.streams.first);
      }
    };
    pc.onIceCandidate = (candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
      onIceCandidate?.call(candidate);
    };
    pc.onConnectionState = (state) => onConnectionStateChange?.call(state);

    _peerConnection = pc;
    return pc;
  }

  // 로컬 스트림의 모든 트랙을 PeerConnection에 추가
  Future<void> addLocalStream() async {
    final stream = _localStream;
    final pc = _peerConnection;
    if (stream == null || pc == null) return;
    for (final track in stream.getTracks()) {
      await pc.addTrack(track, stream);
    }
  }

  // Caller가 호출: offer SDP 생성 후 로컬에 설정하고 반환
  Future<Map<String, dynamic>> createOffer() async {
    final pc = _peerConnection;
    if (pc == null) throw const WebRTCConnectionException();
    final description = await pc.createOffer();
    await pc.setLocalDescription(description);
    return {'sdp': description.sdp, 'type': description.type};
  }

  // Callee가 호출: 상대 offer를 원격에 설정 후 answer SDP 생성해 반환
  Future<Map<String, dynamic>> createAnswer(Map<String, dynamic> remoteSdp) async {
    final pc = _peerConnection;
    if (pc == null) throw const WebRTCConnectionException();
    await setRemoteDescription(remoteSdp);
    final description = await pc.createAnswer();
    await pc.setLocalDescription(description);
    return {'sdp': description.sdp, 'type': description.type};
  }

  Future<void> setRemoteDescription(Map<String, dynamic> sdp) async {
    final pc = _peerConnection;
    if (pc == null) return;
    await pc.setRemoteDescription(
      rtc.RTCSessionDescription(sdp['sdp'] as String?, sdp['type'] as String?),
    );
  }

  Future<void> addIceCandidate(Map<String, dynamic> candidate) async {
    final pc = _peerConnection;
    if (pc == null) return;
    await pc.addCandidate(
      rtc.RTCIceCandidate(
        candidate['candidate'] as String?,
        candidate['sdpMid'] as String?,
        candidate['sdpMLineIndex'] as int?,
      ),
    );
  }

  // 오디오 트랙 enabled 토글 후 값 반환 (음소거 해제=true)
  bool toggleMute() {
    final stream = _localStream;
    if (stream == null) return _audioEnabled;
    _audioEnabled = !_audioEnabled;
    for (final track in stream.getAudioTracks()) {
      track.enabled = _audioEnabled;
    }
    return _audioEnabled;
  }

  // 비디오 트랙 enabled 토글 후 값 반환 (카메라 켜짐=true)
  bool toggleCamera() {
    final stream = _localStream;
    if (stream == null) return _videoEnabled;
    _videoEnabled = !_videoEnabled;
    for (final track in stream.getVideoTracks()) {
      track.enabled = _videoEnabled;
    }
    return _videoEnabled;
  }

  // 전면/후면 카메라 전환 (시니어 전용)
  // 웹은 deviceId 없이 전환하면 예외가 나므로 미지원 기기에서는 조용히 실패 처리
  Future<void> switchCamera() async {
    final stream = _localStream;
    if (stream == null) return;
    final videoTracks = stream.getVideoTracks();
    if (videoTracks.isEmpty) return;
    try {
      await rtc.Helper.switchCamera(videoTracks.first);
    } catch (e) {
      debugPrint('[WebRTCService] switchCamera 실패(이 기기/플랫폼은 카메라 전환을 지원하지 않을 수 있음): $e');
    }
  }

  // MediaStream, PeerConnection 등 네이티브 리소스 해제
  Future<void> dispose() async {
    final pc = _peerConnection;
    _peerConnection = null;
    onRemoteStream = null;
    onIceCandidate = null;
    onConnectionStateChange = null;

    final stream = _localStream;
    _localStream = null;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
    }

    if (pc != null) {
      await pc.close();
      await pc.dispose();
    }
  }
}

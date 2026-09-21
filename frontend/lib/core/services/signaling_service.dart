// WebRTC 시그널링 WebSocket 통신 (offer/answer/candidate/bye 송수신)
import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../config/constants.dart';

// join은 프론트 자체 확장 메시지 (백엔드 계약 문서에는 없음)
// 서버는 메시지를 보낸 클라이언트만 방에 등록하므로, callee가 등록되지 않으면 offer가 유실됨
// join은 연결 직후 내용 없이 보내 방에 등록만 시키는 용도 (받는 쪽은 무시)
enum SignalingMessageType { offer, answer, candidate, bye, join }

// 시그널링 서버와 주고받는 메시지 { type, roomId, data }
class SignalingMessage {
  const SignalingMessage({
    required this.type,
    required this.roomId,
    required this.data,
  });

  final SignalingMessageType type;
  final String roomId;
  final Map<String, dynamic> data;

  static SignalingMessage? tryParse(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;

      final type = _typeFromString(json['type']?.toString());
      final roomId = json['roomId']?.toString();
      final data = json['data'];
      if (type == null || roomId == null || data is! Map) return null;

      return SignalingMessage(
        type: type,
        roomId: roomId,
        data: Map<String, dynamic>.from(data),
      );
    } catch (_) {
      // 형식이 어긋난 메시지는 무시 (통화를 중단시키지 않음)
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'roomId': roomId,
    'data': data,
  };

  static SignalingMessageType? _typeFromString(String? value) {
    for (final type in SignalingMessageType.values) {
      if (type.name == value) return type;
    }
    return null;
  }
}

// 시그널링 연결 최종 실패(재연결 3회 소진) 시 발생하는 에러
class SignalingConnectionException implements Exception {
  const SignalingConnectionException([
    this.message = '시그널링 서버에 연결할 수 없습니다.',
  ]);

  final String message;

  @override
  String toString() => message;
}

// roomId 기준 WebSocket 클라이언트 (끊기면 2초 간격 최대 3회 재연결)
class SignalingService {
  SignalingService({String? signalingUrl})
    : _signalingUrl = signalingUrl ?? BeeperConstants.signalingUrl;

  final String _signalingUrl;

  static const int _maxReconnectAttempts = 3;
  static const Duration _reconnectDelay = Duration(seconds: 2);

  final _messageController = StreamController<SignalingMessage>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  String? _roomId;
  int _reconnectAttempts = 0;
  bool _manuallyClosed = false;
  bool _disposed = false;

  // roomId가 일치하는 수신 메시지만 전달하는 스트림
  Stream<SignalingMessage> get onMessage => _messageController.stream;

  // 사용자에게 노출할 에러 메시지 스트림
  Stream<String> get onError => _errorController.stream;

  bool get isConnected => _channel != null;

  // WebSocket 연결 후 이 roomId로 메시지 송수신 시작
  Future<void> connect(String roomId) async {
    _roomId = roomId;
    _manuallyClosed = false;
    _reconnectAttempts = 0;
    await _connectInternal();
  }

  Future<void> _connectInternal() async {
    if (_disposed || _manuallyClosed) return;
    try {
      final channel = WebSocketChannel.connect(Uri.parse(_signalingUrl));
      await channel.ready;
      if (_disposed || _manuallyClosed) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      _subscription = channel.stream.listen(
        _handleRawMessage,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
        cancelOnError: true,
      );
      _reconnectAttempts = 0;
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleRawMessage(dynamic raw) {
    if (_disposed || raw is! String) return;
    final message = SignalingMessage.tryParse(raw);
    if (message == null) return;
    // 다른 roomId로 온 메시지는 무시
    if (message.roomId != _roomId) return;
    _messageController.add(message);
  }

  void _handleDisconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    if (_disposed || _manuallyClosed) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _errorController.add(const SignalingConnectionException().message);
      return;
    }
    _reconnectAttempts++;
    Future.delayed(_reconnectDelay, _connectInternal);
  }

  void _send(SignalingMessageType type, String roomId, Map<String, dynamic> data) {
    final channel = _channel;
    if (channel == null) return; // 연결이 없으면 드롭 (재연결 후 다음 메시지부터 정상)
    channel.sink.add(
      jsonEncode(SignalingMessage(type: type, roomId: roomId, data: data).toJson()),
    );
  }

  void sendOffer(String roomId, Map<String, dynamic> sdp) =>
      _send(SignalingMessageType.offer, roomId, sdp);

  void sendAnswer(String roomId, Map<String, dynamic> sdp) =>
      _send(SignalingMessageType.answer, roomId, sdp);

  void sendCandidate(String roomId, Map<String, dynamic> candidate) =>
      _send(SignalingMessageType.candidate, roomId, candidate);

  void sendBye(String roomId) => _send(SignalingMessageType.bye, roomId, const {});

  // 연결 직후 방에 자신을 등록시키는 내용 없는 메시지
  void sendJoin(String roomId) => _send(SignalingMessageType.join, roomId, const {});

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _manuallyClosed = true;
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    await _messageController.close();
    await _errorController.close();
  }
}

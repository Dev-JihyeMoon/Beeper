// 연결 상태 텍스트 + 통화 경과 시간(MM:SS) 캡슐형 라벨
import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../video_call_provider.dart';

class VideoCallStatusBar extends StatelessWidget {
  const VideoCallStatusBar({
    super.key,
    required this.status,
    required this.duration,
    this.textStyle = BeeperTypography.bodyMedium,
  });

  final VideoCallStatus status;
  final Duration duration;

  // 시니어 화면에서는 bodyLarge(16px 이상)로 덮어써서 사용
  final TextStyle textStyle;

  String get _statusLabel {
    switch (status) {
      case VideoCallStatus.connecting:
        return '연결 중...';
      case VideoCallStatus.connected:
        return '통화 중 · ${_formatDuration(duration)}';
      case VideoCallStatus.disconnected:
        return '연결 끊김 · 재연결 시도 중';
      case VideoCallStatus.ended:
        return '통화 종료';
      case VideoCallStatus.failed:
        return '연결 실패';
    }
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${two(minutes)}:${two(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BeeperSpacing.s16,
        vertical: BeeperSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(BeeperRadius.button),
      ),
      child: Text(_statusLabel, style: textStyle.copyWith(color: Colors.white)),
    );
  }
}

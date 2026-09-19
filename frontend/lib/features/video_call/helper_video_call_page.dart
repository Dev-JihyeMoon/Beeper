// 봉사자 영상통화 페이지 (요청 수락 직후에만 진입하므로 항상 caller 역할)
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' show RTCVideoView, RTCVideoViewObjectFit;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/services/help_request_service.dart';
import '../../shared/widgets/beeper_button.dart';
import '../../shared/widgets/error_view.dart';
import 'video_call_provider.dart';
import 'widgets/call_control_button.dart';
import 'widgets/video_call_status_bar.dart';

class HelperVideoCallPage extends StatelessWidget {
  const HelperVideoCallPage({super.key, required this.roomId, this.requestId});

  final String roomId;

  // 통화 종료 시 complete API 호출용 원본 요청 ID
  // 알림 탭 등 일부 진입 경로에서는 null일 수 있으며, 그 경우 완료 처리는 건너뜀
  final String? requestId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VideoCallProvider>(
      create: (context) => VideoCallProvider(
        role: VideoCallRole.caller,
        requestId: requestId,
        helpRequestService: HelpRequestService(apiClient: context.read<ApiClient>()),
      )..initializeCall(roomId),
      child: const _HelperVideoCallView(),
    );
  }
}

class _HelperVideoCallView extends StatefulWidget {
  const _HelperVideoCallView();

  @override
  State<_HelperVideoCallView> createState() => _HelperVideoCallViewState();
}

class _HelperVideoCallViewState extends State<_HelperVideoCallView> {
  bool _navigatedAway = false;

  Future<void> _confirmEndCall(VideoCallProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BeeperColors.background,
        title: const Text('통화를 종료할까요?', style: BeeperTypography.titleLarge),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('아니요', style: BeeperTypography.bodyLarge),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              '종료',
              style: BeeperTypography.bodyLarge.copyWith(color: BeeperColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await provider.endCall();
  }

  void _goToDashboardOnce(bool endedByRemote) {
    if (_navigatedAway || !mounted) return;
    _navigatedAway = true;
    if (endedByRemote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('통화가 종료되었습니다')),
      );
    }
    context.go(BeeperRoutes.helperDashboard);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoCallProvider>();

    // 통화 종료(직접 또는 상대방) 시 대시보드로 자동 이동
    if (provider.status == VideoCallStatus.ended && !_navigatedAway) {
      final endedByRemote = provider.endedByRemote;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _goToDashboardOnce(endedByRemote),
      );
    }

    // 초기 연결 실패(카메라/마이크 접근 실패 등)는 배너로는 놓치기 쉬워 전체 화면 에러로 표시
    if (provider.status == VideoCallStatus.failed) {
      return _buildFailedView(provider);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmEndCall(provider);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              _buildRemoteVideo(provider),
              _buildLocalPreview(provider),
              Positioned(
                top: BeeperSpacing.s16,
                left: BeeperSpacing.s16,
                child: VideoCallStatusBar(
                  status: provider.status,
                  duration: provider.callDuration,
                ),
              ),
              _buildBottomControls(provider),
              if (provider.errorMessage != null) _buildErrorBanner(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFailedView(VideoCallProvider provider) {
    return Scaffold(
      backgroundColor: BeeperColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BeeperSpacing.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ErrorView(message: provider.errorMessage ?? '영상 연결에 실패했습니다.'),
              const SizedBox(height: BeeperSpacing.s24),
              BeeperButton(
                label: '대시보드로 돌아가기',
                onPressed: () => context.go(BeeperRoutes.helperDashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteVideo(VideoCallProvider provider) {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: RTCVideoView(
          provider.remoteRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
      ),
    );
  }

  Widget _buildLocalPreview(VideoCallProvider provider) {
    return Positioned(
      top: BeeperSpacing.s16,
      right: BeeperSpacing.s16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BeeperRadius.card),
        child: Container(
          width: 100,
          height: 140,
          color: Colors.black54,
          child: provider.isCameraOff
              ? const Icon(Icons.videocam_off_rounded, color: Colors.white54)
              : RTCVideoView(
                  provider.localRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  mirror: true,
                ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(VideoCallProvider provider) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: BeeperSpacing.s32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CallControlButton(
            icon: provider.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: provider.isMuted ? '마이크 켜기' : '마이크 끄기',
            isActive: !provider.isMuted,
            onPressed: provider.toggleMute,
          ),
          const SizedBox(width: BeeperSpacing.s24),
          CallControlButton(
            icon: provider.isCameraOff
                ? Icons.videocam_off_rounded
                : Icons.videocam_rounded,
            label: provider.isCameraOff ? '카메라 켜기' : '카메라 끄기',
            isActive: !provider.isCameraOff,
            onPressed: provider.toggleCamera,
          ),
          const SizedBox(width: BeeperSpacing.s24),
          CallControlButton(
            icon: Icons.call_end_rounded,
            label: '통화 종료',
            backgroundColor: BeeperColors.error,
            iconColor: Colors.white,
            onPressed: () => _confirmEndCall(provider),
          ),
        ],
      ),
    );
  }

  // 재연결 시도 중 등 통화가 유지되는 상태의 경고만 다룸 (완전 실패는 _buildFailedView)
  Widget _buildErrorBanner(VideoCallProvider provider) {
    return Positioned(
      left: BeeperSpacing.s16,
      right: BeeperSpacing.s16,
      bottom: 120,
      child: Container(
        padding: const EdgeInsets.all(BeeperSpacing.s16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(BeeperRadius.card),
        ),
        child: Text(
          provider.errorMessage!,
          style: BeeperTypography.bodyMedium.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

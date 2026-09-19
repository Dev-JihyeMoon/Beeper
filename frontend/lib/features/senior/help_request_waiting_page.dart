// 도움 요청 대기 페이지 (봉사자 수락 대기 안내, 취소 동선 제공)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/services/help_request_service.dart';
import '../../shared/widgets/beeper_button.dart';
import '../../shared/widgets/beeper_scaffold.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/pulse_animation.dart';
import 'help_request_waiting_provider.dart';

// 메인 페이지에서 go_router의 extra로 넘겨주는 값
class HelpRequestWaitingArgs {
  const HelpRequestWaitingArgs({required this.requestId, required this.roomId});

  final String requestId;
  final String roomId;
}

class HelpRequestWaitingPage extends StatelessWidget {
  const HelpRequestWaitingPage({super.key, this.args});

  final HelpRequestWaitingArgs? args;

  @override
  Widget build(BuildContext context) {
    final requestArgs = args;

    // 요청 정보 없이 접근한 경우(URL 직접 진입, 새로고침) 시니어 메인으로 복귀
    if (requestArgs == null) {
      return BeeperScaffold(
        body: ErrorView(
          message: '잘못된 접근입니다. 다시 도움을 요청해 주세요.',
          onRetry: () => context.go(BeeperRoutes.seniorMain),
        ),
      );
    }

    return ChangeNotifierProvider<HelpRequestWaitingProvider>(
      create: (context) => HelpRequestWaitingProvider(
        requestId: requestArgs.requestId,
        roomId: requestArgs.roomId,
        helpRequestService: HelpRequestService(apiClient: context.read<ApiClient>()),
      ),
      child: const _HelpRequestWaitingView(),
    );
  }
}

class _HelpRequestWaitingView extends StatefulWidget {
  const _HelpRequestWaitingView();

  @override
  State<_HelpRequestWaitingView> createState() => _HelpRequestWaitingViewState();
}

class _HelpRequestWaitingViewState extends State<_HelpRequestWaitingView> {
  bool _navigatedForAccept = false;
  bool _navigatedForCancel = false;

  Future<void> _confirmCancel(HelpRequestWaitingProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BeeperColors.background,
        title: const Text('요청을 취소할까요?', style: BeeperTypography.titleLarge),
        content: const Text(
          '취소하면 봉사자 연결이 중단됩니다.',
          style: BeeperTypography.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('아니요', style: BeeperTypography.bodyLarge),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              '취소하기',
              style: BeeperTypography.bodyLarge.copyWith(color: BeeperColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await provider.cancelRequest();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpRequestWaitingProvider>();

    // 봉사자 수락 이벤트 수신 시 영상통화 화면으로 이동 (임의 자동 전환 금지)
    final acceptedRoomId = provider.acceptedRoomId;
    if (acceptedRoomId != null && !_navigatedForAccept) {
      _navigatedForAccept = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/video-call/senior/$acceptedRoomId');
      });
    }

    // 취소 성공 시 시니어 메인으로 복귀
    if (provider.isCancelled && !_navigatedForCancel) {
      _navigatedForCancel = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(BeeperRoutes.seniorMain);
      });
    }

    return BeeperScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PulseAnimation(size: 64, icon: Icons.podcasts_rounded),
            const SizedBox(height: BeeperSpacing.s32),
            const Text(
              '도움 요청이 접수되었습니다',
              style: BeeperTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BeeperSpacing.s16),
            const Text(
              '봉사자를 찾고 있습니다...',
              style: BeeperTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (provider.errorMessage != null) ...[
              const SizedBox(height: BeeperSpacing.s24),
              Text(
                provider.errorMessage!,
                style: BeeperTypography.bodyLarge.copyWith(color: BeeperColors.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      bottomBar: BeeperButton(
        label: '요청 취소',
        variant: BeeperButtonVariant.secondary,
        height: 56,
        isLoading: provider.isCancelling,
        onPressed: provider.isCancelling ? null : () => _confirmCancel(provider),
      ),
    );
  }
}

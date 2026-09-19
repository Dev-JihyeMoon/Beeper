// 도움 요청 상세 페이지 (확인 후 수락하면 통화 화면으로 이동)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/services/help_request_service.dart';
import '../../shared/utils/relative_time.dart';
import '../../shared/widgets/beeper_button.dart';
import '../../shared/widgets/beeper_card.dart';
import '../../shared/widgets/beeper_scaffold.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'help_request_detail_provider.dart';
import 'widgets/status_badge.dart';
import 'widgets/tag_chip.dart';

class HelpRequestDetailPage extends StatelessWidget {
  const HelpRequestDetailPage({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HelpRequestDetailProvider>(
      create: (context) => HelpRequestDetailProvider(
        requestId: requestId,
        helpRequestService: HelpRequestService(apiClient: context.read<ApiClient>()),
      ),
      child: const _HelpRequestDetailView(),
    );
  }
}

class _HelpRequestDetailView extends StatefulWidget {
  const _HelpRequestDetailView();

  @override
  State<_HelpRequestDetailView> createState() => _HelpRequestDetailViewState();
}

class _HelpRequestDetailViewState extends State<_HelpRequestDetailView> {
  bool _navigatedForAccept = false;

  void _goBackToDashboard() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(BeeperRoutes.helperDashboard);
    }
  }

  Future<void> _confirmAccept(HelpRequestDetailProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BeeperColors.background,
        title: const Text('이 요청을 수락하시겠습니까?', style: BeeperTypography.titleLarge),
        content: const Text(
          '수락하면 요청자와 영상통화로 연결됩니다.',
          style: BeeperTypography.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소', style: BeeperTypography.bodyLarge),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('수락', style: BeeperTypography.bodyLarge),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await provider.accept();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpRequestDetailProvider>();

    // 수락 성공 시 봉사자 통화 화면으로 이동 (한 번만)
    final acceptResult = provider.acceptResult;
    if (acceptResult != null && !_navigatedForAccept) {
      _navigatedForAccept = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/video-call/helper/${acceptResult.roomId}', extra: acceptResult.id);
      });
    }

    return BeeperScaffold(
      header: _buildHeader(),
      body: _buildBody(provider),
      bottomBar: _buildBottomBar(provider),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BeeperSpacing.s8,
        vertical: BeeperSpacing.s16,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: '뒤로가기',
            child: IconButton(
              onPressed: _goBackToDashboard,
              icon: const Icon(Icons.arrow_back_rounded, color: BeeperColors.textPrimary),
            ),
          ),
          const SizedBox(width: BeeperSpacing.s8),
          const Text('도움 요청 상세', style: BeeperTypography.titleLarge),
        ],
      ),
    );
  }

  Widget _buildBody(HelpRequestDetailProvider provider) {
    switch (provider.status) {
      case HelpRequestDetailStatus.loading:
        return const LoadingIndicator();
      case HelpRequestDetailStatus.error:
        return ErrorView(
          message: provider.loadError ?? '알 수 없는 오류가 발생했습니다.',
          onRetry: provider.retryLoad,
        );
      case HelpRequestDetailStatus.loaded:
        return _buildDetail(provider);
    }
  }

  Widget _buildDetail(HelpRequestDetailProvider provider) {
    final request = provider.request!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(request.title, style: BeeperTypography.headlineMedium),
            ),
            const SizedBox(width: BeeperSpacing.s8),
            StatusBadge(status: request.status),
          ],
        ),
        if (request.createdAt != null) ...[
          const SizedBox(height: BeeperSpacing.s8),
          Text(
            '${_absoluteTime(request.createdAt!)} · ${formatRelativeTime(request.createdAt!)}',
            style: BeeperTypography.bodyMedium.copyWith(
              color: BeeperColors.textPrimary.withValues(alpha: 0.6),
            ),
          ),
        ],
        const SizedBox(height: BeeperSpacing.s24),
        BeeperCard(
          child: Text(request.description, style: BeeperTypography.bodyLarge),
        ),
        if (request.tags.isNotEmpty) ...[
          const SizedBox(height: BeeperSpacing.s24),
          const Text('태그', style: BeeperTypography.bodyMedium),
          const SizedBox(height: BeeperSpacing.s8),
          Wrap(
            spacing: BeeperSpacing.s8,
            runSpacing: BeeperSpacing.s8,
            children: request.tags.map((tag) => TagChip(label: tag)).toList(),
          ),
        ],
        // 서버 응답에 포함된 경우에만 표시
        if (request.requesterNickname != null) ...[
          const SizedBox(height: BeeperSpacing.s24),
          const Text('요청자', style: BeeperTypography.bodyMedium),
          const SizedBox(height: BeeperSpacing.s8),
          Text(request.requesterNickname!, style: BeeperTypography.bodyLarge),
        ],
        if (provider.acceptError != null) ...[
          const SizedBox(height: BeeperSpacing.s32),
          Text(
            provider.acceptError!,
            style: BeeperTypography.bodyLarge.copyWith(color: BeeperColors.error),
          ),
          const SizedBox(height: BeeperSpacing.s16),
          BeeperButton(
            label: '대시보드로 돌아가기',
            variant: BeeperButtonVariant.secondary,
            onPressed: () => context.go(BeeperRoutes.helperDashboard),
          ),
        ],
        const SizedBox(height: BeeperSpacing.s32),
      ],
    );
  }

  Widget? _buildBottomBar(HelpRequestDetailProvider provider) {
    // 조회가 끝나지 않았거나 수락 불가 오류 상태면 수락 버튼 숨김
    // 오류 상태에서는 "대시보드로 돌아가기" 버튼만 다음 동작
    if (provider.status != HelpRequestDetailStatus.loaded) return null;
    if (provider.acceptError != null) return null;

    return BeeperButton(
      label: '요청 수락',
      isLoading: provider.isAccepting,
      onPressed: provider.isAccepting ? null : () => _confirmAccept(provider),
    );
  }

  String _absoluteTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}.${two(local.month)}.${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}

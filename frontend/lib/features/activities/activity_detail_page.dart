// 활동 상세 페이지 (통화 일시/시간, 요청 내용, 요약, 요청자, 태그)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/models/activity.dart';
import '../../core/services/activity_service.dart';
import '../../shared/widgets/beeper_card.dart';
import '../../shared/widgets/beeper_scaffold.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../helper/widgets/tag_chip.dart';
import 'activity_detail_provider.dart';

class ActivityDetailPage extends StatelessWidget {
  const ActivityDetailPage({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ActivityDetailProvider>(
      create: (context) => ActivityDetailProvider(
        activityId: activityId,
        activityService: ActivityService(apiClient: context.read<ApiClient>()),
      ),
      child: const _ActivityDetailView(),
    );
  }
}

class _ActivityDetailView extends StatelessWidget {
  const _ActivityDetailView();

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(BeeperRoutes.activities);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityDetailProvider>();

    return BeeperScaffold(header: _buildHeader(context), body: _buildBody(provider));
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BeeperSpacing.s8, vertical: BeeperSpacing.s16),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: '뒤로가기',
            child: IconButton(
              onPressed: () => _goBack(context),
              icon: const Icon(Icons.arrow_back_rounded, color: BeeperColors.textPrimary),
            ),
          ),
          const SizedBox(width: BeeperSpacing.s8),
          const Text('활동 상세', style: BeeperTypography.titleLarge),
        ],
      ),
    );
  }

  Widget _buildBody(ActivityDetailProvider provider) {
    switch (provider.status) {
      case ActivityDetailStatus.loading:
        return const LoadingIndicator();
      case ActivityDetailStatus.error:
        return ErrorView(
          message: provider.errorMessage ?? '알 수 없는 오류가 발생했습니다.',
          onRetry: provider.retryLoad,
        );
      case ActivityDetailStatus.loaded:
        return _buildDetail(provider.activity!);
    }
  }

  Widget _buildDetail(Activity activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(activity.title, style: BeeperTypography.headlineMedium),
        if (activity.date != null) ...[
          const SizedBox(height: BeeperSpacing.s8),
          Text(
            _formatDateTime(activity.date!),
            style: BeeperTypography.bodyMedium.copyWith(
              color: BeeperColors.textPrimary.withValues(alpha: 0.6),
            ),
          ),
        ],
        const SizedBox(height: BeeperSpacing.s24),
        BeeperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: '통화 시간', value: _formatDuration(activity.durationSeconds)),
              if (activity.seniorName != null)
                _DetailRow(label: '도움 요청자', value: activity.seniorName!),
              _DetailRow(label: '활동 ID', value: activity.id),
            ],
          ),
        ),
        if (activity.summary != null && activity.summary!.isNotEmpty) ...[
          const SizedBox(height: BeeperSpacing.s24),
          const Text('활동 요약', style: BeeperTypography.bodyMedium),
          const SizedBox(height: BeeperSpacing.s8),
          BeeperCard(child: Text(activity.summary!, style: BeeperTypography.bodyLarge)),
        ],
        if (activity.tags.isNotEmpty) ...[
          const SizedBox(height: BeeperSpacing.s24),
          const Text('태그', style: BeeperTypography.bodyMedium),
          const SizedBox(height: BeeperSpacing.s8),
          Wrap(
            spacing: BeeperSpacing.s8,
            runSpacing: BeeperSpacing.s8,
            children: activity.tags.map((tag) => TagChip(label: tag)).toList(),
          ),
        ],
        const SizedBox(height: BeeperSpacing.s32),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}.${two(local.month)}.${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes분 $secs초';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BeeperSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: BeeperTypography.bodyMedium.copyWith(
                color: BeeperColors.textPrimary.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(child: Text(value, style: BeeperTypography.bodyLarge)),
        ],
      ),
    );
  }
}

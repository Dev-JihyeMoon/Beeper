// 활동 내역 카드 (제목, 요약 1줄, 날짜, 통화 시간, 요청자, 태그)
import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../core/models/activity.dart';
import '../../../shared/widgets/beeper_card.dart';
import '../../helper/widgets/tag_chip.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity, required this.onTap});

  final Activity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BeeperCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  activity.title,
                  style: BeeperTypography.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (activity.date != null) ...[
                const SizedBox(width: BeeperSpacing.s8),
                Text(
                  _formatDate(activity.date!),
                  style: BeeperTypography.labelSmall.copyWith(
                    color: BeeperColors.textPrimary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
          if (activity.summary != null && activity.summary!.isNotEmpty) ...[
            const SizedBox(height: BeeperSpacing.s8),
            Text(
              activity.summary!,
              style: BeeperTypography.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: BeeperSpacing.s8),
          Row(
            children: [
              const Icon(Icons.call_rounded, size: 14, color: BeeperColors.textPrimary),
              const SizedBox(width: 4),
              Text(_formatDuration(activity.durationSeconds), style: BeeperTypography.labelSmall),
              if (activity.seniorName != null) ...[
                const SizedBox(width: BeeperSpacing.s16),
                const Icon(Icons.person_rounded, size: 14, color: BeeperColors.textPrimary),
                const SizedBox(width: 4),
                Text(activity.seniorName!, style: BeeperTypography.labelSmall),
              ],
            ],
          ),
          if (activity.tags.isNotEmpty) ...[
            const SizedBox(height: BeeperSpacing.s8),
            Wrap(
              spacing: BeeperSpacing.s8,
              runSpacing: BeeperSpacing.s8,
              children: activity.tags.map((tag) => TagChip(label: tag)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}.${two(local.month)}.${two(local.day)}';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes분 $secs초';
  }
}

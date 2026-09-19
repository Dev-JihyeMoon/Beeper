// 대기 중 요청 카드 (제목, 설명 1줄, 상대 시간, 태그, 탭 시 상세 이동)
import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../core/models/help_request.dart';
import '../../../shared/utils/relative_time.dart';
import '../../../shared/widgets/beeper_card.dart';
import 'tag_chip.dart';

class HelpRequestCard extends StatelessWidget {
  const HelpRequestCard({super.key, required this.request, required this.onTap});

  final HelpRequest request;
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
                  request.title,
                  style: BeeperTypography.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (request.createdAt != null) ...[
                const SizedBox(width: BeeperSpacing.s8),
                Text(
                  formatRelativeTime(request.createdAt!),
                  style: BeeperTypography.labelSmall.copyWith(
                    color: BeeperColors.textPrimary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: BeeperSpacing.s8),
          Text(
            request.description,
            style: BeeperTypography.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (request.tags.isNotEmpty) ...[
            const SizedBox(height: BeeperSpacing.s8),
            Wrap(
              spacing: BeeperSpacing.s8,
              runSpacing: BeeperSpacing.s8,
              children: request.tags.map((tag) => TagChip(label: tag)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

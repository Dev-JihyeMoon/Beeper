// 내 알림 태그 요약 카드 (선택된 태그 칩, 편집 페이지 진입점)
import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../shared/widgets/beeper_card.dart';
import 'tag_chip.dart';

class TagSummaryCard extends StatelessWidget {
  const TagSummaryCard({
    super.key,
    required this.tags,
    required this.isLoading,
    required this.errorMessage,
    required this.onEdit,
  });

  final List<String> tags;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return BeeperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('내 알림 태그', style: BeeperTypography.bodyMedium),
              ),
              TextButton(
                onPressed: onEdit,
                child: const Text(
                  '편집',
                  style: TextStyle(color: BeeperColors.info, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: BeeperSpacing.s8),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Text('불러오는 중...', style: BeeperTypography.bodyMedium);
    }
    if (errorMessage != null) {
      return Text(
        '태그를 불러오지 못했습니다.',
        style: BeeperTypography.bodyMedium.copyWith(color: BeeperColors.error),
      );
    }
    if (tags.isEmpty) {
      return const Text(
        '알림 받을 태그를 설정해주세요',
        style: BeeperTypography.bodyMedium,
      );
    }
    return Wrap(
      spacing: BeeperSpacing.s8,
      runSpacing: BeeperSpacing.s8,
      children: tags.map((tag) => TagChip(label: tag)).toList(),
    );
  }
}

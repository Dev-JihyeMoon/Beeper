// 활동 상태 토글 카드 (켜짐: primary, 꺼짐: 회색, 서버 반영 중 비활성화)
import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../shared/widgets/beeper_card.dart';

class AvailabilityToggleCard extends StatelessWidget {
  const AvailabilityToggleCard({
    super.key,
    required this.isAvailable,
    required this.isUpdating,
    required this.onChanged,
  });

  final bool isAvailable;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return BeeperCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('활동 상태', style: BeeperTypography.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  isAvailable ? '활동 가능' : '활동 중지',
                  style: BeeperTypography.titleLarge.copyWith(
                    color: isAvailable ? BeeperColors.success : BeeperColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (isUpdating)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            Switch(
              value: isAvailable,
              activeThumbColor: BeeperColors.primary,
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade300,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

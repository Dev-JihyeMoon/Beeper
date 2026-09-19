// 태그 칩 (surface 배경, textPrimary 텍스트, 반경 8)
import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BeeperSpacing.s16, vertical: BeeperSpacing.s8),
      decoration: BoxDecoration(
        color: BeeperColors.surface,
        borderRadius: BorderRadius.circular(BeeperRadius.small),
      ),
      child: Text(
        label,
        style: BeeperTypography.labelSmall.copyWith(color: BeeperColors.textPrimary),
      ),
    );
  }
}

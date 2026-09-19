// 선택 가능한 태그 칩 (선택 시 primary 테두리 + 체크 아이콘)
import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class SelectableTagChip extends StatelessWidget {
  const SelectableTagChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BeeperRadius.small),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BeeperSpacing.s16,
            vertical: BeeperSpacing.s8,
          ),
          decoration: BoxDecoration(
            color: selected ? BeeperColors.primary.withValues(alpha: 0.12) : BeeperColors.surface,
            borderRadius: BorderRadius.circular(BeeperRadius.small),
            border: Border.all(
              color: selected ? BeeperColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, size: 16, color: BeeperColors.primary),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: BeeperTypography.labelSmall.copyWith(
                  color: selected ? BeeperColors.primary : BeeperColors.textPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

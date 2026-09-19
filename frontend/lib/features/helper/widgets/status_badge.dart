// 도움 요청 상태 뱃지 (WAITING: info, ACCEPTED: success, 그 외: textPrimary)
import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  Color get _color {
    switch (status) {
      case 'WAITING':
        return BeeperColors.info;
      case 'ACCEPTED':
        return BeeperColors.success;
      default:
        return BeeperColors.textPrimary;
    }
  }

  String get _label {
    switch (status) {
      case 'WAITING':
        return '대기 중';
      case 'ACCEPTED':
        return '수락됨';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BeeperSpacing.s8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BeeperRadius.small),
      ),
      child: Text(
        _label,
        style: BeeperTypography.labelSmall.copyWith(color: _color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

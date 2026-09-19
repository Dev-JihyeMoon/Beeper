// 회원 유형 뱃지 (HELPER: success, SENIOR: info)
import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class UserTypeBadge extends StatelessWidget {
  const UserTypeBadge({super.key, required this.userType});

  final String userType;

  Color get _color => userType == 'HELPER' ? BeeperColors.success : BeeperColors.info;

  String get _label {
    switch (userType) {
      case 'HELPER':
        return '봉사자';
      case 'SENIOR':
        return '도움 요청자';
      default:
        return userType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BeeperSpacing.s16, vertical: 6),
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

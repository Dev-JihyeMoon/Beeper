// 빈 상태 UI (펄스 애니메이션 + 안내 텍스트)
import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'pulse_animation.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BeeperSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PulseAnimation(
              size: 48,
              icon: icon ?? Icons.podcasts_rounded,
            ),
            const SizedBox(height: BeeperSpacing.s24),
            Text(
              message,
              style: BeeperTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

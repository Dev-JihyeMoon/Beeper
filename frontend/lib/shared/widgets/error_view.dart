// 공통 에러 UI (에러 메시지 + 재시도 버튼)
import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'beeper_button.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BeeperSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: BeeperColors.error,
              size: 40,
            ),
            const SizedBox(height: BeeperSpacing.s16),
            Text(
              message,
              style: BeeperTypography.bodyLarge.copyWith(
                color: BeeperColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: BeeperSpacing.s24),
              BeeperButton(
                label: '다시 시도',
                onPressed: onRetry,
                variant: BeeperButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

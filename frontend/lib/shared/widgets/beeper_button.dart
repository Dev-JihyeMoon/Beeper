// 공통 버튼 위젯 (CTA/Secondary 스타일, 로딩 상태, 최소 터치 영역 보장)
import 'package:flutter/material.dart';

import '../../config/theme.dart';

enum BeeperButtonVariant { primary, secondary }

class BeeperButton extends StatelessWidget {
  const BeeperButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = BeeperButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final BeeperButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  // 버튼 높이 (최소 터치 영역 48dp 보장, CTA는 더 크게 지정 가능)
  final double height;

  bool get _isPrimary => variant == BeeperButtonVariant.primary;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isPrimary
        ? BeeperColors.primary
        : BeeperColors.surface;
    final foregroundColor = _isPrimary
        ? BeeperColors.onPrimary
        : BeeperColors.textPrimary;
    final disabled = onPressed == null || isLoading;

    return SizedBox(
      width: double.infinity,
      height: height, // 기본값 48dp (최소 터치 영역 보장)
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.6),
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BeeperRadius.button),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(foregroundColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: BeeperSpacing.s8),
                  ],
                  Text(label, style: BeeperTypography.bodyLarge.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  )),
                ],
              ),
      ),
    );
  }
}

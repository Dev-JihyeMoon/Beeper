// 통화 화면 하단 원형 컨트롤 버튼 (마이크/카메라/종료/카메라 전환 공용)
import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class CallControlButton extends StatelessWidget {
  const CallControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.label,
    this.isActive = true,
    this.backgroundColor,
    this.iconColor,
    this.size = 56,
  });

  final IconData icon;
  final VoidCallback onPressed;

  // 스크린 리더 안내용 라벨 (예: "마이크 끄기")
  final String label;

  // false면 꺼진 상태(음소거/카메라 꺼짐) 배경으로 표시
  final bool isActive;
  final Color? backgroundColor;
  final Color? iconColor;

  // 버튼 지름 (봉사자 48 이상, 시니어 56 이상 권장)
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolvedBackground =
        backgroundColor ??
        (isActive ? Colors.white.withValues(alpha: 0.9) : Colors.black54);
    final resolvedIconColor = iconColor ?? BeeperColors.textPrimary;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: resolvedBackground,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: resolvedIconColor, size: size * 0.42),
          ),
        ),
      ),
    );
  }
}

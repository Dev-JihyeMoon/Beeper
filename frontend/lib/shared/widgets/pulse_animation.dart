// 시그널 모티프 펄스 애니메이션 (동심원 효과)
import 'package:flutter/material.dart';

import '../../config/theme.dart';

class PulseAnimation extends StatefulWidget {
  const PulseAnimation({
    super.key,
    this.size = 64,
    this.color = BeeperColors.primary,
    this.icon = Icons.podcasts_rounded,
  });

  final double size;
  final Color color;
  final IconData icon;

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 개별 펄스는 300ms 이내로 유지하고 반복 주기는 더 길게 둠
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _buildRing(0),
              _buildRing(0.5),
              Icon(widget.icon, color: widget.color, size: widget.size * 0.6),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRing(double delay) {
    final progress = (_controller.value + delay) % 1.0;
    return Opacity(
      opacity: (1 - progress).clamp(0.0, 1.0),
      child: Container(
        width: widget.size * (1 + progress),
        height: widget.size * (1 + progress),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: widget.color, width: 2),
        ),
      ),
    );
  }
}

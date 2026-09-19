// 공통 카드 위젯 (컬러 섀도우 + 웹 호버 시 떠오르는 효과)
import 'package:flutter/material.dart';

import '../../config/theme.dart';

class BeeperCard extends StatefulWidget {
  const BeeperCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(BeeperSpacing.s16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  State<BeeperCard> createState() => _BeeperCardState();
}

class _BeeperCardState extends State<BeeperCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(0, _hovering ? -2 : 0, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: BeeperColors.surface,
            borderRadius: BorderRadius.circular(BeeperRadius.card),
            boxShadow: _hovering ? BeeperShadows.cardHover : BeeperShadows.card,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

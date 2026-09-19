// 봉사자용 하단 네비게이션 바 (현재 탭 아이콘 아래 도트 표시)
import 'package:flutter/material.dart';

import '../../../config/theme.dart';

enum HelperNavTab { home, activities, profile }

class HelperBottomNav extends StatelessWidget {
  const HelperBottomNav({super.key, required this.current, required this.onSelect});

  final HelperNavTab current;
  final ValueChanged<HelperNavTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: BeeperColors.background,
        border: Border(top: BorderSide(color: BeeperColors.surface, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: '홈',
                selected: current == HelperNavTab.home,
                onTap: () => onSelect(HelperNavTab.home),
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: '활동 내역',
                selected: current == HelperNavTab.activities,
                onTap: () => onSelect(HelperNavTab.activities),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: '프로필',
                selected: current == HelperNavTab.profile,
                onTap: () => onSelect(HelperNavTab.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? BeeperColors.primary : BeeperColors.textPrimary.withValues(alpha: 0.5);

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(label, style: BeeperTypography.labelSmall.copyWith(color: color)),
              const SizedBox(height: 2),
              Text(
                selected ? '●' : '',
                style: TextStyle(color: color, fontSize: 8, height: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

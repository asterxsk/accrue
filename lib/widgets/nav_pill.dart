import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import 'app_icon.dart';

class NavItem {
  const NavItem({required this.label, required this.icon});

  final String label;
  final String icon;
}

const List<NavItem> navItems = [
  NavItem(label: 'Today', icon: 'home'),
  NavItem(label: 'Insights', icon: 'chart'),
  NavItem(label: 'Routines', icon: 'layers'),
  NavItem(label: 'Profile', icon: 'person'),
];

/// The floating bottom pill: four equal tabs, stretched nearly edge to edge.
class NavPill extends StatelessWidget {
  const NavPill({super.key, required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: Metrics.pillHeight,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.line),
        boxShadow: [colors.shadow],
      ),
      child: Row(
        children: [
          for (var i = 0; i < navItems.length; i++)
            Expanded(
              child: _PillButton(
                item: navItems[i],
                active: i == index,
                onTap: () => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final foreground = active ? colors.accentInk : colors.muted;
    return Semantics(
      selected: active,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: Metrics.pillButtonHeight,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: active ? colors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(item.icon, size: 22, color: foreground),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: AppType.labelSmall.copyWith(color: foreground),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

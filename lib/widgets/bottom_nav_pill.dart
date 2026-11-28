import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_layout.dart';
import 'nav_items.dart';

class SpothBottomNav extends StatelessWidget {
  const SpothBottomNav({
    super.key,
    required this.index,
    required this.items,
    required this.onChanged,
    this.badgeIndex = -1,
    this.badgeCount = 0,
    this.additionalBadgeCounts = const {},
  });

  final int index;
  final List<NavItemData> items;
  final ValueChanged<int> onChanged;
  final int badgeIndex;
  final int badgeCount;

  /// Badge tambahan per index, misalnya Chat dan Booking bersamaan.
  final Map<int, int> additionalBadgeCounts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm + MediaQuery.paddingOf(context).bottom,
      ),
      color: AppColors.canvas,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl + 2),
          border: Border.all(color: AppColors.softBorder),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              _NavItem(
                item: items[i],
                selected: index == i,
                badgeCount:
                    (i == badgeIndex ? badgeCount : 0) +
                    (additionalBadgeCounts[i] ?? 0),
                onTap: () => onChanged(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  final NavItemData item;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryInk : AppColors.secondaryText;

    return Expanded(
      child: Tooltip(
        message: item.label,
        child: Material(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Semantics(
              selected: selected,
              button: true,
              label: item.label,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: selected ? AppColors.lightOrange : AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Badge.count(
                      count: badgeCount,
                      isLabelVisible: badgeCount > 0,
                      backgroundColor: AppColors.primaryOrange,
                      textColor: AppColors.white,
                      child: Icon(
                        selected ? item.activeIcon : item.icon,
                        size: 22,
                        color: selected ? AppColors.primaryDeep : color,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.shortLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

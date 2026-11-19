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
  });

  final int index;

  final List<NavItemData> items;

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        10,
        8,
        10,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      color: AppColors.canvas,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl + 2),
          border: Border.all(color: AppColors.softBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.charcoal.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              _NavItem(
                item: items[i],
                selected: index == i,
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
    required this.onTap,
  });

  final NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryInk : AppColors.secondaryText;

    return Expanded(
      child: Tooltip(
        message: item.label,
        child: Material(
          color: Colors.transparent,
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
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppColors.lightOrange : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? item.activeIcon : item.icon,
                      size: 22,
                      color: selected ? AppColors.primaryDeep : color,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.shortLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        height: 1.2,
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

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/theme/app_layout.dart';
import 'nav_items.dart';

class SpothSidebar extends StatelessWidget {
  const SpothSidebar({
    super.key,
    required this.index,
    required this.items,
    required this.onChanged,
    required this.expanded,
    required this.onToggle,
    this.badgeIndex = -1,
    this.badgeCount = 0,
    this.additionalBadgeCounts = const {},
  });

  final int index;

  final List<NavItemData> items;

  final ValueChanged<int> onChanged;

  final bool expanded;

  final VoidCallback onToggle;

  final int badgeIndex;

  final int badgeCount;

  /// Badge tambahan per index, misalnya Chat dan Booking bersamaan.
  final Map<int, int> additionalBadgeCounts;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: expanded ? 236 : 78,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.sm,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: AppColors.softBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Brand(expanded: expanded, onToggle: onToggle),
          const SizedBox(height: 22),
          if (expanded)
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 8),
              child: Text(
                'Jelajahi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, i) => _SidebarItem(
                item: items[i],
                selected: index == i,
                expanded: expanded,
                badgeCount:
                    (i == badgeIndex ? badgeCount : 0) +
                    (additionalBadgeCounts[i] ?? 0),
                onTap: () => onChanged(i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  Widget _tombolLipat() {
    return Tooltip(
      message: expanded ? 'Kecilkan menu' : 'Buka nama menu',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onToggle,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              expanded ? Icons.chevron_left : Icons.chevron_right,
              size: 20,
              color: AppColors.primaryDeep,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return Column(
        children: [
          const Center(
            child: SizedBox(width: 52, height: 52, child: _Logo(size: 46)),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.softBorder),
          const SizedBox(height: 10),
          _tombolLipat(),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const _Logo(size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'SPOTH UMKM',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.heading(
                fontSize: 14,
                weight: 700,
                letterSpacing: 0.1,
                color: AppColors.charcoal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _tombolLipat(),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/spoth-umkm-logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(
        Icons.storefront,
        color: AppColors.primaryDeep,
        size: size * 0.6,
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.badgeCount,
    required this.onTap,
  });

  final NavItemData item;
  final bool selected;
  final bool expanded;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.white : AppColors.secondaryText;

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 12 : 0,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryOrange : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: expanded
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          Badge.count(
            count: badgeCount,
            isLabelVisible: badgeCount > 0,
            backgroundColor: AppColors.primaryOrange,
            textColor: AppColors.white,
            child: Icon(
              selected ? item.activeIcon : item.icon,
              size: 22,
              color: color,
            ),
          ),
          if (expanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Tooltip(
      message: expanded ? '' : item.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}


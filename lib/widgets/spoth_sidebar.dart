import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import 'nav_items.dart';

class SpothSidebar extends StatelessWidget {
  const SpothSidebar({
    super.key,
    required this.index,
    required this.items,
    required this.onChanged,
    required this.expanded,
  });

  final int index;

  final List<NavItemData> items;

  final ValueChanged<int> onChanged;

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expanded ? 232 : 76,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: AppColors.softBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
            child: expanded
                ? Row(
                    children: [
                      _Logo(size: 52),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'SPOTH UMKM',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.heading(
                            fontSize: 15,
                            weight: 700,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _Logo(size: 56),
                    ),
                  ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            _SidebarItem(
              item: items[i],
              selected: index == i,
              expanded: expanded,
              onTap: () => onChanged(i),
            ),
            const SizedBox(height: 8),
          ],
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
        color: AppColors.primaryOrange,
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
    required this.onTap,
  });

  final NavItemData item;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryOrange : AppColors.secondaryText;

    final child = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 12 : 0,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: expanded
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          Icon(selected ? item.activeIcon : item.icon, size: 22, color: color),
          if (expanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
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
        color: selected ? AppColors.lightOrange : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

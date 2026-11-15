import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'nav_items.dart';

/// Bottom navigation berbentuk pill (rounded) dengan background putih.
///
/// Menu tidak aktif: ikon + label abu-abu. Menu aktif: ikon + label orange
/// (identitas SPOTH UMKM). Dipakai di mobile/tablet; di web memakai sidebar.
class SpothBottomNav extends StatelessWidget {
  const SpothBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
  });

  /// Index tab aktif (0=Beranda, 1=Tempat, 2=Booking, 3=Notifikasi, 4=Profil).
  final int index;

  /// Callback saat pengguna memilih tab baru.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        10,
        10,
        10,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(color: AppColors.white),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.softBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < kNavItems.length; i++)
              _NavItem(
                item: kNavItems[i],
                selected: index == i,
                onTap: () => onChanged(i),
              ),
          ],
        ),
      ),
    );
  }
}

/// Satu butir menu pada bottom navigation.
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
    final color = selected ? AppColors.primaryOrange : AppColors.secondaryText;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                size: 22,
                color: color,
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

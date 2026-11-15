import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import 'nav_items.dart';

/// Sidebar navigasi untuk tampilan **web** SPOTH UMKM.
///
/// - Layar lebar (>= 1100 px): logo + ikon + label.
/// - Layar sempit (< 1100 px): ikon saja (rail) dengan tooltip.
///
/// Di mobile/tablet, navigasi bawah ([SpothBottomNav]) yang dipakai.
class SpothSidebar extends StatelessWidget {
  const SpothSidebar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.expanded,
  });

  /// Index tab aktif (0=Beranda, 1=Tempat, 2=Booking, 3=Profil).
  final int index;

  /// Callback saat pengguna memilih menu baru.
  final ValueChanged<int> onChanged;

  /// `true` untuk mode penuh (logo + label); `false` untuk mode ikon.
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
                          style: AppFonts.serif(
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
          for (var i = 0; i < kNavItems.length; i++) ...[
            _SidebarItem(
              item: kNavItems[i],
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

/// Logo SPOTH UMKM (latar transparan, dari `assets/icons/spoth-umkm-logo.png`).
/// Bila gambar gagal dimuat, tampilkan fallback ikon storefront orange.
class _Logo extends StatelessWidget {
  const _Logo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/spoth-umkm-logo.png',
      width: size,
      height: size,
      // Latar transparan → pakai cover agar logo lebih penuh di sidebar.
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(
        Icons.storefront,
        color: AppColors.primaryOrange,
        size: size * 0.6,
      ),
    );
  }
}

/// Satu butir menu pada sidebar.
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

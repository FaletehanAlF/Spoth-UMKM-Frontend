import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../providers/nav_provider.dart';

class NavItemData {
  const NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    String? shortLabel,
  }) : shortLabel = shortLabel ?? label;

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String shortLabel;
}

const Map<MainTab, NavItemData> kNavItems = {
  MainTab.beranda: NavItemData(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Beranda',
  ),
  MainTab.tempat: NavItemData(
    icon: Icons.storefront_outlined,
    activeIcon: Icons.storefront,
    label: 'Tempat',
  ),
  MainTab.kelolaTempat: NavItemData(
    icon: Icons.business_outlined,
    activeIcon: Icons.business,
    label: 'Kelola Tempat',
    shortLabel: 'Kelola',
  ),
  MainTab.booking: NavItemData(
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long,
    label: 'Booking',
  ),
  MainTab.profil: NavItemData(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profil',
  ),
};

/// Menu navigasi sesuai peran.
///
/// Pemilik (HOST) memakai tab pertama sebagai **Dashboard** karena isinya
/// ringkasan usaha, bukan beranda katalog. Penyewa (TENANT) tetap memakai
/// **Beranda**.
List<NavItemData> navItemsForRole(UserModel? user) {
  final isHost = user?.role == UserModel.roleHost;

  return [
    for (final tab in tabsForRole(user))
      if (tab == MainTab.beranda && isHost)
        const NavItemData(
          icon: Icons.space_dashboard_outlined,
          activeIcon: Icons.space_dashboard,
          label: 'Dashboard',
        )
      else
        kNavItems[tab]!,
  ];
}

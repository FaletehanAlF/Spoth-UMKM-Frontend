import 'package:flutter/material.dart';

import '../providers/nav_provider.dart';

class NavItemData {
  const NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
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

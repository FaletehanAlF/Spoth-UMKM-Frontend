import 'package:flutter/material.dart';

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

const List<NavItemData> kNavItems = [
  NavItemData(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Beranda',
  ),
  NavItemData(
    icon: Icons.storefront_outlined,
    activeIcon: Icons.storefront,
    label: 'Tempat',
  ),
  NavItemData(
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long,
    label: 'Booking',
  ),
  NavItemData(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profil',
  ),
];

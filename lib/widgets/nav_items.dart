import 'package:flutter/material.dart';

/// Butir menu navigasi utama — dipakai bersama oleh bottom bar (mobile)
/// dan sidebar (web).
///
/// Susunan (sama untuk Pemilik dan Penyewa):
/// 0 = Beranda, 1 = Tempat, 2 = Booking, 3 = Profil
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

/// Daftar menu utama aplikasi (urutan = index navigasi).
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

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';

/// Kartu pengaturan akun. Saat ini hanya berisi aksi keluar, tetapi bentuk
/// kartu disiapkan agar pengaturan lain bisa ditambahkan tanpa mengubah
/// layout halaman profil.
class ProfileAccountCard extends StatelessWidget {
  const ProfileAccountCard({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Akun',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: onLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0000),
              foregroundColor: AppColors.white,
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

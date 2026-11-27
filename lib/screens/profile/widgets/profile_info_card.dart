import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/utils/format.dart';
import '../../../models/user_model.dart';

/// Kartu data profil mode lihat.
///
/// Semua nilai ditampilkan sebagai teks biasa, bukan input, supaya tidak ada
/// kesan bahwa data bisa berubah tanpa disengaja.
class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return _ProfileCard(
      title: 'Informasi Pribadi',
      subtitle: 'Data yang dipakai untuk kebutuhan penyewaan.',
      child: Column(
        children: [
          _InfoRow(icon: Icons.mail_outline, label: 'Email', value: user.email),
          const Divider(height: 22),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'No. HP',
            value: (user.noHp ?? '').trim().isEmpty
                ? 'Belum diisi'
                : user.noHp!,
          ),
          const Divider(height: 22),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Bergabung',
            value: formatDateString(user.createdAt.toIso8601String()),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.lightOrange,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: AppColors.primaryDeep),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

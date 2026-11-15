import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/spoth_app_bar.dart';

/// Halaman Profil — data akun pengguna yang login dan tombol keluar.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  /// Menampilkan dialog konfirmasi lalu logout bila disetujui.
  Future<void> _confirmAndLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Anda perlu login kembali untuk masuk ke aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.primaryOrange),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(authNotifierProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const SpothAppBar(title: Text('Profil')),
      body: user == null
          ? const Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: EmptyState(
                  icon: Icons.person_outline,
                  title: 'Profil tidak tersedia',
                  message: 'Silakan login untuk melihat data profil Anda.',
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(user: user),
                  const SizedBox(height: 16),
                  _ProfileInfo(user: user),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _confirmAndLogout(context, ref),
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar'),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Kartu kepala profil: avatar inisial, nama, dan email.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final nama = user.nama.trim();
    final initial = nama.isNotEmpty ? nama[0].toUpperCase() : 'S';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryOrange,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu rincian akun: email, no. HP, peran, dan tanggal bergabung.
class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final bergabung = DateFormat('dd MMM yyyy').format(user.createdAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _InfoRow(icon: Icons.mail_outline, label: 'Email', value: user.email),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'No. HP',
            value: user.noHp ?? '-',
          ),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Peran',
            value: user.role,
          ),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Bergabung',
            value: bergabung,
          ),
        ],
      ),
    );
  }
}

/// Satu baris rincian akun: icon + label + nilai.
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryOrange),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

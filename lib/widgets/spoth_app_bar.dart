import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'notification_icon.dart';
import 'profile_icon_button.dart';
import 'riwayat_icon_button.dart';

class SpothAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SpothAppBar({
    super.key,
    this.title,
    this.actions,
    this.centerTitle = true,
    this.leading,
    this.showRiwayat = false,
    this.showNotification = false,
    this.showProfile = true,
  });

  final Widget? title;

  final List<Widget>? actions;
  final bool centerTitle;

  /// Override tombol kiri. Jika null, AppBar otomatis menampilkan tombol
  /// kembali pada halaman yang bisa di-pop.
  final Widget? leading;

  /// Tampilkan ikon riwayat di pojok kiri. Jangan dipakai bersamaan dengan
  /// halaman yang membutuhkan tombol kembali.
  final bool showRiwayat;

  /// Tampilkan ikon lonceng di pojok kanan.
  final bool showNotification;

  /// Tampilkan profile di pojok kanan atas, samping notifikasi.
  final bool showProfile;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.charcoal,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      titleSpacing: centerTitle ? 0 : 20,
      leading: leading ?? (showRiwayat ? const RiwayatIconButton() : null),
      title: centerTitle
          ? (title ??
                const Text(
                  'Spoth UMKM',
                  style: TextStyle(
                    color: AppColors.charcoal,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ))
          : title,
      actions: [
        ...?actions,
        if (showNotification) const NotificationIconButton(),
        if (showProfile) const ProfileIconButton(),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.softBorder),
      ),
    );
  }
}

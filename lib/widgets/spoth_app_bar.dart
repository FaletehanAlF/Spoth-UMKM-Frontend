import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// AppBar standar SPOTH UMKM.
///
/// Sama seperti bottom navigation, AppBar diberi **garis batas bawah**
/// (`softBorder`) agar konten tidak menyatu dengan area atas.
/// Tanpa elevation/gradient.
class SpothAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SpothAppBar({
    super.key,
    this.title,
    this.actions,
    this.centerTitle = false,
  });

  /// Judul app bar.
  final Widget? title;

  /// Aksi di kanan app bar (mis. ikon notifikasi).
  final List<Widget>? actions;

  /// `true` untuk memusatkan judul (dipakai Home & brand).
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    // Di layar lebar (web/desktop) judul dipusatkan agar sejajar dengan
    // desain sidebar; di ponsel mengikuti pilihan tiap halaman.
    final layarLebar = MediaQuery.sizeOf(context).width >= 900;

    return AppBar(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle || layarLebar,
      title: title,
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.softBorder),
      ),
    );
  }
}

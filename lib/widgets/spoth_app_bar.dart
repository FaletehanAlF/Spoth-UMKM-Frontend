import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class SpothAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SpothAppBar({
    super.key,
    this.title,
    this.actions,
    this.centerTitle = false,
  });

  final Widget? title;

  final List<Widget>? actions;
  final bool centerTitle;

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
      title: centerTitle ? (title ?? const Text('Spoth UMKKM')) : title,
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.softBorder),
      ),
    );
  }
}

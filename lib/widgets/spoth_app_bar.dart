import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class SpothAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SpothAppBar({super.key, this.title, this.actions});

  final Widget? title;

  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: title,
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.softBorder),
      ),
    );
  }
}

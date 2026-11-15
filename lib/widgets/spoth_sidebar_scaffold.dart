import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/nav_provider.dart';
import 'spoth_sidebar.dart';

/// Membungkus halaman dengan sidebar di layar lebar (Chrome/Edge/desktop
/// >= 900 px), layar sempit (ponsel) mengembalikan [child] apa adanya.
///
/// Dipakai agar navigasi sidebar tetap terlihat saat pengguna membuka
/// halaman yang di-push (mis. Form Tempat) — isi halaman tidak lagi
/// menutupi navigasi utama.
///
/// Mengetuk menu sidebar saat halaman ini terbuka akan kembali ke shell
/// utama pada tab yang dipilih.
class SpothSidebarScaffold extends ConsumerWidget {
  const SpothSidebarScaffold({
    super.key,
    required this.child,
    this.activeNavIndex = 1,
  });

  /// Konten halaman (mis. form).
  final Widget child;

  /// Index tab yang ditandai aktif di sidebar.
  final int activeNavIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < 900) {
      return child;
    }

    return Row(
      children: [
        SpothSidebar(
          index: activeNavIndex,
          expanded: width >= 1100,
          onChanged: (i) {
            ref.read(mainNavIndexProvider.notifier).setTab(i);
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

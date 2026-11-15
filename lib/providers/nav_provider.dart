import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index tab aktif pada shell utama (MainShell).
///
/// 0 = Beranda, 1 = Booking, 2 = Profil.
/// Dipisah agar halaman dalam tab (mis. tombol riwayat di Beranda)
/// bisa memindahkan tab tanpa mengubah router.
class MainNavNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Memindahkan tab aktif. Nilai di luar rentang diabaikan.
  void setTab(int index) {
    if (index >= 0 && index <= 2) {
      state = index;
    }
  }
}

/// Provider index tab bottom navigation (Beranda/Booking/Profil).
final mainNavIndexProvider = NotifierProvider<MainNavNotifier, int>(
  MainNavNotifier.new,
);

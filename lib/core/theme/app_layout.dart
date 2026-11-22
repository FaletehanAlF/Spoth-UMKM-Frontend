/// Jarak, radius, dan lebar konten yang dipakai bersama agar layar terasa
/// satu keluarga, baik di ponsel maupun di web lebar.
///
/// Jarak mengikuti skala desain: 4, 8, 12, 16, 20, 24, 28, 32, 40, 48.
abstract final class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double xxxl = 24;
  static const double ultra = 32;
  static const double mega = 40;
  static const double giga = 48;
  static const double listItemHeight = 72;
}

abstract final class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}

abstract final class AppWidth {
  const AppWidth._();
  static const double page = 1120;

  /// Layar mulai menampilkan sidebar.
  static const double sidebar = 900;

  /// Sidebar diperlebar (lengkap) pada lebar ini.
  static const double sidebarExpanded = 1400;
  static const double content = 1080;
  static const double form = 680;
  static const double auth = 430;
  static const double list = 760;

  /// Di bawah lebar ini, layout memakai satu kolom.
  static const double twoColumn = 860;
}

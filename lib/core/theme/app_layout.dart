/// Jarak, radius, dan lebar konten yang dipakai bersama agar layar terasa
/// satu keluarga, baik di ponsel maupun di web lebar.
abstract final class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double xxxl = 40;
}

abstract final class AppRadius {
  const AppRadius._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

abstract final class AppWidth {
  const AppWidth._();

  static const double page = 1120;
  static const double content = 1080;
  static const double list = 760;
  static const double form = 680;
  static const double auth = 430;

  /// Di bawah lebar ini, layout memakai satu kolom.
  static const double twoColumn = 860;
}

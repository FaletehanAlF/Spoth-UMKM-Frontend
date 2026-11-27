import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';

enum MainTab { beranda, tempat, kelolaTempat, booking, profil }

class MainNavNotifier extends Notifier<MainTab> {
  @override
  MainTab build() => MainTab.beranda;

  void setTab(MainTab tab) {
    state = tab;
  }
}

final mainNavIndexProvider = NotifierProvider<MainNavNotifier, MainTab>(
  MainNavNotifier.new,
);

/// Lebar sidebar: `true` = nama menu tampil, `false` = icon saja.
class SidebarNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() {
    state = !state;
  }
}

final sidebarExpandedProvider = NotifierProvider<SidebarNotifier, bool>(
  SidebarNotifier.new,
);

List<MainTab> tabsForRole(UserModel? user) {
  if (user?.role == UserModel.roleHost) {
    return const [
      MainTab.beranda,
      MainTab.tempat,
      MainTab.kelolaTempat,
      MainTab.booking,
      MainTab.profil,
    ];
  }

  return const [
    MainTab.beranda,
    MainTab.tempat,
    MainTab.booking,
    MainTab.profil,
  ];
}

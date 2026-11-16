import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainNavNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    if (index >= 0 && index <= 3) {
      state = index;
    }
  }
}

final mainNavIndexProvider = NotifierProvider<MainNavNotifier, int>(
  MainNavNotifier.new,
);

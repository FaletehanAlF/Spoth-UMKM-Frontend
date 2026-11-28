import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Jumlah pesan baru untuk badge oranye di tab Chat.
class ChatBadgeNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state += 1;
  }

  void setTotal(int total) {
    if (state != total) state = total;
  }

  void reset() {
    if (state != 0) state = 0;
  }
}

final chatBadgeProvider = NotifierProvider<ChatBadgeNotifier, int>(
  ChatBadgeNotifier.new,
);

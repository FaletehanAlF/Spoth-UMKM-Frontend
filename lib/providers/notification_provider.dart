import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/notification_service.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';

/// Ringkasan notifikasi (`GET /notifications/summary`) untuk badge
/// jumlah belum dibaca pada icon notifikasi. `null` bila belum login.
class NotificationSummaryNotifier
    extends AsyncNotifier<NotificationSummaryModel?> {
  Future<NotificationSummaryModel?> _fetch() async {
    final token = ref.read(authNotifierProvider.select((state) => state.token));

    if (token == null) {
      return null;
    }

    return ref.read(notificationServiceProvider).summary(token: token);
  }

  @override
  Future<NotificationSummaryModel?> build() async {
    ref.watch(authNotifierProvider.select((state) => state.token));
    return _fetch();
  }

  /// Memuat ulang ringkasan (setelah notifikasi dibaca, misalnya).
  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }
}

/// Provider ringkasan notifikasi (badge).
final notificationSummaryProvider =
    AsyncNotifierProvider<
      NotificationSummaryNotifier,
      NotificationSummaryModel?
    >(NotificationSummaryNotifier.new);

/// Daftar notifikasi milik pengguna (`GET /notifications`).
class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  Future<List<NotificationModel>> _fetch() async {
    final token = ref.read(authNotifierProvider.select((state) => state.token));

    if (token == null) {
      return const <NotificationModel>[];
    }

    return ref.read(notificationServiceProvider).list(token: token);
  }

  @override
  Future<List<NotificationModel>> build() async {
    ref.watch(authNotifierProvider.select((state) => state.token));
    return _fetch();
  }

  /// Memuat ulang daftar notifikasi.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Menandai satu notifikasi sudah dibaca lalu memuat ulang daftar & badge.
  Future<void> markRead(String id) async {
    final token = ref.read(authNotifierProvider.select((state) => state.token));

    if (token == null) {
      return;
    }

    await ref.read(notificationServiceProvider).markRead(token: token, id: id);
    await refresh();
    await ref.read(notificationSummaryProvider.notifier).refresh();
  }

  /// Menandai semua notifikasi sudah dibaca lalu memuat ulang daftar & badge.
  Future<void> markAllRead() async {
    final token = ref.read(authNotifierProvider.select((state) => state.token));

    if (token == null) {
      return;
    }

    await ref.read(notificationServiceProvider).markAllRead(token: token);
    await refresh();
    await ref.read(notificationSummaryProvider.notifier).refresh();
  }
}

/// Provider daftar notifikasi.
final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
      NotificationsNotifier.new,
    );

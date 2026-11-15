import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/notification_service.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';

/// Satu halaman hasil `GET /notifications` (backend mendukung pagination).
class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  /// Notifikasi yang sudah dimuat (akumulatif saat "Muat Lebih Banyak").
  final List<NotificationModel> items;

  /// Nomor halaman terakhir yang dimuat (dimulai dari 1).
  final int page;

  /// `true` bila server masih punya halaman berikutnya.
  final bool hasMore;
}

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
///
/// Mendukung pagination sederhana (backend mengirim `data.items` +
/// `data.pagination.hasNextPage`; di sini kita pakai panjang halaman).
class NotificationsNotifier extends AsyncNotifier<NotificationsPage> {
  static const int _pageSize = 50;

  bool _loadingMore = false;

  Future<NotificationsPage> _fetch(int page) async {
    final token = ref.read(authNotifierProvider.select((state) => state.token));

    if (token == null) {
      return const NotificationsPage(items: [], page: 1, hasMore: false);
    }

    final items = await ref
        .read(notificationServiceProvider)
        .list(token: token, page: page, limit: _pageSize);

    return NotificationsPage(
      items: items,
      page: page,
      hasMore: items.length >= _pageSize,
    );
  }

  @override
  Future<NotificationsPage> build() async {
    ref.watch(authNotifierProvider.select((state) => state.token));
    return _fetch(1);
  }

  /// Memuat ulang dari halaman pertama.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(1));
  }

  /// Menambahkan halaman berikutnya ke daftar (dipanggil "Muat Lebih Banyak").
  Future<void> loadMore() async {
    final current = state.value;

    if (_loadingMore || current == null || !current.hasMore) {
      return;
    }

    _loadingMore = true;
    try {
      final token = ref.read(
        authNotifierProvider.select((state) => state.token),
      );
      if (token == null) {
        return;
      }

      final more = await ref
          .read(notificationServiceProvider)
          .list(token: token, page: current.page + 1, limit: _pageSize);

      state = AsyncData(
        NotificationsPage(
          items: [...current.items, ...more],
          page: current.page + 1,
          hasMore: more.length >= _pageSize,
        ),
      );
    } catch (_) {
      // Muat-lebih gagal: biarkan daftar lama tetap tampil.
    } finally {
      _loadingMore = false;
    }
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

  /// Menghapus satu notifikasi lalu memuat ulang daftar & badge.
  Future<void> delete(String id) async {
    final token = ref.read(authNotifierProvider.select((state) => state.token));

    if (token == null) {
      return;
    }

    await ref.read(notificationServiceProvider).delete(token: token, id: id);
    await refresh();
    await ref.read(notificationSummaryProvider.notifier).refresh();
  }
}

/// Provider daftar notifikasi.
final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationsPage>(
      NotificationsNotifier.new,
    );

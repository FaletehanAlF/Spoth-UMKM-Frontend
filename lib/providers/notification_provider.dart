import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/notification_service.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';

class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  final List<NotificationModel> items;

  final int page;

  final bool hasMore;
}

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

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }
}

final notificationSummaryProvider =
    AsyncNotifierProvider<
      NotificationSummaryNotifier,
      NotificationSummaryModel?
    >(NotificationSummaryNotifier.new);

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

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(1));
  }

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
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> markAllRead() async {
    final token = ref.read(authNotifierProvider.select((state) => state.token));

    if (token == null) {
      return;
    }

    await ref.read(notificationServiceProvider).markAllRead(token: token);
    await ref.read(notificationSummaryProvider.notifier).refresh();
  }

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

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationsPage>(
      NotificationsNotifier.new,
    );

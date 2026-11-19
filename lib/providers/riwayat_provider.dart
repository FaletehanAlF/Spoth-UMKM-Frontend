import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/services/booking_service.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';
import 'booking_provider.dart';

abstract class RiwayatSeenStore {
  Future<Set<String>> read(String key);

  Future<void> write(String key, Set<String> ids);
}

class SecureRiwayatSeenStore implements RiwayatSeenStore {
  SecureRiwayatSeenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<Set<String>> read(String key) async {
    try {
      final raw = await _storage.read(key: key);
      if (raw == null || raw.isEmpty) {
        return <String>{};
      }
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toSet();
      }
      return <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  @override
  Future<void> write(String key, Set<String> ids) async {
    try {
      await _storage.write(key: key, value: jsonEncode(ids.toList()));
    } catch (_) {}
  }
}

class MemoryRiwayatSeenStore implements RiwayatSeenStore {
  final Map<String, Set<String>> _data = <String, Set<String>>{};

  @override
  Future<Set<String>> read(String key) async =>
      Set<String>.from(_data[key] ?? <String>{});

  @override
  Future<void> write(String key, Set<String> ids) async {
    _data[key] = Set<String>.from(ids);
  }
}

final riwayatSeenStoreProvider = Provider<RiwayatSeenStore>((ref) {
  return SecureRiwayatSeenStore();
});

class RiwayatBadgeNotifier extends AsyncNotifier<int> {
  String _keyFor(UserModel? user) {
    final role = user?.role == UserModel.roleHost ? 'host' : 'tenant';
    final id = user?.id ?? 'anon';
    return 'riwayat_seen_${role}_$id';
  }

  @override
  Future<int> build() async {
    final token = ref.watch(
      authNotifierProvider.select((state) => state.token),
    );
    if (token == null) {
      return 0;
    }

    final bookingsAsync = ref.watch(bookingsProvider);
    final bookings = bookingsAsync.value ?? const <BookingModel>[];
    final user = ref.read(authNotifierProvider).user;
    final lunas = bookings.where((b) => b.status == 'LUNAS').toList();

    final store = ref.read(riwayatSeenStoreProvider);
    final key = _keyFor(user);
    final seen = await store.read(key);

    if (seen.isEmpty && lunas.isNotEmpty) {
      await store.write(key, lunas.map((b) => b.id).toSet());
      return 0;
    }

    return lunas.where((b) => !seen.contains(b.id)).length;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(build);
  }

  Future<void> markAllSeen() async {
    final token = ref.read(authNotifierProvider.select((state) => state.token));
    if (token == null) {
      return;
    }

    final user = ref.read(authNotifierProvider).user;
    final bookings = ref.read(bookingsProvider).value;
    final lunas = (bookings ?? const <BookingModel>[])
        .where((b) => b.status == 'LUNAS')
        .toList();

    List<BookingModel> source = lunas;
    if (source.isEmpty) {
      try {
        final fetched = await ref
            .read(bookingServiceProvider)
            .listBookings(token: token);
        source = fetched.where((b) => b.status == 'LUNAS').toList();
      } catch (_) {
        source = const <BookingModel>[];
      }
    }

    final store = ref.read(riwayatSeenStoreProvider);
    final key = _keyFor(user);
    final seen = await store.read(key);
    seen.addAll(source.map((b) => b.id));
    await store.write(key, seen);

    state = const AsyncData(0);
  }
}

final riwayatBadgeProvider = AsyncNotifierProvider<RiwayatBadgeNotifier, int>(
  RiwayatBadgeNotifier.new,
);

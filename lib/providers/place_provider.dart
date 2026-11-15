import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/place_service.dart';
import '../models/place_model.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

/// State pencarian tempat untuk Penyewa (kata kunci + kategori aktif).
class TenantSearchState {
  const TenantSearchState({this.keyword = '', this.kategori});

  final String keyword;
  final String? kategori;
}

/// Menyimpan filter pencarian. Perubahannya otomatis memuat ulang
/// daftar tempat karena [TenantPlacesNotifier] mengawasi provider ini.
class TenantSearchNotifier extends Notifier<TenantSearchState> {
  @override
  TenantSearchState build() => const TenantSearchState();

  void setKeyword(String value) {
    state = TenantSearchState(keyword: value, kategori: state.kategori);
  }

  void setKategori(String? kategori) {
    state = TenantSearchState(keyword: state.keyword, kategori: kategori);
  }
}

/// Provider filter pencarian Penyewa.
final tenantSearchProvider =
    NotifierProvider<TenantSearchNotifier, TenantSearchState>(
      TenantSearchNotifier.new,
    );

/// Daftar tempat berstatus AKTIF untuk Penyewa (`GET /places`, publik).
class TenantPlacesNotifier extends AsyncNotifier<List<PlaceModel>> {
  Future<List<PlaceModel>> _fetch() {
    final search = ref.read(tenantSearchProvider);
    final keyword = search.keyword.trim();

    return ref
        .read(placeServiceProvider)
        .searchPlaces(
          keyword: keyword.isEmpty ? null : keyword,
          kategori: search.kategori,
        );
  }

  @override
  Future<List<PlaceModel>> build() async {
    // Memuat ulang otomatis saat filter pencarian atau sesi berubah.
    ref.watch(tenantSearchProvider);
    ref.watch(authNotifierProvider.select((state) => state.token));

    return _fetch();
  }

  /// Memuat ulang daftar secara manual (tarik-untuk-memuat).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

/// Provider daftar tempat untuk Penyewa.
final tenantPlacesProvider =
    AsyncNotifierProvider<TenantPlacesNotifier, List<PlaceModel>>(
      TenantPlacesNotifier.new,
    );

/// Daftar tempat milik Host yang sedang login (`GET /places/mine`).
class MyPlacesNotifier extends AsyncNotifier<List<PlaceModel>> {
  Future<List<PlaceModel>> _fetch() {
    final token = ref.read(authNotifierProvider.select((state) => state.token));

    if (token == null) {
      return Future.value(const <PlaceModel>[]);
    }

    return ref.read(placeServiceProvider).getMyPlaces(token: token);
  }

  @override
  Future<List<PlaceModel>> build() async {
    // Hanya Host yang memuat daftar tempat miliknya (pembatasan role).
    ref.watch(authNotifierProvider.select((state) => state.user?.role));

    final user = ref.read(authNotifierProvider.select((state) => state.user));
    if (user?.role != UserModel.roleHost) {
      return const <PlaceModel>[];
    }

    return _fetch();
  }

  /// Memuat ulang daftar tempat milik Host.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

/// Provider daftar tempat milik Host.
final myPlacesProvider =
    AsyncNotifierProvider<MyPlacesNotifier, List<PlaceModel>>(
      MyPlacesNotifier.new,
    );

/// Ringkasan dashboard Host (`GET /places/mine/summary`).
/// Bernilai `null` bila pengguna bukan Host (tidak memanggil API sama sekali).
class HostSummaryNotifier extends AsyncNotifier<PlaceSummaryModel?> {
  Future<PlaceSummaryModel?> _fetch() async {
    final user = ref.read(authNotifierProvider.select((state) => state.user));
    final token = ref.read(authNotifierProvider.select((state) => state.token));

    if (user?.role != UserModel.roleHost || token == null) {
      return null;
    }

    return ref.read(placeServiceProvider).getHostSummary(token: token);
  }

  @override
  Future<PlaceSummaryModel?> build() async {
    ref.watch(authNotifierProvider.select((state) => state.user?.role));
    return _fetch();
  }

  /// Memuat ulang ringkasan dashboard.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

/// Provider ringkasan dashboard Host.
final hostSummaryProvider =
    AsyncNotifierProvider<HostSummaryNotifier, PlaceSummaryModel?>(
      HostSummaryNotifier.new,
    );

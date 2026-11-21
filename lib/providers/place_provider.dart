import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/place_service.dart';
import '../models/place_model.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

class TenantSearchState {
  const TenantSearchState({this.keyword = '', this.kategori});

  final String keyword;
  final String? kategori;
}

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

final tenantSearchProvider =
    NotifierProvider<TenantSearchNotifier, TenantSearchState>(
      TenantSearchNotifier.new,
    );

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
    ref.watch(tenantSearchProvider);
    ref.watch(authNotifierProvider.select((state) => state.token));

    return _fetch();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final tenantPlacesProvider =
    AsyncNotifierProvider<TenantPlacesNotifier, List<PlaceModel>>(
      TenantPlacesNotifier.new,
    );

class OwnerPlacesFilter {
  const OwnerPlacesFilter({this.keyword = ''});

  final String keyword;
}

class OwnerPlacesFilterNotifier extends Notifier<OwnerPlacesFilter> {
  @override
  OwnerPlacesFilter build() => const OwnerPlacesFilter();

  void setKeyword(String keyword) {
    state = OwnerPlacesFilter(keyword: keyword);
  }
}

final ownerPlacesFilterProvider =
    NotifierProvider<OwnerPlacesFilterNotifier, OwnerPlacesFilter>(
      OwnerPlacesFilterNotifier.new,
    );

class MyPlacesNotifier extends AsyncNotifier<List<PlaceModel>> {
  Future<List<PlaceModel>> _fetch() {
    final token = ref.read(authNotifierProvider.select((state) => state.token));

    if (token == null) {
      return Future.value(const <PlaceModel>[]);
    }

    final filter = ref.read(ownerPlacesFilterProvider);

    return ref
        .read(placeServiceProvider)
        .getMyPlaces(
          token: token,
          keyword: filter.keyword.trim().isEmpty ? null : filter.keyword.trim(),
        );
  }

  @override
  Future<List<PlaceModel>> build() async {
    ref.watch(authNotifierProvider.select((state) => state.user?.role));

    ref.watch(ownerPlacesFilterProvider);

    final user = ref.read(authNotifierProvider.select((state) => state.user));
    if (user?.role != UserModel.roleHost) {
      return const <PlaceModel>[];
    }

    return _fetch();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final myPlacesProvider =
    AsyncNotifierProvider<MyPlacesNotifier, List<PlaceModel>>(
      MyPlacesNotifier.new,
    );

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

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final hostSummaryProvider =
    AsyncNotifierProvider<HostSummaryNotifier, PlaceSummaryModel?>(
      HostSummaryNotifier.new,
    );

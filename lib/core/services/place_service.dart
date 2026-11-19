import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/availability_model.dart';
import '../../models/category_model.dart';
import '../../models/place_model.dart';
import 'api_service.dart';

final placeServiceProvider = Provider<PlaceService>((ref) {
  return PlaceService(ref.watch(apiServiceProvider));
});

class PlaceService {
  PlaceService(this._apiService);

  final ApiService _apiService;

  String _query(Map<String, String?> params) {
    final entries = <String, String>{};
    params.forEach((key, value) {
      if (value != null && value.isNotEmpty) {
        entries[key] = value;
      }
    });

    final query = Uri(queryParameters: entries).query;
    return query.isEmpty ? '' : '?$query';
  }

  List<PlaceModel> _placeList(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    final items = data?['items'] as List<dynamic>?;

    if (items == null) {
      throw const FormatException('Respons daftar tempat tidak valid');
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(PlaceModel.fromJson)
        .toList();
  }

  PlaceModel _place(Map<String, dynamic> body, String label) {
    final data = body['data'] as Map<String, dynamic>?;
    final place = data?['place'] as Map<String, dynamic>?;

    if (place == null) {
      throw FormatException('Respons $label tempat tidak valid');
    }

    return PlaceModel.fromJson(place);
  }

  Future<List<PlaceModel>> searchPlaces({
    String? token,
    String? keyword,
    String? kategori,
    int page = 1,
    int limit = 20,
  }) async {
    final body = await _apiService.get(
      '/places${_query({'keyword': keyword, 'kategori': kategori, 'page': '$page', 'limit': '$limit'})}',
      token: token,
    );

    return _placeList(body);
  }

  Future<PlaceModel> getPlaceDetail({required String id, String? token}) async {
    final body = await _apiService.get('/places/$id', token: token);
    return _place(body, 'detail');
  }

  Future<List<PlaceModel>> getMyPlaces({
    required String token,
    String? keyword,
    String? status,
    int limit = 50,
  }) async {
    final body = await _apiService.get(
      '/places/mine${_query({'keyword': keyword, 'status': status, 'page': '1', 'limit': '$limit'})}',
      token: token,
    );

    return _placeList(body);
  }

  Future<PlaceSummaryModel> getHostSummary({required String token}) async {
    final body = await _apiService.get('/places/mine/summary', token: token);
    final data = body['data'] as Map<String, dynamic>?;
    final ringkasan = data?['ringkasan'] as Map<String, dynamic>?;

    if (ringkasan == null) {
      throw const FormatException('Respons ringkasan tidak valid');
    }

    return PlaceSummaryModel.fromJson(ringkasan);
  }

  Future<List<CategoryModel>> listCategories() async {
    final body = await _apiService.get('/categories');
    final data = body['data'] as Map<String, dynamic>?;
    final categories = data?['categories'] as List<dynamic>?;
    if (categories == null) {
      throw const FormatException('Respons daftar kategori tidak valid');
    }
    return categories.whereType<Map<String, dynamic>>().map(CategoryModel.fromJson).toList();
  }

  Future<PlaceModel> createPlace({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final body = await _apiService.post('/places', payload, token: token);
    return _place(body, 'tambah');
  }

  Future<PlaceModel> updatePlace({
    required String token,
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    final body = await _apiService.patch('/places/$id', payload, token: token);
    return _place(body, 'ubah');
  }

  Future<void> deletePlace({required String token, required String id}) async {
    await _apiService.delete('/places/$id', token: token);
  }

  Future<List<AvailabilityRuleModel>> getAvailabilityRules({
    required String placeId,
    String? token,
  }) async {
    final body = await _apiService.get(
      '/places/$placeId/availability-rules',
      token: token,
    );
    final data = body['data'] as Map<String, dynamic>?;
    final items = data?['rules'] as List<dynamic>?;

    if (items == null) {
      throw const FormatException('Respons aturan ketersediaan tidak valid');
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(AvailabilityRuleModel.fromJson)
        .toList();
  }

  Future<AvailabilityRuleModel> createAvailabilityRule({
    required String token,
    required String placeId,
    required Map<String, dynamic> payload,
  }) async {
    final body = await _apiService.post(
      '/places/$placeId/availability-rules',
      payload,
      token: token,
    );
    return _availabilityRule(body, 'tambah');
  }

  Future<AvailabilityRuleModel> updateAvailabilityRule({
    required String token,
    required String placeId,
    required String ruleId,
    required Map<String, dynamic> payload,
  }) async {
    final body = await _apiService.patch(
      '/places/$placeId/availability-rules/$ruleId',
      payload,
      token: token,
    );
    return _availabilityRule(body, 'ubah');
  }

  Future<void> deleteAvailabilityRule({
    required String token,
    required String placeId,
    required String ruleId,
  }) async {
    await _apiService.delete(
      '/places/$placeId/availability-rules/$ruleId',
      token: token,
    );
  }

  Future<PlaceAvailabilityModel> checkAvailability({
    required String placeId,
    required String tanggalMulai,
    required int jumlahDurasi,
    String? token,
  }) async {
    final body = await _apiService.get(
      '/places/$placeId/availability${_query({'tanggal_mulai': tanggalMulai, 'jumlah_durasi': '$jumlahDurasi'})}',
      token: token,
    );
    final data = body['data'] as Map<String, dynamic>?;
    final ketersediaan = data?['ketersediaan'] as Map<String, dynamic>?;

    if (ketersediaan == null) {
      throw const FormatException('Respons ketersediaan tidak valid');
    }

    return PlaceAvailabilityModel.fromJson(ketersediaan);
  }

  AvailabilityRuleModel _availabilityRule(
    Map<String, dynamic> body,
    String label,
  ) {
    final data = body['data'] as Map<String, dynamic>?;
    final rule = data?['rule'] as Map<String, dynamic>?;

    if (rule == null) {
      throw FormatException('Respons $label aturan ketersediaan tidak valid');
    }

    return AvailabilityRuleModel.fromJson(rule);
  }
}

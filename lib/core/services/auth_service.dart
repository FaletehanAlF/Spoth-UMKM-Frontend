import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import 'api_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiServiceProvider));
});

class AuthService {
  AuthService(this._apiService);

  final ApiService _apiService;

  Future<UserModel> register({
    required String nama,
    required String email,
    required String password,
    String? noHp,
    required String role,
  }) async {
    final body = await _apiService.post('/auth/register', {
      'nama': nama,
      'email': email,
      'password': password,
      if (noHp != null && noHp.isNotEmpty) 'no_hp': noHp,
      'role': role,
    });

    return UserModel.fromJson(_userJson(body));
  }

  Future<({String token, UserModel user})> login({
    required String email,
    required String password,
  }) async {
    final body = await _apiService.post('/auth/login', {
      'email': email,
      'password': password,
    });

    final data = body['data'] as Map<String, dynamic>?;
    final token = data?['token'] as String?;

    if (token == null) {
      throw const FormatException('Respons login tidak berisi token');
    }

    return (token: token, user: UserModel.fromJson(_userJson(body)));
  }

  Future<void> logout({required String token}) async {
    await _apiService.post('/auth/logout', {}, token: token);
  }

  Future<UserModel> getCurrentUser({required String token}) async {
    final body = await _apiService.get('/users/me', token: token);

    return UserModel.fromJson(_userJson(body));
  }

  Map<String, dynamic> _userJson(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    final user = data?['user'] as Map<String, dynamic>?;

    if (user == null) {
      throw const FormatException('Respons tidak berisi data user');
    }

    return user;
  }
}

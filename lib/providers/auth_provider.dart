import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/services/api_service.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.token,
    this.isLoading = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? errorMessage;
}

class AuthNotifier extends Notifier<AuthState> {
  static const String _tokenKey = 'jwt_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  AuthState build() => const AuthState();

  AuthService get _authService => ref.read(authServiceProvider);

  Future<bool> restoreSession() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return false;
    }

    try {
      final user = await _authService.getCurrentUser(token: token);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        token: token,
      );
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _storage.delete(key: _tokenKey);
      }
      state = const AuthState(status: AuthStatus.unauthenticated);
      return false;
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return false;
    }
  }

  Future<bool> register({
    required String nama,
    required String email,
    required String password,
    String? noHp,
    required String role,
  }) async {
    state = const AuthState(isLoading: true);

    try {
      await _authService.register(
        nama: nama,
        email: email,
        password: password,
        noHp: noHp,
        role: role,
      );
      state = const AuthState(status: AuthStatus.unauthenticated);
      return true;
    } catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = const AuthState(isLoading: true);

    try {
      final result = await _authService.login(email: email, password: password);
      await _storage.write(key: _tokenKey, value: result.token);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
        token: result.token,
      );
      return true;
    } catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<void> logout() async {
    final token = state.token ?? await _storage.read(key: _tokenKey);

    if (token != null) {
      try {
        await _authService.logout(token: token);
      } catch (_) {}
    }

    await _storage.delete(key: _tokenKey);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 400 &&
          error.errors != null &&
          error.errors!.isNotEmpty) {
        final details = error.errors!
            .map(
              (item) => item is Map
                  ? '${item['field']}: ${item['message']}'
                  : item.toString(),
            )
            .join('; ');
        return '${error.message} ($details)';
      }

      switch (error.statusCode) {
        case 401:
          return error.message;
        case 408:
          return 'Permintaan melebihi batas waktu. Periksa koneksi internet Anda.';
        case 409:
          return error.message;
        case 429:
          return 'Terlalu banyak percobaan. Silakan coba lagi beberapa menit lagi.';
        default:
          return error.message;
      }
    }

    if (error is TimeoutException) {
      return 'Permintaan melebihi batas waktu. Periksa koneksi internet Anda.';
    }

    if (error is FormatException) {
      return 'Respons dari server tidak valid';
    }

    return 'Terjadi kesalahan. Periksa koneksi internet Anda';
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

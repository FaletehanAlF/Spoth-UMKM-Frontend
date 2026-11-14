import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/services/api_service.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

/// Status autentikasi pengguna.
enum AuthStatus {
  /// Belum diperiksa (misalnya token belum dibaca dari secure storage).
  unknown,
  authenticated,
  unauthenticated,
}

/// State authentication yang dibaca oleh UI.
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

/// Notifier yang mengelola autentikasi:
///
/// - Membaca/menulis token JWT ke `flutter_secure_storage`
/// - Memanggil `AuthService` untuk bicara dengan backend
/// - Menyediakan state user + token + status loading/error untuk UI
class AuthNotifier extends Notifier<AuthState> {
  static const String _tokenKey = 'jwt_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  AuthState build() => const AuthState();

  AuthService get _authService => ref.read(authServiceProvider);

  /// Memulihkan sesi dari secure storage saat aplikasi dibuka.
  Future<void> restoreSession() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final user = await _authService.getCurrentUser(token: token);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        token: token,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        // Token kedaluwarsa/tidak valid → hapus agar bersih.
        await _storage.delete(key: _tokenKey);
      }
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (_) {
      // Error jaringan dll.: token dibiarkan, dicoba lagi saat app dibuka.
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Registrasi. Mengembalikan `true` bila berhasil.
  /// Tidak ada token yang tersimpan; user perlu login setelah registrasi.
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

  /// Login. Mengembalikan `true` bila berhasil dan menyimpan token JWT.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
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

  /// Logout: hapus token lokal. Kegagalan memanggil endpoint logout
  /// diabaikan agar user tetap bisa keluar dari aplikasi.
  Future<void> logout() async {
    final token = state.token ?? await _storage.read(key: _tokenKey);

    if (token != null) {
      try {
        await _authService.logout(token: token);
      } catch (_) {
        // Token lokal tetap dihapus meski server tidak terjangkau.
      }
    }

    await _storage.delete(key: _tokenKey);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Mengambil pesan error yang mudah dibaca dari error backend.
  /// Menangani HTTP 400 (validasi), 401 (autentikasi), 409 (konflik email),
  /// dan 429 (terlalu banyak percobaan).
  String _errorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 400 &&
          error.errors != null &&
          error.errors!.isNotEmpty) {
        final details = error.errors!
            .map((item) => item is Map ? '${item['field']}: ${item['message']}' : item.toString())
            .join('; ');
        return '${error.message} ($details)';
      }

      switch (error.statusCode) {
        case 401:
          // Contoh backend: "Email atau password salah" / "Token sudah kedaluwarsa".
          return error.message;
        case 409:
          // Contoh backend: "Email sudah dipakai".
          return error.message;
        case 429:
          return 'Terlalu banyak percobaan. Silakan coba lagi beberapa menit lagi.';
        default:
          return error.message;
      }
    }

    if (error is FormatException) {
      return 'Respons dari server tidak valid';
    }

    return 'Terjadi kesalahan. Periksa koneksi internet Anda';
  }
}

/// Provider state authentication.
final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

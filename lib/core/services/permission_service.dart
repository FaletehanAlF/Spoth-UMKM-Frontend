import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

/// Helper untuk mengirim izin permukaan, mengikuti pola dari dokumentasi
/// guru (https://divdannn.medium.com/permission-di-flutter-kamera-
/// lokasi-kontak-penyimpanan-dan-lainnya-43cbe485f0a3) — kita hanya
/// implementasi yang diperlukan: **Kamera** & **Galeri (foto tempat)**.
/// Lokasi / Kontak / Mikrofon tidak dipakai oleh aplikasi SPOTH UMKM,
/// jadi tidak disesuaikan.
///
/// Di Web `image_picker` melakukan file picker sendiri, jadi tanpa
/// permission di sini tetap boleh.
class PermissionService {
  PermissionService._();

  /// Memastikan izin **Kamera** di-grant sebelum pemakai
  /// mengambil foto lewat `pickImage(source: ImageSource.camera)`.
  static Future<bool> ensureCameraPermission() async {
    if (kIsWeb) return true;

    final status = await Permission.camera.status;
    if (status.isGranted || status.isLimited) return true;

    return (await Permission.camera.request()).isGranted;
  }

  /// Memastikan akses **Galeri** (image picker) menurut platform.
  ///
  /// - Android 13+ (`compileSdk = 37`): request `Permission.photos`
  ///   (READ_MEDIA_IMAGES, sudah ditambahkan di `AndroidManifest.xml`).
  /// - Android ≤12: `Permission.storage` — `image_picker` pakai
  ///   Storage Access Framework, jadigallery bisa dipakai tanpa
  ///   storage permission.
  /// - Web/Windows: asumsi boleh (platform-specific picker).
  static Future<bool> ensureGalleryPermission() async {
    if (kIsWeb) return true;

    final status = await Permission.photos.status;
    if (status.isGranted || status.isLimited) return true;

    final result = await Permission.photos.request();
    return result.isGranted || result.isLimited;
  }

  /// Membuka aplikasi Settings saat pengguna menolak permanen
  /// (kategori dari guru: `isPermanentlyDenied` → `openAppSettings()`).
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

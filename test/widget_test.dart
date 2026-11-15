// Smoke test dan uji layout responsif aplikasi SPOTH UMKM.
//
// Semua dependensi jaringan diganti dengan service palsu (fake) sehingga
// `flutter test` TIDAK pernah mengirim request HTTP ke backend. Data yang
// tampil di layar berasal dari fixture di file ini.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'package:spoth_umkm/core/services/api_service.dart';
import 'package:spoth_umkm/core/services/booking_service.dart';
import 'package:spoth_umkm/core/services/notification_service.dart';
import 'package:spoth_umkm/core/services/place_service.dart';
import 'package:spoth_umkm/core/services/upload_service.dart';
import 'package:spoth_umkm/main.dart';
import 'package:spoth_umkm/models/booking_model.dart';
import 'package:spoth_umkm/models/notification_model.dart';
import 'package:spoth_umkm/models/place_model.dart';
import 'package:spoth_umkm/models/user_model.dart';
import 'package:spoth_umkm/providers/auth_provider.dart';
import 'package:spoth_umkm/screens/auth/login_screen.dart';
import 'package:spoth_umkm/screens/auth/register_screen.dart';
import 'package:spoth_umkm/screens/home/home_screen.dart';
import 'package:spoth_umkm/screens/main/main_shell.dart';
import 'package:spoth_umkm/screens/notification/notification_screen.dart';
import 'package:spoth_umkm/screens/onboarding/onboarding_screen.dart';
import 'package:spoth_umkm/screens/place/place_detail_screen.dart';
import 'package:spoth_umkm/screens/place/tempat_screen.dart';
import 'package:spoth_umkm/screens/place/place_form_screen.dart';

/// Ukuran layar yang diuji (devicePixelRatio 1.0):
/// smartphone kecil, standar, besar, tablet portrait,
/// smartphone landscape, dan tablet landscape.
const List<Size> _screenSizes = [
  Size(320, 480),
  Size(360, 800),
  Size(412, 915),
  Size(800, 1280),
  Size(800, 360),
  Size(1280, 800),
];

// ---------------------------------------------------------------------------
// Data fixture (bentuk JSON persis seperti respons backend).
// ---------------------------------------------------------------------------

/// Penyewa (TENANT) contoh.
UserModel _tenantUser() => UserModel(
  id: '10',
  nama: 'Budi Santoso',
  email: 'budi@contoh.test',
  noHp: '081234567890',
  role: UserModel.roleTenant,
  createdAt: DateTime(2026, 1, 15),
);

/// User dengan role yang TIDAK dikenali backend (skenario error).
UserModel _userRoleAneh() => UserModel(
  id: '30',
  nama: 'Ratu Aneh',
  email: 'aneh@contoh.test',
  noHp: '081234567892',
  role: 'MAJELIS',
  createdAt: DateTime(2026, 3, 1),
);

/// Pemilik (HOST) contoh.
UserModel _hostUser() => UserModel(
  id: '20',
  nama: 'Sari Dewi',
  email: 'sari@contoh.test',
  noHp: '081234567891',
  role: UserModel.roleHost,
  createdAt: DateTime(2026, 2, 10),
);

/// Tempat yang dilihat/dipilih Penyewa.
const PlaceModel _tempatPenyewa1 = PlaceModel(
  id: '101',
  hostId: '20',
  namaTempat: 'Lapak Kuliner Baru',
  kategori: 'LAPAK_USAHA',
  alamat: 'Jl. Merdeka 12',
  kota: 'Bandung',
  hargaNormal: 250000,
  hargaPromo: 200000,
  hargaEfektif: 200000,
  tipeDurasi: 'HARIAN',
  status: 'AKTIF',
  namaHost: 'Sari Dewi',
);

/// Tempat kedua untuk daftar Penyewa.
const PlaceModel _tempatPenyewa2 = PlaceModel(
  id: '102',
  hostId: '20',
  namaTempat: 'Booth Bazar Sekolah',
  kategori: 'BOOTH_EVENT',
  alamat: 'Jl. Kenanga 5',
  kota: 'Bandung',
  hargaNormal: 150000,
  hargaEfektif: 150000,
  tipeDurasi: 'HARIAN',
  status: 'AKTIF',
  namaHost: 'Sari Dewi',
);

/// Detail tempat (memuat fasilitas, aturan, dan jadwal terpakai).
PlaceModel _tempatDetail() => PlaceModel(
  id: '101',
  hostId: '20',
  namaTempat: 'Lapak Kuliner Baru',
  kategori: 'LAPAK_USAHA',
  deskripsi: 'Lapak strategis di pasar',
  alamat: 'Jl. Merdeka 12',
  kota: 'Bandung',
  fasilitas: 'Listrik, Kipas',
  aturan: 'Tutup pukul 21.00',
  hargaNormal: 250000,
  hargaPromo: 200000,
  hargaEfektif: 200000,
  tipeDurasi: 'HARIAN',
  status: 'AKTIF',
  namaHost: 'Sari Dewi',
  foto: const [
    'https://cdn.example.test/a.jpg',
    'https://cdn.example.test/b.jpg',
  ],
  jadwalTerpakai: [
    BookedRange(
      tanggalMulai: '2026-11-20',
      tanggalSelesai: '2026-11-21',
      status: 'LUNAS',
    ),
  ],
);

/// Tempat milik Pemilik (HOST).
const PlaceModel _tempatMilikHost = PlaceModel(
  id: '201',
  hostId: '20',
  namaTempat: 'Teras Dagang Pagi',
  kategori: 'TERAS_KOMERSIAL',
  alamat: 'Jl. Cendana 9',
  kota: 'Bandung',
  hargaNormal: 300000,
  hargaEfektif: 300000,
  tipeDurasi: 'BULANAN',
  status: 'AKTIF',
);

BookingModel _booking({
  required String id,
  required String status,
  required String namaTempat,
  required String namaTenant,
}) => BookingModel(
  id: id,
  kodeBooking: 'SPT-$id',
  placeId: '101',
  tenantId: '10',
  jenisUsaha: 'Warung Makan',
  tanggalMulai: '2026-11-20',
  tanggalSelesai: '2026-11-22',
  jumlahDurasi: 3,
  hargaSatuan: 200000,
  totalHarga: 600000,
  status: status,
  namaTempat: namaTempat,
  namaTenant: namaTenant,
  kota: 'Bandung',
);

NotificationModel _notifikasi({
  required String judul,
  required String pesan,
  required bool dibaca,
}) => NotificationModel(
  id: judul,
  judul: judul,
  pesan: pesan,
  dibaca: dibaca,
  createdAt: DateTime(2026, 11, 12, 9, 30),
);

// ---------------------------------------------------------------------------
// Service & notifier palsu (tidak menyentuh jaringan sama sekali).
// ---------------------------------------------------------------------------

/// Auth palsu: selalu ter-authenticated dengan user yang diberikan.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._user);

  final UserModel _user;

  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: _user,
    token: 'fake-token',
  );
}

/// Auth palsu: authenticated tetapi TANPA data user (role null).
class _FakeAuthNoUserNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

/// PlaceService palsu: mengembalikan data fixture.
class _FakePlaceService extends PlaceService {
  _FakePlaceService() : super(ApiService());

  /// Payload terakhir create/update — dipakai test untuk memeriksa
  /// kontrak request (mis. harga promo null vs key di-omit).
  Map<String, dynamic>? lastCreatePayload;
  Map<String, dynamic>? lastUpdatePayload;

  @override
  Future<List<PlaceModel>> searchPlaces({
    String? token,
    String? keyword,
    String? kategori,
    int page = 1,
    int limit = 20,
  }) async => const [_tempatPenyewa1, _tempatPenyewa2];

  @override
  Future<PlaceModel> getPlaceDetail({
    required String id,
    String? token,
  }) async => _tempatDetail();

  @override
  Future<List<PlaceModel>> getMyPlaces({
    required String token,
    String? keyword,
    String? status,
    int limit = 50,
  }) async => const [_tempatMilikHost];

  @override
  Future<PlaceSummaryModel> getHostSummary({required String token}) async =>
      const PlaceSummaryModel(
        totalTempat: 2,
        tempatAktif: 1,
        totalPemesanan: 5,
        pemesananMenunggu: 1,
        pemesananLunas: 3,
        totalPendapatan: 750000,
        totalKomisi: 75000,
      );

  @override
  Future<PlaceModel> createPlace({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    lastCreatePayload = payload;
    return _tempatDetail();
  }

  @override
  Future<PlaceModel> updatePlace({
    required String token,
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    lastUpdatePayload = payload;
    return _tempatDetail();
  }
}

/// UploadService palsu: mencatat jumlah upload, mengembalikan URL fixture.
class _FakeUploadService extends UploadService {
  _FakeUploadService() : super(http.Client());

  int callCount = 0;
  final List<String> uploadedFiles = [];

  @override
  Future<UploadResult> uploadPhoto({
    required String token,
    required String filename,
    required List<int> bytes,
    String? mimeType,
  }) async {
    callCount += 1;
    uploadedFiles.add(filename);
    return UploadResult(
      secureUrl: 'https://cdn.example.test/${callCount}_$filename',
      publicId: 'public_$callCount',
    );
  }
}

/// NotificationService palsu: mengembalikan data fixture.
class _FakeNotificationService extends NotificationService {
  _FakeNotificationService() : super(ApiService());

  @override
  Future<List<NotificationModel>> list({
    required String token,
    bool unreadOnly = false,
    int page = 1,
    int limit = 50,
  }) async => [
    _notifikasi(
      judul: 'Pemesanan diterima',
      pesan: 'Penyewaan Anda berhasil dibuat, menunggu pembayaran.',
      dibaca: false,
    ),
    _notifikasi(
      judul: 'Pembayaran diterima',
      pesan: 'Pembayaran penyewaan telah dikonfirmasi.',
      dibaca: true,
    ),
  ];

  @override
  Future<NotificationSummaryModel> summary({required String token}) async =>
      const NotificationSummaryModel(total: 2, belumDibaca: 1);
}

/// BookingService palsu: mengembalikan riwayat fixture.
class _FakeBookingService extends BookingService {
  _FakeBookingService() : super(ApiService());

  @override
  Future<List<BookingModel>> listBookings({
    required String token,
    String? status,
    int limit = 50,
  }) async => [
    _booking(
      id: '301',
      status: 'MENUNGGU_PEMBAYARAN',
      namaTempat: 'Lapak Kuliner Baru',
      namaTenant: 'Budi Santoso',
    ),
    _booking(
      id: '302',
      status: 'LUNAS',
      namaTempat: 'Booth Bazar Sekolah',
      namaTenant: 'Budi Santoso',
    ),
  ];
}

/// MaterialApp + ProviderScope dengan auth & service palsu (Penyewa).
Widget _tenantApp(Widget home) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(() => _FakeAuthNotifier(_tenantUser())),
    placeServiceProvider.overrideWithValue(_FakePlaceService()),
    notificationServiceProvider.overrideWithValue(_FakeNotificationService()),
    bookingServiceProvider.overrideWithValue(_FakeBookingService()),
  ],
  child: MaterialApp(home: home),
);

/// MaterialApp + ProviderScope dengan auth & service palsu (Pemilik).
Widget _hostApp(Widget home) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(() => _FakeAuthNotifier(_hostUser())),
    placeServiceProvider.overrideWithValue(_FakePlaceService()),
    notificationServiceProvider.overrideWithValue(_FakeNotificationService()),
    bookingServiceProvider.overrideWithValue(_FakeBookingService()),
  ],
  child: MaterialApp(home: home),
);

// ---------------------------------------------------------------------------
// Helper pump.
// ---------------------------------------------------------------------------

/// Mem-pump [create] pada setiap ukuran di [_screenSizes] dan memastikan
/// tidak ada layout error (termasuk RenderFlex overflow).
Future<void> _pumpOnAllSizes(
  WidgetTester tester,
  Widget Function() create,
) async {
  for (final size in _screenSizes) {
    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = size;

    await tester.pumpWidget(create());
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason: 'Layout error pada ukuran ${size.width}x${size.height}',
    );

    tester.view.reset();
  }
}

/// Mem-pump halaman dengan auth/service palsu pada satu ukuran layar
/// (default 412x915). Set [host] `true` untuk skenario Pemilik.
Future<void> _pumpSized(
  WidgetTester tester,
  Widget home, {
  bool host = false,
  Size size = const Size(412, 915),
}) async {
  tester.view
    ..devicePixelRatio = 1.0
    ..physicalSize = size;

  await tester.pumpWidget(host ? _hostApp(home) : _tenantApp(home));
  await tester.pumpAndSettle();
}

/// Mem-pump MaterialApp.router dengan service palsu Pemilik — dipakai test
/// form tempat yang memanggil `context.pop` (butuh GoRouter) dan butuh
/// akses ke [_FakePlaceService] untuk memeriksa payload yang dikirim.
/// Set [fakeUpload] untuk juga mengganti UploadService.
Future<void> _pumpFormRouter(
  WidgetTester tester, {
  required GoRouter router,
  required _FakePlaceService fakePlace,
  _FakeUploadService? fakeUpload,
  Size size = const Size(800, 1500),
}) async {
  tester.view
    ..devicePixelRatio = 1.0
    ..physicalSize = size;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => _FakeAuthNotifier(_hostUser())),
        placeServiceProvider.overrideWithValue(fakePlace),
        notificationServiceProvider.overrideWithValue(
          _FakeNotificationService(),
        ),
        bookingServiceProvider.overrideWithValue(_FakeBookingService()),
        if (fakeUpload != null)
          uploadServiceProvider.overrideWithValue(fakeUpload),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Test.
// ---------------------------------------------------------------------------

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpothApp()));

    expect(find.text('SPOTH UMKM'), findsOneWidget);
  });

  testWidgets('Login layout tanpa overflow pada semua ukuran layar', (
    WidgetTester tester,
  ) async {
    await _pumpOnAllSizes(
      tester,
      () => ProviderScope(child: MaterialApp(home: const LoginScreen())),
    );
  });

  testWidgets('Register layout tanpa overflow pada semua ukuran layar', (
    WidgetTester tester,
  ) async {
    await _pumpOnAllSizes(
      tester,
      () => ProviderScope(child: MaterialApp(home: const RegisterScreen())),
    );
  });

  testWidgets('Onboarding layout tanpa overflow pada semua ukuran layar', (
    WidgetTester tester,
  ) async {
    await _pumpOnAllSizes(
      tester,
      () => MaterialApp(home: const OnboardingScreen()),
    );
  });

  testWidgets('Home penyewa tanpa overflow pada semua ukuran layar', (
    WidgetTester tester,
  ) async {
    await _pumpOnAllSizes(tester, () => _tenantApp(const HomeScreen()));
  });

  testWidgets('Main shell (bottom bar) tanpa overflow pada semua ukuran', (
    WidgetTester tester,
  ) async {
    await _pumpOnAllSizes(tester, () => _tenantApp(const MainShell()));
  });

  testWidgets('Home pemilik tanpa overflow pada semua ukuran layar', (
    WidgetTester tester,
  ) async {
    await _pumpOnAllSizes(tester, () => _hostApp(const HomeScreen()));
  });

  testWidgets('Home penyewa menampilkan headline dan preview tempat', (
    WidgetTester tester,
  ) async {
    await _pumpSized(tester, const HomeScreen());

    expect(find.textContaining('Tempat Usahamu'), findsOneWidget);

    // Daftar tempat berasal dari service palsu (bukan data dummy UI).
    expect(find.text('Lapak Kuliner Baru'), findsOneWidget);
    expect(find.text('Booth Bazar Sekolah'), findsOneWidget);
  });

  testWidgets(
    'Bottom bar berpindah antar tab Beranda, Tempat, Booking, Profil',
    (WidgetTester tester) async {
      await _pumpSized(tester, const MainShell());

      // Tab Tempat — katalog untuk Penyewa (pencarian + daftar).
      await tester.tap(find.text('Tempat'));
      await tester.pumpAndSettle();
      expect(find.text('Cari tempat, kota, atau lokasi...'), findsOneWidget);
      expect(find.text('Lapak Kuliner Baru'), findsOneWidget);

      // Tab Booking — judul dan isi sesuai role Penyewa.
      await tester.tap(find.text('Booking'));
      await tester.pumpAndSettle();
      expect(find.text('Penyewaan Saya'), findsOneWidget);
      // Jenis usaha tampil tergabung dengan kode booking pada setiap kartu.
      expect(find.textContaining('Warung Makan'), findsNWidgets(2));
      expect(find.text('Menunggu Bayar'), findsOneWidget);

      // Tab Profil — data akun dari auth state.
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      // Email tampil dua kali: di kartu kepala dan baris rincian Email.
      expect(find.text('budi@contoh.test'), findsNWidgets(2));
      expect(find.text('Keluar'), findsOneWidget);

      // Kembali ke Beranda.
      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tempat Usahamu'), findsOneWidget);
    },
  );

  testWidgets('Home pemilik menampilkan ringkasan dan daftar tempat miliknya', (
    WidgetTester tester,
  ) async {
    await _pumpSized(tester, const HomeScreen(), host: true);

    expect(find.text('SPOTH UMKM'), findsOneWidget);

    // Ringkasan dashboard dari GET /places/mine/summary (fixture).
    expect(find.text('Total Tempat'), findsOneWidget);
    expect(find.text('Tempat Aktif'), findsOneWidget);
    expect(find.text('Rp 750.000'), findsOneWidget);

    // Kartu ajakan ke tab Tempat — tombol tambah sudah dipindah ke tab Tempat.
    expect(find.text('Tempat Saya'), findsOneWidget);
    expect(find.text('Tambah Tempat'), findsNothing);
  });

  testWidgets('Tempat (pemilik) menampilkan daftar miliknya + tombol tambah', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_hostApp(const TempatScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Tempat'), findsOneWidget);
    expect(find.text('Teras Dagang Pagi'), findsOneWidget);
    expect(find.text('Tambah Tempat'), findsOneWidget);
  });

  testWidgets('Tempat (penyewa) menampilkan katalog tanpa tombol tambah', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_tenantApp(const TempatScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Tempat'), findsOneWidget);
    expect(find.text('Cari tempat, kota, atau lokasi...'), findsOneWidget);
    expect(find.text('Lapak Kuliner Baru'), findsOneWidget);
    expect(find.text('Tambah Tempat'), findsNothing);
  });

  testWidgets('Detail tempat untuk penyewa menampilkan tombol sewa', (
    WidgetTester tester,
  ) async {
    await _pumpSized(tester, const PlaceDetailScreen(placeId: '101'));

    expect(find.byTooltip('Kembali'), findsOneWidget);
    expect(find.text('Lapak Kuliner Baru'), findsOneWidget);
    // Indikator jumlah foto (fixture memuat 2 foto).
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('Fasilitas'), findsOneWidget);
    expect(find.text('Listrik'), findsOneWidget);
    expect(find.text('Kipas'), findsOneWidget);
    expect(find.text('Jadwal Sudah Dipesan'), findsOneWidget);

    // CTA penyewaan khusus role Penyewa.
    expect(find.text('Sewa Tempat Ini'), findsOneWidget);
  });

  testWidgets('Halaman notifikasi menampilkan isi dari backend', (
    WidgetTester tester,
  ) async {
    await _pumpSized(tester, const NotificationScreen());

    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Pemesanan diterima'), findsOneWidget);
    expect(find.text('Pembayaran diterima'), findsOneWidget);
  });

  testWidgets(
    'Role tidak dikenal tidak masuk Home Penyewa, tapi halaman error',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(_userRoleAneh()),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Halaman error dengan tombol keluar (logout mekanisme yang sudah ada).
      expect(find.text('Role akun tidak dikenali'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);

      // Konten Home Penyewa tidak ditampilkan.
      expect(find.text('Tempat Untuk Disewa'), findsNothing);
    },
  );

  testWidgets('Sesi tanpa data user juga tidak masuk Home Penyewa', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNoUserNotifier.new),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Role akun tidak dikenali'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);
    expect(find.text('Tempat Untuk Disewa'), findsNothing);
  });

  testWidgets(
    'Form ubah: promo kosong dikirim null dan fasilitas bisa kosong',
    (WidgetTester tester) async {
      final fakePlace = _FakePlaceService();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Awal Dummy')),
          ),
          GoRoute(
            path: '/place-form',
            builder: (_, _) => const PlaceFormScreen(placeId: '201'),
          ),
        ],
      );

      await _pumpFormRouter(tester, router: router, fakePlace: fakePlace);
      router.push('/place-form');
      await tester.pumpAndSettle();

      // Form terisi dari data tempat (mode ubah).
      expect(find.text('Ubah Tempat'), findsOneWidget);

      // Kosongkan harga promo dan fasilitas.
      await tester.enterText(
        find.widgetWithText(TextField, 'Harga Promo (Rp)'),
        '',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Fasilitas (opsional)'),
        '',
      );

      await tester.tap(find.text('Simpan Tempat'));
      await tester.pumpAndSettle();

      final payload = fakePlace.lastUpdatePayload;
      expect(payload, isNotNull);
      // Key tetap dikirim dengan nilai null agar promo terhapus di backend.
      expect(payload!.containsKey('harga_promo'), isTrue);
      expect(payload['harga_promo'], isNull);
      // Fasilitas dikirim sebagai string kosong (bukan key di-omit).
      expect(payload['fasilitas'], '');
      expect(payload['status'], 'AKTIF');
    },
  );

  testWidgets(
    'Form tambah: promo kosong di-omit (tidak dikirim sebagai null)',
    (WidgetTester tester) async {
      final fakePlace = _FakePlaceService();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Awal Dummy')),
          ),
          GoRoute(
            path: '/place-form',
            builder: (_, _) => const PlaceFormScreen(),
          ),
        ],
      );

      await _pumpFormRouter(tester, router: router, fakePlace: fakePlace);
      router.push('/place-form');
      await tester.pumpAndSettle();

      expect(find.text('Tambah Tempat'), findsOneWidget);

      // Isi field wajib.
      await tester.enterText(
        find.widgetWithText(TextField, 'Nama Tempat'),
        'Lapak Baru',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Alamat'),
        'Jl. Baru 1',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Kota'), 'Bandung');
      await tester.enterText(
        find.widgetWithText(TextField, 'Harga Normal (Rp)'),
        '250000',
      );

      await tester.tap(find.text('Simpan Tempat'));
      await tester.pumpAndSettle();

      final payload = fakePlace.lastCreatePayload;
      expect(payload, isNotNull);
      // Skema create backend tidak menerima null — key harus di-omit.
      expect(payload!.containsKey('harga_promo'), isFalse);
      expect(payload['fasilitas'], '');
    },
  );

  testWidgets('Form tempat: penyewa tidak dapat mengakses (pembatasan role)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_tenantApp(const PlaceFormScreen()));
    await tester.pumpAndSettle();

    expect(
      find.text('Hanya pemilik yang dapat mengelola tempat'),
      findsOneWidget,
    );
    expect(find.text('Tambah Tempat'), findsNothing);
  });

  testWidgets('Form ubah: hapus satu foto existing, foto tersisa dikirim', (
    WidgetTester tester,
  ) async {
    final fakePlace = _FakePlaceService();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Awal Dummy')),
        ),
        GoRoute(
          path: '/place-form',
          builder: (_, _) => const PlaceFormScreen(placeId: '201'),
        ),
      ],
    );

    await _pumpFormRouter(tester, router: router, fakePlace: fakePlace);
    router.push('/place-form');
    await tester.pumpAndSettle();

    // Dua foto existing dari fixture tampil dengan tombol hapus.
    expect(find.byIcon(Icons.close), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.text('Simpan Tempat'));
    await tester.pumpAndSettle();

    final payload = fakePlace.lastUpdatePayload;
    expect(payload, isNotNull);
    // Foto yang dihapus tidak dikirim; sisanya menjaga urutan.
    expect(payload!['foto'], ['https://cdn.example.test/b.jpg']);
  });

  testWidgets('Form ubah: hapus semua foto, foto kosong dikirim', (
    WidgetTester tester,
  ) async {
    final fakePlace = _FakePlaceService();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Awal Dummy')),
        ),
        GoRoute(
          path: '/place-form',
          builder: (_, _) => const PlaceFormScreen(placeId: '201'),
        ),
      ],
    );

    await _pumpFormRouter(tester, router: router, fakePlace: fakePlace);
    router.push('/place-form');
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsNothing);

    await tester.tap(find.text('Simpan Tempat'));
    await tester.pumpAndSettle();

    final payload = fakePlace.lastUpdatePayload;
    expect(payload, isNotNull);
    expect(payload!['foto'], isEmpty);
  });
}

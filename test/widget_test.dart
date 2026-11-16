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
import 'package:spoth_umkm/providers/nav_provider.dart';
import 'package:spoth_umkm/screens/auth/forgot_password_screen.dart';
import 'package:spoth_umkm/screens/auth/login_screen.dart';
import 'package:spoth_umkm/screens/auth/register_screen.dart';
import 'package:spoth_umkm/screens/home/home_screen.dart';
import 'package:spoth_umkm/screens/main/main_shell.dart';
import 'package:spoth_umkm/screens/notification/notification_screen.dart';
import 'package:spoth_umkm/screens/onboarding/onboarding_screen.dart';
import 'package:spoth_umkm/screens/place/place_detail_screen.dart';
import 'package:spoth_umkm/screens/place/tempat_screen.dart';
import 'package:spoth_umkm/screens/place/place_form_screen.dart';

const List<Size> _screenSizes = [
  Size(320, 480),
  Size(360, 800),
  Size(412, 915),
  Size(800, 1280),
  Size(800, 360),
  Size(1280, 800),
];

UserModel _tenantUser() => UserModel(
  id: '10',
  nama: 'Budi Santoso',
  email: 'budi@contoh.test',
  noHp: '081234567890',
  role: UserModel.roleTenant,
  createdAt: DateTime(2026, 1, 15),
);

UserModel _userRoleAneh() => UserModel(
  id: '30',
  nama: 'Ratu Aneh',
  email: 'aneh@contoh.test',
  noHp: '081234567892',
  role: 'MAJELIS',
  createdAt: DateTime(2026, 3, 1),
);

UserModel _hostUser() => UserModel(
  id: '20',
  nama: 'Sari Dewi',
  email: 'sari@contoh.test',
  noHp: '081234567891',
  role: UserModel.roleHost,
  createdAt: DateTime(2026, 2, 10),
);

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

const PlaceModel _tempatMilikOrangLain = PlaceModel(
  id: '303',
  hostId: '99',
  namaTempat: 'Lapak Milik Orang Lain',
  kategori: 'LAPAK_USAHA',
  alamat: 'Jl. Contoh 1',
  kota: 'Bandung',
  hargaNormal: 200000,
  hargaEfektif: 200000,
  tipeDurasi: 'HARIAN',
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

class _FakeAuthNoUserNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

class _FakePlaceService extends PlaceService {
  _FakePlaceService() : super(ApiService());

  PlaceModel? placeOverride;

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
  }) async => placeOverride ?? _tempatDetail();

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

Widget _tenantApp(Widget home) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(() => _FakeAuthNotifier(_tenantUser())),
    placeServiceProvider.overrideWithValue(_FakePlaceService()),
    notificationServiceProvider.overrideWithValue(_FakeNotificationService()),
    bookingServiceProvider.overrideWithValue(_FakeBookingService()),
  ],
  child: MaterialApp(home: home),
);

Widget _hostApp(Widget home) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(() => _FakeAuthNotifier(_hostUser())),
    placeServiceProvider.overrideWithValue(_FakePlaceService()),
    notificationServiceProvider.overrideWithValue(_FakeNotificationService()),
    bookingServiceProvider.overrideWithValue(_FakeBookingService()),
  ],
  child: MaterialApp(home: home),
);

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

Future<void> _pumpDetail(
  WidgetTester tester, {
  required _FakePlaceService fakePlace,
  bool host = false,
  Size size = const Size(412, 915),
}) async {
  tester.view
    ..devicePixelRatio = 1.0
    ..physicalSize = size;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(host ? _hostUser() : _tenantUser()),
        ),
        placeServiceProvider.overrideWithValue(fakePlace),
        notificationServiceProvider.overrideWithValue(
          _FakeNotificationService(),
        ),
        bookingServiceProvider.overrideWithValue(_FakeBookingService()),
      ],
      child: const MaterialApp(home: PlaceDetailScreen(placeId: '101')),
    ),
  );
  await tester.pumpAndSettle();
}

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

  testWidgets('Login: email dengan format salah menampilkan pesan error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'bukan-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'rahasia123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Format email tidak valid'), findsOneWidget);
  });

  testWidgets('Login: tautan Daftar membuka halaman Register', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Daftar'));
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Buat Akun Baru'), findsOneWidget);
  });

  testWidgets('Login: tautan Lupa Password membuka halaman lupa password', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Lupa password?'));
    await tester.tap(find.text('Lupa password?'));
    await tester.pumpAndSettle();

    expect(find.text('Lupa Password'), findsOneWidget);
  });

  testWidgets('Register: konfirmasi password harus sama', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RegisterScreen())),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(3), 'rahasia123');
    await tester.enterText(find.byType(TextFormField).at(4), 'rahasia456');

    final button = find.widgetWithText(ElevatedButton, 'Daftar');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi password tidak sama'), findsOneWidget);
  });

  testWidgets('Register: nomor telepon harus format Indonesia', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RegisterScreen())),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(2), '12345');

    final button = find.widgetWithText(ElevatedButton, 'Daftar');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Gunakan format 08xxxxxxxxxx'), findsOneWidget);
  });

  testWidgets('Register: peran wajib dipilih sebelum daftar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RegisterScreen())),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Budi Santoso');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'budi@contoh.test',
    );
    await tester.enterText(find.byType(TextFormField).at(2), '081234567890');
    await tester.enterText(find.byType(TextFormField).at(3), 'rahasia123');
    await tester.enterText(find.byType(TextFormField).at(4), 'rahasia123');

    final button = find.widgetWithText(ElevatedButton, 'Daftar');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Pilih salah satu peran'), findsOneWidget);
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
    expect(
      find.textContaining('Cari tempat, kota, atau lokasi'),
      findsOneWidget,
    );
    expect(find.textContaining('Lihat Semua'), findsOneWidget);

    expect(find.text('Lapak Kuliner Baru'), findsOneWidget);
    expect(find.text('Booth Bazar Sekolah'), findsOneWidget);
  });

  testWidgets(
    'Bottom bar berpindah antar tab Beranda, Tempat, Booking, Profil',
    (WidgetTester tester) async {
      await _pumpSized(tester, const MainShell());

      await tester.tap(find.text('Tempat'));
      await tester.pumpAndSettle();
      expect(find.text('Cari tempat, kota, atau lokasi...'), findsOneWidget);
      expect(find.text('Lapak Kuliner Baru'), findsOneWidget);

      await tester.tap(find.text('Booking'));
      await tester.pumpAndSettle();
      expect(find.text('Penyewaan Saya'), findsOneWidget);
      expect(find.textContaining('Warung Makan'), findsNWidgets(2));
      expect(find.text('Menunggu Bayar'), findsOneWidget);

      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('budi@contoh.test'), findsNWidgets(2));
      expect(find.text('Keluar'), findsOneWidget);

      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tempat Usahamu'), findsOneWidget);
    },
  );

  testWidgets('Home pemilik menampilkan ringkasan dan daftar tempat miliknya', (
    WidgetTester tester,
  ) async {
    await _pumpSized(tester, const HomeScreen(), host: true);

    expect(find.text('Spoth UMKM'), findsOneWidget);

    expect(find.text('Total Tempat'), findsOneWidget);
    expect(find.text('Tempat Aktif'), findsOneWidget);
    expect(find.text('Rp 750.000'), findsOneWidget);

    expect(find.text('Tempat Saya'), findsOneWidget);
    expect(find.text('Tambah Tempat'), findsNothing);
  });

  testWidgets('Beranda pemilik menampilkan galeri jelajah tempat lain', (
    WidgetTester tester,
  ) async {
    await _pumpSized(tester, const HomeScreen(), host: true);

    expect(find.text('Jelajahi Tempat Lain'), findsOneWidget);
    expect(find.text('Lihat Semua'), findsOneWidget);

    expect(find.text('Lapak Kuliner Baru'), findsOneWidget);
    expect(find.text('Booth Bazar Sekolah'), findsOneWidget);
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

  testWidgets('Tempat (pemilik) punya pencarian & filter status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_hostApp(const TempatScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Cari nama atau kota tempat...'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Nonaktif'), findsOneWidget);

    expect(find.text('1 tempat'), findsOneWidget);
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

    expect(find.text('Detail Tempat'), findsOneWidget);
    expect(find.text('Lapak Kuliner Baru'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('Fasilitas'), findsOneWidget);
    expect(find.text('Listrik'), findsOneWidget);
    expect(find.text('Kipas'), findsOneWidget);
    expect(find.text('Jadwal Sudah Dipesan'), findsOneWidget);

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

      expect(find.text('Role akun tidak dikenali'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);

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

      expect(find.text('Ubah Tempat'), findsOneWidget);

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
      expect(payload!.containsKey('harga_promo'), isTrue);
      expect(payload['harga_promo'], isNull);
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

    expect(find.byIcon(Icons.close), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.text('Simpan Tempat'));
    await tester.pumpAndSettle();

    final payload = fakePlace.lastUpdatePayload;
    expect(payload, isNotNull);
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

  testWidgets('Detail tempat tanpa overflow pada semua ukuran layar', (
    WidgetTester tester,
  ) async {
    await _pumpOnAllSizes(
      tester,
      () => _tenantApp(const PlaceDetailScreen(placeId: '101')),
    );
  });

  testWidgets('Detail tempat tanpa overflow pada lebar web', (
    WidgetTester tester,
  ) async {
    const ukuranWeb = [Size(1440, 900), Size(1920, 1080)];
    for (final size in ukuranWeb) {
      tester.view
        ..devicePixelRatio = 1.0
        ..physicalSize = size;

      await tester.pumpWidget(
        _tenantApp(const PlaceDetailScreen(placeId: '101')),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Layout error pada ukuran ${size.width}x${size.height}',
      );

      tester.view.reset();
    }
  });

  testWidgets('Detail tempat menampilkan sapaan lokasi, host, dan aturan', (
    WidgetTester tester,
  ) async {
    await _pumpSized(tester, const PlaceDetailScreen(placeId: '101'));

    expect(find.text('Detail Tempat'), findsOneWidget);
    expect(find.text('Lapak Kuliner Baru'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('Jl. Merdeka 12, Bandung'), findsOneWidget);
    expect(find.text('Sari Dewi'), findsOneWidget);
    expect(find.text('Pemilik tempat'), findsOneWidget);
    expect(find.text('Deskripsi'), findsOneWidget);
    expect(find.text('Fasilitas'), findsOneWidget);
    expect(find.text('Listrik'), findsOneWidget);
    expect(find.text('Kipas'), findsOneWidget);
    expect(find.text('Aturan'), findsOneWidget);
    expect(find.text('Jadwal Sudah Dipesan'), findsOneWidget);
    expect(find.text('Sewa Tempat Ini'), findsOneWidget);
  });

  testWidgets('Detail tempat: ketuk sisi kanan foto memajukan galeri', (
    WidgetTester tester,
  ) async {
    await _pumpSized(tester, const PlaceDetailScreen(placeId: '101'));

    expect(find.text('1 / 2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('Detail tempat untuk pemilik menampilkan aksi kelola', (
    WidgetTester tester,
  ) async {
    await _pumpSized(
      tester,
      const PlaceDetailScreen(placeId: '101'),
      host: true,
    );

    expect(find.text('Detail Tempat'), findsOneWidget);
    expect(find.text('Kelola Tempat'), findsOneWidget);
    expect(find.text('Sewa Tempat Ini'), findsNothing);

    expect(find.text('Nonaktifkan Tempat'), findsNothing);
    expect(find.text('Hapus Tempat'), findsNothing);

    await tester.tap(find.text('Kelola Tempat'));
    await tester.pumpAndSettle();

    expect(find.text('Ubah Data Tempat'), findsOneWidget);
    expect(find.text('Nonaktifkan Tempat'), findsOneWidget);
    expect(find.text('Hapus Tempat'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
  });

  testWidgets('Detail tempat: pemilik melihat tempat milik akun lain', (
    WidgetTester tester,
  ) async {
    final fakePlace = _FakePlaceService()
      ..placeOverride = _tempatMilikOrangLain;

    await _pumpDetail(tester, fakePlace: fakePlace, host: true);

    expect(find.text('Lapak Milik Orang Lain'), findsOneWidget);
    expect(find.text('Kelola Tempat'), findsNothing);
    expect(find.text('Sewa Tempat Ini'), findsNothing);
    expect(find.text('Tempat ini dikelola oleh akun lain.'), findsOneWidget);
  });

  testWidgets('Detail tempat tidak memakai gradien dekoratif', (
    WidgetTester tester,
  ) async {
    await _pumpSized(tester, const PlaceDetailScreen(placeId: '101'));

    final bergradien = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).gradient != null,
    );

    expect(bergradien, findsNothing);
  });

  testWidgets('Detail tempat: thumbnail galeri memilih foto lain', (
    WidgetTester tester,
  ) async {
    await _pumpSized(tester, const PlaceDetailScreen(placeId: '101'));

    expect(find.text('1 / 2'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('galeri-thumb-1')));
    await tester.tap(find.byKey(const ValueKey('galeri-thumb-1')));
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets(
    'Detail tempat: tombol perbesar membuka dan menutup penampil foto',
    (WidgetTester tester) async {
      await _pumpSized(tester, const PlaceDetailScreen(placeId: '101'));

      await tester.tap(find.byIcon(Icons.open_in_full));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsNothing);
    },
  );

  testWidgets('Detail tempat di layar lebar menampilkan harga pada bar aksi', (
    WidgetTester tester,
  ) async {
    await _pumpSized(
      tester,
      const PlaceDetailScreen(placeId: '101'),
      size: const Size(1200, 900),
    );

    expect(find.text('Harga sewa'), findsOneWidget);
    expect(find.text('Sewa Tempat Ini'), findsOneWidget);
    expect(find.text('Rp 200.000'), findsWidgets);
  });

  testWidgets('Detail tempat untuk pemilik menampilkan status pada bar aksi', (
    WidgetTester tester,
  ) async {
    await _pumpSized(
      tester,
      const PlaceDetailScreen(placeId: '101'),
      host: true,
      size: const Size(1200, 900),
    );

    expect(find.text('Tempat aktif dan tampil di pencarian'), findsOneWidget);
    expect(find.text('Kelola Tempat'), findsOneWidget);
  });

  testWidgets('Detail tempat: pemilik menonaktifkan mengirim status NONAKTIF', (
    WidgetTester tester,
  ) async {
    final fakePlace = _FakePlaceService();

    await _pumpDetail(tester, fakePlace: fakePlace, host: true);

    await tester.tap(find.text('Kelola Tempat'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nonaktifkan Tempat'));
    await tester.pumpAndSettle();

    expect(fakePlace.lastUpdatePayload, {'status': 'NONAKTIF'});
  });

  testWidgets('Home penyewa menampilkan sapaan dan shortcut pencarian', (
    WidgetTester tester,
  ) async {
    await _pumpSized(tester, const HomeScreen());

    expect(find.text('Halo, Budi'), findsOneWidget);
    expect(find.textContaining('Tempat Usahamu'), findsOneWidget);
    expect(
      find.textContaining('Cari tempat, kota, atau lokasi'),
      findsOneWidget,
    );
    expect(find.textContaining('Lihat Semua'), findsOneWidget);
  });

  testWidgets('Shortcut pencarian beranda membuka tab Tempat', (
    WidgetTester tester,
  ) async {
    await _pumpSized(tester, const MainShell());

    final context = tester.element(find.byType(MainShell));
    final container = ProviderScope.containerOf(context);

    expect(container.read(mainNavIndexProvider), 0);

    await tester.tap(find.textContaining('Cari tempat, kota, atau lokasi'));
    await tester.pumpAndSettle();

    expect(container.read(mainNavIndexProvider), 1);
  });
}

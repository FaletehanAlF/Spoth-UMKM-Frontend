import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoth_umkm/core/theme/app_colors.dart';
import 'package:spoth_umkm/core/theme/app_theme.dart';
import 'package:spoth_umkm/models/booking_model.dart';
import 'package:spoth_umkm/models/notification_model.dart';
import 'package:spoth_umkm/models/user_model.dart';
import 'package:spoth_umkm/providers/auth_provider.dart';
import 'package:spoth_umkm/providers/booking_provider.dart';
import 'package:spoth_umkm/providers/nav_provider.dart';
import 'package:spoth_umkm/providers/notification_provider.dart';
import 'package:spoth_umkm/providers/riwayat_provider.dart';
import 'package:spoth_umkm/screens/booking/booking_screen.dart';
import 'package:spoth_umkm/widgets/bottom_nav_pill.dart';
import 'package:spoth_umkm/widgets/nav_items.dart';
import 'package:spoth_umkm/widgets/spoth_sidebar.dart';

class FakeAuthBooking extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: UserModel(
      id: '3',
      nama: 'Andi Wijaya',
      email: 'uji@spoth.test',
      role: UserModel.roleTenant,
      createdAt: DateTime(2026, 1, 1),
    ),
    token: 'token-uji',
  );
}

class FakeBookingsGrid extends BookingsNotifier {
  FakeBookingsGrid(this.items);

  final List<BookingModel> items;

  @override
  Future<List<BookingModel>> build() async => items;
}

class FakeNotifGrid extends NotificationSummaryNotifier {
  @override
  Future<NotificationSummaryModel?> build() async =>
      const NotificationSummaryModel(total: 0, belumDibaca: 0);
}

class FakeRiwayatGrid extends RiwayatBadgeNotifier {
  @override
  Future<int> build() async => 0;
}

List<BookingModel> empatBooking() => [
  for (var i = 1; i <= 4; i++)
    BookingModel(
      id: '$i',
      placeId: '$i',
      jenisUsaha: 'Kuliner',
      tanggalMulai: '2026-11-25',
      tanggalSelesai: '2026-12-01',
      jumlahDurasi: 1,
      hargaSatuan: 500000,
      totalHarga: 500000,
      status: 'LUNAS',
      namaTempat: 'Tempat $i',
    ),
];

Future<void> tampilkanBooking(WidgetTester tester, double lebar) async {
  tester.view.physicalSize = Size(lebar, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(FakeAuthBooking.new),
        bookingsProvider.overrideWith(() => FakeBookingsGrid(empatBooking())),
        notificationSummaryProvider.overrideWith(FakeNotifGrid.new),
        riwayatBadgeProvider.overrideWith(FakeRiwayatGrid.new),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const BookingScreen(),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('booking web menampilkan dua kartu per baris', (tester) async {
    await tampilkanBooking(tester, 1200);

    expect(tester.takeException(), isNull);
    final pertama = tester.getCenter(find.text('Tempat 1')).dy;
    final kedua = tester.getCenter(find.text('Tempat 2')).dy;
    final ketiga = tester.getCenter(find.text('Tempat 3')).dy;

    expect((pertama - kedua).abs(), lessThan(2));
    expect(ketiga, greaterThan(pertama + 20));
  });

  testWidgets('booking ponsel tetap satu kartu per baris', (tester) async {
    await tampilkanBooking(tester, 390);

    expect(tester.takeException(), isNull);
    final pertama = tester.getCenter(find.text('Tempat 1')).dy;
    final kedua = tester.getCenter(find.text('Tempat 2')).dy;

    expect(kedua, greaterThan(pertama + 20));
  });

  testWidgets('badge booking muncul untuk pesanan belum dibayar', (tester) async {
    final container = ProviderContainer(
      overrides: [
        bookingsProvider.overrideWith(
          () => FakeBookingsGrid([
            BookingModel(
              id: '1',
              placeId: '1',
              jenisUsaha: 'Kuliner',
              tanggalMulai: '2026-11-25',
              tanggalSelesai: '2026-12-01',
              jumlahDurasi: 1,
              hargaSatuan: 500000,
              totalHarga: 500000,
              status: 'MENUNGGU_PEMBAYARAN',
              namaTempat: 'Tempat 1',
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(bookingsProvider.future);
    expect(container.read(bookingBadgeProvider), 1);
  });

  testWidgets('badge oranye tampil di menu Booking ponsel dan web', (
    tester,
  ) async {
    final items = [
      kNavItems[MainTab.beranda]!,
      kNavItems[MainTab.tempat]!,
      kNavItems[MainTab.booking]!,
    ];

    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SpothBottomNav(
            index: 0,
            items: items,
            badgeIndex: 2,
            badgeCount: 2,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final badge = tester.widget<Badge>(
      find.descendant(
        of: find.byWidgetPredicate(
          (widget) => widget is Tooltip && widget.message == 'Booking',
        ),
        matching: find.byType(Badge),
      ),
    );
    expect(badge.isLabelVisible, isTrue);
    expect(badge.backgroundColor, AppColors.primaryOrange);
  });

  testWidgets('badge oranye tampil di sidebar Booking', (tester) async {
    final items = [
      kNavItems[MainTab.beranda]!,
      kNavItems[MainTab.booking]!,
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SpothSidebar(
            index: 0,
            items: items,
            expanded: true,
            badgeIndex: 1,
            badgeCount: 1,
            onToggle: () {},
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final badges = tester.widgetList<Badge>(find.byType(Badge));
    final terlihat = badges.where((badge) => badge.isLabelVisible).toList();
    expect(terlihat, hasLength(1));
    expect(terlihat.first.backgroundColor, AppColors.primaryOrange);
  });
}

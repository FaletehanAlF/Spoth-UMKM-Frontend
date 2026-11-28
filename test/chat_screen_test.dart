import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoth_umkm/core/services/api_service.dart';
import 'package:spoth_umkm/core/services/chat_service.dart';
import 'package:spoth_umkm/core/services/notification_socket_service.dart';
import 'package:spoth_umkm/core/theme/app_theme.dart';
import 'package:spoth_umkm/models/booking_model.dart';
import 'package:spoth_umkm/models/chat_message.dart';
import 'package:spoth_umkm/models/notification_model.dart';
import 'package:spoth_umkm/models/user_model.dart';
import 'package:spoth_umkm/providers/auth_provider.dart';
import 'package:spoth_umkm/providers/booking_provider.dart';
import 'package:spoth_umkm/providers/chat_badge_provider.dart';
import 'package:spoth_umkm/providers/notification_provider.dart';
import 'package:spoth_umkm/providers/notification_realtime_provider.dart';
import 'package:spoth_umkm/providers/riwayat_provider.dart';
import 'package:spoth_umkm/screens/chat/chat_screen.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => AuthState(
        status: AuthStatus.authenticated,
        user: UserModel(
          id: '3',
          nama: 'Andi',
          email: 'uji@spoth.test',
          role: UserModel.roleTenant,
          createdAt: DateTime(2026, 1, 1),
        ),
        token: 'token-uji',
      );
}

class _Bookings extends BookingsNotifier {
  @override
  Future<List<BookingModel>> build() async => const [];
}

class _Notifikasi extends NotificationSummaryNotifier {
  @override
  Future<NotificationSummaryModel?> build() async =>
      const NotificationSummaryModel(total: 0, belumDibaca: 0);
}

class _Riwayat extends RiwayatBadgeNotifier {
  @override
  Future<int> build() async => 0;
}

class _Chat extends ChatService {
  _Chat() : super(ApiService());

  @override
  Future<List<ChatConversation>> conversations({required String token}) async {
    return [
      ChatConversation(
        bookingId: '42',
        kodeBooking: 'SP-42',
        namaTempat: 'Ruang A',
        namaLain: 'Budi Santoso',
        lastMessage: 'Balasan baru',
        lastMessageAt: DateTime(2026, 11, 28, 9, 0),
        unreadCount: 2,
      ),
    ];
  }

  @override
  Future<int> markRead({required String token, required String bookingId}) async => 0;

  @override
  Future<List<ChatMessageModel>> messages({
    required String token,
    required String bookingId,
  }) async => const [];
}

class _ProbeBadge extends ConsumerWidget {
  const _ProbeBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(
      '${ref.watch(chatBadgeProvider)}',
      key: const ValueKey('probe-badge'),
    );
  }
}

Future<void> tampilkanChat(
  WidgetTester tester, {
  required double lebar,
  required double tinggi,
}) async {
  tester.view.physicalSize = Size(lebar, tinggi);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_Auth.new),
        chatServiceProvider.overrideWithValue(_Chat()),
        bookingsProvider.overrideWith(_Bookings.new),
        notificationSummaryProvider.overrideWith(_Notifikasi.new),
        riwayatBadgeProvider.overrideWith(_Riwayat.new),
        notificationSocketServiceProvider.overrideWithValue(
          NotificationSocketService('http://127.0.0.1:3004'),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Stack(
          children: [ChatScreen(), _ProbeBadge()],
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('kartu chat menampilkan jumlah belum dibaca dan badge ikon mengikuti', (
    tester,
  ) async {
    await tampilkanChat(tester, lebar: 375, tinggi: 812);

    expect(find.text('2'), findsWidgets);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('probe-badge'))).data,
      '2',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('web menampilkan daftar dan percakapan berdampingan', (
    tester,
  ) async {
    await tampilkanChat(tester, lebar: 1440, tinggi: 900);

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Belum ada percakapan dibuka'), findsOneWidget);

    await tester.tap(find.text('Balasan baru'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada percakapan dibuka'), findsNothing);
    // Nama tempat yang dipesan sengaja tidak ditampilkan di chat.
    expect(find.text('Ruang A'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('web ESC menutup chat kanan dan kembali kosong', (tester) async {
    await tampilkanChat(tester, lebar: 1440, tinggi: 900);
    await tester.tap(find.text('Balasan baru'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Belum ada percakapan dibuka'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

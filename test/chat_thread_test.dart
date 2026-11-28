import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoth_umkm/core/services/api_service.dart';
import 'package:spoth_umkm/core/theme/app_colors.dart';
import 'package:spoth_umkm/core/services/chat_service.dart';
import 'package:spoth_umkm/core/services/notification_socket_service.dart';
import 'package:spoth_umkm/core/theme/app_theme.dart';
import 'package:spoth_umkm/core/utils/format.dart';
import 'package:spoth_umkm/models/chat_message.dart';
import 'package:spoth_umkm/models/user_model.dart';
import 'package:spoth_umkm/providers/auth_provider.dart';
import 'package:spoth_umkm/providers/notification_realtime_provider.dart';
import 'package:spoth_umkm/screens/chat/chat_thread_screen.dart';

class _Auth extends AuthNotifier {
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

class _Chat extends ChatService {
  _Chat() : super(ApiService());

  @override
  Future<List<ChatMessageModel>> messages({
    required String token,
    required String bookingId,
  }) async {
    return [
      ChatMessageModel(
        id: '1',
        bookingId: bookingId,
        senderId: '4',
        body: 'Halo, ini pesan uji',
        createdAt: DateTime(2026, 11, 28, 9, 0),
      ),
    ];
  }

  @override
  Future<int> markRead({required String token, required String bookingId}) async => 0;

  @override
  Future<ChatMessageModel> send({
    required String token,
    required String bookingId,
    required String body,
  }) async {
    return ChatMessageModel(
      id: '2',
      bookingId: bookingId,
      senderId: '3',
      body: body,
      createdAt: DateTime(2026, 11, 28, 9, 1),
    );
  }
}

Widget _halaman(Widget child) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(_Auth.new),
      chatServiceProvider.overrideWithValue(_Chat()),
      notificationSocketServiceProvider.overrideWithValue(
        NotificationSocketService('http://127.0.0.1:3004'),
      ),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

void main() {
  testWidgets('halaman chat merender pesan tanpa error Material', (
    tester,
  ) async {
    final errors = <Object>[];
    final original = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exception);
    addTearDown(() => FlutterError.onError = original);

    await tester.pumpWidget(
      _halaman(const ChatThreadScreen(bookingId: '42', title: 'Budi')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Halo, ini pesan uji'), findsOneWidget);
    expect(errors, isEmpty, reason: errors.map((e) => e.toString()).join('\n'));
  });

  testWidgets('header chat menampilkan nama tanpa nama tempat', (
    tester,
  ) async {
    await tester.pumpWidget(
      _halaman(
        const ChatThreadScreen(
          bookingId: '42',
          title: 'Budi Santoso',
          subtitle: 'Ruang A',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Ruang A'), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('tombol kirim abu saat kosong dan oranye saat ada teks', (
    tester,
  ) async {
    await tester.pumpWidget(
      _halaman(const ChatThreadScreen(bookingId: '42', title: 'Budi')),
    );
    await tester.pumpAndSettle();

    IconButton tombolKirim() => tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.arrow_upward),
        matching: find.byType(IconButton),
      ),
    );

    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(tombolKirim().color, Colors.grey);
    expect(tombolKirim().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Halo Budi');
    await tester.pump();

    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(tombolKirim().color, AppColors.primaryDeep);
    expect(tombolKirim().onPressed, isNotNull);
  });

  testWidgets('Enter mengirim pesan', (tester) async {
    await tester.pumpWidget(
      _halaman(const ChatThreadScreen(bookingId: '42', title: 'Budi')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Halo Budi');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('Halo Budi'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });

  testWidgets('Shift + Enter membuat baris baru, tidak mengirim', (tester) async {
    await tester.pumpWidget(
      _halaman(const ChatThreadScreen(bookingId: '42', title: 'Budi')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Halo');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, contains('\n'));
    expect(find.text('Halo'), findsNothing);
  });

  test('format waktu chat memakai Hari ini atau Kemarin', () {
    final sekarang = DateTime.now();

    expect(
      formatWaktuChat(sekarang),
      startsWith('Hari ini,'),
    );
    expect(
      formatWaktuChat(sekarang.subtract(const Duration(days: 1))),
      startsWith('Kemarin,'),
    );
    expect(
      formatWaktuChat(DateTime(2026, 1, 2, 8, 30)),
      startsWith('02 Jan,'),
    );
  });
}

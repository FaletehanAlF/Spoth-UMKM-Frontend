import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/api_service.dart';
import 'core/services/chat_service.dart';
import 'core/services/notification_socket_service.dart';
import 'core/theme/app_theme.dart';
import 'models/booking_model.dart';
import 'models/chat_message.dart';
import 'models/notification_model.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/notification_realtime_provider.dart';
import 'providers/riwayat_provider.dart';
import 'screens/chat/chat_screen.dart';

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
      ChatConversation(
        bookingId: '43',
        kodeBooking: 'SP-43',
        namaTempat: 'Warung Makan',
        namaLain: 'Siti Aminah',
        lastMessage: 'Baik, sampai ketemu',
        lastMessageAt: DateTime(2026, 11, 27, 16, 30),
        unreadCount: 0,
      ),
    ];
  }

  @override
  Future<int> markRead({required String token, required String bookingId}) async => 0;

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
        body: 'Halo, saya mau tanya tempatnya',
        createdAt: DateTime(2026, 11, 28, 8, 55),
      ),
      ChatMessageModel(
        id: '2',
        bookingId: bookingId,
        senderId: '3',
        body: 'Halo, silakan',
        createdAt: DateTime(2026, 11, 28, 8, 57),
      ),
      ChatMessageModel(
        id: '3',
        bookingId: bookingId,
        senderId: '4',
        body: 'Balasan baru',
        createdAt: DateTime(2026, 11, 28, 9, 0),
      ),
    ];
  }
}

void main() {
  runApp(
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
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const ChatScreen(),
      ),
    ),
  );
}

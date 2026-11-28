class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ChatConversation {
  const ChatConversation({
    required this.bookingId,
    required this.kodeBooking,
    required this.namaTempat,
    required this.namaLain,
    this.foto,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  final String bookingId;
  final String? kodeBooking;
  final String namaTempat;
  final String namaLain;
  final String? foto;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ChatConversation copyWith({int? unreadCount}) {
    return ChatConversation(
      bookingId: bookingId,
      kodeBooking: kodeBooking,
      namaTempat: namaTempat,
      namaLain: namaLain,
      foto: foto,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      bookingId: json['booking_id']?.toString() ?? '',
      kodeBooking: json['kode_booking']?.toString(),
      namaTempat: json['nama_tempat']?.toString() ?? '',
      namaLain: json['nama_lain']?.toString() ?? '',
      foto: json['foto']?.toString(),
      lastMessage: json['last_message']?.toString(),
      lastMessageAt: DateTime.tryParse(
        json['last_message_at']?.toString() ?? '',
      ),
      unreadCount: json['unread_count'] is num
          ? (json['unread_count'] as num).toInt()
          : int.tryParse(json['unread_count']?.toString() ?? '') ?? 0,
    );
  }
}

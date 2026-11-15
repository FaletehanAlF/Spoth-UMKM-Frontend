/// Model data notifikasi sesuai respons backend SPOTH UMKM
/// (`GET /notifications`, `GET /notifications/summary`).
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.dibaca,
    this.createdAt,
    this.metadata,
  });

  final String id;
  final String judul;
  final String pesan;
  final bool dibaca;
  final DateTime? createdAt;

  /// Data tambahan dari backend (mis. `{ booking_id, tipe }`).
  final Map<String, dynamic>? metadata;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      judul: json['judul'] as String? ?? '',
      pesan: json['pesan'] as String? ?? '',
      dibaca: json['dibaca'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
    );
  }
}

/// Ringkasan notifikasi dari `GET /notifications/summary`
/// (kunci JSON: `data.ringkasan`) — dipakai untuk badge jumlah belum dibaca.
class NotificationSummaryModel {
  const NotificationSummaryModel({
    required this.total,
    required this.belumDibaca,
  });

  final int total;
  final int belumDibaca;

  factory NotificationSummaryModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) => value is num ? value.toInt() : 0;

    return NotificationSummaryModel(
      total: toInt(json['total']),
      belumDibaca: toInt(json['belum_dibaca']),
    );
  }
}

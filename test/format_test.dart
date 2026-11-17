import 'package:flutter_test/flutter_test.dart';

import 'package:spoth_umkm/core/utils/format.dart';

void main() {
  group('formatDiskonPersen', () {
    test('menghitung persentase promo dari harga normal dan promo', () {
      expect(formatDiskonPersen(250000, 200000), '-20%');
      expect(formatDiskonPersen(100000, 75000), '-25%');
    });

    test('membulatkan persentase ke bilangan terdekat', () {
      expect(formatDiskonPersen(3000, 2000), '-33%');
      expect(formatDiskonPersen(300000, 199000), '-34%');
    });

    test('mengembalikan null ketika harga promo tidak ada', () {
      expect(formatDiskonPersen(250000, null), isNull);
    });

    test('mengembalikan null ketika harga promo tidak lebih murah', () {
      expect(formatDiskonPersen(250000, 250000), isNull);
      expect(formatDiskonPersen(250000, 300000), isNull);
    });

    test('mengembalikan null ketika harga promo nol atau negatif', () {
      expect(formatDiskonPersen(250000, 0), isNull);
      expect(formatDiskonPersen(250000, -1000), isNull);
    });

    test('mengembalikan null ketika harga normal tidak valid', () {
      expect(formatDiskonPersen(0, 0), isNull);
      expect(formatDiskonPersen(-100, -200), isNull);
    });
  });

  group('tanggalSelesaiSewa', () {
    test('menghitung durasi harian secara inklusif', () {
      expect(
        tanggalSelesaiSewa(DateTime(2026, 12, 1), 'HARIAN', 3),
        DateTime.utc(2026, 12, 3),
      );
      expect(
        tanggalSelesaiSewa(DateTime(2026, 12, 1), 'HARIAN', 1),
        DateTime.utc(2026, 12, 1),
      );
    });

    test('menghitung durasi mingguan dalam hari', () {
      expect(
        tanggalSelesaiSewa(DateTime(2026, 12, 1), 'MINGGUAN', 2),
        DateTime.utc(2026, 12, 14),
      );
    });

    test('menghitung durasi bulanan dan menyesuaikan akhir bulan', () {
      expect(
        tanggalSelesaiSewa(DateTime(2026, 12, 1), 'BULANAN', 1),
        DateTime.utc(2026, 12, 31),
      );
      expect(
        tanggalSelesaiSewa(DateTime(2026, 1, 31), 'BULANAN', 1),
        DateTime.utc(2026, 2, 27),
      );
      expect(
        tanggalSelesaiSewa(DateTime(2026, 3, 31), 'BULANAN', 1),
        DateTime.utc(2026, 4, 29),
      );
    });
  });

  group('namaDepan', () {
    test('mengambil kata pertama dari nama lengkap', () {
      expect(namaDepan('Budi Santoso'), 'Budi');
      expect(namaDepan('Sari Dewi'), 'Sari');
    });

    test('mengabaikan spasi berlebih di awal dan tengah', () {
      expect(namaDepan('  Budi   Santoso  '), 'Budi');
    });

    test('mengembalikan null ketika nama kosong atau tidak ada', () {
      expect(namaDepan(null), isNull);
      expect(namaDepan('   '), isNull);
    });
  });
}

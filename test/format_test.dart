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
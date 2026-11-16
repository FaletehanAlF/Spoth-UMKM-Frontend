import 'package:flutter_test/flutter_test.dart';

import 'package:spoth_umkm/models/user_model.dart';

void main() {
  test('fromJson mem-parsing respons lengkap dari backend', () {
    final user = UserModel.fromJson({
      'id': 1,
      'nama': 'Budi Santoso',
      'email': 'budi@contoh.test',
      'no_hp': '081234567890',
      'role': 'TENANT',
      'created_at': '2026-01-15T09:30:00.000Z',
    });

    expect(user.id, '1');
    expect(user.nama, 'Budi Santoso');
    expect(user.role, UserModel.roleTenant);
    expect(user.createdAt, DateTime.utc(2026, 1, 15, 9, 30));
  });

  test('fromJson tidak crash saat created_at bernilai null', () {
    final sebelumPanggil = DateTime.now();

    final user = UserModel.fromJson({
      'id': 2,
      'nama': 'Sari Dewi',
      'email': 'sari@contoh.test',
      'no_hp': null,
      'role': 'HOST',
      'created_at': null,
    });

    expect(user.role, UserModel.roleHost);
    expect(
      user.createdAt.isAfter(
        sebelumPanggil.subtract(const Duration(minutes: 1)),
      ),
      isTrue,
    );
  });

  test('fromJson tidak crash saat key created_at tidak ada', () {
    final user = UserModel.fromJson({
      'id': 3,
      'nama': 'Andi Pratama',
      'email': 'andi@contoh.test',
      'no_hp': null,
      'role': 'TENANT',
    });

    expect(user.role, UserModel.roleTenant);
    expect(user.createdAt.year, DateTime.now().year);
  });

  test('fromJson tidak crash saat created_at format tidak valid', () {
    final user = UserModel.fromJson({
      'id': 4,
      'nama': 'Citra Lestari',
      'email': 'citra@contoh.test',
      'no_hp': null,
      'role': 'HOST',
      'created_at': 'bukan-tanggal',
    });

    expect(user.createdAt.year, DateTime.now().year);
  });
}

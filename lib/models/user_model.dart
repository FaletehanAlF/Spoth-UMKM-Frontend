class UserModel {
  const UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    required this.createdAt,
    this.noHp,
    this.foto,
  });

  static const String roleHost = 'HOST';
  static const String roleTenant = 'TENANT';

  final String id;
  final String nama;
  final String email;
  final String? noHp;
  final String? foto;
  final String role;
  final DateTime createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      nama: json['nama'] as String,
      email: json['email'] as String,
      noHp: json['no_hp'] as String?,
      foto: json['foto'] as String?,
      role: json['role'] as String,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'no_hp': noHp,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

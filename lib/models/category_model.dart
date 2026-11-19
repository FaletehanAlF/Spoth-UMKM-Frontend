class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.nama,
    required this.isPreset,
  });

  final String id;
  final String nama;
  final bool isPreset;

  static const String useLainya = '__LOPRINA__'; // sentinel internal only

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] ?? '').toString(),
      nama: (json['nama'] ?? '').toString(),
      isPreset: json['is_preset'] == true,
    );
  }
}

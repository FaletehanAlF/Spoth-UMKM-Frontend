# Testing Frontend (Flutter)

## Prasyarat
- Flutter SDK terpasang
- Backend berjalan di `http://localhost:3003` (atau sesuaikan `lib/core/config/app_config.dart`)

## Pengujian Otomatis
```bash
flutter analyze
flutter test
flutter build web --release
```

## Checklist Manual
- [ ] Login dan register berhasil
- [ ] Dashboard menampilkan KPI dan grafik pendapatan bersih
- [ ] Profil mode lihat + Edit Profil berfungsi
- [ ] CRUD tempat + kategori "Lainnya" berfungsi
- [ ] Booking dan riwayat tampil benar
- [ ] Empty state tampil bersih (tanpa border abu-abu)
- [ ] Layout responsif di mobile dan web (tanpa overflow)
- [ ] Tombol Keluar berwarna merah #FF0000

## Catatan
- `app_config.dart` sengaja disimpan lokal (tidak di-commit).
- Satu test timing async (`Form penyewaan: pratinjau lama tidak menimpa pilihan terbaru`) bisa flaky di beberapa lingkungan, tetapi tidak memengaruhi fungsi aplikasi.

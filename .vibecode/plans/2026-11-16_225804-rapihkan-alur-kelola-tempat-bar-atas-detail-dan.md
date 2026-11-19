# Rapihkan alur Kelola Tempat, bar atas detail, dan hapus gradient

## Tujuan

Permintaan pengguna (bahasa Indonesia):

1. Tempat yang dimiliki pemilik sebaiknya tetap bisa dilihat oleh semua akun, dan pengelolaan tempat (ubah, aktif/nonaktif, hapus) dipisah ke menu sendiri supaya tidak bercampur dengan tampilan detail publik dan UI/UX lebih mudah dipahami.
2. Saat membuka detail, app bar terasa "numpuk halaman" — perlu dijelaskan dan dibereskan.
3. Jangan memakai gradient warna oranye.

Semua pekerjaan di branch `feature/place-detail` (sudah aktif, commit terakhir `eeb7ed1`).

## Temuan dari pembacaan kode

- `_ActionBar` (`lib/screens/place/place_detail_screen.dart:1173-1279`) menampilkan tiga tombol berdesakan untuk pemilik: `Nonaktifkan`, `Hapus`, `Edit` — termasuk aksi destruktif (`Hapus`) di bar aksi utama. Cabang `else` (pemilik yang membuka tempat milik orang lain) menghasilkan `SizedBox.shrink()` sehingga bar aksi kosong.
- Halaman detail **tidak punya `AppBar`**. Tombol kembali berupa `_CircleButton` melayang di atas galeri (`_HeroGallery` baris 461-471) pada layar sempit, dan `_TopBar` khusus (baris 347-383) pada layar lebar. Ini penyebab tampilan bar tidak konsisten dengan halaman lain (`TempatScreen`, `NotificationScreen`, `ProfileScreen`, `PlaceFormScreen`, `BookingFormScreen` semuanya memakai `SpothAppBar`).
- Soal "app bar numpuk": `context.push('/place-detail?...')` (dipanggil dari `lib/widgets/place_grid_card.dart:23` dan `lib/widgets/owner_place_list.dart:272`) menumpuk rute di atas shell. Rute `/place-detail` berada **di luar** shell sehingga menutupi seluruh layar — bukan numpuk visual, tapi menumpuk tumpukan navigasi: dari Beranda → Tempat → Detail → Edit, tekan kembali hanya mundur satu langkah tiap kali. Perbaikannya bukan mengubah router (di luar cakupan), melainkan memberi detail `SpothAppBar` dengan panah kembali yang jelas sehingga pengguna selalu tahu posisinya.
- Gradient: satu-satunya `LinearGradient` di seluruh `lib/` adalah `place_detail_screen.dart:427`, dan itu **gradien hitam transparan** (lapisan penggelap foto) — bukan oranye. Permintaan "jangan gradient oranye" berarti: jangan menambahkan gradien oranye baru, dan lapisan penggelap foto diganti warna solid agar tidak ada gradien sama sekali di halaman ini.
- `hostId` dibandingkan dengan `authNotifierProvider.user!.id` (baris 185-188) untuk menentukan `isOwner`.

## Pendekatan

Tiga perubahan UI saja, tanpa menyentuh service/provider/rute:

1. **Satu bar atas standar.** `Scaffold` detail diberi `appBar: SpothAppBar(title: const Text('Detail Tempat'), actions: ...)` — `SpothAppBar` sudah `PreferredSizeWidget` (tinggi `kToolbarHeight + 1`), putih, `elevation: 0`, `scrolledUnderElevation: 0`, `centerTitle: true`, bergaris bawah `softBorder`, jadi tampilannya identik dengan `TempatScreen`, `NotificationScreen`, `ProfileScreen`, `PlaceFormScreen`, `BookingFormScreen`.

   Judulnya teks tetap `Detail Tempat`, **bukan** `place.namaTempat`: nama tempat sudah menjadi judul besar (`fontSize: 27`) di `_DetailSheet` tepat di bawah galeri. Menampilkan nama yang sama dua kali bertumpuk adalah duplikasi yang membingungkan, bukan kejelasan.

   Tombol kembali tidak dibuat manual — `AppBar` menampilkan panah kembali otomatis karena rute detail selalu dibuka dengan `context.push` (dari `place_grid_card.dart:23` dan `owner_place_list.dart:272`), sehingga `ModalRoute.canPop` bernilai true.

   Konsekuensi yang ikut dibereskan: `_TopBar` (baris 347–383) dihapus, tombol kembali melayang di atas galeri dihapus, parameter `showChrome`/`topInset` dihapus dari `_HeroGallery`, dan `_CircleButton` (baris 536–566) dihapus karena tidak terpakai lagi — dibiarkan akan memunculkan peringatan unused pada `flutter analyze`.

   Catatan perilaku: `isOwner` dihitung dari `_place` yang masih `null` saat loading, jadi tombol `Kelola` baru muncul setelah detail berhasil dimuat. Ini disengaja — tombol kelola tidak boleh tampil untuk tempat yang belum diketahui pemiliknya.

2. **Aksi kelola dipisah ke sheet "Kelola Tempat".** Bar aksi bawah menjadi satu aksi utama per peran: penyewa melihat `Sewa Tempat Ini` (atau `Tempat Sedang Nonaktif` saat nonaktif); pemilik tempat ini melihat satu tombol `Kelola Tempat`; pemilik yang membuka tempat milik akun lain melihat keterangan tenang "Tempat ini dikelola oleh akun lain." Tombol `Kelola Tempat` membuka `showModalBottomSheet` berisi tiga aksi: `Ubah Data Tempat` (→ `_edit()`), `Aktifkan`/`Nonaktifkan Tempat` (→ `_toggleStatus()`), dan `Hapus Tempat` (→ `_delete()`, dengan dialog konfirmasi yang sudah ada), plus `Batal`. Dengan begitu `Hapus` tidak lagi berdampingan langsung dengan aksi utama, dan setiap akun tetap melihat detail publik yang sama — menjawab "tempat tetap bisa dilihat semua akun" sekaligus "menu sendiri untuk tiap pemilik".

3. **Hapus gradien.** `LinearGradient` di `_HeroGallery` dihapus dan tidak diganti gradien apa pun. Cabang `else → SizedBox.shrink()` di `_ActionBar` dihapus.

## Berkas yang diubah

| Berkas | Perubahan |
|---|---|
| `lib/screens/place/place_detail_screen.dart` | `build` (baris 191-244): tambah `appBar: SpothAppBar(title: Text('Detail Tempat'))`. `_DetailScrollView`: hapus blok `_TopBar` (baris 293-305), hapus `topInset`, sesuaikan padding atas jadi 12. `_HeroGallery` (baris 385-499): hapus `showChrome`/`topInset`, hapus `LinearGradient` (baris 425-438), hapus `Positioned` tombol kembali, jadikan penghitung foto tampil tanpa syarat. `_ActionBar` (baris 1173-1279): cabang penyewa tetap; pemilik → satu tombol `Kelola Tempat`; pemilik tempat milik akun lain → keterangan tenang; hapus cabang `else → SizedBox.shrink()`. Tambah `_KelolaSheet` (Ubah Data / Aktifkan-Nonaktifkan / Hapus Tempat / Batal) + `_KelolaAction`. Hapus `_TopBar` (baris 347-383) dan `_CircleButton` (baris 536-566). |
| `test/widget_test.dart` | Sesuaikan `'Detail tempat untuk pemilik menampilkan aksi kelola'` (kini satu tombol `Kelola Tempat`; `Nonaktifkan`/`Hapus Tempat` belum ada sebelum sheet dibuka; setelah tap `Kelola Tempat` keduanya ada), `'Detail tempat: pemilik menonaktifkan mengirim status NONAKTIF'` (tap `Kelola Tempat` dulu), `'Detail tempat: ketuk sisi kanan foto memajukan galeri'` (pakai `find.byIcon(Icons.chevron_right)`), `'Detail tempat untuk penyewa menampilkan tombol sewa'`, `'Detail tempat menampilkan sapaan lokasi, host, dan aturan'` (pakai helper `_pumpDetailRouter`). Tambah tes: pemilik melihat tempat milik akun lain tanpa aksi kelola; tidak ada `LinearGradient` di pohon widget detail. |

## Reuse (pakai yang sudah ada)

- `lib/widgets/spoth_app_bar.dart` — `SpothAppBar` siap pakai.
- `_toggleStatus`, `_delete`, `_edit` (`place_detail_screen.dart:84-179`) — logika sudah benar, hanya pindah pemicu.
- Pola bottom sheet: `PlaceFormScreen._showPickSheet` (`place_form_screen.dart:148`) dan `PlaceCatalog._showFilterSheet` (`place_catalog.dart:45`).
- `lib/widgets/empty_state.dart`, `lib/widgets/shimmer_loading.dart` (`DetailSkeleton`), `lib/core/utils/format.dart` (`formatRupiah`, `formatDiskonPersen`, `namaDepan`).

## Langkah kerja

1. Baca ulang `place_detail_screen.dart` bagian `build`, `_DetailScrollView`, `_HeroGallery`, `_ActionBar` sebelum menyunting.
2. Tambah `appBar: SpothAppBar(title: Text('Detail Tempat'))` di `Scaffold`, lalu hapus `_TopBar` beserta pemakaiannya dan sesuaikan `padding` atas.
3. Di `_HeroGallery`: hapus `showChrome`/`topInset`, hapus `LinearGradient`, hapus `Positioned` tombol kembali; **pertahankan** penghitung foto (tampil tanpa syarat).
4. Di `_ActionBar`: ubah cabang pemilik menjadi satu tombol `Kelola Tempat`; tambah `_KelolaSheet` + `_KelolaAction`; hapus cabang `else → SizedBox.shrink()`.
5. `flutter analyze` — pastikan `No issues found!` (termasuk tidak ada unused element).
6. Sesuaikan tes di `test/widget_test.dart`, tambah tes baru.
7. `flutter test` — semua hijau termasuk `'Detail tempat tanpa overflow pada lebar web'` (1440/1920) dan `'... semua ukuran layar'`.
8. Commit di `feature/place-detail`: bar atas seragam, aksi kelola via menu, gradien dihapus.

## Di luar cakupan

- Tidak mengubah `PlaceService`, `PlaceModel`, provider Riverpod, atau `app_router.dart` — rute tetap `push`.
- Tidak mengubah tampilan Beranda penyewa/pemilik (sudah beres di commit sebelumnya).
- Tidak mengubah halaman lain selain memastikan tidak ada regresi.
- Tidak menambah warna baru; palet tetap `AppColors` (oranye `0xFFF97316`, `lightOrange`, `charcoal`, `secondaryText`, `softBorder`).
- Tidak menyentuh aset tak terlacak (`assets/icons/spoth-umkm-logo.avif`, `assets/referensi/`, `AGENTS.md`).

## Verifikasi

1. `flutter analyze` → `No issues found!`
2. `flutter test` → semua lulus, termasuk tes overflow lebar web (1440×900, 1920×1080) dan semua ukuran (320×480 … 1280×800).
3. Manual (`flutter run` yang sedang jalan, hot restart):
   - Pemilik buka detail tempatnya → bar atas menampilkan **Detail Tempat** + panah kembali; bar bawah hanya satu tombol `Kelola Tempat`.
   - Ketuk ikon `Kelola` → sheet muncul dengan `Nonaktifkan` dan `Hapus Tempat`; `Hapus Tempat` memunculkan dialog konfirmasi, lalu menghapus dan kembali.
   - Penyewa buka detail → `Sewa Tempat Ini`, tanpa opsi kelola.
   - Galeri foto: tidak ada tombol kembali melayang, tidak ada gradien gelap.
   - `flutter analyze` bersih tanpa warning unused.
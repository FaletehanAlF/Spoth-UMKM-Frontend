## Catatan dari refleksi VibeCode

### layout-web-lebar

Aplikasi ini dipakai di web pada jendela lebar, bukan hanya di ponsel. Layar yang hanya punya satu kolom selebar penuh dengan tinggi maksimum (mis. galeri maksimal ~420px, sheet info mengapung di ruang kosong) terbaca "kurang" di web meski benar di ponsel.

Pola yang dipakai: pada ruang lebar (sekitar ≥860px) pecah jadi dua kolom, dan pada ruang sedang (sekitar ≥720px) kartu/ringkasan disandingkan mendatar alih-alih menumpuk. Konten dibatasi lebarnya dan dipusatkan supaya teks tidak melebar jadi satu baris panjang.

Permukaan kartu memakai latar putih dengan border tipis; latar gelap (charcoal) hanya untuk aksen, bukan latar kartu.

Widget test pada ukuran lebar (mis. 1440×900, 1920×1080) berguna untuk menangkap overflow yang tidak terlihat di ukuran ponsel. Perhitungan lebar kolom harus mengurangi padding kontainer lebih dulu, karena `LayoutBuilder` melaporkan batas kotaknya sendiri, bukan batas anak di dalam padding.

<!-- ditambahkan 2026-11-16T14:49:59.496Z -->

### sidebar-jangan-dobel

`MainShell` sudah merender sidebar (web ≥900px) atau bar bawah (ponsel) untuk semua tab di `IndexedStack`. Layar yang hidup di dalam shell itu (Beranda, Tempat, Kelola Tempat, Booking, Profil) harus berupa `Scaffold` polos tanpa membungkus `SpothSidebarScaffold` lagi — jika dibungkus, sidebar tampil dua kali berdampingan di web.

`SpothSidebarScaffold` hanya untuk rute yang dibuka di luar shell (detail tempat, form tempat, form sewa, notifikasi). Kalau ada layar baru yang bisa dipanggil dari dua tempat (di shell dan sebagai rute), pilih salah satu; jangan pasang wrapper "untuk berjaga-jaga".

<!-- ditambahkan 2026-11-17T13:10:00.000Z -->

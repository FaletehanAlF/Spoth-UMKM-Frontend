import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/booking_service.dart';
import '../../core/services/place_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/booking_model.dart';
import '../../models/place_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/nav_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';

/// Form pemesanan tempat untuk **Penyewa (TENANT)**.
///
/// Alur sesuai backend:
/// 1. Penyewa memilih tanggal mulai, lama sewa, dan jenis usaha.
/// 2. "Cek Pratinjau Biaya" → `GET /bookings/preview-price` (mencakup
///    pemeriksaan bentrok jadwal oleh server).
/// 3. "Buat Pemesanan" → `POST /bookings`; backend yang menghitung total,
///    membuat notifikasi, dan mengembalikan status MENUNGGU_PEMBAYARAN.
///
/// Hanya dapat diakses Penyewa — role lain melihat pesan pembatasan.
class BookingFormScreen extends ConsumerStatefulWidget {
  const BookingFormScreen({super.key, required this.placeId});

  final String placeId;

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durasiController = TextEditingController();
  final _jenisUsahaController = TextEditingController();

  DateTime? _tanggalMulai;
  PricePreviewModel? _preview;
  bool _loadingPlace = true;
  bool _checkingPreview = false;
  bool _submitting = false;
  String? _loadError;
  PlaceModel? _place;

  @override
  void initState() {
    super.initState();
    _loadPlace();
  }

  @override
  void dispose() {
    _durasiController.dispose();
    _jenisUsahaController.dispose();
    super.dispose();
  }

  Future<void> _loadPlace() async {
    setState(() {
      _loadingPlace = true;
      _loadError = null;
    });

    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      final place = await ref
          .read(placeServiceProvider)
          .getPlaceDetail(id: widget.placeId, token: token);

      if (!mounted) return;
      setState(() => _place = place);
    } catch (_) {
      if (mounted) {
        setState(() => _loadError = 'Gagal memuat data tempat');
      }
    } finally {
      if (mounted) setState(() => _loadingPlace = false);
    }
  }

  Future<void> _pickTanggal() async {
    final hariIni = DateTime.now();
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggalMulai ?? hariIni,
      firstDate: DateTime(hariIni.year, hariIni.month, hariIni.day),
      lastDate: hariIni.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme
              .copyWith(primary: AppColors.primaryOrange),
        ),
        child: child!,
      ),
    );

    if (dipilih != null) {
      setState(() {
        _tanggalMulai = dipilih;
        _preview = null;
      });
    }
  }

  bool get _formLengkap =>
      _tanggalMulai != null &&
      (int.tryParse(_durasiController.text.trim()) ?? 0) > 0 &&
      _jenisUsahaController.text.trim().isNotEmpty;

  String _tanggalText(DateTime tanggal) {
    final bulan = tanggal.month.toString().padLeft(2, '0');
    final hari = tanggal.day.toString().padLeft(2, '0');
    return '${tanggal.year}-$bulan-$hari';
  }

  Future<void> _checkPreview() async {
    if (_checkingPreview) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || !_formLengkap) return;

    setState(() => _checkingPreview = true);
    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      if (token == null) return;

      final preview = await ref
          .read(bookingServiceProvider)
          .previewPrice(
            token: token,
            placeId: widget.placeId,
            tanggalMulai: _tanggalText(_tanggalMulai!),
            jumlahDurasi: int.parse(_durasiController.text.trim()),
          );

      if (!mounted) return;
      setState(() => _preview = preview);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghitung pratinjau biaya.')),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingPreview = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || !_formLengkap) return;

    setState(() => _submitting = true);
    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      if (token == null) return;

      await ref
          .read(bookingServiceProvider)
          .createBooking(
            token: token,
            payload: {
              'place_id': widget.placeId,
              'tanggal_mulai': _tanggalText(_tanggalMulai!),
              'jumlah_durasi': int.parse(_durasiController.text.trim()),
              'jenis_usaha': _jenisUsahaController.text.trim(),
            },
          );

      // Daftar penyewaan diperbarui agar tab Booking menampilkan data terbaru.
      await ref.read(bookingsProvider.notifier).refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pemesanan berhasil dibuat. Silakan lakukan pembayaran.',
          ),
        ),
      );

      // Arahkan ke tab Booking.
      ref.read(mainNavIndexProvider.notifier).setTab(2);
      context.go('/home');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal membuat pemesanan. Jadwal mungkin sudah dipesan — coba cek lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final bolehMemesan = user?.role == UserModel.roleTenant;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const SpothAppBar(title: Text('Form Penyewaan')),
      body: !bolehMemesan
          ? const Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: EmptyState(
                  icon: Icons.lock_outline,
                  title: 'Hanya penyewa yang dapat memesan',
                  message:
                      'Fitur penyewaan tempat khusus untuk akun dengan role '
                      'Penyewa.',
                ),
              ),
            )
          : _loadingPlace
          ? const Padding(padding: EdgeInsets.all(20), child: DetailSkeleton())
          : _loadError != null
          ? Center(
              child: EmptyState(
                icon: Icons.wifi_off,
                title: _loadError!,
                message: 'Periksa koneksi internet Anda lalu coba lagi.',
                actionLabel: 'Coba Lagi',
                onAction: _loadPlace,
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lightOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _place?.namaTempat ?? '-',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatRupiah(_place?.hargaEfektif ?? 0)} '
                          '/${_place?.durasiLabel ?? '-'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: _tanggalMulai == null
                          ? ''
                          : formatDateString(_tanggalMulai.toString()),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Tanggal Mulai',
                      hintText: 'Pilih tanggal mulai sewa',
                      prefixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.secondaryText,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.edit_calendar_outlined),
                        tooltip: 'Pilih tanggal',
                        onPressed: _pickTanggal,
                      ),
                    ),
                    onTap: _pickTanggal,
                    validator: (value) => _tanggalMulai == null
                        ? 'Tanggal mulai wajib dipilih'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durasiController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Lama Sewa',
                      hintText: 'Jumlah satuan durasi, mis: 3',
                    ),
                    onChanged: (_) => setState(() => _preview = null),
                    validator: (value) {
                      final jumlah = int.tryParse(value?.trim() ?? '') ?? 0;
                      if (jumlah < 1) {
                        return 'Lama sewa minimal 1';
                      }
                      if (jumlah > 365) {
                        return 'Lama sewa maksimal 365';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _jenisUsahaController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Usaha',
                      hintText: 'Contoh: Warung Makan',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Jenis usaha wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: _checkingPreview ? null : _checkPreview,
                    child: Text(
                      _checkingPreview
                          ? 'Menghitung...'
                          : 'Cek Pratinjau Biaya',
                    ),
                  ),
                  if (_preview != null) ...[
                    const SizedBox(height: 16),
                    _PreviewCard(preview: _preview!),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(
                      _submitting ? 'Memproses...' : 'Buat Pemesanan',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

/// Kartu hasil pratinjau biaya dari backend.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});

  final PricePreviewModel preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview.tersedia ? 'Jadwal tersedia' : 'Jadwal bentrok',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: preview.tersedia
                  ? AppColors.primaryOrange
                  : AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          _PreviewRow(
            label: 'Selesai pada',
            value: formatDateString(preview.tanggalSelesai),
          ),
          _PreviewRow(
            label: 'Harga satuan',
            value: formatRupiah(preview.hargaSatuan),
          ),
          _PreviewRow(
            label: 'Total',
            value: formatRupiah(preview.totalHarga),
            bold: true,
          ),
          if (!preview.tersedia)
            Text(
              preview.jumlahKonflik > 0
                  ? 'Terdapat ${preview.jumlahKonflik} jadwal yang sudah '
                        'dipesan pada rentang ini.'
                  : 'Jadwal tidak tersedia.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/api_service.dart';
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
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';
import '../../widgets/spoth_sidebar_scaffold.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  const BookingFormScreen({super.key, required this.placeId});

  final String placeId;

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tanggalController = TextEditingController();
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
    _tanggalController.dispose();
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
        _tanggalController.text = formatDateString(_tanggalText(dipilih));
        _preview = null;
      });
    }
  }

  String _tanggalText(DateTime tanggal) {
    final bulan = tanggal.month.toString().padLeft(2, '0');
    final hari = tanggal.day.toString().padLeft(2, '0');
    return '${tanggal.year}-$bulan-$hari';
  }

  int get _jumlahDurasi => int.tryParse(_durasiController.text.trim()) ?? 0;

  String get _satuanDurasi => switch (_place?.tipeDurasi) {
    'HARIAN' => 'hari',
    'MINGGUAN' => 'minggu',
    'BULANAN' => 'bulan',
    _ => 'satuan',
  };

  DateTime? get _tanggalSelesai {
    final mulai = _tanggalMulai;
    final place = _place;
    final jumlah = _jumlahDurasi;

    if (mulai == null || place == null || jumlah < 1 || jumlah > 365) {
      return null;
    }

    return tanggalSelesaiSewa(mulai, place.tipeDurasi, jumlah);
  }

  int? get _totalHari {
    final mulai = _tanggalMulai;
    final selesai = _tanggalSelesai;

    if (mulai == null || selesai == null) {
      return null;
    }

    final awal = DateTime.utc(mulai.year, mulai.month, mulai.day);
    return selesai.difference(awal).inDays + 1;
  }

  String get _ringkasanDurasi {
    final totalHari = _totalHari;

    if (totalHari == null) {
      return 'Dihitung otomatis setelah tanggal dan lama sewa diisi.';
    }

    if (_satuanDurasi == 'hari') {
      return '$_jumlahDurasi hari, dihitung otomatis oleh sistem.';
    }

    return '$_jumlahDurasi $_satuanDurasi ($totalHari hari), '
        'dihitung otomatis oleh sistem.';
  }

  void _setDurasi(int nilai) {
    final baru = nilai.clamp(1, 365);
    final teks = '$baru';

    _durasiController.value = TextEditingValue(
      text: teks,
      selection: TextSelection.collapsed(offset: teks.length),
    );

    setState(() => _preview = null);
  }

  bool get _formLengkap =>
      _tanggalMulai != null &&
      _jumlahDurasi > 0 &&
      _jenisUsahaController.text.trim().isNotEmpty;

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
            jumlahDurasi: _jumlahDurasi,
          );

      if (!mounted) return;
      setState(() => _preview = preview);
    } on ApiException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('Gagal menghitung pratinjau biaya.');
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

      final booking = await ref
          .read(bookingServiceProvider)
          .createBooking(
            token: token,
            payload: {
              'place_id': widget.placeId,
              'tanggal_mulai': _tanggalText(_tanggalMulai!),
              'jumlah_durasi': _jumlahDurasi,
              'jenis_usaha': _jenisUsahaController.text.trim(),
            },
          );

      await ref.read(bookingsProvider.notifier).refresh();

      if (!mounted) return;

      await context.push('/payment?id=${booking.id}');

      if (!mounted) return;

      await ref.read(bookingsProvider.notifier).refresh();

      if (!mounted) return;
      ref.read(mainNavIndexProvider.notifier).setTab(MainTab.booking);
      context.go('/home');
    } on ApiException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack(
        'Gagal membuat pemesanan. Jadwal mungkin sudah dipesan — coba cek lagi.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(labelText: label, hintText: hint);
  }

  Widget _buildFields() {
    final selesai = _tanggalSelesai;
    final teksSelesai = selesai == null
        ? ''
        : formatDateString(_tanggalText(selesai));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.date_range_outlined,
          title: 'Periode Sewa',
        ),
        const SizedBox(height: 12),
        TextFormField(
          readOnly: true,
          controller: _tanggalController,
          decoration:
              _inputDecoration(
                'Tanggal Mulai',
                'Pilih tanggal mulai sewa',
              ).copyWith(
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
          validator: (value) =>
              _tanggalMulai == null ? 'Tanggal mulai wajib dipilih' : null,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DurasiButton(
              icon: Icons.remove,
              onPressed: _jumlahDurasi > 1
                  ? () => _setDurasi(_jumlahDurasi - 1)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _durasiController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: _inputDecoration(
                  'Lama Sewa',
                  'Contoh: 3',
                ).copyWith(suffixText: _satuanDurasi),
                onChanged: (_) => setState(() => _preview = null),
                validator: (value) {
                  final jumlah = int.tryParse(value?.trim() ?? '') ?? 0;
                  if (jumlah < 1) {
                    return 'Lama sewa minimal 1 $_satuanDurasi';
                  }
                  if (jumlah > 365) {
                    return 'Lama sewa maksimal 365 $_satuanDurasi';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            _DurasiButton(
              icon: Icons.add,
              onPressed: _jumlahDurasi < 365
                  ? () => _setDurasi(_jumlahDurasi + 1)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: ValueKey('tanggal-selesai-$teksSelesai'),
          initialValue: teksSelesai,
          readOnly: true,
          canRequestFocus: false,
          decoration: _inputDecoration('Tanggal Selesai', 'Terisi otomatis')
              .copyWith(
                filled: true,
                fillColor: AppColors.lightOrange,
                prefixIcon: const Icon(
                  Icons.event_available_outlined,
                  color: AppColors.primaryOrange,
                ),
                helperText: _ringkasanDurasi,
                helperMaxLines: 2,
              ),
        ),
        const SizedBox(height: 24),
        const _SectionHeader(
          icon: Icons.storefront_outlined,
          title: 'Detail Usaha',
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _jenisUsahaController,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration('Jenis Usaha', 'Contoh: Warung Makan'),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Jenis usaha wajib diisi'
              : null,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _checkingPreview ? null : _checkPreview,
            icon: _checkingPreview
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.calculate_outlined),
            label: Text(
              _checkingPreview ? 'Menghitung...' : 'Cek Pratinjau Biaya',
            ),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Buat Pemesanan',
          isLoading: _submitting,
          height: 52,
          borderRadius: 14,
          onPressed: _submit,
        ),
        const SizedBox(height: 8),
        Text(
          'Tanggal selesai dihitung otomatis oleh server berdasarkan '
          'lama sewa dan tipe durasi tempat.',
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.4,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final bolehMemesan = user?.role == UserModel.roleTenant;

    final page = Scaffold(
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
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: DetailSkeleton(),
            )
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
          : Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final lebarKolomWeb = constraints.maxWidth >= 860;

                      if (!lebarKolomWeb) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TempatCard(place: _place!),
                            const SizedBox(height: 20),
                            Form(key: _formKey, child: _buildFields()),
                            if (_preview != null) ...[
                              const SizedBox(height: 20),
                              _PreviewCard(preview: _preview!),
                            ],
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Form(key: _formKey, child: _buildFields()),
                          ),
                          const SizedBox(width: 28),
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _TempatCard(place: _place!),
                                if (_preview != null) ...[
                                  const SizedBox(height: 16),
                                  _PreviewCard(preview: _preview!),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
    );

    return SpothSidebarScaffold(activeTab: MainTab.tempat, child: page);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryOrange),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}

class _DurasiButton extends StatelessWidget {
  const _DurasiButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final aktif = onPressed != null;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: Icon(
            icon,
            size: 20,
            color: aktif ? AppColors.charcoal : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}

class _TempatCard extends StatelessWidget {
  const _TempatCard({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final foto = place.foto.isNotEmpty ? place.foto.first : null;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                foto == null
                    ? const _TempatPhotoPlaceholder()
                    : Image.network(
                        foto,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const _TempatPhotoPlaceholder(),
                      ),
                if (place.foto.length > 1)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.softBorder),
                      ),
                      child: Text(
                        '${place.foto.length} foto',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.namaTempat,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${place.kategoriLabel} • ${place.durasiLabel}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.secondaryText,
                  ),
                ),
                if (place.alamat.trim().isNotEmpty ||
                    place.kota.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${place.alamat}, ${place.kota}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatRupiah(place.hargaEfektif),
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '/${place.durasiLabel.toLowerCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TempatPhotoPlaceholder extends StatelessWidget {
  const _TempatPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightOrange,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 34,
            color: AppColors.primaryOrange,
          ),
          SizedBox(height: 6),
          Text(
            'Foto tempat belum tersedia',
            style: TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});

  final PricePreviewModel preview;

  @override
  Widget build(BuildContext context) {
    final promo = preview.hargaPromo;
    final adaPromo = promo != null && promo > 0 && promo < preview.hargaNormal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: preview.tersedia
              ? AppColors.neutralBorder
              : AppColors.softBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                preview.tersedia
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                size: 18,
                color: preview.tersedia
                    ? AppColors.primaryOrange
                    : AppColors.secondaryText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  preview.tersedia ? 'Jadwal tersedia' : 'Jadwal bentrok',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: preview.tersedia
                        ? AppColors.charcoal
                        : AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Row(label: 'Tempat', value: preview.namaTempat),
          _Row(
            label: 'Tanggal',
            value:
                '${formatDateString(preview.tanggalMulai)} – '
                '${formatDateString(preview.tanggalSelesai)}',
          ),
          _Row(
            label: 'Lama Sewa',
            value:
                '${preview.jumlahDurasi} × ${preview.tipeDurasi.toLowerCase()}',
          ),
          if (adaPromo)
            _Row(
              label: 'Harga Normal',
              value: formatRupiah(preview.hargaNormal),
              coret: true,
            ),
          _Row(
            label: 'Harga Sewa',
            value:
                '${formatRupiah(preview.hargaSatuan)} '
                '/${preview.tipeDurasi.toLowerCase()}',
          ),
          const _Divider(),
          _Row(
            label: 'Total',
            value: formatRupiah(preview.totalHarga),
            bold: true,
          ),
          _Row(
            label: 'Komisi Platform',
            value: formatRupiah(preview.komisiPlatform),
          ),
          if (!preview.tersedia) ...[
            const SizedBox(height: 10),
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
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.bold = false,
    this.coret = false,
  });

  final String label;
  final String value;
  final bool bold;
  final bool coret;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: bold ? AppColors.charcoal : AppColors.secondaryText,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: bold ? 14 : 12.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: bold ? AppColors.charcoal : AppColors.darkText,
                decoration: coret ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Divider(height: 1, thickness: 1, color: AppColors.softBorder),
    );
  }
}

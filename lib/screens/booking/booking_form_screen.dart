import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/api_service.dart';
import '../../core/services/booking_service.dart';
import '../../core/services/place_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/format.dart';
import '../../models/availability_model.dart';
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
  final _jenisUsahaController = TextEditingController();

  /// Paket yang dipilih penyewa: "MINGGUAN" atau "BULANAN".
  String _tipeDurasi = 'MINGGUAN';

  /// Berapa paket yang disewa (1-3 minggu, atau 1-6 bulan).
  int _jumlahDurasi = 1;

  DateTime? _tanggalMulai;
  PricePreviewModel? _preview;
  String? _previewKey;
  PlaceAvailabilityModel? _availability;
  String? _availabilityKey;
  String? _availabilityError;
  Timer? _availabilityDebounce;
  int _availabilityRequest = 0;
  int _previewRequest = 0;
  bool _loadingPlace = true;
  bool _checkingPreview = false;
  bool _checkingAvailability = false;
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
    _availabilityDebounce?.cancel();
    _tanggalController.dispose();
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
      setState(() {
        _place = place;
        final paket = place.paketTermurah;
        if (paket != null) {
          _tipeDurasi = paket.tipe;
          _jumlahDurasi = 1;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadError = 'Gagal memuat data tempat');
      }
    } finally {
      if (mounted) setState(() => _loadingPlace = false);
    }
  }

  /// Tanggal paling awal yang boleh dipilih: hari ini.
  DateTime get _tanggalPertama {
    final hariIni = DateTime.now();
    return DateTime(hariIni.year, hariIni.month, hariIni.day);
  }

  /// Tanggal paling akhir yang boleh dipilih (setahun setelah mulai).
  DateTime get _tanggalTerakhir => _tanggalPertama.add(const Duration(days: 365));

  Future<void> _pickTanggal() async {
    final pertama = _tanggalPertama;
    final terakhir = _tanggalTerakhir;
    final awalTerpilih = _tanggalMulai;
    final awal = awalTerpilih != null && !awalTerpilih.isBefore(pertama)
        ? awalTerpilih
        : pertama;

    final dipilih = await showDatePicker(
      context: context,
      initialDate: awal,
      firstDate: pertama,
      lastDate: terakhir,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme
              .copyWith(primary: AppColors.primaryInk),
        ),
        child: child!,
      ),
    );

    if (dipilih != null) {
      setState(() {
        _tanggalMulai = dipilih;
        _tanggalController.text = _formatTanggalInput(dipilih);
        _batalkanPratinjau();
        _availability = null;
        _availabilityKey = null;
        _availabilityError = null;
      });
      _jadwalkanCekKetersediaan();
    }
  }

  String _tanggalText(DateTime tanggal) {
    final bulan = tanggal.month.toString().padLeft(2, '0');
    final hari = tanggal.day.toString().padLeft(2, '0');
    return '${tanggal.year}-$bulan-$hari';
  }

  /// Format tanggal untuk diketik penyewa, contoh "26/11/2026".
  String _formatTanggalInput(DateTime tanggal) {
    final bulan = tanggal.month.toString().padLeft(2, '0');
    final hari = tanggal.day.toString().padLeft(2, '0');
    return '$hari/$bulan/${tanggal.year}';
  }

  /// Membaca tanggal yang diketik (format dd/MM/yyyy).
  DateTime? _bacaTanggalInput(String nilai) {
    final bagian = nilai.trim().split('/');
    if (bagian.length != 3) return null;

    final hari = int.tryParse(bagian[0]);
    final bulan = int.tryParse(bagian[1]);
    final tahun = int.tryParse(bagian[2]);
    if (hari == null || bulan == null || tahun == null) return null;

    final tanggal = DateTime(tahun, bulan, hari);
    final cocok =
        tanggal.day == hari && tanggal.month == bulan && tanggal.year == tahun;
    return cocok ? tanggal : null;
  }

  bool _diLuarBatasTanggal(DateTime tanggal) {
    final hari = DateTime(tanggal.year, tanggal.month, tanggal.day);
    return hari.isBefore(_tanggalPertama) || hari.isAfter(_tanggalTerakhir);
  }

  void _ubahTanggalMulai(String nilai) {
    final tanggal = _bacaTanggalInput(nilai);

    if (nilai.trim().isEmpty) {
      setState(() {
        _tanggalMulai = null;
        _batalkanPratinjau();
        _availability = null;
        _availabilityKey = null;
        _availabilityError = null;
      });
      return;
    }

    if (tanggal == null || _diLuarBatasTanggal(tanggal)) return;

    setState(() {
      _tanggalMulai = tanggal;
      _batalkanPratinjau();
      _availability = null;
      _availabilityKey = null;
      _availabilityError = null;
    });
    _jadwalkanCekKetersediaan();
  }

  String? _validasiTanggalMulai(String? nilai) {
    final teks = nilai?.trim() ?? '';
    if (teks.isEmpty) return 'Tanggal mulai wajib diisi';

    final tanggal = _bacaTanggalInput(teks);
    if (tanggal == null) return 'Gunakan format 26/11/2026';

    if (tanggal.isBefore(_tanggalPertama)) {
      return 'Tanggal mulai tidak boleh sebelum hari ini';
    }
    if (tanggal.isAfter(_tanggalTerakhir)) {
      return 'Tanggal mulai maksimal 1 tahun ke depan';
    }
    return null;
  }

  /// Batas jumlah paket: 3 minggu atau 6 bulan.
  int get _batasPaket => _tipeDurasi == 'BULANAN' ? 6 : 3;

  String get _satuanDurasi => labelSatuan(_tipeDurasi);

  DateTime? get _tanggalSelesai {
    final mulai = _tanggalMulai;

    if (mulai == null || _jumlahDurasi < 1 || _jumlahDurasi > _batasPaket) {
      return null;
    }

    return tanggalSelesaiSewa(mulai, _tipeDurasi, _jumlahDurasi);
  }

  void _setJumlahDurasi(int nilai) {
    setState(() {
      _jumlahDurasi = nilai.clamp(1, _batasPaket);
      _batalkanPratinjau();
      _availability = null;
      _availabilityKey = null;
      _availabilityError = null;
    });
    _jadwalkanCekKetersediaan();
  }

  void _setTipeDurasi(String tipe) {
    if (tipe == _tipeDurasi) {
      return;
    }

    setState(() {
      _tipeDurasi = tipe;
      _jumlahDurasi = 1;
      _batalkanPratinjau();
      _availability = null;
      _availabilityKey = null;
      _availabilityError = null;
    });
    _jadwalkanCekKetersediaan();
  }

  bool get _formLengkap =>
      _tanggalMulai != null &&
      _jumlahDurasi > 0 &&
      _jenisUsahaController.text.trim().isNotEmpty;

  String? get _availabilitySelectionKey {
    final mulai = _tanggalMulai;

    if (mulai == null || _jumlahDurasi < 1 || _jumlahDurasi > _batasPaket) {
      return null;
    }

    return '${_tanggalText(mulai)}|$_tipeDurasi|$_jumlahDurasi';
  }

  PlaceAvailabilityModel? get _availabilitySaatIni =>
      _availabilityKey == _availabilitySelectionKey ? _availability : null;

  PricePreviewModel? get _previewSaatIni =>
      _previewKey == _availabilitySelectionKey ? _preview : null;

  void _batalkanPratinjau() {
    _preview = null;
    _previewKey = null;
    _previewRequest += 1;
    _checkingPreview = false;
  }

  bool get _tidakTersedia =>
      _availabilitySaatIni != null && !_availabilitySaatIni!.tersedia;

  void _jadwalkanCekKetersediaan() {
    _availabilityDebounce?.cancel();
    _availabilityRequest += 1;

    if (_availabilitySelectionKey == null) {
      if (_availability != null ||
          _availabilityError != null ||
          _checkingAvailability) {
        setState(() {
          _availability = null;
          _availabilityKey = null;
          _availabilityError = null;
          _checkingAvailability = false;
        });
      }
      return;
    }

    _availabilityDebounce = Timer(
      const Duration(milliseconds: 400),
      _cekKetersediaan,
    );
  }

  Future<PlaceAvailabilityModel?> _cekKetersediaan() async {
    final key = _availabilitySelectionKey;
    final mulai = _tanggalMulai;
    final jumlahDurasi = _jumlahDurasi;

    if (key == null || mulai == null) {
      return null;
    }

    _availabilityDebounce?.cancel();
    final permintaan = ++_availabilityRequest;
    setState(() {
      _checkingAvailability = true;
      _availabilityError = null;
    });

    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      final hasil = await ref
          .read(placeServiceProvider)
          .checkAvailability(
            placeId: widget.placeId,
            tanggalMulai: _tanggalText(mulai),
            tipeDurasi: _tipeDurasi,
            jumlahDurasi: jumlahDurasi,
            token: token,
          );

      if (!mounted ||
          permintaan != _availabilityRequest ||
          key != _availabilitySelectionKey) {
        return null;
      }

      setState(() {
        _availability = hasil;
        _availabilityKey = key;
        _checkingAvailability = false;
      });
      return hasil;
    } on ApiException catch (error) {
      if (!mounted || permintaan != _availabilityRequest) {
        return null;
      }

      setState(() {
        _availability = null;
        _availabilityKey = null;
        _availabilityError = error.message;
        _checkingAvailability = false;
      });
      return null;
    } catch (_) {
      if (!mounted || permintaan != _availabilityRequest) {
        return null;
      }

      setState(() {
        _availability = null;
        _availabilityKey = null;
        _availabilityError = 'Gagal memeriksa ketersediaan jadwal.';
        _checkingAvailability = false;
      });
      return null;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _checkPreview() async {
    if (_checkingPreview) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || !_formLengkap) return;

    final key = _availabilitySelectionKey;
    final mulai = _tanggalMulai;

    if (key == null || mulai == null) {
      return;
    }

    final jumlahDurasi = _jumlahDurasi;
    final permintaan = ++_previewRequest;

    setState(() => _checkingPreview = true);
    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      if (token == null) return;

      final preview = await ref
          .read(bookingServiceProvider)
          .previewPrice(
            token: token,
            placeId: widget.placeId,
            tanggalMulai: _tanggalText(mulai),
            tipeDurasi: _tipeDurasi,
            jumlahDurasi: jumlahDurasi,
          );

      if (!mounted ||
          permintaan != _previewRequest ||
          key != _availabilitySelectionKey) {
        return;
      }

      setState(() {
        _preview = preview;
        _previewKey = key;
      });
    } on ApiException catch (error) {
      if (!mounted || permintaan != _previewRequest) {
        return;
      }
      _showSnack(error.message);
    } catch (_) {
      if (!mounted || permintaan != _previewRequest) {
        return;
      }
      _showSnack('Gagal menghitung pratinjau biaya.');
    } finally {
      if (mounted && permintaan == _previewRequest) {
        setState(() => _checkingPreview = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || !_formLengkap) return;

    final key = _availabilitySelectionKey;
    final mulai = _tanggalMulai;

    if (key == null || mulai == null) {
      return;
    }

    final jumlahDurasi = _jumlahDurasi;

    setState(() => _submitting = true);
    try {
      final ketersediaan = await _cekKetersediaan();

      if (!mounted) return;

      if (key != _availabilitySelectionKey) {
        _showSnack(
          'Pilihan tanggal atau lama sewa berubah. Periksa ketersediaan lagi '
          'sebelum memesan.',
        );
        return;
      }

      if (ketersediaan == null) {
        _showSnack(
          _availabilityError ??
              'Gagal memeriksa ketersediaan jadwal. Coba lagi.',
        );
        return;
      }

      if (!ketersediaan.tersedia) {
        _showSnack(
          'Tanggal yang dipilih tidak tersedia. Pilih tanggal atau lama sewa '
          'lain.',
        );
        return;
      }

      final token = ref.read(authNotifierProvider.select((s) => s.token));
      if (token == null) return;

      final booking = await ref
          .read(bookingServiceProvider)
          .createBooking(
            token: token,
            payload: {
              'place_id': widget.placeId,
              'tanggal_mulai': _tanggalText(mulai),
              'tipe_durasi': _tipeDurasi,
              'jumlah_durasi': jumlahDurasi,
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
        'Gagal membuat pemesanan. Jadwal mungkin sudah dipesan - coba cek lagi.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(labelText: label, hintText: hint);
  }

  Widget _buildPaket() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Lama Sewa'),
        const SizedBox(height: 12),
        _PemilihPaket(
          paket: _place?.paket ?? const [],
          aktif: _tipeDurasi,
          onPilih: _setTipeDurasi,
          enabled: !_submitting,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DurasiButton(
              icon: Icons.remove,
              onPressed: _jumlahDurasi > 1
                  ? () => _setJumlahDurasi(_jumlahDurasi - 1)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$_jumlahDurasi $_satuanDurasi',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Maksimal $_batasPaket $_satuanDurasi',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _DurasiButton(
              icon: Icons.add,
              onPressed: _jumlahDurasi < _batasPaket
                  ? () => _setJumlahDurasi(_jumlahDurasi + 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJadwal() {
    final selesai = _tanggalSelesai;
    final teksSelesai = selesai == null ? '' : _formatTanggalInput(selesai);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Periode Sewa'),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tanggalController,
          keyboardType: TextInputType.datetime,
          decoration:
              _inputDecoration(
                'Tanggal Mulai',
                'Contoh: 26/11/2026',
              ).copyWith(
                prefixIcon: IconButton(
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.secondaryText,
                  ),
                  tooltip: 'Pilih dari kalender',
                  onPressed: _pickTanggal,
                ),
              ),
          onChanged: _ubahTanggalMulai,
          validator: _validasiTanggalMulai,
        ),
        const SizedBox(height: 20),
        const _SectionHeader(title: 'Waktu Sewa'),
        const SizedBox(height: 12),
        TextFormField(
          key: ValueKey('tanggal-selesai-$teksSelesai'),
          initialValue: teksSelesai,
          readOnly: true,
          canRequestFocus: false,
          decoration: _inputDecoration('Tanggal Selesai', 'Terisi otomatis')
              .copyWith(filled: true, fillColor: AppColors.lightOrange),
        ),
        if (_availabilitySelectionKey != null) ...[
          const SizedBox(height: 12),
          _AvailabilityInfo(
            loading: _checkingAvailability,
            error: _availabilityError,
            availability: _availabilitySaatIni,
            onRetry: _cekKetersediaan,
          ),
        ],
      ],
    );
  }

  Widget _buildDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Detail Usaha'),
        const SizedBox(height: 12),
        TextFormField(
          controller: _jenisUsahaController,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration('Jenis Usaha', 'Contoh: Warung Makan'),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Jenis usaha wajib diisi';
            if (text.length < 3) return 'Jenis usaha minimal 3 karakter';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAksi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
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
        const SizedBox(height: 12),
        PrimaryButton(
          label: _tidakTersedia ? 'Tanggal Tidak Tersedia' : 'Buat Pemesanan',
          isLoading: _submitting,
          height: 52,
          borderRadius: 14,
          onPressed: _tidakTersedia ? null : _submit,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final adalahPemilik =
        _place != null && user?.id == _place!.hostId && user!.id.isNotEmpty;
    final bolehMemesan =
        user?.role == UserModel.roleTenant && !adalahPemilik;
    final preview = _previewSaatIni;

    final page = Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const SpothAppBar(title: Text('Form Penyewaan')),
      body: !bolehMemesan
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: EmptyState(
                  icon: Icons.lock_outline,
                  title: adalahPemilik
                      ? 'Ini tempat Anda sendiri'
                      : 'Hanya penyewa yang dapat memesan',
                  message: adalahPemilik
                      ? 'Anda tidak bisa menyewa tempat milik Anda sendiri.'
                      : 'Fitur penyewaan tempat khusus untuk akun dengan role '
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
                  constraints: const BoxConstraints(maxWidth: AppWidth.page),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final duaKolom =
                          constraints.maxWidth >= AppWidth.twoColumn;
                      final form = Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPaket(),
                            const SizedBox(height: 24),
                            _buildJadwal(),
                            const SizedBox(height: 24),
                            _buildDetail(),
                          ],
                        ),
                      );
                      final kartuTempat = _TempatCard(place: _place!);
                      final aksi = _buildAksi();
                      final pratinjau = preview == null
                          ? null
                          : _PreviewCard(preview: preview);

                      if (!duaKolom) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            kartuTempat,
                            const SizedBox(height: 24),
                            form,
                            const SizedBox(height: 20),
                            aksi,
                            if (pratinjau != null) ...[
                              const SizedBox(height: 16),
                              pratinjau,
                            ],
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: form),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                kartuTempat,
                                const SizedBox(height: 16),
                                aksi,
                                if (pratinjau != null) ...[
                                  const SizedBox(height: 16),
                                  pratinjau,
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

class _AvailabilityInfo extends StatelessWidget {
  const _AvailabilityInfo({
    required this.loading,
    required this.error,
    required this.availability,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final PlaceAvailabilityModel? availability;
  final VoidCallback onRetry;

  String _alasanKonflik(BookedRange konflik) {
    switch (konflik.status) {
      case 'MENUNGGU_PEMBAYARAN':
        return 'Sudah dipesan dan menunggu pembayaran';
      case 'LUNAS':
        return 'Sudah dipesan dan lunas';
      default:
        return 'Jadwal sudah dipesan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    if (loading || (availability == null && error == null)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.softBorder),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Memeriksa ketersediaan tanggal...',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.softBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.wifi_off, size: 17, color: errorColor),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                error!,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    final hasil = availability!;
    final tersedia = hasil.tersedia;
    final alasan = <String>{
      for (final konflik in hasil.konflik) _alasanKonflik(konflik),
    }.toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tersedia
            ? AppColors.lightOrange
            : errorColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tersedia
              ? AppColors.softBorder
              : errorColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                tersedia ? Icons.check_circle_outline : Icons.event_busy,
                size: 18,
                color: tersedia ? AppColors.primaryInk : errorColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tersedia ? 'Tanggal tersedia' : 'Tanggal tidak tersedia',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tersedia ? AppColors.charcoal : errorColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${formatDateString(hasil.tanggalMulai)} - '
            '${formatDateString(hasil.tanggalSelesai)}',
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.secondaryText,
            ),
          ),
          if (!tersedia) ...[
            const SizedBox(height: 7),
            for (final item in alasan)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '- ',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 3),
            const Text(
              'Pilih tanggal atau lama sewa lain untuk melanjutkan.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
      ),
    );
  }
}

/// Pemilih paket sewa: mingguan, bulanan, atau keduanya.
///
/// Hanya paket yang ditawarkan tempat yang bisa dipilih. Bila tempat hanya
/// punya satu paket, bagian ini menampilkan satu keterangan saja.
class _PemilihPaket extends StatelessWidget {
  const _PemilihPaket({
    required this.paket,
    required this.aktif,
    required this.onPilih,
    required this.enabled,
  });

  final List<PaketSewa> paket;
  final String aktif;
  final ValueChanged<String> onPilih;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (paket.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paket sewa',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in paket)
              ChoiceChip(
                label: Text(
                  '${item.label} ${formatRupiah(item.harga)}',
                ),
                selected: aktif == item.tipe,
                selectedColor: AppColors.primaryDeep,
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: aktif == item.tipe
                      ? AppColors.white
                      : AppColors.charcoal,
                ),
                showCheckmark: false,
                onSelected: enabled && paket.length > 1
                    ? (_) => onPilih(item.tipe)
                    : null,
              ),
          ],
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
                  '${place.kategoriLabel} · '
                  '${place.paket.map((item) => item.label).join(' & ')}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.secondaryText,
                  ),
                ),
                if (place.alamat.trim().isNotEmpty ||
                    place.kecamatan.trim().isNotEmpty) ...[
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
                          '${place.alamat}, ${place.kecamatan}',
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
                for (final item in place.paket)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatRupiah(item.harga),
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 16,
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
                            '/${item.satuan}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
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
            color: AppColors.primaryInk,
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
                    ? AppColors.primaryInk
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
                '${formatDateString(preview.tanggalMulai)} - '
                '${formatDateString(preview.tanggalSelesai)}',
          ),
          _Row(
            label: 'Lama Sewa',
            value: labelDurasi(preview.tipeDurasi, preview.jumlahDurasi),
          ),
          _Row(
            label: 'Harga Sewa',
            value:
                '${formatRupiah(preview.hargaSatuan)} '
                '/${labelSatuan(preview.tipeDurasi)}',
          ),
          const _Divider(),
          _Row(
            label: 'Biaya Admin',
            value: formatRupiah(preview.adminFee),
          ),
          _Row(
            label: 'Total',
            value: formatRupiah(preview.totalHarga),
            bold: true,
          ),
          if (!preview.tersedia) ...[
            const SizedBox(height: 10),
            Text(
              preview.jumlahKonflik > 0
                  ? 'Ada ${preview.jumlahKonflik} konflik jadwal pada rentang '
                        'ini. Pilih tanggal atau lama sewa lain.'
                  : 'Jadwal pada rentang ini tidak tersedia. Pilih tanggal '
                        'atau lama sewa lain.',
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
  });

  final String label;
  final String value;
  final bool bold;

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



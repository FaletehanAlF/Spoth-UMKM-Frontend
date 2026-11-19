import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/api_service.dart';
import '../core/services/place_service.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/format.dart';
import '../models/availability_model.dart';
import '../providers/auth_provider.dart';
import 'availability_rule_card.dart';

class AvailabilityRuleSection extends ConsumerStatefulWidget {
  const AvailabilityRuleSection({
    super.key,
    required this.placeId,
    this.periodeSelesai,
  });

  final String? placeId;
  final DateTime? periodeSelesai;

  @override
  ConsumerState<AvailabilityRuleSection> createState() =>
      _AvailabilityRuleSectionState();
}

class _AvailabilityRuleSectionState
    extends ConsumerState<AvailabilityRuleSection> {
  List<AvailabilityRuleModel> _rules = const [];
  bool _loading = false;
  bool _menyimpan = false;
  String? _error;
  int _permintaan = 0;

  @override
  void initState() {
    super.initState();
    if (widget.placeId != null) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant AvailabilityRuleSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.placeId == widget.placeId) {
      return;
    }

    _rules = const [];
    _error = null;
    _loading = false;

    if (widget.placeId != null) {
      _load();
    }
  }

  Future<void> _load() async {
    final placeId = widget.placeId;
    if (placeId == null) {
      return;
    }

    final permintaan = ++_permintaan;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      final rules = await ref
          .read(placeServiceProvider)
          .getAvailabilityRules(placeId: placeId, token: token);

      if (!mounted || permintaan != _permintaan) {
        return;
      }

      final daftar = [...rules]..sort(_bandingkanAturan);
      setState(() {
        _rules = daftar;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted || permintaan != _permintaan) {
        return;
      }
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || permintaan != _permintaan) {
        return;
      }
      setState(() {
        _error = 'Gagal memuat aturan ketersediaan.';
        _loading = false;
      });
    }
  }

  Future<void> _bukaEditor({AvailabilityRuleModel? rule}) async {
    if (widget.placeId == null || _menyimpan) {
      return;
    }

    final draft = await showModalBottomSheet<_RuleDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RuleEditorSheet(
        initial: rule,
        periodeSelesai: widget.periodeSelesai,
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    await _simpan(draft, rule);
  }

  Future<void> _simpan(_RuleDraft draft, AvailabilityRuleModel? rule) async {
    final placeId = widget.placeId;
    final token = ref.read(authNotifierProvider.select((s) => s.token));

    if (placeId == null || token == null) {
      _showSnack('Sesi Anda berakhir. Silakan masuk kembali.');
      return;
    }

    setState(() => _menyimpan = true);

    try {
      final service = ref.read(placeServiceProvider);

      if (rule == null) {
        final baru = await service.createAvailabilityRule(
          token: token,
          placeId: placeId,
          payload: draft.toPayload(),
        );

        if (!mounted) return;

        final daftar = [..._rules, baru]..sort(_bandingkanAturan);
        setState(() => _rules = daftar);
        _showSnack('Aturan ketersediaan berhasil ditambahkan.');
      } else {
        final diperbarui = await service.updateAvailabilityRule(
          token: token,
          placeId: placeId,
          ruleId: rule.id,
          payload: draft.toPayload(),
        );

        if (!mounted) return;

        final daftar = [
          for (final item in _rules)
            item.id == diperbarui.id ? diperbarui : item,
        ]..sort(_bandingkanAturan);
        setState(() => _rules = daftar);
        _showSnack('Aturan ketersediaan berhasil diperbarui.');
      }
    } on ApiException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('Gagal menyimpan aturan ketersediaan. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _menyimpan = false);
      }
    }
  }

  Future<void> _hapus(AvailabilityRuleModel rule) async {
    final placeId = widget.placeId;
    final token = ref.read(authNotifierProvider.select((s) => s.token));

    if (placeId == null || token == null || _menyimpan) {
      return;
    }

    final dikonfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text('Hapus aturan?'),
        content: Text(
          'Aturan ${rule.tipeLabel.toLowerCase()} '
          '${rule.sasaranLabel.toLowerCase()} akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (dikonfirmasi != true || !mounted) {
      return;
    }

    setState(() => _menyimpan = true);

    try {
      await ref
          .read(placeServiceProvider)
          .deleteAvailabilityRule(
            token: token,
            placeId: placeId,
            ruleId: rule.id,
          );

      if (!mounted) return;

      setState(() {
        _rules = _rules.where((item) => item.id != rule.id).toList();
      });
      _showSnack('Aturan ketersediaan berhasil dihapus.');
    } on ApiException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('Gagal menghapus aturan ketersediaan. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _menyimpan = false);
      }
    }
  }

  void _showSnack(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  @override
  Widget build(BuildContext context) {
    final placeId = widget.placeId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_available_outlined,
                size: 18,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Aturan Ketersediaan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              if (placeId != null && _rules.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_rules.length} aturan',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Atur tanggal, hari, atau bulan saat tempat tidak dapat disewa. '
            'Aturan ini opsional.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.lightOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Aturan "Tidak tersedia" memblokir jadwal yang cocok. '
              'Aturan "Tersedia" hanya menjadi penanda dan tidak membuka '
              'blokir dari aturan lain.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (placeId == null)
            const _InfoBaris(
              icon: Icons.info_outline,
              pesan:
                  'Simpan tempat terlebih dahulu. Setelah tempat memiliki '
                  'ID dari server, aturan ketersediaan dapat ditambahkan.',
            )
          else if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            )
          else if (_error != null)
            _InfoBaris(
              icon: Icons.wifi_off,
              pesan: _error!,
              aksiLabel: 'Coba Lagi',
              onAksi: _load,
            )
          else ...[
            if (_rules.isEmpty)
              const _InfoBaris(
                icon: Icons.event_note_outlined,
                pesan:
                    'Belum ada aturan khusus. Ketersediaan mengikuti periode '
                    'tersedia dan jadwal yang sudah dipesan.',
              )
            else
              Column(
                children: [
                  for (var i = 0; i < _rules.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    AvailabilityRuleCard(
                      rule: _rules[i],
                      onEdit: _menyimpan
                          ? null
                          : () => _bukaEditor(rule: _rules[i]),
                      onDelete: _menyimpan ? null : () => _hapus(_rules[i]),
                    ),
                  ],
                ],
              ),
            if (_menyimpan) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 2),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _menyimpan ? null : () => _bukaEditor(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Aturan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBaris extends StatelessWidget {
  const _InfoBaris({
    required this.icon,
    required this.pesan,
    this.aksiLabel,
    this.onAksi,
  });

  final IconData icon;
  final String pesan;
  final String? aksiLabel;
  final VoidCallback? onAksi;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.secondaryText),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              pesan,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          if (aksiLabel != null && onAksi != null)
            TextButton(onPressed: onAksi, child: Text(aksiLabel!)),
        ],
      ),
    );
  }
}

class _RuleDraft {
  const _RuleDraft({
    required this.tipeAturan,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.tersedia,
    this.hari,
    this.bulan,
  });

  final String tipeAturan;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final int? hari;
  final int? bulan;
  final bool tersedia;

  Map<String, dynamic> toPayload() {
    return {
      'tipe_aturan': tipeAturan,
      'tanggal_mulai': formatTanggalApi(tanggalMulai),
      'tanggal_selesai': formatTanggalApi(tanggalSelesai),
      'hari': tipeAturan == 'HARI' ? hari : null,
      'bulan': tipeAturan == 'BULAN' ? bulan : null,
      'tersedia': tersedia,
    };
  }
}

class _RuleEditorSheet extends StatefulWidget {
  const _RuleEditorSheet({this.initial, this.periodeSelesai});

  final AvailabilityRuleModel? initial;
  final DateTime? periodeSelesai;

  @override
  State<_RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends State<_RuleEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _mulaiController = TextEditingController();
  final _selesaiController = TextEditingController();

  late String _tipe;
  late DateTime _mulai;
  late DateTime _selesai;
  late int? _hari;
  late int? _bulan;
  late bool _tersedia;

  @override
  void initState() {
    super.initState();

    final initial = widget.initial;
    final hariIni = DateTime.now();
    _mulai =
        DateTime.tryParse(initial?.tanggalMulai ?? '') ??
        DateTime(hariIni.year, hariIni.month, hariIni.day);
    _selesai = DateTime.tryParse(initial?.tanggalSelesai ?? '') ?? _mulai;
    _tipe = initial?.tipeAturan ?? 'TANGGAL';
    _hari = initial?.hari ?? 1;
    _bulan = initial?.bulan ?? 1;
    _tersedia = initial?.tersedia ?? false;

    _mulaiController.text = formatTanggal(_mulai);
    _selesaiController.text = formatTanggal(_selesai);
  }

  @override
  void dispose() {
    _mulaiController.dispose();
    _selesaiController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal({required bool mulai}) async {
    final hariIni = DateTime.now();
    final awal = mulai ? _mulai : _selesai;
    final pertama = mulai
        ? DateTime(2000)
        : DateTime(_mulai.year, _mulai.month, _mulai.day);
    final terakhir = DateTime(hariIni.year + 10, 12, 31);
    final initial = awal.isBefore(pertama)
        ? pertama
        : awal.isAfter(terakhir)
        ? terakhir
        : awal;

    final dipilih = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: pertama,
      lastDate: terakhir,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme
              .copyWith(primary: AppColors.primaryOrange),
        ),
        child: child!,
      ),
    );

    if (dipilih == null || !mounted) {
      return;
    }

    setState(() {
      if (mulai) {
        _mulai = dipilih;
        _mulaiController.text = formatTanggal(_mulai);
        if (_selesai.isBefore(_mulai)) {
          _selesai = _tipe == 'TANGGAL' ? _mulai : _batasAkhirDefault(_tipe);
          _selesaiController.text = formatTanggal(_selesai);
        }
      } else {
        _selesai = dipilih;
        _selesaiController.text = formatTanggal(_selesai);
      }
    });
  }

  bool get _aturanBaru => widget.initial == null;

  DateTime _batasAkhirDefault(String tipe) {
    final setahun = DateTime(_mulai.year + 1, _mulai.month, _mulai.day);
    final periode = widget.periodeSelesai;

    if (periode != null && periode.isAfter(_mulai)) {
      final cukup = tipe == 'BULAN'
          ? !periode.isBefore(setahun)
          : periode.difference(_mulai).inDays >= 6;

      if (cukup) {
        return periode;
      }
    }

    return setahun;
  }

  void _terapkanRentangDefault() {
    if (!_aturanBaru || _tipe == 'TANGGAL') {
      return;
    }

    if (_selesai.isAfter(_mulai)) {
      return;
    }

    _selesai = _batasAkhirDefault(_tipe);
    _selesaiController.text = formatTanggal(_selesai);
  }

  int get _jumlahTanggalCocok {
    if (_selesai.isBefore(_mulai)) {
      return 0;
    }

    var jumlah = 0;
    var tanggal = DateTime(_mulai.year, _mulai.month, _mulai.day);
    final akhir = DateTime(_selesai.year, _selesai.month, _selesai.day);

    while (!tanggal.isAfter(akhir)) {
      final cocok = switch (_tipe) {
        'HARI' => tanggal.weekday % 7 == _hari,
        'BULAN' => tanggal.month == _bulan,
        _ => true,
      };

      if (cocok) {
        jumlah += 1;
      }

      tanggal = DateTime(tanggal.year, tanggal.month, tanggal.day + 1);
    }

    return jumlah;
  }

  String get _ringkasanRentang {
    final rentang = '${formatTanggal(_mulai)} – ${formatTanggal(_selesai)}';
    final jumlah = _jumlahTanggalCocok;

    if (jumlah == 0) {
      return 'Tidak ada tanggal yang cocok dengan pilihan ini dalam rentang '
          '$rentang. Perpanjang tanggal selesai atau ubah pilihan hari/bulan.';
    }

    final sasaran = switch (_tipe) {
      'HARI' => 'setiap hari ${AvailabilityRuleModel.hariLabels[_hari] ?? '-'}',
      'BULAN' =>
        'setiap bulan ${AvailabilityRuleModel.bulanLabels[_bulan] ?? '-'}',
      _ => 'semua tanggal',
    };

    return 'Aturan berlaku untuk $sasaran dalam rentang $rentang '
        '($jumlah tanggal cocok).';
  }

  void _simpan() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    if (_tipe == 'HARI' && _hari == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih hari untuk aturan ini.')),
      );
      return;
    }

    if (_tipe == 'BULAN' && _bulan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih bulan untuk aturan ini.')),
      );
      return;
    }

    Navigator.of(context).pop(
      _RuleDraft(
        tipeAturan: _tipe,
        tanggalMulai: _mulai,
        tanggalSelesai: _selesai,
        hari: _tipe == 'HARI' ? _hari : null,
        bulan: _tipe == 'BULAN' ? _bulan : null,
        tersedia: _tersedia,
      ),
    );
  }

  String get _keteranganTipe {
    switch (_tipe) {
      case 'HARI':
        return 'Aturan berlaku pada hari yang dipilih di dalam rentang tanggal.';
      case 'BULAN':
        return 'Aturan berlaku pada bulan yang dipilih di dalam rentang tanggal.';
      default:
        return 'Aturan berlaku pada semua tanggal di dalam rentang tanggal.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final errorColor = Theme.of(context).colorScheme.error;
    final jumlahCocok = _jumlahTanggalCocok;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.initial == null
                                ? 'Tambah Aturan Ketersediaan'
                                : 'Ubah Aturan Ketersediaan',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tutup',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Tipe Aturan',
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
                        for (final tipe
                            in AvailabilityRuleModel.tipeLabels.entries)
                          ChoiceChip(
                            label: Text(tipe.value),
                            selected: _tipe == tipe.key,
                            selectedColor: AppColors.primaryOrange,
                            labelStyle: TextStyle(
                              color: _tipe == tipe.key
                                  ? AppColors.white
                                  : AppColors.secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                            showCheckmark: false,
                            onSelected: (_) {
                              if (tipe.key == _tipe) {
                                return;
                              }

                              setState(() {
                                _tipe = tipe.key;
                                _terapkanRentangDefault();
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _keteranganTipe,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mulaiController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Tanggal Mulai',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            onTap: () => _pilihTanggal(mulai: true),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Tanggal mulai wajib diisi'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _selesaiController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Tanggal Selesai',
                              prefixIcon: Icon(Icons.event_available_outlined),
                            ),
                            onTap: () => _pilihTanggal(mulai: false),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tanggal selesai wajib diisi';
                              }
                              if (_selesai.isBefore(_mulai)) {
                                return 'Tidak boleh sebelum tanggal mulai';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: jumlahCocok > 0
                            ? AppColors.lightOrange
                            : errorColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: jumlahCocok > 0
                              ? AppColors.softBorder
                              : errorColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            jumlahCocok > 0
                                ? Icons.event_available_outlined
                                : Icons.warning_amber_outlined,
                            size: 16,
                            color: jumlahCocok > 0
                                ? AppColors.primaryOrange
                                : errorColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _ringkasanRentang,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.45,
                                color: jumlahCocok > 0
                                    ? AppColors.secondaryText
                                    : errorColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_tipe == 'HARI') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Hari',
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
                          for (final hari
                              in AvailabilityRuleModel.hariLabels.entries)
                            ChoiceChip(
                              label: Text(hari.value),
                              selected: _hari == hari.key,
                              selectedColor: AppColors.primaryOrange,
                              labelStyle: TextStyle(
                                color: _hari == hari.key
                                    ? AppColors.white
                                    : AppColors.secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                              showCheckmark: false,
                              onSelected: (_) =>
                                  setState(() => _hari = hari.key),
                            ),
                        ],
                      ),
                    ],
                    if (_tipe == 'BULAN') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Bulan',
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
                          for (final bulan
                              in AvailabilityRuleModel.bulanLabels.entries)
                            ChoiceChip(
                              label: Text(bulan.value),
                              selected: _bulan == bulan.key,
                              selectedColor: AppColors.primaryOrange,
                              labelStyle: TextStyle(
                                color: _bulan == bulan.key
                                    ? AppColors.white
                                    : AppColors.secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                              showCheckmark: false,
                              onSelected: (_) =>
                                  setState(() => _bulan = bulan.key),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.primaryOrange,
                      title: const Text(
                        'Tersedia untuk dipesan',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                      subtitle: Text(
                        _tersedia
                            ? 'Aturan ini menjadi penanda tersedia.'
                            : 'Jadwal yang cocok akan diblokir.',
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.4,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      value: _tersedia,
                      onChanged: (value) => setState(() => _tersedia = value),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _simpan,
                        child: const Text('Simpan Aturan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

int _bandingkanAturan(AvailabilityRuleModel a, AvailabilityRuleModel b) {
  final berdasarkanTanggal = a.tanggalMulai.compareTo(b.tanggalMulai);

  if (berdasarkanTanggal != 0) {
    return berdasarkanTanggal;
  }

  final idA = int.tryParse(a.id) ?? 0;
  final idB = int.tryParse(b.id) ?? 0;
  return idA.compareTo(idB);
}

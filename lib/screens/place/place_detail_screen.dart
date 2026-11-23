import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/place_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/utils/format.dart';
import '../../models/availability_model.dart';
import '../../models/place_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nav_provider.dart';
import '../../widgets/availability_rule_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';
import '../../widgets/spoth_sidebar_scaffold.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  const PlaceDetailScreen({super.key, required this.placeId});

  final String placeId;

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  PlaceModel? _place;
  List<AvailabilityRuleModel> _rules = const [];
  bool _loading = true;
  bool _loadingRules = false;
  String? _error;
  String? _rulesError;
  int _fotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _rulesError = null;
    });

    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      final place = await ref
          .read(placeServiceProvider)
          .getPlaceDetail(id: widget.placeId, token: token);

      if (!mounted) return;
      setState(() {
        _place = place;
        _fotoIndex = 0;
      });
      await _loadRules();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat detail tempat');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadRules() async {
    final user = ref.read(authNotifierProvider.select((s) => s.user));
    final place = _place;
    final isOwner =
        user?.role == UserModel.roleHost &&
        place != null &&
        user!.id == place.hostId;

    // Aturan ketersediaan hanya boleh dibaca oleh pemilik tempat. Hindari
    // panggilan yang pasti ditolak (403) untuk penyewa/tamu.
    if (!isOwner) {
      if (!mounted) return;
      setState(() {
        _rules = const [];
        _loadingRules = false;
        _rulesError = null;
      });
      return;
    }

    setState(() {
      _loadingRules = true;
      _rulesError = null;
    });

    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      final rules = await ref
          .read(placeServiceProvider)
          .getAvailabilityRules(placeId: widget.placeId, token: token);

      if (!mounted) return;
      setState(() => _rules = rules);
    } catch (_) {
      if (!mounted) return;
      setState(() => _rulesError = 'Gagal memuat aturan ketersediaan tempat.');
    } finally {
      if (mounted) setState(() => _loadingRules = false);
    }
  }

  Future<void> _refresh() async {
    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      final place = await ref
          .read(placeServiceProvider)
          .getPlaceDetail(id: widget.placeId, token: token);

      if (!mounted) return;
      setState(() {
        _place = place;
        _fotoIndex = 0;
      });
      await _loadRules();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui detail tempat.')),
      );
    }
  }

  Future<void> _openKelolaAturan() async {
    await context.push('/place-form?id=${widget.placeId}');
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final place = _place;
    final isOwner =
        user?.role == UserModel.roleHost &&
        place != null &&
        user!.id == place.hostId;
    final isTenant = user?.role == UserModel.roleTenant;

    final page = Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const SpothAppBar(title: Text('Detail Tempat')),
      body: _loading
          ? const SingleChildScrollView(child: DetailSkeleton())
          : _error != null
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: EmptyState(
                  icon: Icons.wifi_off,
                  title: _error!,
                  message: 'Periksa koneksi internet Anda lalu coba lagi.',
                  actionLabel: 'Coba Lagi',
                  onAction: _load,
                ),
              ),
            )
          : place == null
          ? const Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: EmptyState(
                  icon: Icons.storefront,
                  title: 'Tempat tidak ditemukan',
                  message: 'Data tempat tidak tersedia di server.',
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _DetailScrollView(
                    place: place,
                    fotoIndex: _fotoIndex,
                    onFotoChanged: (index) =>
                        setState(() => _fotoIndex = index),
                    onRefresh: _refresh,
                    rules: _rules,
                    loadingRules: _loadingRules,
                    rulesError: _rulesError,
                    onRetryRules: _loadRules,
                    onKelolaAturan: isOwner ? _openKelolaAturan : null,
                  ),
                ),
                _ActionBar(place: place, isOwner: isOwner, isTenant: isTenant),
              ],
            ),
    );

    return SpothSidebarScaffold(activeTab: MainTab.tempat, child: page);
  }
}

class _DetailScrollView extends StatelessWidget {
  const _DetailScrollView({
    required this.place,
    required this.fotoIndex,
    required this.onFotoChanged,
    required this.onRefresh,
    required this.rules,
    required this.loadingRules,
    required this.rulesError,
    required this.onRetryRules,
    required this.onKelolaAturan,
  });

  final PlaceModel place;
  final int fotoIndex;
  final ValueChanged<int> onFotoChanged;
  final Future<void> Function() onRefresh;
  final List<AvailabilityRuleModel> rules;
  final bool loadingRules;
  final String? rulesError;
  final VoidCallback onRetryRules;
  final VoidCallback? onKelolaAturan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ruang = constraints.maxWidth;
          const jarakKolom = 24.0;
          final duaKolom = ruang >= 840;
          final lebarKiri = duaKolom ? (ruang - jarakKolom) * 0.46 : ruang;
          final lebarKanan = duaKolom ? ruang - jarakKolom - lebarKiri : ruang;
          final adaHost = (place.namaHost?.trim() ?? '').isNotEmpty;
          final adaThumbs = place.foto.length > 1;

          final foto = _HeroPhoto(
            place: place,
            fotoIndex: fotoIndex,
            lebar: lebarKiri,
            tinggi: duaKolom
                ? (lebarKiri * 0.78).clamp(230.0, 430.0)
                : (ruang * 0.56).clamp(200.0, 320.0),
            onFotoChanged: onFotoChanged,
          );

          final thumbs = _HeroThumbs(
            place: place,
            fotoIndex: fotoIndex,
            onFotoChanged: onFotoChanged,
          );

          final seksi = _seksiRincian(
            place: place,
            rules: rules,
            loadingRules: loadingRules,
            rulesError: rulesError,
            onRetryRules: onRetryRules,
            onKelolaAturan: onKelolaAturan,
          );
          final daftarSeksi = [
            for (var i = 0; i < seksi.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              seksi[i],
            ],
          ];

          Widget isi;
          if (duaKolom) {
            isi = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: lebarKiri,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      foto,
                      if (adaThumbs) ...[const SizedBox(height: 10), thumbs],
                      const SizedBox(height: 16),
                      _RingkasanTempat(place: place),
                      if (adaHost) ...[
                        const SizedBox(height: 14),
                        _HostCard(place: place),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: jarakKolom),
                SizedBox(
                  width: lebarKanan,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _KepalaTempat(place: place),
                      const SizedBox(height: 20),
                      ...daftarSeksi,
                      const SizedBox(height: 16),
                      _KeteranganUpdate(place: place),
                    ],
                  ),
                ),
              ],
            );
          } else {
            isi = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                foto,
                if (adaThumbs) ...[const SizedBox(height: 10), thumbs],
                const SizedBox(height: 14),
                _KepalaTempat(place: place),
                const SizedBox(height: 14),
                _RingkasanTempat(place: place),
                if (adaHost) ...[
                  const SizedBox(height: 14),
                  _HostCard(place: place),
                ],
                const SizedBox(height: 14),
                ...daftarSeksi,
                const SizedBox(height: 16),
                _KeteranganUpdate(place: place),
              ],
            );
          }

          return RefreshIndicator(
            color: AppColors.primaryOrange,
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: isi,
            ),
          );
        },
      ),
    );
  }
}

class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto({
    required this.place,
    required this.fotoIndex,
    required this.lebar,
    required this.tinggi,
    required this.onFotoChanged,
  });

  final PlaceModel place;
  final int fotoIndex;
  final double lebar;
  final double tinggi;
  final ValueChanged<int> onFotoChanged;

  @override
  Widget build(BuildContext context) {
    final fotos = place.foto;
    final index = fotos.isEmpty ? 0 : fotoIndex.clamp(0, fotos.length - 1);
    final aktif = fotos.isNotEmpty ? fotos[index] : null;
    final adaNavigasi = fotos.length > 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: tinggi,
        width: lebar,
        child: Stack(
          fit: StackFit.expand,
          children: [
            aktif != null
                ? Image.network(
                    aktif,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _HeroPlaceholder(),
                  )
                : const _HeroPlaceholder(),
            if (adaNavigasi)
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) {
                  final keKanan = details.localPosition.dx > lebar / 2;
                  final baru = (index + (keKanan ? 1 : -1)) % fotos.length;
                  onFotoChanged(baru < 0 ? fotos.length - 1 : baru);
                },
              ),
            if (adaNavigasi)
              IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _GalleryCue(icon: Icons.chevron_left),
                      _GalleryCue(icon: Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            if (aktif != null)
              Positioned(
                top: 12,
                right: 12,
                child: _GalleryButton(
                  icon: Icons.open_in_full,
                  tooltip: 'Perbesar foto',
                  onPressed: () => _bukaFoto(context, fotos, index),
                ),
              ),
            if (adaNavigasi)
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${index + 1} / ${fotos.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _bukaFoto(BuildContext context, List<String> fotos, int mulai) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => _PhotoViewer(fotos: fotos, initialIndex: mulai),
    );
  }
}

class _HeroThumbs extends StatelessWidget {
  const _HeroThumbs({
    required this.place,
    required this.fotoIndex,
    required this.onFotoChanged,
  });

  final PlaceModel place;
  final int fotoIndex;
  final ValueChanged<int> onFotoChanged;

  @override
  Widget build(BuildContext context) {
    final fotos = place.foto;
    final index = fotos.isEmpty ? 0 : fotoIndex.clamp(0, fotos.length - 1);

    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: fotos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final dipilih = i == index;

          return GestureDetector(
            key: ValueKey('galeri-thumb-$i'),
            onTap: () => onFotoChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 78,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: dipilih
                      ? AppColors.primaryOrange
                      : AppColors.softBorder,
                  width: dipilih ? 2 : 1,
                ),
              ),
              child: Image.network(
                fotos[i],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _HeroPlaceholder(iconSize: 22),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: AppColors.white),
          ),
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.fotos, required this.initialIndex});

  final List<String> fotos;
  final int initialIndex;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late int _index = widget.initialIndex.clamp(0, widget.fotos.length - 1);

  void _geser(int arah) {
    setState(() {
      _index = (_index + arah) % widget.fotos.length;
      if (_index < 0) _index = widget.fotos.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adaNavigasi = widget.fotos.length > 1;

    return SizedBox.expand(
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  widget.fotos[_index],
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Center(child: _HeroPlaceholder()),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _ViewerButton(
                icon: Icons.close,
                tooltip: 'Tutup',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (adaNavigasi) ...[
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ViewerButton(
                    icon: Icons.chevron_left,
                    tooltip: 'Foto sebelumnya',
                    onPressed: () => _geser(-1),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ViewerButton(
                    icon: Icons.chevron_right,
                    tooltip: 'Foto berikutnya',
                    onPressed: () => _geser(1),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
                  child: Text(
                    '${_index + 1} / ${widget.fotos.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ViewerButton extends StatelessWidget {
  const _ViewerButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: AppColors.white),
          ),
        ),
      ),
    );
  }
}

class _GalleryCue extends StatelessWidget {
  const _GalleryCue({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.white),
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder({this.iconSize = 64});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.lightOrange,
      child: Center(
        child: Icon(
          Icons.storefront,
          size: iconSize,
          color: AppColors.primaryOrange,
        ),
      ),
    );
  }
}

List<Widget> _seksiRincian({
  required PlaceModel place,
  required List<AvailabilityRuleModel> rules,
  required bool loadingRules,
  required String? rulesError,
  required VoidCallback onRetryRules,
  required VoidCallback? onKelolaAturan,
}) {
  final seksi = <Widget>[];
  final deskripsi = place.deskripsi.trim();
  final aturan = place.aturan?.trim() ?? '';

  if (deskripsi.isNotEmpty) {
    seksi.add(
      _DetailSectionCard(
        icon: Icons.description_outlined,
        title: 'Deskripsi',
        child: Text(
          deskripsi,
          style: const TextStyle(
            fontSize: 14,
            height: 1.65,
            color: AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  if (place.fasilitasList.isNotEmpty) {
    seksi.add(
      _DetailSectionCard(
        icon: Icons.widgets_outlined,
        title: 'Fasilitas',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final fasilitas in place.fasilitasList)
              _FasilitasChip(label: fasilitas),
          ],
        ),
      ),
    );
  }

  if (aturan.isNotEmpty) {
    seksi.add(
      _DetailSectionCard(
        icon: Icons.rule_outlined,
        title: 'Aturan',
        child: Text(
          aturan,
          style: const TextStyle(
            fontSize: 14,
            height: 1.65,
            color: AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  seksi.add(
    _DetailSectionCard(
      icon: Icons.date_range_outlined,
      title: 'Periode Ketersediaan',
      child: _PeriodeKetersediaan(place: place),
    ),
  );

  // Aturan ketersediaan adalah data internal pemilik tempat. Backend
  // membatasi endpoint ini ke HOST pemilik, jadi hanya tampil untuk pemilik.
  if (onKelolaAturan != null) {
    seksi.add(
      _DetailSectionCard(
        icon: Icons.event_available_outlined,
        title: 'Aturan Ketersediaan',
        child: _AturanKetersediaan(
          rules: rules,
          loading: loadingRules,
          error: rulesError,
          onRetry: onRetryRules,
          onKelola: onKelolaAturan,
        ),
      ),
    );
  }

  seksi.add(
    _DetailSectionCard(
      icon: Icons.event_busy_outlined,
      title: 'Jadwal Sudah Dipesan',
      child: _JadwalDipesan(place: place),
    ),
  );

  return seksi;
}

class _PeriodeKetersediaan extends StatelessWidget {
  const _PeriodeKetersediaan({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final mulai = place.tanggalMulaiTersedia;
    final selesai = place.tanggalSelesaiTersedia;

    if (mulai == null || selesai == null) {
      return const Text(
        'Pemilik belum menetapkan periode khusus. Ketersediaan mengikuti '
        'jadwal yang sudah dipesan.',
        style: TextStyle(
          fontSize: 13,
          height: 1.5,
          color: AppColors.secondaryText,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.lightOrange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 18,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '${formatTanggal(mulai)} - ${formatTanggal(selesai)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Penyewaan hanya dapat dilakukan di dalam periode ini.',
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

class _AturanKetersediaan extends StatelessWidget {
  const _AturanKetersediaan({
    required this.rules,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onKelola,
  });

  final List<AvailabilityRuleModel> rules;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback? onKelola;

  @override
  Widget build(BuildContext context) {
    final jumlahMemblokir = rules.where((rule) => rule.memblokir).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(
                  'Memuat aturan ketersediaan...',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          )
        else if (error != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.wifi_off,
                size: 18,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  error!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
            ],
          )
        else if (rules.isEmpty)
          const Text(
            'Belum ada aturan khusus. Ketersediaan mengikuti periode di atas '
            'dan jadwal yang sudah dipesan.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.secondaryText,
            ),
          )
        else ...[
          if (jumlahMemblokir > 0) ...[
            Text(
              '$jumlahMemblokir aturan membatasi tanggal yang dapat dipesan.',
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 9),
          ],
          for (var i = 0; i < rules.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            AvailabilityRuleCard(rule: rules[i]),
          ],
        ],
        if (onKelola != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onKelola,
              icon: const Icon(Icons.tune, size: 17),
              label: const Text('Kelola Aturan Ketersediaan'),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _KepalaTempat extends StatelessWidget {
  const _KepalaTempat({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBadge(label: place.kategoriLabel),
          const SizedBox(height: 12),
          Text(
            place.namaTempat,
            style: AppFonts.heading(
              fontSize: 24,
              weight: 600,
              height: 1.25,
              letterSpacing: -0.4,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 17,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${place.alamat}, ${place.kota}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingkasanTempat extends StatelessWidget {
  const _RingkasanTempat({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PriceBlock(place: place),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.softBorder),
          const SizedBox(height: 16),
          _SpecRow(place: place),
        ],
      ),
    );
  }
}

class _JadwalDipesan extends StatelessWidget {
  const _JadwalDipesan({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    if (place.jadwalTerpakai.isEmpty) {
      return const Row(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 18,
            color: AppColors.primaryOrange,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Belum ada jadwal yang terisi. Semua tanggal masih tersedia.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < place.jadwalTerpakai.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _BookedScheduleRow(jadwal: place.jadwalTerpakai[i]),
        ],
      ],
    );
  }
}

class _KeteranganUpdate extends StatelessWidget {
  const _KeteranganUpdate({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final updatedAt = place.updatedAt;
    if (updatedAt == null) {
      return const SizedBox.shrink();
    }

    return Text(
      'Terakhir diperbarui ${formatTanggal(updatedAt)}',
      style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
        ),
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final diskon = formatDiskonPersen(place.hargaNormal, place.hargaPromo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  style: AppFonts.heading(
                    fontSize: 26,
                    weight: 700,
                    letterSpacing: -0.6,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '/${place.durasiLabel.toLowerCase()}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
        if (diskon != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                formatRupiah(place.hargaNormal),
                style: const TextStyle(
                  fontSize: 13,
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  diskon,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SpecItem(
            icon: Icons.event_repeat,
            value: place.durasiLabel,
            label: 'Durasi',
          ),
        ),
        const _SpecDivider(),
        Expanded(
          child: _SpecItem(
            icon: Icons.photo_library_outlined,
            value: '${place.foto.length}',
            label: 'Foto',
          ),
        ),
        const _SpecDivider(),
        Expanded(
          child: _SpecItem(
            icon: Icons.event_busy_outlined,
            value: '${place.jadwalTerpakai.length}',
            label: 'Jadwal Terisi',
          ),
        ),
      ],
    );
  }
}

class _SpecItem extends StatelessWidget {
  const _SpecItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryOrange),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

class _SpecDivider extends StatelessWidget {
  const _SpecDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 38, color: AppColors.softBorder);
  }
}

class _HostCard extends StatelessWidget {
  const _HostCard({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final namaHost = place.namaHost?.trim() ?? '';
    final inisial = namaHost.isEmpty
        ? '?'
        : namaHost.characters.first.toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.lightOrange,
              shape: BoxShape.circle,
            ),
            child: Text(
              inisial,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaHost,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Pemilik tempat',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.secondaryText,
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

class _FasilitasChip extends StatelessWidget {
  const _FasilitasChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 15,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookedScheduleRow extends StatelessWidget {
  const _BookedScheduleRow({required this.jadwal});

  final BookedRange jadwal;

  @override
  Widget build(BuildContext context) {
    final status = jadwal.status?.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_busy,
            size: 18,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${formatDateString(jadwal.tanggalMulai)} – '
              '${formatDateString(jadwal.tanggalSelesai)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.charcoal,
              ),
            ),
          ),
          if (status != null && status.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.place,
    required this.isOwner,
    required this.isTenant,
  });

  final PlaceModel place;
  final bool isOwner;
  final bool isTenant;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Widget content;
    if (isOwner) {
      content = _BarHarga(place: place);
    } else if (isTenant) {
      final tombol = ElevatedButton.icon(
        onPressed: () => context.push('/booking-form?id=${place.id}'),
        icon: const Icon(Icons.event_available, size: 18),
        label: const Text('Sewa Tempat Ini'),
      );

      content = LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 520) {
            return Row(
              children: [
                Expanded(child: _BarHarga(place: place)),
                const SizedBox(width: 24),
                SizedBox(width: 240, height: 48, child: tombol),
              ],
            );
          }

          return SizedBox(width: double.infinity, height: 48, child: tombol);
        },
      );
    } else {
      content = Row(
        children: const [
          Icon(Icons.info_outline, size: 18, color: AppColors.secondaryText),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tempat ini dikelola oleh akun lain.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.softBorder)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: content,
        ),
      ),
    );
  }
}

class _BarHarga extends StatelessWidget {
  const _BarHarga({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Harga sewa',
          style: TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 2),
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
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../models/place_model.dart';
import 'free_map_view.dart';

/// Peta lokasi tempat yang ringkas.
///
/// Menampilkan peta dengan marker. Tombol atau tap pada peta membuka
/// Google Maps di luar aplikasi. Bila koordinat kosong, tetap muncul kartu
/// lokasi dengan tombol buka Google Maps berdasarkan alamat.
class PlaceMapCard extends StatelessWidget {
  const PlaceMapCard({super.key, required this.place});

  final PlaceModel place;

  static const double _radius = 16;
  static const double _mapHeight = 200;
  static const double _gap = 14;
  static const double _defaultLat = -6.2;
  static const double _defaultLng = 106.8167;

  @override
  Widget build(BuildContext context) {
    final punyaKoordinat =
        place.latitude != null && place.longitude != null;
    final posisi = LatLng(
      place.latitude ?? _defaultLat,
      place.longitude ?? _defaultLng,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.lightOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Lokasi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _gap),
          _PetaStatis(
            posisi: posisi,
            place: place,
            punyaLokasi: punyaKoordinat,
            onBuka: () => _bukaGoogleMaps(context),
          ),
          const SizedBox(height: _gap),
          if (!punyaKoordinat) ...[
            const Text(
              'Koordinat peta belum diisi. Peta ditampilkan; alamat tetap tersedia.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            _alamatLengkap(),
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: _gap),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _bukaGoogleMaps(context),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Buka di Google Maps'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _alamatLengkap() {
    final alamat = place.alamat.trim();
    final kecamatan = place.kecamatan.trim();

    if (kecamatan.isEmpty ||
        alamat.toLowerCase().contains(kecamatan.toLowerCase())) {
      return alamat.isEmpty ? kecamatan : alamat;
    }

    return '$alamat, $kecamatan';
  }

  Future<void> _bukaGoogleMaps(BuildContext context) async {
    final lat = place.latitude;
    final lng = place.longitude;

    final query = (lat != null && lng != null)
        ? '$lat,$lng'
        : Uri.encodeComponent(_alamatLengkap());

    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {
      // Lanjutkan ke pesan di bawah.
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak bisa membuka Google Maps.')),
    );
  }
}

/// Peta statis yang ringkas; buka Google Maps untuk interaksi.
class _PetaStatis extends StatelessWidget {
  const _PetaStatis({
    required this.posisi,
    required this.place,
    required this.punyaLokasi,
    required this.onBuka,
  });

  final LatLng posisi;
  final PlaceModel place;
  final bool punyaLokasi;
  final VoidCallback onBuka;

  @override
  Widget build(BuildContext context) {
    return FreeMapView(
      center: posisi,
      punyaLokasi: punyaLokasi,
      markerId: place.id,
      title: place.namaTempat,
      interactive: false,
      height: PlaceMapCard._mapHeight,
      onTap: (_, _) => onBuka(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../models/place_model.dart';

/// Peta lokasi tempat yang ringkas.
///
/// Menampilkan peta dengan marker. Tombol atau tap pada peta membuka
/// Google Maps di luar aplikasi. Bila koordinat kosong, tetap muncul kartu
/// lokasi dengan tombol buka Google Maps berdasarkan alamat.
class PlaceMapCard extends StatelessWidget {
  const PlaceMapCard({super.key, required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final punyaKoordinat =
        place.latitude != null && place.longitude != null;
    final posisi = LatLng(
      place.latitude ?? 0,
      place.longitude ?? 0,
    );

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
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 6),
              const Text(
                'Lokasi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (punyaKoordinat) ...[
            SizedBox(
              height: 180,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: posisi,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId(place.id),
                      position: posisi,
                      infoWindow: InfoWindow(title: place.namaTempat),
                    ),
                  },
                  onTap: (_) => _bukaGoogleMaps(context),
                  // Peta statis yang ringkas; buka Google Maps untuk interaksi.
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Koordinat peta belum diisi. Alamat tetap tersedia.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            _alamatLengkap(),
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _bukaGoogleMaps(context),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Buka di Google Maps'),
            ),
          ),
        ],
      ),
    );
  }

  String _alamatLengkap() {
    final alamat = place.alamat.trim();
    final kecamatan = place.kecamatan.trim();

    if (kecamatan.isEmpty || alamat.toLowerCase().contains(kecamatan.toLowerCase())) {
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

    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

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

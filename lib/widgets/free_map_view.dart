import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_colors.dart';

/// Peta tanpa API key.
///
/// Memakai ubin OpenStreetMap. `google_maps_flutter` butuh kunci Google Maps;
/// komponen ini membuat peta tetap tampil tanpa kunci. Buka Google Maps
/// terpisah tetap memakai `url_launcher`.
class FreeMapView extends StatelessWidget {
  const FreeMapView({
    super.key,
    required this.center,
    required this.punyaLokasi,
    this.markerId,
    this.title,
    this.interactive = false,
    this.height = 200,
    this.onTap,
  });

  final LatLng center;
  final bool punyaLokasi;
  final String? markerId;
  final String? title;
  final bool interactive;
  final double height;
  final void Function(double latitude, double longitude)? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15,
            interactionOptions: InteractionOptions(
              flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
            ),
            onTap: onTap == null
                ? null
                : (tapPosition, point) =>
                      onTap!(point.latitude, point.longitude),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.spoth_umkm',
            ),
            if (punyaLokasi)
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.location_on,
                      color: AppColors.primaryOrange,
                      size: 36,
                      shadows: const [
                        Shadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

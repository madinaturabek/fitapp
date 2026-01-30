import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/route_point.dart';

class MapWidget extends StatelessWidget {
  final List<RoutePoint> route;
  final bool followUser; // если true — центрируем на последней точке (простая логика)
  final RoutePoint? currentPoint;
  final String? headerText;

  const MapWidget({
    super.key,
    required this.route,
    this.followUser = true,
    this.currentPoint,
    this.headerText,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    final points = route
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);

    // Центр карты:
    // - если есть точки: последняя
    // - иначе: запасной центр (Москва)
    final center = points.isNotEmpty ? points.last : const LatLng(55.751244, 37.618423);
    final markerPoint = currentPoint == null
        ? null
        : LatLng(currentPoint!.latitude, currentPoint!.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: t.colorScheme.outlineVariant),
        ),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: points.isNotEmpty ? 16 : 10,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            // Подложка карты (OpenStreetMap)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.kursovaya',
            ),

            // Линия маршрута
            if (points.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: points,
                    strokeWidth: 5,
                    // цвет не задаём — но flutter_map требует цвет, возьмём theme primary
                    color: t.colorScheme.primary,
                  ),
                ],
              ),

            // Маркеры старт/финиш
            if (points.isNotEmpty || markerPoint != null)
              MarkerLayer(
                markers: [
                  if (points.isNotEmpty)
                    Marker(
                      point: points.first,
                      width: 36,
                      height: 36,
                      child: _Pin(
                        color: Colors.green,
                        icon: Icons.play_arrow_rounded,
                      ),
                    ),
                  if (points.isNotEmpty)
                    Marker(
                      point: points.last,
                      width: 36,
                      height: 36,
                      child: _Pin(
                        color: t.colorScheme.primary,
                        icon: Icons.flag_rounded,
                      ),
                    ),
                  if (markerPoint != null)
                    Marker(
                      point: markerPoint,
                      width: 36,
                      height: 36,
                      child: _Pin(
                        color: const Color(0xFF00D9FF),
                        icon: Icons.directions_run_rounded,
                      ),
                    ),
                ],
              ),

            // Водяная плашка сверху (чтобы не выглядело пусто)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: t.colorScheme.surface.withOpacity(0.9),
                  border: Border.all(color: t.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        headerText ?? (points.isEmpty ? 'Ожидание GPS…' : 'Маршрут записывается'),
                        style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '${points.length} точек',
                      style: t.textTheme.labelMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _Pin({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.18),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

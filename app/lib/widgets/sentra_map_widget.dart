import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants.dart';

class SentraMapWidget extends StatelessWidget {
  final String lastCommand;
  final List<String> motorStates;

  const SentraMapWidget({
    super.key,
    required this.lastCommand,
    required this.motorStates,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: const LatLng(30.0444, 31.2357),
            initialZoom: 15.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.sentra.app',
            ),
            const MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(30.0444, 31.2357),
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.smart_toy_rounded,
                    color: c1,
                    size: 36,
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

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/core/utils/utils.dart';


class TrackedPathMap extends StatefulWidget {
  final List<LatLng>trackedPath;

  const TrackedPathMap({super.key, required this.trackedPath});

  @override
  State<TrackedPathMap> createState() => _TrackedPathMapState();
}

class _TrackedPathMapState extends State<TrackedPathMap> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Activity map")),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter:
              widget.trackedPath.first,
          initialZoom: 15.0,
          onMapReady: () async {
            // Delay to load a tiles properly
            Future.delayed(const Duration(milliseconds: 100), () {
              AppUtils.fitMapToPath(widget.trackedPath, _mapController);
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.runtrack',
          ),
          if (widget.trackedPath.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: widget.trackedPath ,
                  color: Colors.blue,
                  strokeWidth: 4.0,
                ),
              ],
            ),
          if (widget.trackedPath.isNotEmpty )
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.trackedPath.first,
                  width: 40,
                  height: 40,
                  child: Icon(Icons.flag, color: Colors.green),
                ),
                if (
                widget.trackedPath.length > 1)
                  Marker(
                    point: widget.trackedPath.last,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.stop, color: Colors.red),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

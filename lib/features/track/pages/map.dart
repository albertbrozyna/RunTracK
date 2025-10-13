import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/activity.dart';
import '../../../theme/colors.dart';

class TrackMap extends StatefulWidget {
  final Activity? activity;

  const TrackMap({super.key, this.activity});

  @override
  State<TrackMap> createState() => _TrackMapState();
}

class _TrackMapState extends State<TrackMap> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Activity map",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, letterSpacing: 1),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: widget.activity?.trackedPath?.first ?? LatLng(0, 0), initialZoom: 15.0),
        children: [
          TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.runtrack'),
          if (widget.activity?.trackedPath?.isNotEmpty ?? false)
            PolylineLayer(
              polylines: [Polyline(points: widget.activity?.trackedPath ?? [], color: Colors.blue, strokeWidth: 4.0)],
            ),
          if (widget.activity?.trackedPath?.isNotEmpty ?? false)
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.activity!.trackedPath!.first,
                  width: 40,
                  height: 40,
                  child: Icon(Icons.flag, color: Colors.green),
                ),
                if (widget.activity!.trackedPath != null && widget.activity!.trackedPath!.length > 1)
                  Marker(
                    point: widget.activity!.trackedPath!.last,
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

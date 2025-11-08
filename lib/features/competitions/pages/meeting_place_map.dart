import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/utils/app_constants.dart';

import '../../../theme/app_colors.dart';

class MeetingPlaceMap extends StatefulWidget {
  final LatLng? latLng;

  const MeetingPlaceMap({super.key, this.latLng});

  @override
  State<MeetingPlaceMap> createState() => _MeetingPlaceMapState();
}

class _MeetingPlaceMapState extends State<MeetingPlaceMap> {
  final MapController _mapController = MapController();
  LatLng? latLng;
  bool edit = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() {
    setState(() {
      latLng = widget.latLng;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => {
        if (!didPop) {Navigator.pop(context, latLng)},
      },

      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Meeting place",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, letterSpacing: 1),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(!edit ? Icons.edit_location_alt_outlined : Icons.check, color: !edit ? AppColors.white : AppColors.green),
            ),
          ],
          centerTitle: true,
          backgroundColor: AppColors.primary,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              edit = !edit;
            });
          },
          backgroundColor: edit ? Colors.green : AppColors.primary,
          label: Text(edit ? "Save" : "Select point"),
          icon: Icon(edit ? Icons.check : Icons.edit_location_alt_outlined),
        ),
        body: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: latLng ?? LatLng(AppConstants.defaultLat, AppConstants.defaultLon),  // Move to meeting point
            initialZoom: 15.0,
            onTap: (tapPosition, point) => {
              if (edit)
                setState(() {
                  latLng = point;
                }),
            },
          ),
          children: [
            TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.runtrack'),
            if (latLng != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: latLng!,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

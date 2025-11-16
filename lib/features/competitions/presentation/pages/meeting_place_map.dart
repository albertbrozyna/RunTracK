import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/core/utils/utils.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

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

  Future<void> _moveToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          if (mounted) {
            AppUtils.showMessage(
              context,
              'Location permission are required',
              messageType: MessageType.info,
            );
          }
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.best),
      );

      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    } catch (e) {
      print("Error fetching location: $e");
    }
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
              child: Icon(
                edit ? Icons.check : Icons.edit_location_alt_outlined,
                color: edit ? AppColors.green : AppColors.white,
              ),
            ),
          ],
          centerTitle: true,
          backgroundColor: AppColors.primary,
        ),

        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              mini: true,
              onPressed: _moveToCurrentLocation,
              heroTag: 'fab_gps',
              child: const Icon(Icons.my_location),
            ),
            const SizedBox(height: 16),

            FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  edit = !edit;
                });
              },
              backgroundColor: edit ? Colors.green : AppColors.primary,
              label: Text(edit ? "Save" : "Select point"),
              icon: Icon(edit ? Icons.check : Icons.edit_location_alt_outlined),
              heroTag: 'fab_edit',
            ),
          ],
        ),
        body: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: latLng ?? LatLng(AppConstants.defaultLat, AppConstants.defaultLon),
            // Move to meeting point
            initialZoom: 15.0,
            onTap: (tapPosition, point) => {
              if (edit)
                setState(() {
                  latLng = point;
                }),
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.runtrack',
            ),
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

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../common/utils/app_data.dart';
import '../../../common/utils/utils.dart';
import '../../../models/activity.dart';
import '../../../theme/colors.dart';

class MeetingPlaceMap extends StatefulWidget {
  LatLng? latLng;

  MeetingPlaceMap({super.key, this.latLng});

  @override
  State<MeetingPlaceMap> createState() => _MeetingPlaceMapState();
}

class _MeetingPlaceMapState extends State<MeetingPlaceMap> {
  final MapController _mapController = MapController();
  LatLng? latLng;


  @override
  void initState() {
    super.initState();
  }

  void initialize(){
    latLng = widget.latLng;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Meeting place",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, letterSpacing: 1),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: FlutterMap(
        mapController: _mapController,

        options: MapOptions(
          // TODO ADD DEFAULT pol location
          initialCenter: widget.latLng ?? AppData.currentUser?.userDefaultLocation ?? LatLng(0, 0),
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.runtrack'),

          if (latLng != null)
            MarkerLayer(
              markers: [
                Marker(
                  // TODO THE SAME
                  point: latLng ?? LatLng(0, 0),
                  width: 40,
                  height: 40,
                  child: Icon(Icons.flag, color: Colors.green),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

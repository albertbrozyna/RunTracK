import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:run_track/app/navigation/app_routes.dart';
import 'package:run_track/app/theme/app_colors.dart';
import 'package:run_track/core/constants/app_constants.dart';
import 'package:run_track/core/constants/firestore_collections.dart';
import 'package:run_track/core/enums/competition_role.dart';
import 'package:run_track/core/utils/utils.dart';
import 'package:run_track/features/competitions/data/models/competition.dart';

class CompetitionMapPage extends StatefulWidget {
  const CompetitionMapPage({super.key});

  @override
  State<CompetitionMapPage> createState() => _CompetitionMapPageState();
}

class _CompetitionMapPageState extends State<CompetitionMapPage> {
  final MapController _mapController = MapController();

  LatLng _searchCenter = const LatLng(AppConstants.defaultLat, AppConstants.defaultLon);
  double _radiusInKm = 10.0; // Default radius

  late Stream<List<Competition>> _competitionsStream;
  bool _showSearchHereButton = false;

  @override
  void initState() {
    super.initState();
    _updateQuery();
  }

  /// Main function creating the Firestore query
  void _updateQuery() {
    setState(() {
      final collectionRef = FirebaseFirestore.instance.collection(
        FirestoreCollections.competitions,
      );
      final centerGeoPoint = GeoFirePoint(
        GeoPoint(_searchCenter.latitude, _searchCenter.longitude),
      );

      _competitionsStream = GeoCollectionReference(collectionRef)
          .subscribeWithin(
            center: centerGeoPoint,
            radiusInKm: _radiusInKm,
            field: 'geo',
            geopointFrom: (data) => (data['geo'] as Map<String, dynamic>)['geopoint'] as GeoPoint,
            strictMode: true,
          )
          .map((snapshots) {
            return snapshots.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['competitionId'] = doc.id;
              return Competition.fromMap(data);
            }).toList();
          });

      _showSearchHereButton = false;
    });
  }

  /// Navigate to competition details
  void _onCompetitionTapped(Competition competition) {
    Navigator.pushNamed(
      context,
      AppRoutes.competitionDetails,
      arguments: {
        'enterContext': CompetitionContext.viewerAbleToJoin,
        'competitionData': competition,
        'initTab': 0,
      },
    );
  }

  /// Move to user location
  Future<void> _moveToUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      AppUtils.showMessage(context, 'Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        AppUtils.showMessage(context, 'Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      AppUtils.showMessage(context, 'Location permissions are permanently denied.');
      return;
    }

    // Get position
    final position = await Geolocator.getCurrentPosition();
    final newCenter = LatLng(position.latitude, position.longitude);

    setState(() {
      _searchCenter = newCenter;
      _mapController.move(newCenter, 15.0);
      _updateQuery(); // Search i new location
    });
  }

  /// Shows the settings tab
  void _showLocationSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Search Settings",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text("Radius: ${_radiusInKm.toStringAsFixed(0)} km")],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(
                      context,
                    ).copyWith(activeTrackColor: AppColors.primary, thumbColor: AppColors.primary),
                    child: Slider(
                      value: _radiusInKm,
                      min: 1.0,
                      max: 100.0,
                      divisions: 99,
                      label: "${_radiusInKm.round()} km",
                      onChanged: (value) {
                        setModalState(() => _radiusInKm = value);
                        setState(() {});
                      },
                      onChangeEnd: (value) {
                        // Update after change
                        _updateQuery();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _searchCenter,
              initialZoom: 11.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _showSearchHereButton = true;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.runtrack.app',
              ),

              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _searchCenter,
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderColor: Colors.blue.withValues(alpha: 0.7),
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                    radius: _radiusInKm * 1000, // To meters
                  ),
                ],
              ),

              StreamBuilder<List<Competition>>(
                stream: _competitionsStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  final competitions = snapshot.data!;

                  return MarkerLayer(
                    markers: competitions
                        .map((comp) {
                          if (comp.location == null) return null;

                          return Marker(
                            point: comp.location!,
                            width: 50,
                            height: 50,
                            child: GestureDetector(
                              onTap: () => _onCompetitionTapped(comp),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.primary, width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.emoji_events,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                        .whereType<Marker>()
                        .toList(),
                  );
                },
              ),
            ],
          ),

          // Button show here
          if (_showSearchHereButton)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchCenter = _mapController.camera.center;
                      _updateQuery();
                    });
                  },
                  icon: const Icon(
                    Icons.refresh,
                    size: 20,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  label: const Text("Search this area", style: TextStyle(color: AppColors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Title
                  const Text(
                    "Find Competitions",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),

                  // Settings Button
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.tune, color: AppColors.white, size: 23),
                      onPressed: _showLocationSettings,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              onPressed: _moveToUserLocation,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.my_location, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

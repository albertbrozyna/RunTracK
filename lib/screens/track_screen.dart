import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'home_page.dart';
import 'permission_utils.dart';

class TrackScreen extends StatefulWidget {
  @override
  _TrackScreenState createState() => _TrackScreenState();
}

enum TrackingState { stopped, running, paused }

class _TrackScreenState extends State<TrackScreen> {
  int _selectedIndex = 0;
  final MapController _mapController = MapController();
  List<LatLng> _trackedPath = [];
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _followUser = true;
  final Distance _distanceCalculator = Distance();
  double _totalDistance = 0.0; // w metrach
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  TrackingState _trackingState = TrackingState.stopped;
  final LatLng defaultLocation = LatLng(52.2297, 21.0122);
  // Current position
  LatLng? _currentPosition;

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // Function to get location permission
  Future<void> _getLocation() async {
    try {
      final position = await LocationService.determinePosition();
      setState(() {
        _currentPosition = LatLng(position!.latitude, position.longitude);
      });

      // Move and zoom map to current location
      final newPos = LatLng(position!.latitude, position.longitude);
      _mapController.move(newPos, 15.0);
    } catch (e) {
      // Show an error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // Function to start tracking
  void _pauseTracking() {
    _positionStreamSubscription?.pause();
    // Pause timer
    _timer?.cancel();
    _positionStreamSubscription = null;
    setState(() {
      _trackingState = TrackingState.paused;
    });
  }

  // Function to resume tracking
  void _resumeTracking() {
    _positionStreamSubscription?.resume();
    setState(() {
      _trackingState = TrackingState.running;
    });
  }

  void _cancelTracking() {
    _positionStreamSubscription?.cancel();
    // Pause timer
    _timer?.cancel();
    _positionStreamSubscription = null;
    setState(() {
      _trackingState = TrackingState.stopped;
      _trackedPath.clear();
    });
  }

  void _startTracking() {
    // Setting starting parameters
    setState(() {
      _totalDistance = 0.0;
      _elapsedTime = Duration.zero;
      _startTime = DateTime.now();
      _trackedPath.clear();
      _trackingState = TrackingState.running;
    });

    // Setting timer
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (_trackingState == TrackingState.running) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
        });
      }
    });

    const locationSettings = LocationSettings(
      // Get the best accuracy
      accuracy: LocationAccuracy.best,
      // The location will update after at least 5 meters
      distanceFilter: 5,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            final latLng = LatLng(position.latitude, position.longitude);
            setState(() {
              if (_currentPosition != null) {
                // Calculate distance from last postion
                _totalDistance += _distanceCalculator.as(
                  LengthUnit.Meter,
                  _currentPosition!,
                  latLng,
                );
              }
              _currentPosition = latLng;
              _trackedPath.add(latLng);
            });
            // Move map to follow current location
            if (_trackingState == TrackingState.running && _followUser) {
              _mapController.move(latLng, _mapController.camera.zoom);
            }
          },
        );
  }

  // TODO To learn
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildControls() {
    // Stats of the run, pace and distance
    Widget stats = Row(
      children: [
        Text(
          "Distance: ${(_totalDistance / 1000).toStringAsFixed(2)} km",
          style: TextStyle(fontSize: 18),
        ),
        Text("Pace: $_formattedPace", style: TextStyle(fontSize: 18)),
      ],
    );

    switch (_trackingState) {
      case TrackingState.stopped:
        return ElevatedButton(
          onPressed: _startTracking,
          child: Text("Start Run"),
        );

      case TrackingState.running:
        return Column(
          children: [
            // Show stats and cancel button while running
            stats,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _cancelTracking,
                  child: Text("Cancel"),
                ),
              ],
            ),
          ],
        );

      case TrackingState.paused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: _resumeTracking, child: Text("Resume")),
            ElevatedButton(onPressed: _pauseTracking, child: Text("Finish")),
          ],
        );
    }
  }

  String get _formattedPace {
    if (_totalDistance < 10) return "--"; // Not enough data
    double km = _totalDistance / 1000;
    double pace = _elapsedTime.inSeconds / km;
    int paceMin = (pace / 60).floor();
    int paceSec = (pace % 60).round();
    return "$paceMin:${paceSec.toString().padLeft(2, '0')} min/km";
  }

  Widget _buildMapWithButton() {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  // Current location or default position
                  // TODO Add here a variable with default location
                  initialCenter: _currentPosition ?? defaultLocation,
                  initialZoom: 15.0,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    // z is zoom x,y are longitude and latitude
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    // Different domains used to speed up downloading a maps, just different servers
                    userAgentPackageName: 'com.example.runtrack',
                  ),
                  if (_trackedPath.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _trackedPath,
                          strokeWidth: 4.0,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  if (_currentPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition!,
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildControls(),
            ),
          ],
        ),
        Positioned(
          bottom: 90,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _followUser = !_followUser;
              });
            },
            child: Icon(_followUser ? Icons.gps_fixed : Icons.gps_not_fixed),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _pages = [
      _buildMapWithButton(),
      Center(child: Text('Search Page')),
      Center(child: Text('Profile Page')),
    ];
    return Scaffold(
      appBar: AppBar(title: Text('RunTracK')),
      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

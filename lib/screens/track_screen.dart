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

  List<LatLng> _trackedPath = [];
  StreamSubscription<Position>? _positionStreamSubscription;

  TrackingState _trackingState = TrackingState.stopped;

  // Current position
  LatLng? _currentPosition;

  // Function to get location permission
  Future<void> _getLocation() async {
    try {
      final position = await LocationService.determinePosition();
      setState(() {
        _currentPosition = LatLng(position!.latitude, position.longitude);
      });
    } catch (e) {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
  // Function to start tracking
  void _startTracking() {
    _trackedPath.clear();
    _isTracking = true;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5, // meters to ignore minor movements
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = latLng;
        _trackedPath.add(latLng);
      });
    });
  }

  void _stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
  }

  // TODO To learn
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _pages = [
      _buildMapWithButton(),
      Center(child: Text('Search Page')),
      Center(child: Text('Profile Page')),
    ];
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildMapWithButton() {
    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              // Current location or default position
              // TODO Add here a variable with default location
              initialCenter: _currentPosition ?? LatLng(52.2297, 21.0122),
              initialZoom: 15.0,
            ), children: [
            TileLayer(
              // z is zoom x,y are longitude and latitude
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
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
            if(_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition!,
                    width: 40,
                    height: 40,
                    child:
                        Icon(
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
        ElevatedButton(
          onPressed: () {
            if (_isTracking) {
              _stopTracking();
            } else {
              _startTracking();
            }
          },
          child: Text(_isTracking ? "Stop run" : "Start run"),
        ),

      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RunTracK'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}



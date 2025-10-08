import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../common/enums/tracking_state.dart';

class TrackState {
  List<LatLng> trackedPath = [];
  double totalDistance = 0.0;
  TrackingState trackingState = TrackingState.stopped;

  DateTime? _startTime;
  Duration elapsedTime = Duration.zero;
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;
  final Distance _distance = Distance();
  LatLng? _currentPosition;

}
import 'package:latlong2/latlong.dart';
import '../../../common/enums/tracking_state.dart';

class LocationUpdate {
  final String type;
  final double lat;
  final double lng;
  final double totalDistance;
  final Duration? elapsedTime;
  final double elevationGain;
  final double elevationLoss;
  final double avgSpeed;
  final double pace;
  final int steps;
  final double calories;
  final List<LatLng>? trackedPath;
  final double positionAccuracy;
  final TrackingState? trackingState;

  LocationUpdate({
    required this.type,
    required this.lat,
    required this.lng,
    required this.totalDistance,
    this.elapsedTime,
    required this.elevationGain,
    required this.elevationLoss,
    required this.avgSpeed,
    required this.pace,
    required this.steps,
    required this.calories,
    required this.positionAccuracy,
    this.trackingState,
    this.trackedPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'type':type,
      'lat': lat,
      'lng': lng,
      'totalDistance': totalDistance,
      'elapsedTime': elapsedTime?.inSeconds,
      'elevationGain': elevationGain,
      'elevationLoss': elevationLoss,
      'avgSpeed': avgSpeed,
      'pace': pace,
      'steps': steps,
      'calories': calories,
      'trackedPath': trackedPath?.map((e) => {'lat': e.latitude, 'lng': e.longitude}).toList(),
      'positionAccuracy': positionAccuracy,
      'trackingState': trackingState?.name,
    };
  }

  factory LocationUpdate.fromJson(Map<String, dynamic> json) {
    List<LatLng>? path;
    if (json['trackedPath'] != null) {
      path = (json['trackedPath'] as List)
          .map((e) => LatLng(e['lat'], e['lng']))
          .toList();
    }

    return LocationUpdate(
      type: json['type'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      totalDistance: (json['totalDistance'] ?? 0).toDouble(),
      elapsedTime: Duration(seconds: json['elapsedTime'] ?? 0),
      elevationGain: (json['elevationGain'] ?? 0).toDouble(),
      elevationLoss: (json['elevationLoss'] ?? 0).toDouble(),
      avgSpeed: (json['avgSpeed'] ?? 0).toDouble(),
      pace: (json['pace'] ?? 0).toDouble(),
      steps: json['steps'] ?? 0,
      calories: (json['calories'] ?? 0).toDouble(),
      trackedPath: path,
      positionAccuracy: (json['positionAccuracy'] ?? 0).toDouble(),
      trackingState: json['trackingState'] != null
          ? TrackingState.values.firstWhere((e) => e.name == json['trackingState']) : null,
    );
  }
}

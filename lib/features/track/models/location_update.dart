class LocationUpdate {
  final double lat;
  final double lng;
  final double totalDistance;
  final Duration elapsedTime;
  final double elevationGain;
  final double avgSpeed; // km/h
  final double pace; // min/km
  final int steps;
  final double calories;

  LocationUpdate({
    required this.lat,
    required this.lng,
    required this.totalDistance,
    required this.elapsedTime,
    required this.elevationGain,
    required this.avgSpeed,
    required this.pace,
    required this.steps,
    required this.calories,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'totalDistance': totalDistance,
      'elapsedTime': elapsedTime.inSeconds,
      'elevationGain': elevationGain,
      'avgSpeed': avgSpeed,
      'pace': pace,
      'steps': steps,
      'calories': calories,
    };
  }

  static LocationUpdate fromJson(Map<String, dynamic> json) {
    return LocationUpdate(
      lat: json['lat'],
      lng: json['lng'],
      totalDistance: json['totalDistance'],
      elapsedTime: Duration(seconds: json['elapsedTime']),
      elevationGain: json['elevationGain'],
      avgSpeed: json['avgSpeed'],
      pace: json['pace'],
      steps: json['steps'],
      calories: json['calories'],
    );
  }
}

import 'package:flutter/cupertino.dart';

class ActivitySummary extends StatefulWidget{
  final List<LatLng> trackedPath;
  final double totalDistance;

  const ActivitySummary({
    Key? key,
    required this.trackedPath,
    required this.totalDistance,
  }) : super(key: key);

  @override
  _ActivitySummaryState createState() => _ActivitySummaryState();
}

class _ActivitySummaryState extends State<ActivitySummary> {
  final List<LatLng> _trackedPath = [];
  final double _totalDistance = 0.0; // In meters



  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

}
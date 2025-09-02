import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:run_track/features/track/widgets/activity_stats.dart';

class Competitions extends StatefulWidget{
  _CompetitionsState createState() => _CompetitionsState();
}

class _CompetitionsState extends State<Competitions>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RunStats(totalDistance: 5, pace: "5", elapsedTime: Duration.zero),
    );
  }

}
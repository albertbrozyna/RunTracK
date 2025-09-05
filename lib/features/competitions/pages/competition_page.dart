import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:run_track/features/track/widgets/activity_stats.dart';

class Competitions extends StatefulWidget{
  _CompetitionsState createState() => _CompetitionsState();
}

class _CompetitionsState extends State<Competitions>{

  void _showCreateOptions(){

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () => _showCreateOptions()),
      body: RunStats(totalDistance: 5, pace: "5", elapsedTime: Duration.zero),
    );
  }

}
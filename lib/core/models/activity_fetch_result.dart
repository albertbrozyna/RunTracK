import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:run_track/core/models/activity.dart';

class ActivitiesFetchResult {
  final List<Activity> activities;
  final DocumentSnapshot? lastDocument;

  ActivitiesFetchResult({required this.activities, this.lastDocument});
}
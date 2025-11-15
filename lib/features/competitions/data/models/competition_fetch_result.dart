import 'package:cloud_firestore/cloud_firestore.dart';

import 'competition.dart';

class CompetitionFetchResult {
  final List<Competition> competitions;
  final DocumentSnapshot? lastDocument;

  CompetitionFetchResult({required this.competitions, this.lastDocument});
}
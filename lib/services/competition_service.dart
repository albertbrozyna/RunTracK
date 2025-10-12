import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:run_track/models/competition.dart';

import '../common/enums/visibility.dart' as enums;
import '../common/enums/visibility.dart';

class CompetitionService {

  /// Convert Firestore data => Competition object
  static Competition fromMap(Map<String, dynamic> map) {


    return Competition(
      competitionId: map['competitionId'],
      organizerUid: map['organizerUid'] ?? '',
      name: map['name'] ?? '',
      visibility: parseVisibility(map['visibility'] ) ?? enums.Visibility.me,
      startDate: map['startDate'] != null
          ? (map['startDate'] as Timestamp).toDate()
          : null,
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      participantsUids: map['participantsUids'] != null
          ? List<String>.from(map['participantsUids'])
          : [],
      invitedParticipantsUids: map['invitedParticipantsUids'] != null
          ? List<String>.from(map['invitedParticipantsUids'])
          : [],
      resultsUids: map['resultsUids'] != null
          ? List<String>.from(map['resultsUids'])
          : [],
    );
  }

  /// Convert Competition object to Firestore map
  static Map<String, dynamic> toMap(Competition competition) {
    String? visibilityToString(enums.Visibility? visibility) {
      if (visibility == null) return null;
      switch (visibility) {
        case enums.Visibility.friends:
          return 'friends';
        case enums.Visibility.everyone:
          return 'everyone';
        case enums.Visibility.me:
          return 'me';
      }
    }

    return {
      'competitionId': competition.competitionId,
      'organizerUid': competition.organizerUid,
      'name': competition.name,
      'visibility': visibilityToString(competition.visibility),
      'startDate': competition.startDate != null
          ? Timestamp.fromDate(competition.startDate!)
          : null,
      'endDate': competition.endDate != null
          ? Timestamp.fromDate(competition.endDate!)
          : null,
      'participantsUids': competition.participantsUids ?? [],
      'invitedParticipantsUids': competition.invitedParticipantsUids ?? [],
      'resultsUids': competition.resultsUids ?? [],
    };
  }

  Future<bool>saveCompetition(Competition competition) async {
    try{
      final docRef = FirebaseFirestore.instance.collection('competitions').doc(); // Generate id
      competition.competitionId = docRef.id;
      await docRef.set(CompetitionService.toMap(competition));
    }catch(e){
      return false;
    }
    return true;
  }

  // TODO
  /// Fetch last {limit} activities from all users
  static Future<List<Competition>> fetchLatestCompetitions(int limit) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where("visibility", isEqualTo: "EVERYONE")
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final activities = querySnapshot.docs
          .map((doc) => CompetitionService.fromMap(doc.data()))
          .toList();

      return activities;
    } catch (e) {
      // TODO TO DELETE
      print("Error fetching latest activities: $e");
      return [];
    }
  }

  /// Fetch last friend activities
  static Future<List<Competition>> fetchLastFriendsCompetitions(
      List<String> friendsUids,
      int limit,
      ) async {
    List<Competition> lastCompetitions = [];
    if (friendsUids.isEmpty) {
      return lastCompetitions;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('competitions')
          .where("uid", whereIn: friendsUids)
          .where("visibility", whereIn: ["everyone", "friends"])
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final competitions = querySnapshot.docs
          .map((doc) => CompetitionService.fromMap(doc.data()))
          .toList();

      lastCompetitions.addAll(competitions);

      // Sort activities by date and take limit
      lastCompetitions.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(1970);
        final bTime = b.createdAt ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      return lastCompetitions.take(limit).toList();
    } catch (e) {
      // TODO TO DELETE
      print("Error fetching friends' activities: $e");
      return [];
    }
  }

  static Future<List<Competition>> fetchLatestUserCompetitions(
      String uid,
      int limit,
      ) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('competitions')
          .where("uid", isEqualTo: "me")
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final competitions = querySnapshot.docs
          .map((doc) => CompetitionService.fromMap(doc.data()))
          .toList();

      return competitions;
    } catch (e) {
      // TODO TO DELETE
      print("Error fetching latest activities: $e");
      return [];
    }
  }


}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:run_track/models/competition.dart';

import '../common/enums/visibility.dart' as enums;

class CompetitionService {

  /// Convert Firestore data -> Competition object
  static Competition fromMap(Map<String, dynamic> map) {
    enums.Visibility? parseVisibility(String? str) {
      if (str == null) return null;
      switch (str) {
        case 'me':
          return enums.Visibility.me;
        case 'friends':
          return enums.Visibility.friends;
        case 'everyone':
          return enums.Visibility.everyone;
      }
    }

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


}

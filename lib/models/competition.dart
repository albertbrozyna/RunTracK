import 'package:flutter/cupertino.dart';
import '../common/enums/visibility.dart' as enums;

class Competition{
  String? competitionId; // Competition id
  String organizerUid; // Event organizer user
  DateTime? startDate;  // Start of the event
  DateTime? endDate; // End of the event
  String name;
  List<String>?participantsUids;
  List<String>?invitedParticipantsUids;
  enums.Visibility visibility;
  List<String>?resultsUids;  // List of winners

  Competition({
    required this.organizerUid,
    required this.name,
    required this.visibility,
    this.competitionId,
    this.startDate,
    this.endDate,
    this.participantsUids,
    this.invitedParticipantsUids,
    this.resultsUids
});
}
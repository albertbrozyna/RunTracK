import 'package:flutter/cupertino.dart';
import '../common/enums/visibility.dart' as enums;

class Competition{
  String? competitionId; // Competition id
  String organizerUid; // Event organizer user
  DateTime? startDate;  // Start of the event
  DateTime? endDate; // End of the event
  final DateTime? createdAt; // Date of creation
  String name;
  String? description;
  List<String>?participantsUids;
  List<String>?invitedParticipantsUids;
  enums.Visibility visibility;
  String? competitionType; // Activity type of competition
  List<String>?resultsUids;  // List of winners

  Competition({
    required this.organizerUid,
    required this.name,
    required this.visibility,
    this.createdAt,
    this.competitionId,
    this.startDate,
    this.endDate,
    this.participantsUids,
    this.invitedParticipantsUids,
    this.resultsUids,
    this.description,
    this.competitionType
  });
}
import 'package:flutter/cupertino.dart';
import '../common/enums/visibility.dart' as enums;

class Competition{
  String? competitionId; // Competition id // Done
  String organizerUid; // Event organizer user // Done
  DateTime? startDate;  // Start of the event // done
  DateTime? endDate; // End of the event // done
  final DateTime? createdAt; // Date of creation
  String name; // Done
  String? description; // Done
  List<String>?participantsUids;
  List<String>?invitedParticipantsUids;
  enums.Visibility visibility; // Done
  String? competitionType; // Activity type of competition // Done
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
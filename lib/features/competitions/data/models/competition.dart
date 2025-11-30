import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import '../../../../core/enums/visibility.dart' as enums;

class Competition {
  String competitionId; // Competition id
  String organizerUid; // Event organizer user
  String name; // Name of competition
  String? description; // Description of competition
  DateTime? startDate; // Start of the event
  DateTime? endDate; // End of the event
  DateTime? registrationDeadline; // Deadline to register for the event
  int? maxTimeToCompleteActivityHours; // Max time to complete activity
  int? maxTimeToCompleteActivityMinutes; // Max time to complete activity
  DateTime? createdAt; // Date of creation
  Set<String> participantsUid;
  Set<String> invitedParticipantsUid;
  enums.ComVisibility visibility; // Visibility of competition
  String? activityType; // Allowed activity types of competition
  String? locationName; // Location name
  LatLng? location; // Location
  double distanceToGo; // Km
  bool closedBeforeEndTime;


  Competition({
    this.competitionId = '',
    required this.organizerUid,
    required this.name,
    required this.visibility,
    required this.distanceToGo,
    this.createdAt,
    this.startDate,
    this.endDate,
    this.registrationDeadline,
    this.maxTimeToCompleteActivityHours,
    this.maxTimeToCompleteActivityMinutes,
    this.invitedParticipantsUid = const {},
    this.participantsUid = const {},
    this.description,
    this.activityType,
    this.locationName,
    this.location,
    this.closedBeforeEndTime = false,
  });

  factory Competition.fromMap(Map<String, dynamic> map) {
    return Competition(
      competitionId: map['competitionId'] ?? '',
      organizerUid: map['organizerUid'] ?? '',
      name: map['name'] ?? '',
      distanceToGo: (map['distanceToGo'] is num) ? (map['distanceToGo'] as num).toDouble() : 0.0,
      visibility: enums.ComVisibility.fromDbString(map['visibility']),
      description: map['description'],
      startDate: map['startDate'] != null ? (map['startDate'] as Timestamp).toDate() : null,
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      registrationDeadline: map['registrationDeadline'] != null ? (map['registrationDeadline'] as Timestamp).toDate() : null,
      maxTimeToCompleteActivityHours: map['maxTimeToCompleteActivityHours'],
      maxTimeToCompleteActivityMinutes: map['maxTimeToCompleteActivityMinutes'],
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      participantsUid: map['participantsUid'] != null ? Set<String>.from(List.from(map['participantsUid'])) : {},
      invitedParticipantsUid: map['invitedParticipantsUid'] != null ? Set<String>.from(List.from(map['invitedParticipantsUid'])) : {},
      activityType: map['activityType'],
      locationName: map['locationName'],
      location: (map['latitude'] != null && map['longitude'] != null)
          ? LatLng((map['latitude'] as num).toDouble(), (map['longitude'] as num).toDouble())
          : null,
      closedBeforeEndTime: map['closedBeforeEndTime'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    final map =  {
      'competitionId': competitionId,
      'organizerUid': organizerUid,
      'name': name,
      'distanceToGo': distanceToGo,
      'description': description,
      'visibility': visibility.toDbString(),
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'registrationDeadline': registrationDeadline != null ? Timestamp.fromDate(registrationDeadline!) : null,
      'maxTimeToCompleteActivityHours': maxTimeToCompleteActivityHours,
      'maxTimeToCompleteActivityMinutes': maxTimeToCompleteActivityMinutes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'participantsUid': participantsUid.toList(),
      'invitedParticipantsUid': invitedParticipantsUid.toList(),
      'activityType': activityType,
      'locationName': locationName,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
      'closedBeforeEndTime': closedBeforeEndTime,
    };

    if (location != null) {
      final GeoFirePoint geoFirePoint = GeoFirePoint(
          GeoPoint(location!.latitude, location!.longitude)
      );
      map['geo'] = geoFirePoint.data;
    }
    return map;
  }

  Competition copyWith({
    String? competitionId,
    String? organizerUid,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    int? maxTimeToCompleteActivityHours,
    int? maxTimeToCompleteActivityMinutes,
    DateTime? createdAt,
    Set<String>? participantsUid,
    Set<String>? invitedParticipantsUid,
    enums.ComVisibility? visibility,
    Map<String, String>? results,
    String? activityType,
    String? locationName,
    LatLng? location,
    double? goal,
    List<String>? photos,
    bool? closedBeforeEndTime,
  }) {
    return Competition(
      competitionId: competitionId ?? this.competitionId,
      organizerUid: organizerUid ?? this.organizerUid,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      maxTimeToCompleteActivityHours: maxTimeToCompleteActivityHours ?? this.maxTimeToCompleteActivityHours,
      maxTimeToCompleteActivityMinutes: maxTimeToCompleteActivityMinutes ?? this.maxTimeToCompleteActivityMinutes,
      createdAt: createdAt ?? this.createdAt,
      participantsUid: participantsUid ?? this.participantsUid,
      invitedParticipantsUid: invitedParticipantsUid ?? this.invitedParticipantsUid,
      visibility: visibility ?? this.visibility,
      activityType: activityType ?? this.activityType,
      locationName: locationName ?? this.locationName,
      location: location ?? this.location,
      distanceToGo: goal ?? distanceToGo,
      closedBeforeEndTime: closedBeforeEndTime ?? this.closedBeforeEndTime,
    );
  }

  bool isEqual(Competition other) {
    if (identical(this, other)) {
      return true;
    }

    return other.competitionId == competitionId &&
        other.organizerUid == organizerUid &&
        other.name == name &&
        other.description == description &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.registrationDeadline == registrationDeadline &&
        other.maxTimeToCompleteActivityHours == maxTimeToCompleteActivityHours &&
        other.maxTimeToCompleteActivityMinutes == maxTimeToCompleteActivityMinutes &&
        other.createdAt == createdAt &&
        other.visibility == visibility &&
        other.activityType == activityType &&
        other.locationName == locationName &&
        other.location == location &&
        other.distanceToGo == distanceToGo &&
        other.closedBeforeEndTime == closedBeforeEndTime;
  }
}




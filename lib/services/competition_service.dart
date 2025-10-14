import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/constans/firestore_names.dart';
import 'package:run_track/models/competition.dart';
import 'package:run_track/services/activity_service.dart';

import '../common/enums/visibility.dart' as enums;
import '../common/enums/visibility.dart';
import '../common/utils/utils.dart';

class CompetitionService {
  static DocumentSnapshot? lastFetchedDocumentMyCompetitions;
  static DocumentSnapshot? lastFetchedDocumentFriendsCompetitions;
  static DocumentSnapshot? lastFetchedDocumentAllCompetitions;

  static Competition fromMap(Map<String, dynamic> map) {
    return Competition(
      competitionId: map['competitionId'],
      organizerUid: map['organizerUid'] ?? '',
      name: map['name'] ?? '',
      visibility: parseVisibility(map['visibility']) ?? enums.Visibility.me,
      description: map['description'],
      startDate: map['startDate'] != null ? (map['startDate'] as Timestamp).toDate() : null,
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      registrationDeadline: map['registrationDeadline'] != null ? (map['registrationDeadline'] as Timestamp).toDate() : null,
      participantsUids: map['participantsUids'] != null ? List<String>.from(map['participantsUids']) : [],
      invitedParticipantsUids: map['invitedParticipantsUids'] != null ? List<String>.from(map['invitedParticipantsUids']) : [],
      distanceKm: map['distanceKm'] != null ? (map['distanceKm'] as num).toDouble() : null,
      allowedActivityTypes: map['allowedActivityTypes'] != null ? List<String>.from(map['allowedActivityTypes']) : [],
      results: map['results'] != null
          ? Map<String, double>.from(map['results'].map((key, value) => MapEntry(key, (value as num).toDouble())))
          : {},
      locationName: map['locationName'],
      location: (map['latitude'] != null && map['longitude'] != null)
          ? LatLng((map['latitude'] as num).toDouble(), (map['longitude'] as num).toDouble())
          : null,
    );
  }

  /// Covert competition to firestore
  static Map<String, dynamic> toMap(Competition competition) {
    return {
      'competitionId': competition.competitionId,
      'organizerUid': competition.organizerUid,
      'name': competition.name,
      'description': competition.description,
      'visibility': competition.visibility.toString(),
      'startDate': competition.startDate != null ? Timestamp.fromDate(competition.startDate!) : null,
      'endDate': competition.endDate != null ? Timestamp.fromDate(competition.endDate!) : null,
      'registrationDeadline': competition.registrationDeadline != null ? Timestamp.fromDate(competition.registrationDeadline!) : null,
      'participantsUids': competition.participantsUids ?? [],
      'invitedParticipantsUids': competition.invitedParticipantsUids ?? [],
      'distanceKm': competition.distanceKm,
      'allowedActivityTypes': competition.allowedActivityTypes ?? [],
      'results': competition.results ?? {},
      'locationName': competition.locationName,
      'latitude': competition.location?.latitude,
      'longitude': competition.location?.longitude,
    };
  }

  Future<bool> saveCompetition(Competition competition) async {
    try {
      if (competition.competitionId.isNotEmpty) {
        // Competition exists, edit it
        final docRef = FirebaseFirestore.instance.collection('activities').doc(competition.competitionId); // Fetch existing document
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          await docRef.set(CompetitionService.toMap(competition));
          return true;
        }
      }
      // Save new competition
      final docRef = FirebaseFirestore.instance.collection('competitions').doc(); // Generate id
      competition.competitionId = docRef.id;
      await docRef.set(CompetitionService.toMap(competition));
    } catch (e) {
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
      final activities = querySnapshot.docs.map((doc) => CompetitionService.fromMap(doc.data())).toList();

      return activities;
    } catch (e) {
      // TODO TO DELETE
      print("Error fetching latest activities: $e");
      return [];
    }
  }

  /// Fetch last friend activities
  static Future<List<Competition>> fetchLastFriendsCompetitions(List<String> friendsUids, int limit) async {
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

      final competitions = querySnapshot.docs.map((doc) => CompetitionService.fromMap(doc.data())).toList();

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

  static Future<List<Competition>> fetchLatestUserCompetitions(String uid, int limit) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('competitions')
          .where("uid", isEqualTo: "me")
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final competitions = querySnapshot.docs.map((doc) => CompetitionService.fromMap(doc.data())).toList();

      return competitions;
    } catch (e) {
      // TODO TO DELETE
      print("Error fetching latest activities: $e");
      return [];
    }
  }


  /// Fetch last page of user activities
  static Future<List<Competition>> fetchLatestCompetitionsPage(int limit, DocumentSnapshot? lastDocument) async {
    try {
      Query queryCompetitions = FirebaseFirestore.instance
          .collection(FirestoreCollections.competitions)
          .where("visibility", isEqualTo: "Visibility.everyone")
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        queryCompetitions = queryCompetitions.startAfterDocument(lastDocument);
      }

      final querySnapshot = await queryCompetitions.get();

      if (querySnapshot.docs.isNotEmpty) {
        lastFetchedDocumentAllCompetitions = querySnapshot.docs.last;
      }

      final competitions = querySnapshot.docs
          .map((doc) => CompetitionService.fromMap(doc.data() as Map<String, dynamic>))
          .where((competition) => competition.organizerUid != FirebaseAuth.instance.currentUser?.uid) // Reject my competitions
          .toList();
      return competitions;
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  /// Fetch pages of friends competitions
  static Future<List<Competition>> fetchLastFriendsCompetitionsPage(int limit, DocumentSnapshot? lastDocument, List<String> friendsUids) async {
    if (friendsUids.isEmpty) {
      return [];
    }

    try {
      Query queryCompetitions = FirebaseFirestore.instance
          .collection(FirestoreCollections.competitions)
          .where("uid", whereIn: friendsUids)
          .where("visibility", whereIn: ["Visibility.everyone", "Visibility.friends"])
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        queryCompetitions = queryCompetitions.startAfterDocument(lastDocument);
      }

      final querySnapshot = await queryCompetitions.get();

      if (querySnapshot.docs.isNotEmpty) {
        lastFetchedDocumentFriendsCompetitions = querySnapshot.docs.last;
      }

      final competitions = querySnapshot.docs
          .map((doc) => CompetitionService.fromMap(doc.data() as Map<String, dynamic>))
          .where((competition) => competition.organizerUid != FirebaseAuth.instance.currentUser?.uid) // Reject my competitions
          .toList();
      return competitions;
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  /// Fetch my latest activities by pages
  static Future<List<Competition>> fetchMyLatestCompetitionsPage(String uid, int limit, DocumentSnapshot? lastDocument) async {
    try {
      Query queryCompetitions = FirebaseFirestore.instance
          .collection(FirestoreCollections.competitions)
          .where("uid", isEqualTo: uid.trim())
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        queryCompetitions = queryCompetitions.startAfterDocument(lastDocument);
      }

      final querySnapshot = await queryCompetitions.get();

      if (querySnapshot.docs.isNotEmpty) {
        lastFetchedDocumentMyCompetitions = querySnapshot.docs.last;
      }
      final competitions = querySnapshot.docs.map((doc) => CompetitionService.fromMap(doc.data() as Map<String, dynamic>)).toList();
      return competitions;
    } catch (e) {
      // TODO TO DELETE
      print("Error fetching latest competitions: $e");
      return [];
    }
  }


  /// Compare two competitions and check if they are equal
  static bool competitionsEqual(Competition c1, Competition c2) {
    return c1.competitionId == c2.competitionId &&
        c1.organizerUid == c2.organizerUid &&
        c1.name == c2.name &&
        c1.description == c2.description &&
        c1.visibility == c2.visibility &&
        c1.startDate == c2.startDate &&
        c1.endDate == c2.endDate &&
        c1.registrationDeadline == c2.registrationDeadline &&
        c1.distanceKm == c2.distanceKm &&
        AppUtils.listsEqual(c1.allowedActivityTypes, c2.allowedActivityTypes) &&
        AppUtils.listsEqual(c1.participantsUids, c2.participantsUids) &&
        AppUtils.listsEqual(c1.invitedParticipantsUids, c2.invitedParticipantsUids) &&
        AppUtils.mapsEqual(c1.results, c2.results) &&
        c1.locationName == c2.locationName &&
        c1.location?.latitude == c2.location?.latitude &&
        c1.location?.longitude == c2.location?.longitude;
  }
}

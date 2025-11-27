import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_track/core/constants/firestore_collections.dart';
import 'package:run_track/features/competitions/data/models/result_record.dart';
import 'package:run_track/features/notifications/data/services/notification_service.dart';

import '../../../../app/config/app_data.dart';
import '../../../../core/enums/participant_management_action.dart';
import '../../../../core/enums/visibility.dart';
import '../models/competition.dart';
import '../../../notifications/data/models/notification.dart';
import '../models/competition_fetch_result.dart';
import '../models/competition_result.dart';



class CompetitionService {
  CompetitionService._();

  static Future<Competition?> fetchCompetition(String competitionId) async {
    if (competitionId.isEmpty) {
      return null;
    }
    final docSnapshot = await FirebaseFirestore.instance
        .collection(FirestoreCollections.competitions)
        .doc(competitionId)
        .get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      return Competition.fromMap(data);
    } else {
      return null;
    }
  }

  static Future<Competition?> saveCompetition(Competition competition) async {
    try {
      if (competition.competitionId.isNotEmpty) {
        // Competition exists, edit it
        final docRef = FirebaseFirestore.instance
            .collection(FirestoreCollections.competitions)
            .doc(competition.competitionId); // Fetch existing document
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          await docRef.set(competition.toMap());
          return competition;
        }
      }
      // Save new competition
      final docRef = FirebaseFirestore.instance.collection(FirestoreCollections.competitions).doc(); // Generate id
      competition.competitionId = docRef.id;
      await docRef.set(competition.toMap());
    } catch (e) {
      return null;
    }
    return competition;
  }

  /// Fetch last page of user activities
  static Future<CompetitionFetchResult> fetchLatestCompetitionsPage(int limit, DocumentSnapshot? lastDocument) async {
    try {
      Query queryCompetitions = FirebaseFirestore.instance
          .collection(FirestoreCollections.competitions)
          .where("visibility", isEqualTo: ComVisibility.everyone.toString())
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        queryCompetitions = queryCompetitions.startAfterDocument(lastDocument);
      }

      final querySnapshot = await queryCompetitions.get();
      DocumentSnapshot? newLastDocument;
      if (querySnapshot.docs.isNotEmpty) {
        newLastDocument = querySnapshot.docs.last;
      }

      final competitions = querySnapshot.docs
          .map((doc) => Competition.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      return CompetitionFetchResult(competitions: competitions, lastDocument: newLastDocument);
    } catch (e) {
      print("Error: $e");
      return CompetitionFetchResult(competitions: [], lastDocument: null);
    }
  }

  /// Fetch pages of friends competitions
  static Future<CompetitionFetchResult> fetchLastFriendsCompetitionsPage(
    int limit,
    DocumentSnapshot? lastDocument,
    Set<String> friends,
  ) async {
    if (friends.isEmpty) {
      return CompetitionFetchResult(competitions: [], lastDocument: null);
    }

    try {
      Query queryCompetitions = FirebaseFirestore.instance
          .collection(FirestoreCollections.competitions)
          .where("organizerUid", whereIn: friends)
          .where("visibility", whereIn: [ComVisibility.everyone.toString(), ComVisibility.friends.toString()])
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        queryCompetitions = queryCompetitions.startAfterDocument(lastDocument);
      }

      final querySnapshot = await queryCompetitions.get();

      DocumentSnapshot? newLastDocument;
      if (querySnapshot.docs.isNotEmpty) {
        newLastDocument = querySnapshot.docs.last;
      }

      final competitions = querySnapshot.docs
          .map((doc) => Competition.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      return CompetitionFetchResult(competitions: competitions, lastDocument: newLastDocument);
    } catch (e) {
      print("Error: $e");
      return CompetitionFetchResult(competitions: [], lastDocument: null);
    }
  }

  /// Fetch my latest activities by pages
  static Future<CompetitionFetchResult> fetchMyLatestCompetitionsPage(String uid, int limit, DocumentSnapshot? lastDocument) async {
    if (uid.isEmpty) {
      return CompetitionFetchResult(competitions: [], lastDocument: null);
    }
    try {
      Query queryCompetitions = FirebaseFirestore.instance
          .collection(FirestoreCollections.competitions)
          .where("organizerUid", isEqualTo: uid.trim())
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        queryCompetitions = queryCompetitions.startAfterDocument(lastDocument);
      }

      final querySnapshot = await queryCompetitions.get();
      DocumentSnapshot? newLastDocument;
      if (querySnapshot.docs.isNotEmpty) {
        newLastDocument = querySnapshot.docs.last;
      }
      final competitions = querySnapshot.docs.map((doc) => Competition.fromMap(doc.data() as Map<String, dynamic>)).toList();
      return CompetitionFetchResult(competitions: competitions, lastDocument: newLastDocument);
    } catch (e) {
      print("Error fetching latest competitions: $e");
      return CompetitionFetchResult(competitions: [], lastDocument: null);
    }
  }

  /// Fetch my competition which I am invited
  static Future<CompetitionFetchResult> fetchMyInvitedCompetitions(
    Set<String> competitionsIds,
    int limit,
    DocumentSnapshot? lastDocument,
  ) async {
    if (competitionsIds.isEmpty) {
      return CompetitionFetchResult(competitions: [], lastDocument: null);
    }

    // Limit for 30 to make it work
    if(competitionsIds.length > 30){
      competitionsIds = competitionsIds.take(30).toSet();
    }

    try {
      Query queryCompetitions = FirebaseFirestore.instance
          .collection(FirestoreCollections.competitions)
          .where("competitionId", whereIn: competitionsIds)
          .orderBy("createdAt",descending: true)
          .limit(limit);
      

      if (lastDocument != null) {
        queryCompetitions = queryCompetitions.startAfterDocument(lastDocument);
      }
      final querySnapshot = await queryCompetitions.get();

      DocumentSnapshot? newLastDocument;
      if (querySnapshot.docs.isNotEmpty) {
        newLastDocument = querySnapshot.docs.last;
      }
      final competitions = querySnapshot.docs.map((doc) => Competition.fromMap(doc.data() as Map<String, dynamic>)).toList();
      return CompetitionFetchResult(competitions: competitions, lastDocument: newLastDocument);
    } catch (e) {
      print("Error fetching latest competitions: $e");
      return CompetitionFetchResult(competitions: [], lastDocument: null);
    }
  }

  static Future<List<Competition>> fetchMyParticipatedCompetitions({
    required Set<String>myParticipatedCompetitions,
  }) async {
    if (myParticipatedCompetitions.isEmpty) {
      return [];
    }

    Set<String> competitionsToGet = myParticipatedCompetitions;
    if(myParticipatedCompetitions.length > 30){
      competitionsToGet = myParticipatedCompetitions.take(30).toSet();
    }

    try {
      Query queryCompetitions = FirebaseFirestore.instance
          .collection(FirestoreCollections.competitions)
          .where("competitionId",whereIn: competitionsToGet)
          .orderBy("createdAt")
          .limit(10);

      final querySnapshot = await queryCompetitions.get();

      final competitions = querySnapshot.docs
          .map((doc) => Competition.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      return competitions;
    } catch (e) {
      print("Error fetching latest competitions: $e");
      return [];
    }
  }

  /// Close competition before EndTime
  static Future<bool> closeCompetitionBeforeEndTime(String competitionId) async {
    if (competitionId.isEmpty) {
      return false;
    }
    try {
      await FirebaseFirestore.instance.collection(FirestoreCollections.competitions).doc(competitionId).update({
        'closedBeforeEndTime': true,
      });
      return true;
    } catch (e) {
      print("Error closing competition: $e");
      return false;
    }
  }

  /// Delete competition
  static Future<bool> deleteCompetition(String competitionId) async {
    if (competitionId.isEmpty) {
      return false;
    }
    try {
      await FirebaseFirestore.instance.collection(FirestoreCollections.competitions).doc(competitionId).delete();
      return true;
    } catch (e) {
      print("Error deleting competition: $e");
      return false;
    }
  }

  static Future<bool> manageParticipant({
    required String competitionId,
    required String targetUserId,
    required ParticipantManagementAction action,
  }) async {
    if (competitionId.isEmpty || targetUserId.isEmpty) {
      return false;
    }
    AppNotification? notification;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final competitionRef = FirebaseFirestore.instance.collection(FirestoreCollections.competitions).doc(competitionId);
        final targetUserRef = FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(targetUserId);

        final competitionSnap = await transaction.get(competitionRef);
        final targetUserSnap = await transaction.get(targetUserRef);

        if (!competitionSnap.exists || !targetUserSnap.exists) {
          throw Exception("One or more documents not found");
        }

        final competitionName = competitionSnap.data()?['name'] ?? 'a competition';

        final participantsList = Set<String>.from(competitionSnap.data()?['participantsUid'] ?? []);
        final invitedList = Set<String>.from(competitionSnap.data()?['invitedParticipantsUid'] ?? []);

        final userParticipatedList = Set<String>.from(targetUserSnap.data()?['participatedCompetitions'] ?? []);
        final userReceivedInvitesList = Set<String>.from(targetUserSnap.data()?['receivedInvitationsToCompetitions'] ?? []);

        switch (action) {
          case ParticipantManagementAction.invite:
            invitedList.add(targetUserId);
            userReceivedInvitesList.add(competitionId);
            notification = AppNotification(
              notificationId: "",
              uid: targetUserId,
              title: "You are invited you to join '$competitionName'",
              createdAt: DateTime.now(),
              seen: false,
              type: NotificationType.inviteCompetition,
              objectId: competitionId,
            );
            break;
          case ParticipantManagementAction.resignFromCompetition:
          case ParticipantManagementAction.kick:
            participantsList.remove(targetUserId);
            userParticipatedList.remove(competitionId);
            invitedList.remove(targetUserId);
            userReceivedInvitesList.remove(competitionId);
            break;
          case ParticipantManagementAction.cancelInvitation:
          case ParticipantManagementAction.declineInvitation:
            invitedList.remove(targetUserId);
            userReceivedInvitesList.remove(competitionId);
            break;

          case ParticipantManagementAction.joinCompetition:
          case ParticipantManagementAction.acceptInvitation:
            participantsList.add(targetUserId);
            userParticipatedList.add(competitionId);
            invitedList.remove(targetUserId);
            userReceivedInvitesList.remove(competitionId);
            break;
        }

        transaction.update(competitionRef, {'participantsUid': participantsList.toList(), 'invitedParticipantsUid': invitedList.toList()});

        transaction.update(targetUserRef, {
          'participatedCompetitions': userParticipatedList.toList(),
          'receivedInvitationsToCompetitions': userReceivedInvitesList.toList(),
        });

        // Change current competition
        if(AppData.instance.currentCompetition != null && AppData.instance.currentCompetition!.competitionId == competitionId){
          AppData.instance.currentCompetition!.participantsUid = participantsList;
          AppData.instance.currentCompetition!.invitedParticipantsUid = invitedList;
        }
      });

      if (notification != null) {
        await NotificationService.saveNotification(notification: notification!);
      }

      return true;
    } catch (e) {
      print("Error managing participant ($action): $e");
      return false;
    }
  }

  /// Update field in competition
  static Future<void> updateFields(String competitionId, List<String> fields, List<dynamic> values) async {
    if (competitionId.isEmpty || fields.isEmpty || values.isEmpty) {
      return;
    }
    if (fields.length != values.length) {
      return;
    }
    final Map<String, dynamic> updateData = {};
    for (int i = 0; i < fields.length; i++) {
      updateData[fields[i]] = values[i];
    }
    try {
      await FirebaseFirestore.instance.collection(FirestoreCollections.competitions).doc(competitionId).update(updateData);
    } catch (e) {
      print("Error closing competition: $e");
    }
  }

  /// Save results of competition
  static Future<void> saveResult(CompetitionResult result) async {
    try {
      await FirebaseFirestore.instance.collection(FirestoreCollections.competitionResults)
          .doc(result.competitionId)
          .set(result.toJson());
    } catch (e) {
      print("Error saving results: $e");
      rethrow;
    }
  }

  static Future<CompetitionResult?> fetchResult(String competitionId) async {
    try {
      if(competitionId.isEmpty) return null;
      final docSnap = await FirebaseFirestore.instance.collection(FirestoreCollections.competitionResults)
          .doc(competitionId).get();

      if (docSnap.exists) {
        return CompetitionResult.fromJson(docSnap.data()!);
      } else {
        return null;
      }
    } catch (e) {
      print("Error loading results: $e");
      return null;
    }
  }

  static Future<void> addOrUpdateRecord(String competitionId, ResultRecord newRecord) async {
    final docRef = FirebaseFirestore.instance.collection(FirestoreCollections.competitionResults).doc(competitionId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docSnap = await transaction.get(docRef);

        List<ResultRecord> currentRanking = [];

        if (!docSnap.exists) {
          currentRanking = [newRecord.copyWith(finalPlace: 1)];
        } else {
          final data = docSnap.data();
          if (data != null) {
            final rankingList = (data['ranking'] as List<dynamic>?) ?? [];
            currentRanking = rankingList
                .map((recordData) =>
                ResultRecord.fromJson(recordData as Map<String, dynamic>))
                .toList();
          }

          final existingIndex = currentRanking
              .indexWhere((r) => r.userUid == newRecord.userUid);

          if (existingIndex != -1) {
            currentRanking[existingIndex] = newRecord;
          } else {
            currentRanking.add(newRecord);
          }
        }

        // Sort by finished and time
        currentRanking.sort((a, b) {
          if (a.finished && !b.finished) return -1;
          if (!a.finished && b.finished) return 1;
          return a.time.compareTo(b.time);
        });

        List<ResultRecord> finalRanking = [];
        for (int i = 0; i < currentRanking.length; i++) {
          finalRanking.add(currentRanking[i].copyWith(finalPlace: i + 1));
        }

        final resultToSave = CompetitionResult(
          competitionId: competitionId,
          ranking: finalRanking,
        );

        transaction.set(docRef, resultToSave.toJson());
      });
    } catch (e) {
      print("Error: $e");
      rethrow;
    }
  }

}

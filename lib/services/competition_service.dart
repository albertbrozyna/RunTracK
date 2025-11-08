import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_track/constants/firestore_names.dart';
import 'package:run_track/models/competition.dart';

import '../common/enums/visibility.dart';


class CompetitionFetchResult {
  final List<Competition> competitions;
  final DocumentSnapshot? lastDocument;

  CompetitionFetchResult({
    required this.competitions,
    this.lastDocument,
  });
}

class CompetitionService {
  static Future<Competition?> fetchCompetition(String competitionId) async {
    if(competitionId.isEmpty){
      return null;
    }
    final docSnapshot = await FirebaseFirestore.instance.collection(FirestoreCollections.competitions).doc(competitionId).get(); // Fetch existing document
    if (docSnapshot.exists)  {
      final data = docSnapshot.data() as Map<String, dynamic>;
      return Competition.fromMap(data);
    } else {
      return null;
    }
  }


    static Future<bool> saveCompetition(Competition competition) async {
    try {
      if (competition.competitionId.isNotEmpty) {
        // Competition exists, edit it
        final docRef = FirebaseFirestore.instance.collection(FirestoreCollections.competitions).doc(competition.competitionId); // Fetch existing document
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          await docRef.set(competition.toMap());
          return true;
        }
      }
      // Save new competition
      final docRef = FirebaseFirestore.instance.collection(FirestoreCollections.competitions).doc(); // Generate id
      competition.competitionId = docRef.id;
      await docRef.set(competition.toMap());
    } catch (e) {
      return false;
    }
    return true;
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
          .where((competition) => competition.organizerUid != FirebaseAuth.instance.currentUser?.uid) // Reject my competitions
          .toList();
      return CompetitionFetchResult(competitions: competitions,lastDocument: newLastDocument);
    } catch (e) {
      print("Error: $e");
      return CompetitionFetchResult(competitions: [],lastDocument: null);
    }
  }

  /// Fetch pages of friends competitions
  static Future<CompetitionFetchResult> fetchLastFriendsCompetitionsPage(
    int limit,
    DocumentSnapshot? lastDocument,
    Set<String> friendsUids,
  ) async {
    if (friendsUids.isEmpty) {
      return CompetitionFetchResult(competitions: [],lastDocument: null);
    }

    try {
      Query queryCompetitions = FirebaseFirestore.instance
          .collection(FirestoreCollections.competitions)
          .where("organizerUid", whereIn: friendsUids)
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
          .where((competition) => competition.organizerUid != FirebaseAuth.instance.currentUser?.uid) // Reject my competitions
          .toList();
      return CompetitionFetchResult(competitions: competitions,lastDocument: newLastDocument);
    } catch (e) {
      print("Error: $e");
      return CompetitionFetchResult(competitions: [],lastDocument: null);
    }
  }

  /// Fetch my latest activities by pages
  static Future<CompetitionFetchResult> fetchMyLatestCompetitionsPage(String uid, int limit, DocumentSnapshot? lastDocument) async {
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
      return CompetitionFetchResult(competitions: competitions,lastDocument: newLastDocument);
    } catch (e) {
      print("Error fetching latest competitions: $e");
      return CompetitionFetchResult(competitions: [],lastDocument: null);
    }
  }

  /// Fetch my competition which I am invited
  static Future<CompetitionFetchResult> fetchMyInvitedCompetitions(
    Set<String> competitionsIds,
    int limit,
    DocumentSnapshot? lastDocument,
  ) async {
    try {
      Query queryCompetitions = FirebaseFirestore.instance
          .collection(FirestoreCollections.competitions)
          .where("competitionId", whereIn: competitionsIds)
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
      return CompetitionFetchResult(competitions: competitions,lastDocument: newLastDocument);
    } catch (e) {
      print("Error fetching latest competitions: $e");
      return CompetitionFetchResult(competitions: [],lastDocument: null);
    }
  }

  /// Fetch my competition which I participate
  static Future<CompetitionFetchResult> fetchMyParticipatedCompetitions(
    Set<String> competitionsIds,
    int limit,
    DocumentSnapshot? lastDocument,
  ) async {
    try {
      Query queryCompetitions = FirebaseFirestore.instance
          .collection(FirestoreCollections.competitions)
          .where("competitionId", whereIn: competitionsIds)
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
      return CompetitionFetchResult(competitions: competitions,lastDocument: newLastDocument);
    } catch (e) {
      print("Error fetching latest competitions: $e");
      return CompetitionFetchResult(competitions: [],lastDocument: null);
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

  /// Accept invitation to competition
  static Future<bool> acceptInvitation(Competition competition) async {
    try {

      await FirebaseFirestore.instance.runTransaction((transaction)async {
        final competitionReference = FirebaseFirestore.instance
            .collection(FirestoreCollections.competitions)
            .doc(competition.competitionId);
        final userReference = FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(FirebaseAuth.instance.currentUser?.uid);

        final competitionS = await transaction.get(competitionReference);
        if (!competitionS.exists) {
          throw Exception("Competition not found in database");
        }

        final updatedInviteList = List<String>.from(competitionS['invitedParticipantsUid'] ?? []);
        updatedInviteList.remove(FirebaseAuth.instance.currentUser?.uid);

        transaction.update(competitionReference, {
          'invitedParticipantsUid': updatedInviteList,
        });
        final userS = await transaction.get(userReference);

        // Updated received invitation list

        List<String> receivedInvitationsToCompetitions = userS['receivedInvitationsToCompetitions'] ?? [];
        receivedInvitationsToCompetitions.remove(competition.competitionId);

        transaction.update(userReference, {
          'receivedInvitationsToCompetitions': receivedInvitationsToCompetitions,
          'participatedCompetitions':
          FieldValue.arrayUnion([competition.competitionId]),
        });

    });
      return true;
    } catch (e) {
      print("Error accepting invitation: $e");
      return false;
    }
  }

  /// Decline invitation to competition
  static Future<bool> declineInvitation(Competition competition) async {


      try {
        // Do this in one transaction
        await FirebaseFirestore.instance.runTransaction((transaction)async {
          final competitionReference = FirebaseFirestore.instance
              .collection(FirestoreCollections.competitions)
              .doc(competition.competitionId);
          final userReference = FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(FirebaseAuth.instance.currentUser?.uid);

          final competitionS = await transaction.get(competitionReference);
          if (!competitionS.exists) {
            throw Exception("Competition not found in database");
          }

          final updatedInviteList = List<String>.from(competitionS['invitedParticipantsUid'] ?? []);
          updatedInviteList.remove(FirebaseAuth.instance.currentUser?.uid);

          transaction.update(competitionReference, {
            'invitedParticipantsUid': updatedInviteList,
          });

          final userS = await transaction.get(userReference);
          // Updated received invitation list
          List<String> receivedInvitationsToCompetitions = userS['receivedInvitationsToCompetitions'] ?? [];
          receivedInvitationsToCompetitions.remove(competition.competitionId);

          transaction.update(userReference, {
            'receivedInvitationsToCompetitions': receivedInvitationsToCompetitions,
          });

        });
        return true;
      } catch (e) {
        print("Error accepting invitation: $e");
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

}

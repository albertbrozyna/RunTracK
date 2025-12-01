import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_track/core/constants/firestore_collections.dart';
import 'package:run_track/core/enums/user_action.dart';
import 'package:run_track/core/utils/extensions.dart';
import 'package:run_track/features/auth/data/models/auth_response.dart';

import '../../app/config/app_data.dart';
import '../../features/notifications/data/models/notification.dart';
import '../models/user.dart' as model;
import '../utils/utils.dart';
import '../../features/notifications/data/services/notification_service.dart';



class UserService {
  UserService._();

  /// Fetch one user data
  static Future<model.User?> fetchUser(String uid) async {
    try {
      if (uid.isEmpty) return null;
      final docSnapshot = await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return model.User.fromMap(docSnapshot.data()!);
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
    return null;
  }

  /// Fetch users list from firestore
  static Future<List<model.User>> fetchUsers({required List<String> uids, int limit = 20}) async {
    if (uids.isEmpty) {
      return [];
    }

    List<model.User> allUsers = [];

    try {
      final uidsList = uids.toList();
      List<List<String>> chunkedUids = [];

      for (int i = 0; i < uidsList.length; i += 10) {
        int end = (i + 10 > uidsList.length) ? uidsList.length : i + 10;
        chunkedUids.add(uidsList.sublist(i, end));
      }

      for (List<String> chunk in chunkedUids) {
        Query queryUsers = FirebaseFirestore.instance
            .collection(FirestoreCollections.users)
            .where("uid", whereIn: chunk)
            .limit(limit);

        final querySnapshot = await queryUsers.get();
        final users = querySnapshot.docs
            .map((doc) => model.User.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        allUsers.addAll(users);
      }

      allUsers.sort((a, b) => a.uid.compareTo(b.uid));

      return allUsers;
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  /// Search users in firestore
  static Future<List<model.User>> searchUsers(
    String query, {
    bool exceptMe = false,
    String myUid = "",
  }) async {
    if (query.isEmpty) {
      return [];
    }
    QuerySnapshot snap;

    if (exceptMe) {
      snap = await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .where('uid', isNotEqualTo: myUid)
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
    } else {
      snap = await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .where('uid', isNotEqualTo: myUid)
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
    }

    if (snap.docs.isEmpty) {
      return [];
    }

    final List<model.User> users = snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final firstName = data['firstName'].toString();
      final lastName = data['lastName'].toString();
      final email = data['email'].toString();
      final gender = data['gender'].toString();

      return model.User(
        uid: doc.id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        gender: gender,
      );
    }).toList();

    return users;
  }


  /// Create a new user in firestore
  static Future<model.User?> addUser(model.User user) async {
    if (user.uid.isEmpty) {
      return null;
    }

    final userf = FirebaseAuth.instance.currentUser;
    if (userf == null) {
      print("User not logged in!");
    }
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await docRef.set(user.toMap());
      return user;
    } catch (e) {
      print(e);
      return null;
    }
  }


  /// Do action in one transaction to users depending on action type
  static Future<bool> manageUsers({
    required String senderUid, // Who makes action
    required String receiverUid,
    required UserAction action,
  }) async {
    if (senderUid.isEmpty || receiverUid.isEmpty || senderUid == receiverUid) {
      return false;
    }

    Set<String> finalFriendsList = {};
    Set<String> finalPendingList = {};
    Set<String> finalReceivedList = {};

    AppNotification? notification;
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSenderReference = FirebaseFirestore.instance
            .collection(FirestoreCollections.users)
            .doc(senderUid);

        final userReceiverReference = FirebaseFirestore.instance
            .collection(FirestoreCollections.users)
            .doc(receiverUid);

        final senderSnap = await transaction.get(userSenderReference);
        if (!senderSnap.exists) {
          throw Exception("User not found in database");
        }

        final receiverSnap = await transaction.get(userReceiverReference);
        if (!receiverSnap.exists) {
          throw Exception("User not found in database");
        }

        final senderFriendsList = Set<String>.from(senderSnap['friends'] ?? []);
        final senderPendingInvitationsList = Set<String>.from(
          senderSnap['pendingInvitationsToFriends'] ?? [],
        );
        final senderReceivedInvitationList = Set<String>.from(
          senderSnap['receivedInvitationsToFriends'] ?? [],
        );

        final receiverFriendsList = Set<String>.from(receiverSnap['friends'] ?? []);
        final receiverPendingInvitationsList = Set<String>.from(
          receiverSnap['pendingInvitationsToFriends'] ?? [],
        );
        final receiverReceivedInvitationsList = Set<String>.from(
          receiverSnap['receivedInvitationsToFriends'] ?? [],
        );

        final senderFirstName = senderSnap['firstName'] ?? '';
        final senderLastName = senderSnap['lastName'] ?? '';
        final receiverFirstName = receiverSnap['firstName'] ?? '';
        final receiverLastName = receiverSnap['lastName'] ?? '';

        switch (action) {
          case UserAction.inviteToFriends:
            // Check if we are not already friends
            if (senderFriendsList.contains(receiverUid) ||
                receiverFriendsList.contains(senderUid)) {
              return false;
            }
            // Check limits
            if(senderFriendsList.length >= 30 || receiverFriendsList.length >= 30){
              return false;
            }
            // Check if receiver do not send us request to friends before
            if (receiverPendingInvitationsList.contains(senderUid) ||
                senderReceivedInvitationList.contains(receiverUid)) {
              senderFriendsList.add(receiverUid);
              receiverFriendsList.add(senderUid);

              receiverPendingInvitationsList.remove(senderUid);
              receiverReceivedInvitationsList.remove(senderUid);
              senderReceivedInvitationList.remove(receiverUid);
              senderPendingInvitationsList.remove(receiverUid);
              notification = AppNotification(
                notificationId: "",
                uid: receiverUid,
                title: "$receiverFirstName $receiverLastName accepted your friend request",
                createdAt: DateTime.now(),
                seen: false,
                type: NotificationType.inviteFriends,
                objectId: receiverUid,
              );

              break;
            }

            senderPendingInvitationsList.add(receiverUid);
            receiverReceivedInvitationsList.add(senderUid);
            notification = AppNotification(
              notificationId: "",
              uid: receiverUid,
              title: "$senderFirstName $senderLastName wants to be your friend",
              createdAt: DateTime.now(),
              seen: false,
              type: NotificationType.inviteFriends,
              objectId: senderUid,
            );
            break;
          case UserAction.removeInvitation:
            // Remove for friends list
            senderFriendsList.remove(receiverUid);
            receiverFriendsList.remove(senderUid);

            // Remove invitation
            receiverReceivedInvitationsList.remove(senderUid);
            senderPendingInvitationsList.remove(receiverUid);

            senderReceivedInvitationList.remove(receiverUid);
            receiverPendingInvitationsList.remove(senderUid);

            break;
          case UserAction.acceptInvitationToFriends:
            // Check limits
            if(senderFriendsList.length >= 30 || receiverFriendsList.length >= 30){
              return false;
            }
            senderFriendsList.add(receiverUid);
            receiverFriendsList.add(senderUid);
            senderReceivedInvitationList.remove(receiverUid);
            receiverPendingInvitationsList.remove(senderUid);

            receiverReceivedInvitationsList.remove(senderUid);
            senderPendingInvitationsList.remove(receiverUid);

            notification = AppNotification(
              notificationId: "",
              uid: receiverUid,
              title: "$receiverFirstName $receiverLastName accepted your friend request",
              createdAt: DateTime.now(),
              seen: false,
              type: NotificationType.inviteFriends,
              objectId: receiverUid,
            );
            break;
          case UserAction.declineInvitationToFriends:
            senderReceivedInvitationList.remove(receiverUid);
            receiverPendingInvitationsList.remove(senderUid);
            break;
          case UserAction.deleteFriend:
            senderFriendsList.remove(receiverUid);
            receiverFriendsList.remove(senderUid);
            break;
        }

        transaction.update(userSenderReference, {
          'pendingInvitationsToFriends': senderPendingInvitationsList,
          'friends': senderFriendsList,
          'receivedInvitationsToFriends': senderReceivedInvitationList,
        });

        transaction.update(userReceiverReference, {
          'pendingInvitationsToFriends': receiverPendingInvitationsList,
          'friends': receiverFriendsList,
          'receivedInvitationsToFriends': receiverReceivedInvitationsList,
        });

        finalFriendsList = senderFriendsList;
        finalPendingList = senderPendingInvitationsList;
        finalReceivedList = senderReceivedInvitationList;
      });

      AppData.instance.currentUser?.friends = finalFriendsList;
      AppData.instance.currentUser?.pendingInvitationsToFriends = finalPendingList;
      AppData.instance.currentUser?.receivedInvitationsToFriends = finalReceivedList;

      if (notification != null) {
        await NotificationService.saveNotification(notification:notification!);
      }

      return true;
    } catch (e) {
      print("Error doing action: $e");
      return false;
    }
  }

  /// Create a user in firebase auth
  static Future<AuthResponse> createUserInFirebaseAuth(String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );

      return AuthResponse(message: "User created", userCredential: userCredential);
    } on FirebaseAuthException catch (e) {
      return AuthResponse(message: "Auth error ${e.message}");
    } catch (e) {
      return AuthResponse(message: "Auth error $e");
    }
  }

  /// Create user account in firestore
  static Future<String> createUserInFirestore(
    String uid,
    String firstname,
    String lastname,
    String email,
    String gender,
    DateTime dateOfBirth,
      double weight,
      int height
  ) async {
    await UserService.addUser(
      model.User(
        uid: uid,
        firstName: firstname.trim().toLowerCase().capitalize(),
        lastName: lastname.trim().toLowerCase().capitalize(),
        email: email.trim().toLowerCase(),
        gender: gender.trim().toLowerCase(),
        dateOfBirth: dateOfBirth,
        createdAt: DateTime.now(),
        activityNames: AppUtils.getDefaultActivities(),
        friends: {},
      ),
    );

    return "User created";
  }

  static bool usersEqual(model.User u1, model.User u2) {
    return u1.uid == u2.uid &&
        u1.firstName == u2.firstName &&
        u1.lastName == u2.lastName &&
        u1.fullName == u2.fullName &&
        u1.email == u2.email &&
        u1.gender == u2.gender &&
        u1.dateOfBirth == u2.dateOfBirth &&
        u1.kilometers == u2.kilometers &&
        u1.burnedCalories == u2.burnedCalories &&
        u1.secondsOfActivity == u2.secondsOfActivity &&
        AppUtils.listsEqual(u1.activityNames, u2.activityNames) &&
        AppUtils.setsEqual(u1.friends, u2.friends) &&
        AppUtils.setsEqual(u1.pendingInvitationsToFriends, u2.pendingInvitationsToFriends) &&
        AppUtils.setsEqual(u1.receivedInvitationsToFriends, u2.receivedInvitationsToFriends) &&
        AppUtils.setsEqual(
          u1.receivedInvitationsToCompetitions,
          u2.receivedInvitationsToCompetitions,
        ) &&
        AppUtils.setsEqual(u1.participatedCompetitions, u2.participatedCompetitions);
  }

  static Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return "User not logged in.";
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
     await user.updatePassword(newPassword.trim());

      return "Password successfully changed.";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'user-not-found') {
        return "Current password is incorrect.";
      }
      return "Error changing password: ${e.message}";
    } catch (e) {
      return "An unknown error occurred: $e";
    }
  }

  static Future<bool> checkIfUserAccountExists(String uid) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get();
      return docSnapshot.exists;
    } catch (e) {
      return true;
    }
  }

  /// Update user fields in transaction
  static Future<bool> updateFieldsInTransaction(String uid, Map<String, dynamic> fieldsToUpdate) async {
    if (uid.isEmpty || fieldsToUpdate.isEmpty) {
      return false;
    }

    final docRef = FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docSnap = await transaction.get(docRef);

        if (!docSnap.exists) {
          throw Exception("User don't exists.");
        }
        transaction.update(docRef, fieldsToUpdate);
      });

      return true;

    } catch (e) {
      return false;
    }
  }

}

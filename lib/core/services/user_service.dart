import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/core/constants/firestore_names.dart';
import 'package:run_track/features/auth/models/auth_response.dart';

import '../../app/config/app_data.dart';
import '../../app/navigation/app_routes.dart';
import '../models/notification.dart';
import '../models/user.dart' as model;
import '../utils/utils.dart';
import 'notification_service.dart';

enum UserAction {
  inviteToFriends,
  removeInvitation,
  acceptInvitationToFriends,
  declineInvitationToFriends,
  deleteFriend,
}

class UserService {
  /// Check if current user i logged in to app
  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null &&
        AppData.instance.currentUser != null &&
        AppData.instance.currentUser!.uid == FirebaseAuth.instance.currentUser!.uid;
  }

  /// Sign out user
  static Future<void> signOutUser() async {
    await FirebaseAuth.instance.signOut();
    AppData.instance.currentUser = null;
  }

  static void checkAppUseState(BuildContext context) {
    if (!isUserLoggedIn()) {
      signOutUser();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.start, (route) => false);
        }
      });
    }
  }

  /// Method used to calculate age of User
  static int calculateAge(DateTime? birthDate) {
    if (birthDate == null) {
      return 0;
    }
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }



  /// Delete user from firestore
  static Future<bool> deleteUserFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print("No user is currently logged in.");
        }
        return false;
      }
      final uid = user.uid;
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(uid)
          .delete();
      await user.delete();

      return true;
    } catch (e) {
      print("Error deleting user: $e");
      return false;
    }
  }


  /// Fetch one user data
  static Future<model.User?> fetchUser(String uid) async {
    if (uid.isEmpty) {
      return null;
    }
    final docSnapshot = await FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();

    if (docSnapshot.exists) {
      final userData = docSnapshot.data();
      if (userData != null) {
        return model.User.fromMap(userData);
      }
    }
    return null;
  }

  /// Fetch  user firstName LastName and profile photo uri data
  static Future<model.User?> fetchUserForBlock(String uid) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null) {
        final firstName = data['firstName'] as String?;
        final lastName = data['lastName'] as String?;
        final gender = data['gender'] as String?;
        final email = data['email'] as String?;
        final profilePhotoUrl = data['profilePhotoUrl'] as String?;

        if (firstName == null ||
            lastName == null ||
            gender == null ||
            email == null) {
          return null;
        }

        return model.User(
          uid: uid,
          firstName: firstName,
          lastName: lastName,
          email: email,
          gender: gender,
          profilePhotoUrl: profilePhotoUrl,
        );
      }
    }
    return null;
  }

  /// Fetch users list from firestore
  static Future<List<model.User>> fetchUsers({
    required List<String> uids,
    int limit = 20,
  }) async {
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
            .map(
              (doc) => model.User.fromMap(doc.data() as Map<String, dynamic>),
            )
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
          .collection('users')
          .where('uid', isNotEqualTo: myUid)
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
    } else {
      snap = await FirebaseFirestore.instance
          .collection('users')
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
      final profilePhotoUrl = data['profilePhotoUrl'].toString();

      return model.User(
        uid: doc.id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        gender: gender,
        profilePhotoUrl: profilePhotoUrl,
      );
    }).toList();

    return users;
  }

  /// Fetch list of users
  static Future<List<model.User>> fetchParticipants({
    required List<String> uids,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    if (uids.isEmpty) {
      return [];
    }

    try {
      Query queryUsers = FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .where("uid", whereIn: uids)
          .limit(limit);

      if (lastDocument != null) {
        queryUsers = queryUsers.startAfterDocument(lastDocument);
      }
      final querySnapshot = await queryUsers.get();

      if (querySnapshot.docs.isNotEmpty) {
        //lastFetchedDocumentParticipants = querySnapshot.docs.last;
      }

      final users = querySnapshot.docs
          .map((doc) => model.User.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      return users;
    } catch (e) {
      print("Error: $e");
      return [];
    }
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
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await docRef.set(user.toMap());
      return user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  /// Update existing user
  static Future<model.User?> updateUser(model.User user) async {
    try {
      if (user.uid.isEmpty) {
        return null;
      }
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await docRef.set(user.toMap());
      return user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  /// Do action in one transaction to users depending on action type
  static Future<bool> actionToUsers(
    String senderUid,
    String receiverUid,
    UserAction action,
  ) async {
    if (senderUid.isEmpty || receiverUid.isEmpty || senderUid == receiverUid) {
      return false;
    }

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

        final senderFriendsList = Set<String>.from(
          senderSnap['friendsUid'] ?? [],
        );
        final senderPendingInvitationsList = Set<String>.from(
          senderSnap['pendingInvitationsToFriends'] ?? [],
        );
        final senderReceivedInvitationList = Set<String>.from(
          senderSnap['receivedInvitationsToFriends'],
        );

        final receiverFriendsList = Set<String>.from(
          receiverSnap['friendsUid'] ?? [],
        );
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

            // Check if receiver do not send us request to friends before
            if (receiverPendingInvitationsList.contains(senderUid)) {
              senderFriendsList.add(receiverUid);
              receiverFriendsList.add(senderUid);
              receiverPendingInvitationsList.remove(senderUid);
              receiverReceivedInvitationsList.remove(senderUid);
              senderReceivedInvitationList.remove(receiverUid);
              senderPendingInvitationsList.remove(receiverUid);
              notification = AppNotification(
                notificationId: "",
                uid: receiverUid,
                title:
                    "$receiverFirstName $receiverLastName accepted your friend request",
                createdAt: DateTime.now(),
                seen: false,
                type: NotificationType.inviteFriends,
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
            );
            break;
          case UserAction.removeInvitation:
            receiverReceivedInvitationsList.remove(senderUid);
            senderPendingInvitationsList.remove(receiverUid);
            break;
          case UserAction.acceptInvitationToFriends:
            senderFriendsList.add(receiverUid);
            receiverFriendsList.add(senderUid);
            senderPendingInvitationsList.remove(receiverUid);
            receiverReceivedInvitationsList.remove(senderUid);
            notification = AppNotification(
              notificationId: "",
              uid: receiverUid,
              title:
                  "$receiverFirstName $receiverLastName accepted your friend request",
              createdAt: DateTime.now(),
              seen: false,
              type: NotificationType.inviteFriends,
            );
            break;
          case UserAction.declineInvitationToFriends:
            receiverReceivedInvitationsList.remove(senderUid);
            senderPendingInvitationsList.remove(receiverUid);
            break;
          case UserAction.deleteFriend:
            senderFriendsList.remove(receiverUid);
            receiverFriendsList.remove(senderUid);
            break;
        }

        transaction.update(userSenderReference, {
          'pendingInvitationsToFriends': senderPendingInvitationsList,
          'friendsUid': senderFriendsList,
          'receivedInvitationsToFriends': senderReceivedInvitationList,
        });
        transaction.update(userReceiverReference, {
          'pendingInvitationsToFriends': receiverPendingInvitationsList,
          'friendsUid': receiverFriendsList,
          'receivedInvitationsToFriends': receiverReceivedInvitationsList,
        });
      });

      if (notification != null) {
        await NotificationService.saveNotification(notification!);
      }

      return true;
    } catch (e) {
      print("Error doing action: $e");
      return false;
    }
  }

  /// Create a user in firebase auth
  static Future<AuthResponse> createUserInFirebaseAuth(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim().toLowerCase(),
            password: password.trim(),
          );

      return AuthResponse(
        message: "User created",
        userCredential: userCredential,
      );
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
  ) async {
    await UserService.addUser(
      model.User(
        uid: uid,
        firstName: firstname.trim().toLowerCase().capitalize(),
        lastName: lastname.trim().toLowerCase().capitalize(),
        email: email.trim().toLowerCase(),
        gender: gender.trim().toLowerCase(),
        dateOfBirth: dateOfBirth,
        profilePhotoUrl: "",
        activityNames: AppUtils.getDefaultActivities(),
        friendsUid: {},
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
        u1.profilePhotoUrl == u2.profilePhotoUrl &&
        u1.gender == u2.gender &&
        u1.dateOfBirth == u2.dateOfBirth &&
        u1.kilometers == u2.kilometers &&
        u1.burnedCalories == u2.burnedCalories &&
        u1.hoursOfActivity == u2.hoursOfActivity &&
        u1.userDefaultLocation.latitude == u2.userDefaultLocation.latitude &&
        u1.userDefaultLocation.longitude == u2.userDefaultLocation.longitude &&
        AppUtils.listsEqual(u1.activityNames, u2.activityNames) &&
        AppUtils.setsEqual(u1.friendsUid, u2.friendsUid) &&
        AppUtils.setsEqual(
          u1.pendingInvitationsToFriends,
          u2.pendingInvitationsToFriends,
        ) &&
        AppUtils.setsEqual(
          u1.receivedInvitationsToFriends,
          u2.receivedInvitationsToFriends,
        ) &&
        AppUtils.setsEqual(
          u1.receivedInvitationsToCompetitions,
          u2.receivedInvitationsToCompetitions,
        ) &&
        AppUtils.setsEqual(
          u1.participatedCompetitions,
          u2.participatedCompetitions,
        );
  }

  /// Check if the user account exists in firestore
  // TODO TO FIX THIS with returning true
  static Future<bool> checkIfUserAccountExists(String uid) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return docSnapshot.exists;
    } catch (e) {
      return true;
    }
  }
}

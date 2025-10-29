import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/constants/firestore_names.dart';
import 'package:run_track/features/auth/models/auth_response.dart';
import 'package:run_track/models/notification.dart';
import 'package:run_track/models/user.dart' as model;
import 'package:run_track/services/notification_service.dart';

enum UserAction { inviteToFriends, removeInvitation, acceptInvitationToFriends, declineInvitationToFriends, deleteFriend }

class UserService {
  /// Check if current user i logged in to app
  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null &&
        AppData.currentUser != null &&
        AppData.currentUser!.uid == FirebaseAuth.instance.currentUser!.uid;
  }

  /// Sign out user
  static Future<void> signOutUser() async {
    await FirebaseAuth.instance.signOut();
    AppData.currentUser = null;
  }

  /// Method used to calculate age of User
  static int calculateAge(DateTime? birthDate) {
    if (birthDate == null) {
      return 0;
    }
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  // TODO check if you clone all fields
  static model.User cloneUserData(model.User sourceUser) {
    return model.User(
      uid: sourceUser.uid,
      firstName: sourceUser.firstName,
      lastName: sourceUser.lastName,
      gender: sourceUser.gender,
      activityNames: sourceUser.activityNames != null ? List.from(sourceUser.activityNames!) : null,
      friendsUid: Set.from(sourceUser.friendsUid),
      email: sourceUser.email,
      profilePhotoUrl: sourceUser.profilePhotoUrl,
      dateOfBirth: sourceUser.dateOfBirth != null
          ? DateTime.fromMillisecondsSinceEpoch(sourceUser.dateOfBirth!.millisecondsSinceEpoch)
          : null,
      defaultLocation: LatLng(sourceUser.userDefaultLocation.latitude, sourceUser.userDefaultLocation.longitude),
    );
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
      await FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(uid).delete();
      await user.delete();

      return true;
    } catch (e) {
      print("Error deleting user: $e");
      return false;
    }
  }

  /// Map user to firestore collection
  static Map<String, dynamic> toMap(model.User user) {
    return {
      'uid': user.uid,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'fullName': user.fullName,
      'email': user.email,
      'activityNames': user.activityNames ?? [],
      'dateOfBirth': user.dateOfBirth != null ? Timestamp.fromDate(user.dateOfBirth!) : null,
      'gender': user.gender,
      'friendsUid': user.friendsUid,
      'pendingInvitationsToFriends': user.pendingInvitationsToFriends,
      'receivedInvitationsToFriends': user.receivedInvitationsToFriends,
      'receivedInvitationsToCompetitions': user.receivedInvitationsToCompetitions,
      'participatedCompetitions': user.participatedCompetitions,
      'profilePhotoUrl': user.profilePhotoUrl,
      'userDefaultLocation': {'latitude': user.userDefaultLocation.latitude, 'longitude': user.userDefaultLocation.longitude},
      'kilometers': user.kilometers,
      'burnedCalories': user.burnedCalories,
      'hoursOfActivity': user.hoursOfActivity,
    };
  }

  /// Create user from firestore collection
  static model.User fromMap(Map<String, dynamic> map) {
    final location = map['userDefaultLocation'];
    return model.User(
      uid: map['uid'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'],
      activityNames: List<String>.from(map['activityNames'] ?? []),
      friendsUid: Set<String>.from(map['friendsUid'] ?? []),
      pendingInvitationsToFriends: Set<String>.from(map['pendingInvitationsToFriends'] ?? []),
      receivedInvitationsToFriends: Set<String>.from(map['receivedInvitationsToFriends'] ?? []),
      receivedInvitationsToCompetitions: Set<String>.from(map['receivedInvitationsToCompetitions'] ?? []),
      participatedCompetitions: Set<String>.from(map['participatedCompetitions'] ?? []),
      profilePhotoUrl: map['profilePhotoUrl'],
      defaultLocation: location != null
          ? LatLng((location['latitude'] ?? 0.0).toDouble(), (location['longitude'] ?? 0.0).toDouble())
          : LatLng(0.0, 0.0),
      dateOfBirth: map['dateOfBirth'] != null ? (map['dateOfBirth'] as Timestamp).toDate() : null,
      gender: map['gender'],
      kilometers: map['kilometers'] ?? 0,
      burnedCalories: map['burnedCalories'] ?? 0,
      hoursOfActivity: map['hoursOfActivity'] ?? 0,
    );
  }

  /// Fetch one user data
  static Future<model.User?> fetchUser(String uid) async {
    if (uid.isEmpty) {
      return null;
    }
    final docSnapshot = await FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(uid).get();

    if (docSnapshot.exists) {
      final userData = docSnapshot.data();
      if (userData != null) {
        return UserService.fromMap(userData);
      }
    }
    return null;
  }

  /// Fetch  user firstName LastName and profile photo uri data
  static Future<model.User?> fetchUserForBlock(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null) {
        final firstName = data['firstName'] as String?;
        final lastName = data['lastName'] as String?;
        final gender = data['gender'] as String?;
        final email = data['email'] as String?;
        final profilePhotoUrl = data['profilePhotoUrl'] as String?;

        if (firstName == null || lastName == null || gender == null || email == null) {
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
        Query queryUsers = FirebaseFirestore.instance.collection(FirestoreCollections.users).where("uid", whereIn: chunk).limit(limit);

        final querySnapshot = await queryUsers.get();
        final users = querySnapshot.docs.map((doc) => UserService.fromMap(doc.data() as Map<String, dynamic>)).toList();

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
  static Future<List<model.User>> searchUsers(String query, {bool exceptMe = false, String myUid = ""}) async {
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
  static Future<List<model.User>> fetchParticipants({required List<String> uids, DocumentSnapshot? lastDocument, int limit = 10}) async {
    if (uids.isEmpty) {
      return [];
    }

    try {
      Query queryUsers = FirebaseFirestore.instance.collection(FirestoreCollections.users).where("uid", whereIn: uids).limit(limit);

      if (lastDocument != null) {
        queryUsers = queryUsers.startAfterDocument(lastDocument);
      }
      final querySnapshot = await queryUsers.get();

      if (querySnapshot.docs.isNotEmpty) {
        //lastFetchedDocumentParticipants = querySnapshot.docs.last;
      }

      final users = querySnapshot.docs.map((doc) => UserService.fromMap(doc.data() as Map<String, dynamic>)).toList();
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
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await docRef.set(UserService.toMap(user));
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
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await docRef.set(UserService.toMap(user));
      return user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  /// Do action in one transaction to users depending on action type
  static Future<bool> actionToUsers(String senderUid, String receiverUid, UserAction action) async {
    if (senderUid.isEmpty || receiverUid.isEmpty) {
      return false;
    }

    // Przypadek ze obydwoje wysyłają sobie zaproszenie
    AppNotification? notification;
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSenderReference = FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(senderUid);

        final userReceiverReference = FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(receiverUid);

        final senderSnap = await transaction.get(userSenderReference);
        if (!senderSnap.exists) {
          throw Exception("User not found in database");
        }

        final receiverSnap = await transaction.get(userReceiverReference);
        if (!receiverSnap.exists) {
          throw Exception("User not found in database");
        }

        final senderFriendsList = Set<String>.from(senderSnap['friendsUid'] ?? []);
        final senderPendingInvitationsList = Set<String>.from(senderSnap['pendingInvitationsToFriends'] ?? []);
        final receiverFriendsList = Set<String>.from(receiverSnap['friendsUid'] ?? []);
        final receiverReceivedInvitationsList = Set<String>.from(receiverSnap['receivedInvitationsToFriends'] ?? []);

        final senderFirstName = senderSnap['firstName'] ?? '';
        final senderLastName = senderSnap['lastName'] ?? '';
        final receiverFirstName = receiverSnap['firstName'] ?? '';
        final receiverLastName = receiverSnap['lastName'] ?? '';

        if (action == UserAction.inviteToFriends) {
          if(senderFriendsList.contains(receiverUid)) {
            return false;
          }
          if(receiverFriendsList.contains(senderUid)) {
            return false;
          }

          if(senderPendingInvitationsList.contains(receiverUid)) {
            return false;
          }

          if(receiverReceivedInvitationsList.contains(senderUid)) {
            return false;
          }

          if(senderReceivedInvitationsList.contains(receiverUid)) {
            return false;
          }


            senderPendingInvitationsList.add(receiverUid);
          AppData.currentUser?.pendingInvitationsToFriends = senderPendingInvitationsList;
          receiverReceivedInvitationsList.add(senderUid);
          notification = AppNotification(
            notificationId: "",
            uid: receiverUid,
            title: "$senderFirstName $senderLastName wants to be your friend",
            createdAt: DateTime.now(),
            seen: false,
            type: NotificationType.inviteFriends,
          );
        } else if (action == UserAction.removeInvitation) {
          receiverReceivedInvitationsList.remove(senderUid);
          senderPendingInvitationsList.remove(receiverUid);
          AppData.currentUser?.pendingInvitationsToFriends = senderPendingInvitationsList;
        } else if (action == UserAction.acceptInvitationToFriends) {
          senderFriendsList.add(receiverUid);
          receiverFriendsList.add(senderUid);

          AppNotification(
            notificationId: "",
            uid: receiverUid,
            title: "$receiverFirstName $receiverLastName accepted your friend request",
            createdAt: DateTime.now(),
            seen: false,
            type: NotificationType.inviteFriends,
          );

          AppData.currentUser?.friendsUid = receiverFriendsList;
          AppData.currentUser?.receivedInvitationsToFriends = receiverReceivedInvitationsList;

          senderPendingInvitationsList.remove(receiverUid);
          receiverReceivedInvitationsList.remove(senderUid);
        } else if (action == UserAction.declineInvitationToFriends) {
          receiverReceivedInvitationsList.remove(receiverUid);

          AppData.currentUser?.receivedInvitationsToFriends = receiverReceivedInvitationsList;
        } else if (action == UserAction.deleteFriend) {
          senderFriendsList.remove(receiverUid);
          receiverFriendsList.remove(senderUid);
          AppData.currentUser?.friendsUid = senderFriendsList;
        }

        transaction.update(userSenderReference, {
          'pendingInvitationsToFriends': senderPendingInvitationsList,
          'friendsUid': senderFriendsList,
        });
        transaction.update(userReceiverReference, {
          'receivedInvitationsToFriends': receiverReceivedInvitationsList,
          'friendsUid': receiverFriendsList,
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
        AppUtils.setsEqual(u1.pendingInvitationsToFriends, u2.pendingInvitationsToFriends) &&
        AppUtils.setsEqual(u1.receivedInvitationsToFriends, u2.receivedInvitationsToFriends) &&
        AppUtils.setsEqual(u1.receivedInvitationsToCompetitions, u2.receivedInvitationsToCompetitions) &&
        AppUtils.setsEqual(u1.participatedCompetitions, u2.participatedCompetitions);
  }

  /// Check if the user account exists in firestore
  // TODO TO FIX THIS with returning true
  static Future<bool> checkIfUserAccountExists(String uid) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return docSnapshot.exists;
    } catch (e) {
      return true;
    }
  }
}

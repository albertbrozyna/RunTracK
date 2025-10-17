import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/constans/firestore_names.dart';
import 'package:run_track/features/auth/models/auth_response.dart';
import 'package:run_track/models/activity.dart';
import 'package:run_track/models/user.dart' as model;

class UserService {
  static DocumentSnapshot? lastFetchedDocumentParticipants; // Participants in run competition
  static DocumentSnapshot? lastFetchedDocumentInvitedParticipants; // Invited participants

  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null &&
        AppData.currentUser != null &&
        AppData.currentUser!.uid == FirebaseAuth.instance.currentUser!.uid;
  }

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

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
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
      activityNames: sourceUser.activityNames != null
          ? List.from(sourceUser.activityNames!)
          : null,
      friendsUid: sourceUser.friendsUid != null
          ? List.from(sourceUser.friendsUid!)
          : null,
      email: sourceUser.email,
      profilePhotoUrl: sourceUser.profilePhotoUrl,
      dateOfBirth: sourceUser.dateOfBirth != null
          ? DateTime.fromMillisecondsSinceEpoch(
              sourceUser.dateOfBirth!.millisecondsSinceEpoch,
            )
          : null,
      defaultLocation: LatLng(
        sourceUser.userDefaultLocation.latitude,
        sourceUser.userDefaultLocation.longitude,
      ),
    );
  }

  /// Delete user from firestore
  static Future<bool> deleteUserFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No user is currently logged in.");
        return false;
      }
      final uid = user.uid;
      // Delete a collection from a firestore
      await FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(uid).delete();

      // Delete user from Firebase Auth
      await user.delete();

      print("User deleted successfully.");
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
      'fullName' : user.fullName,
      'email': user.email,
      'activityNames': user.activityNames ?? [],
      'dateOfBirth': user.dateOfBirth != null
          ? Timestamp.fromDate(user.dateOfBirth!)
          : null,
      'gender': user.gender,
      'friendsUid': user.friendsUid,
      'pendingInvitationsToFriends' : user.pendingInvitationsToFriends,
      'receivedInvitationsToFriends' : user.receivedInvitationsToFriends,
      'receivedInvitationsToCompetitions' : user.receivedInvitationsToCompetitions,
      'profilePhotoUrl': user.profilePhotoUrl,
      'userDefaultLocation': {
        'latitude': user.userDefaultLocation.latitude,
        'longitude': user.userDefaultLocation.longitude,
      },
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
      friendsUid: List<String>.from(map['friendsUids'] ?? []),
      pendingInvitationsToFriends: map['pendingInvitationsToFriends'],
      receivedInvitationsToFriends: map['receivedInvitationsToFriends'],
      receivedInvitationForCompetitions: map['receivedInvitationForCompetitions'],
      participatedCompetitions: map['participatedCompetitions'],
      profilePhotoUrl: map['profilePhotoUrl'],
      defaultLocation: location != null
          ? LatLng(
              (location['latitude'] ?? 0.0).toDouble(),
              (location['longitude'] ?? 0.0).toDouble(),
            )
          : LatLng(0.0, 0.0),
      dateOfBirth: map['dateOfBirth'] != null
          ? (map['dateOfBirth'] as Timestamp).toDate()
          : null,

      gender: map['gender'],
      kilometers: map['kilometers'] ?? 0,
      burnedCalories: map['burnedCalories'] ?? 0,
      hoursOfActivity: map['hoursOfActivity'] ?? 0,
    );
  }

  /// Fetch one user data
  static Future<model.User?> fetchUser(String uid) async {
    if(uid.isEmpty){
      return null;
    }
    final docSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

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
        final profilePhotoUrl = data['profilePhotoUrl'] as String?;

        if(firstName == null || lastName == null){
          return null;
        }

        return model.User(
          uid: uid,
          firstName: firstName,
          lastName: lastName,
          gender: gender,
          profilePhotoUrl: profilePhotoUrl,
        );
      }
    }
    return null;
  }

  /// Fetch participants invited to run competition
  static Future<List<model.User>> fetchInvitedParticipants({required List<String> uids,DocumentSnapshot? lastDocument,int limit = 10}) async{
    if (uids.isEmpty) {
      return [];
    }

    try {
      Query queryUsers = FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .where("uid", whereIn: uids)
          .limit(limit);

      if (lastDocument != null) {
        queryUsers =  queryUsers.startAfterDocument(lastDocument);
      }
      final querySnapshot = await queryUsers.get();

      if (querySnapshot.docs.isNotEmpty) {
        lastFetchedDocumentInvitedParticipants = querySnapshot.docs.last;
      }

      final users = querySnapshot.docs
          .map((doc) => UserService.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      return users;
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }


  /// Search users in firestore
  static Future<List<model.User>> searchUsers(String query) async {
    if(query.isEmpty){
      return [];
    }
    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('fullName', isGreaterThanOrEqualTo: query)
        .where('fullName', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    if (docSnapshot.docs.isEmpty) {
      return [];
    }

    final List<model.User> users = docSnapshot.docs.map((doc) {
      final data = doc.data();
      final firstName = data['firstName'].toString();
      final lastName = data['lastName'].toString();
      final gender = data['gender'].toString();
      final profilePhotoUrl = data['profilePhotoUrl'].toString();

      return model.User(
        uid: doc.id,
        firstName: firstName,
        lastName: lastName,
        gender: gender ?? "",
        profilePhotoUrl: profilePhotoUrl,
      );
    }).toList();

    return users;
  }




  /// Fetch list of users
  static Future<List<model.User>> fetchParticipants({required List<String> uids,DocumentSnapshot? lastDocument,int limit = 10}) async{
    if (uids.isEmpty) {
      return [];
    }

    try {
      Query queryUsers = FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .where("uid", whereIn: uids)
          .limit(limit);

      if (lastDocument != null) {
        queryUsers =  queryUsers.startAfterDocument(lastDocument);
      }
      final querySnapshot = await queryUsers.get();

      if (querySnapshot.docs.isNotEmpty) {
        lastFetchedDocumentParticipants = querySnapshot.docs.last;
      }

      final users = querySnapshot.docs
          .map((doc) => UserService.fromMap(doc.data() as Map<String, dynamic>))
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
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await docRef.set(UserService.toMap(user));
      return user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  /// Send invitations to friends to another user returns true if success
  static Future<bool> inviteToFriends(
    String senderUid,
    String receiverUid,
  ) async {
    // TODO
    try {
      // Add a uid to send invites
      model.User? sender = await UserService.fetchUser(senderUid);
      model.User? receiver = await UserService.fetchUser(receiverUid);

      if (sender == null || receiver == null) {
        return false;
      }
      sender.pendingInvitationsToFriends.add(receiverUid);
      receiver.receivedInvitationsToFriends.add(senderUid);
      await UserService.updateUser(sender);
      await UserService.updateUser(receiver);
    } catch (e) {
      print(e);
    }
    return false;
  }

  /// Accept invitations to friends from another user, returns true if success
  static Future<bool> acceptFriend(String senderUid, String receiverUid) async {
    // TODO
    try {
      // Add a uid to send invites
      model.User? sender = await UserService.fetchUser(senderUid);
      model.User? receiver = await UserService.fetchUser(receiverUid);

      if (sender == null || receiver == null) {
        return false;
      }
      if (sender.pendingInvitationsToFriends.contains(receiverUid)) {
        sender.pendingInvitationsToFriends.remove(receiverUid);
      }
      if (receiver.receivedInvitationsToFriends.contains(senderUid)) {
        receiver.receivedInvitationsToFriends.remove(senderUid);
      }
      // TODO The same as with invitations
      receiver.friendsUid.add(senderUid);
      sender.friendsUid.add(receiverUid);
      await UserService.updateUser(sender);
      await UserService.updateUser(receiver);
    } catch (e) {
      print(e);
    }
    return false;
  }

  /// Create a user in firebase auth
  static Future<AuthResponse> createUserInFirebaseAuth(String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim().toLowerCase(),
            password: password.trim(),
          );

      return AuthResponse(message: "User created",userCredential: userCredential);
    } on FirebaseAuthException catch (e) {
      return AuthResponse(message:"Auth error ${e.message}");
    } catch (e) {
      return AuthResponse(message:"Auth error $e");
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

    model.User? user = await UserService.addUser(
      model.User(
        uid: uid,
        firstName: firstname.trim().toLowerCase().capitalize(),
        lastName: lastname.trim().toLowerCase().capitalize(),
        email: email.trim().toLowerCase(),
        gender: gender.trim().toLowerCase(),
        dateOfBirth: dateOfBirth,
        profilePhotoUrl: "",
        activityNames: AppUtils.getDefaultActivities(),
        friendsUid: [],
      ),
    );

    return "User created";
  }

  /// Check if the user account exists in firestore
  // TODO TO FIX THIS with returning true
  static Future<bool> checkIfUserAccountExists(String uid) async {
    try{
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return docSnapshot.exists;
    }catch(e){
      return true;
    }
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/models/activity.dart';
import 'package:run_track/models/competition.dart';
import 'package:run_track/services/activity_service.dart';
import 'package:run_track/theme/colors.dart';

import '../../../common/enums/competition_role.dart';
import '../../../services/user_service.dart';

class CompetitionBlock extends StatefulWidget{
  final String firstName;
  final String lastName;
  final String? profilePhotoUrl;
  final Competition competition;

  const CompetitionBlock({super.key, required this.competition, String? firstName, String? lastName, String? profilePhotoUrl})
      : firstName = firstName ?? "",
        lastName = lastName ?? "",
        profilePhotoUrl = profilePhotoUrl ?? "";

  State<CompetitionBlock>_createState() => _CompetitionBlockState();
}



class _CompetitionBlockState extends State<CompetitionBlock> {
  CompetitionRole role = CompetitionRole.viewer;


  @override
  void initState() {
    super.initState();
    initialize();
    initializeAsync();
  }

  void initialize() {
    if (FirebaseAuth.instance.currentUser?.uid == widget.competition.organizerUid) {
      role == CompetitionRole.owner;
    }


    firstname = widget.firstName;
    lastname = widget.lastName;
    profilePhotoUrl = widget.profilePhotoUrl;
  }

  Future<void> initializeAsync() async {
    if (widget.firstName.isEmpty || widget.lastName.isEmpty) {
      // If there is no name and last name fetch it from firestore
      return UserService.fetchUserForBlock(widget.activity.uid)
          .then((user) {
        setState(() {
          firstname = user?.firstName;
          lastname = user?.lastName;
          profilePhotoUrl = user?.profilePhotoUrl;
        });
      })
          .catchError((error) {
        print("Error fetching user data: $error");
      });
    }
  }

  /// On activity block tap
  void onTapBlock(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivitySummary(
          activityData: widget.activity,
          readonly: readonly,
          editMode: edit,
          firstName: widget.firstName,
          lastName: widget.lastName,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFFFA726).withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24, width: 1, style: BorderStyle.solid),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4.0, spreadRadius: 2.0, offset: Offset(2, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24, width: 1, style: BorderStyle.solid),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Header with name, date  and profile page
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile photo
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.0),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundImage: profilePhotoUrl != null
                                ? NetworkImage(profilePhotoUrl!)
                                : AssetImage('assets/DefaultProfilePhoto.png') as ImageProvider,
                          ),
                        ),
                        SizedBox(width: 10),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // tekst wyrównany do lewej
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "$firstName $lastName",
                              textAlign: TextAlign.left,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            Text(
                              "CreatedAt: Time: ${DateFormat('dd-MM-yyyy hh:mm').format(competition.createdAt ?? DateTime.now())}",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ],
                        ),

                        // Date
                        // TODO Think about it what if start time is null
                      ],
                    ),
                    // Title + Stats Block
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white, // białe tło
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title on top
                          if (competition.name != null && competition.name!.isNotEmpty)
                            Text(
                              competition.name!,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                            ),

                          SizedBox(height: 4),

                          if (competition.description != null && competition.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(competition.description!, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                            ),

                          // Time and Distance row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Time
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 22, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Text(competition.startDate.toString(), style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                                ],
                              ),
                              SizedBox(width: 16),

                              // Distance
                              Row(
                                children: [
                                  Icon(Icons.map, size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Text("Text", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                                ],
                              ),
                            ],
                          ),

                          // Optional Description under stats
                        ],
                      ),
                    ),

                    // TODO TO THINK ABOUT IT WITH C# BACKEND
                    // Photos from the run
                    // if (competition.photos.isNotEmpty)
                    //   SizedBox(
                    //     height: 120,
                    //     child: ListView.builder(
                    //       // From left to right
                    //       scrollDirection: Axis.horizontal,
                    //       itemCount: activity.photos.length,
                    //       itemBuilder: (context, index) {
                    //         return Padding(
                    //           padding: const EdgeInsets.all(4.0),
                    //           child: ClipRRect(
                    //             borderRadius: BorderRadius.circular(10),
                    //             child: Image.network(
                    //               activity.photos[index],
                    //               width: 120,
                    //               height: 120,
                    //               fit: BoxFit.cover,
                    //             ),
                    //           ),
                    //         );
                    //       },
                    //     ),
                    //   ),
                    // Map with activity map
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

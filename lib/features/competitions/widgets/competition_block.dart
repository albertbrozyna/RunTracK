import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/features/competitions/pages/compeption_add.dart';
import 'package:run_track/models/activity.dart';
import 'package:run_track/models/competition.dart';
import 'package:run_track/services/activity_service.dart';
import 'package:run_track/theme/colors.dart';

import '../../../common/enums/competition_role.dart';
import '../../../services/user_service.dart';
import '../../track/widgets/stat_card.dart';

class CompetitionBlock extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String? profilePhotoUrl;
  final Competition competition;
  final int initIndex;
  final double titleFontSizeBlock = 14;
  final double valueFontSizeBlock = 14;
  final double innerPaddingBlock = 10;
  final double blockWidth = 120;
  final double blockHeight = 100;
  final double iconSize = 26;

  const CompetitionBlock({super.key, required this.competition,required this.initIndex, String? firstName, String? lastName, String? profilePhotoUrl})
    : firstName = firstName ?? "",
      lastName = lastName ?? "",
      profilePhotoUrl = profilePhotoUrl ?? "";

  @override
  State<StatefulWidget> createState() {
    return _CompetitionBlockState();
  }
}

class _CompetitionBlockState extends State<CompetitionBlock> {
  CompetitionContext enterContext = CompetitionContext.viewerNotAbleToJoin;
  String firstName = "";
  String lastName = "";
  String profilePhotoUrl = "";
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    initialize();
    initializeAsync();
  }

  void initialize() {
    if (widget.initIndex == 0) {  // My competitions
        enterContext  == CompetitionContext.ownerModify;
    }else if(widget.initIndex == 1 && (widget.competition.registrationDeadline?.isBefore(DateTime.now()) ?? false)){
        enterContext ==  CompetitionContext.viewerNotAbleToJoin;
    }else if(widget.initIndex == 1 && (widget.competition.registrationDeadline?.isAfter(DateTime.now()) ?? false)){
      enterContext ==  CompetitionContext.viewerAbleToJoin;
    }else if(widget.initIndex == 2 && (widget.competition.registrationDeadline?.isAfter(DateTime.now()) ?? false)){
      enterContext ==  CompetitionContext.viewerAbleToJoin;
    }else if(widget.initIndex == 2 && (widget.competition.registrationDeadline?.isBefore(DateTime.now()) ?? false)){
      enterContext ==  CompetitionContext.viewerNotAbleToJoin;
    }else if(widget.initIndex == 3 && (widget.competition.registrationDeadline?.isBefore(DateTime.now()) ?? false)){
      enterContext ==  CompetitionContext.participant;
    }else if(widget.initIndex == 4 && (widget.competition.registrationDeadline?.isBefore(DateTime.now()) ?? false)){
      enterContext ==  CompetitionContext.invited;
    }

    firstName = widget.firstName;
    lastName = widget.lastName;
  }

  Future<void> initializeAsync() async {
    if (widget.firstName.isEmpty || widget.lastName.isEmpty) {
      // If there is no name and last name fetch it from firestore
      return UserService.fetchUserForBlock(widget.competition.organizerUid)
          .then((user) {
            setState(() {
              firstName = user?.firstName ?? "User";
              lastName = user?.lastName ?? "Unknown";
              profilePhotoUrl = user?.profilePhotoUrl ?? "";
            });
          })
          .catchError((error) {
            print("Error fetching user data: $error");
          });
    }
  }

  /// On competition block tap
  void onTapBlock(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>CompetitionDetails(
          enterContext: enterContext,
          competitionData: widget.competition,
          initTab: widget.initIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
      child: InkWell(
        onTap: () => onTapBlock(context),
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
                        backgroundImage: widget.profilePhotoUrl != null
                            ? NetworkImage(widget.profilePhotoUrl!)
                            : AssetImage('assets/DefaultProfilePhoto.png') as ImageProvider,
                      ),
                    ),
                    SizedBox(width: 10),

                    // First name and date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$firstName $lastName",
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        if (widget.competition.createdAt != null)
                          Text(
                            "Time: ${DateFormat('dd-MM-yyyy hh:mm').format(widget.competition.createdAt!)}",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                      ],
                    ),
                  ],
                ),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title on top
                      if (widget.competition.name.isNotEmpty)
                        Text(
                          widget.competition.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                        ),
                      SizedBox(height: 4),
                      // Stats on the left and map on the right
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Scrollbar(
                          thumbVisibility: true,
                          controller: _scrollController,
                          thickness: 4,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              spacing: 10,
                              children: [
                                if (widget.competition.startDate != null)
                                  StatCard(
                                    title: "Time",
                                    value: widget.competition.startDate!.toString(),
                                    icon: Icon(Icons.timer, size: widget.iconSize),
                                    titleFontSize: widget.titleFontSizeBlock,
                                    valueFontSize: widget.valueFontSizeBlock,
                                    innerPadding: widget.innerPaddingBlock,
                                    cardWidth: widget.blockWidth,
                                  ),
                                if (widget.competition.endDate != null)
                                  StatCard(
                                    title: "Distance",
                                    value: widget.competition.endDate.toString(),
                                    icon: Icon(Icons.social_distance),
                                    titleFontSize: widget.titleFontSizeBlock,
                                    valueFontSize: widget.valueFontSizeBlock,
                                    innerPadding: widget.innerPaddingBlock,
                                    cardWidth: widget.blockWidth,
                                  ),
                                if (widget.competition.activityType != null)
                                  StatCard(
                                    title: "Pace",
                                    value: widget.competition.activityType.toString(),
                                    icon: Icon(Icons.man, size: widget.iconSize),
                                  ),
                                if (widget.competition.maxTimeToCompleteActivityHours != null ||
                                    widget.competition.maxTimeToCompleteActivityMinutes != null)
                                  // TODO
                                  StatCard(
                                    title: "Max time to complete activity",
                                    value:
                                        (widget.competition.maxTimeToCompleteActivityHours != null &&
                                            widget.competition.maxTimeToCompleteActivityMinutes != null)
                                        ? "${widget.competition.maxTimeToCompleteActivityHours}h ${widget.competition.maxTimeToCompleteActivityMinutes}m"
                                        : widget.competition.maxTimeToCompleteActivityHours != null
                                        ? "${widget.competition.maxTimeToCompleteActivityHours}h"
                                        : "${widget.competition.maxTimeToCompleteActivityMinutes}m",
                                    icon: Icon(Icons.local_fire_department, size: widget.iconSize),
                                    titleFontSize: widget.titleFontSizeBlock,
                                    valueFontSize: widget.valueFontSizeBlock,
                                    innerPadding: widget.innerPaddingBlock,
                                    cardWidth: widget.blockWidth,
                                  ),
                                  StatCard(
                                    title: widget.competition.competitionGoalType.toString(),
                                    value: '${widget.competition.goal.toString()} km',
                                    icon: Icon(Icons.speed, size: widget.iconSize),
                                    titleFontSize: widget.titleFontSizeBlock,
                                    valueFontSize: widget.valueFontSizeBlock,
                                    innerPadding: widget.innerPaddingBlock,
                                    cardWidth: widget.blockWidth,
                                  ),
                                if (widget.competition.registrationDeadline != null)
                                  StatCard(
                                    title: "Steps",
                                    value: widget.competition.registrationDeadline.toString(),
                                    icon: Icon(Icons.directions_walk, size: widget.iconSize),
                                    titleFontSize: widget.titleFontSizeBlock,
                                    valueFontSize: widget.valueFontSizeBlock,
                                    innerPadding: widget.innerPaddingBlock,
                                    cardWidth: widget.blockWidth,
                                  ),
                                if (widget.competition.locationName != null)
                                  StatCard(
                                    title: "Elevation",
                                    value: '${widget.competition.locationName}',
                                    icon: Icon(Icons.terrain, size: widget.iconSize),
                                    titleFontSize: widget.titleFontSizeBlock,
                                    valueFontSize: widget.valueFontSizeBlock,
                                    innerPadding: widget.innerPaddingBlock,
                                    cardWidth: widget.blockWidth,
                                  ),
                              ],
                            ),
                          ),
                          // Map with activity
                        ),
                        // Optional Description under stats
                      ),
                    ],
                  ),
                ),

                // Photos from the run
                if (widget.competition.photos.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      // From left to right
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.competition.photos.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(widget.competition.photos[index], width: 120, height: 120, fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:run_track/common/utils/app_data.dart';
import 'package:run_track/config/assets/app_images.dart';
import 'package:run_track/config/routes/app_routes.dart';
import 'package:run_track/models/competition.dart';
import 'package:run_track/theme/ui_constants.dart';

import '../../../common/enums/competition_role.dart';
import '../../../common/utils/utils.dart';
import '../../../services/user_service.dart';
import '../../../common/widgets/stat_card.dart';

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

  const CompetitionBlock({
    super.key,
    required this.competition,
    required this.initIndex,
    String? firstName,
    String? lastName,
    String? profilePhotoUrl,
  }) : firstName = firstName ?? "",
       lastName = lastName ?? "",
       profilePhotoUrl = profilePhotoUrl ?? "";

  @override
  State<StatefulWidget> createState() => _CompetitionBlockState();
}

class _CompetitionBlockState extends State<CompetitionBlock> {
  CompetitionContext enterContext = CompetitionContext.viewerNotAbleToJoin;
  String firstName = "";
  String lastName = "";
  String profilePhotoUrl = "";
  String goalType = "";
  String goalFormatted = "";
  String? meetingPlace;
  String? maxTimeToCompleteActivity;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    initialize();
    initializeAsync();
  }

  void initialize() {
    if (widget.initIndex == 0) {
      // Set enter context
      enterContext = CompetitionContext.ownerModify;
    } else if (widget.initIndex == 1 && (widget.competition.registrationDeadline?.isBefore(DateTime.now()) ?? false)) {
      enterContext = CompetitionContext.viewerNotAbleToJoin;
    } else if (widget.initIndex == 1 && (widget.competition.registrationDeadline?.isAfter(DateTime.now()) ?? false)) {
      enterContext = CompetitionContext.viewerAbleToJoin;
    } else if (widget.initIndex == 2 && (widget.competition.registrationDeadline?.isAfter(DateTime.now()) ?? false)) {
      enterContext = CompetitionContext.viewerAbleToJoin;
    } else if (widget.initIndex == 2 && (widget.competition.registrationDeadline?.isBefore(DateTime.now()) ?? false)) {
      enterContext = CompetitionContext.viewerNotAbleToJoin;
    } else if (widget.initIndex == 3 && (widget.competition.registrationDeadline?.isBefore(DateTime.now()) ?? false)) {
      enterContext = CompetitionContext.participant;
    } else if (widget.initIndex == 4 && (widget.competition.registrationDeadline?.isBefore(DateTime.now()) ?? false)) {
      enterContext = CompetitionContext.invited;
    }

    firstName = widget.firstName;
    lastName = widget.lastName;

    goalType = "Distance";
    goalFormatted = '${widget.competition.distanceToGo} km';

    if (widget.competition.location != null) {
      String? latStr = widget.competition.location?.latitude.toStringAsFixed(4);
      String? lngStr = widget.competition.location?.longitude.toStringAsFixed(4);

      if (widget.competition.locationName != null) {
        meetingPlace = "${widget.competition.locationName}\nLat: ${latStr ?? ''}, Lng: ${lngStr ?? ''}";
      } else {
        meetingPlace = "Lat: $latStr, Lng: $lngStr";
      }
    }

    if (widget.competition.maxTimeToCompleteActivityHours != null && widget.competition.maxTimeToCompleteActivityMinutes != null) {
      maxTimeToCompleteActivity =
          '${widget.competition.maxTimeToCompleteActivityHours}h ${widget.competition.maxTimeToCompleteActivityMinutes}m';
    }
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
    Navigator.pushNamed(
      context,
      AppRoutes.competitionDetails,
      arguments: {'enterContext': enterContext, 'competitionData': widget.competition, 'initTab': widget.initIndex},
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTapBlock(context),
      child: Container(
        decoration: AppUiConstants.decorationBlock,
        child: Padding(
          // Inside padding
          padding: const EdgeInsets.all(AppUiConstants.blockInsideContentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name, date  and profile page
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile photo
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.0),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: widget.profilePhotoUrl != null && widget.profilePhotoUrl!.isNotEmpty
                          ? NetworkImage(widget.profilePhotoUrl!)
                          : AssetImage(AppImages.defaultProfilePhoto) as ImageProvider,
                    ),
                  ),
                  SizedBox(width: 4),
                  // First name and date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$firstName $lastName",
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      if (widget.competition.createdAt != null)
                        Text(
                          "Created At: ${DateFormat('dd-MM-yyyy hh:mm').format(widget.competition.createdAt!)}",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 6),
              // Title
              Padding(
                padding: EdgeInsets.only(left: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.competition.name,
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    if (widget.competition.description != null)
                      Text(
                        widget.competition.description!,
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: Colors.grey[800]),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 7),
              // Stats scrollable
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
                        if (widget.competition.activityType != null)
                          StatCard(
                            title: "Activity",
                            value: widget.competition.activityType.toString(),
                            icon: Icon(Icons.directions_run, size: widget.iconSize),
                            titleFontSize: widget.titleFontSizeBlock,
                            valueFontSize: widget.valueFontSizeBlock,
                            innerPadding: widget.innerPaddingBlock,
                          ),
                        // Goal formatted - amount of kilometers minutes
                        StatCard(
                          title: goalType,
                          value: goalFormatted,
                          icon: Icon(Icons.timeline),
                          titleFontSize: widget.titleFontSizeBlock,
                          valueFontSize: widget.valueFontSizeBlock,
                          innerPadding: widget.innerPaddingBlock,
                        ),
                        // Max time to complete activity
                        if (maxTimeToCompleteActivity != null)
                          StatCard(
                            title: "Max time to\n complete activity",
                            value: maxTimeToCompleteActivity!,
                            icon: Icon(Icons.timer, size: widget.iconSize),
                            titleFontSize: widget.titleFontSizeBlock,
                            valueFontSize: widget.valueFontSizeBlock,
                            innerPadding: widget.innerPaddingBlock,
                          ),
                        if (widget.competition.startDate != null)
                          StatCard(
                            title: "Start time",
                            value: AppUtils.formatDateTime(widget.competition.startDate),
                            icon: Icon(Icons.play_arrow),
                            titleFontSize: widget.titleFontSizeBlock,
                            valueFontSize: widget.valueFontSizeBlock,
                            innerPadding: widget.innerPaddingBlock,
                          ),
                        if (widget.competition.endDate != null)
                          StatCard(
                            title: "End date",
                            value: AppUtils.formatDateTime(widget.competition.endDate),
                            icon: Icon(Icons.calendar_today, size: widget.iconSize),
                            titleFontSize: widget.titleFontSizeBlock,
                            valueFontSize: widget.valueFontSizeBlock,
                            innerPadding: widget.innerPaddingBlock,
                          ),
                        if (widget.competition.registrationDeadline != null)
                          StatCard(
                            title: "Register to",
                            value: AppUtils.formatDateTime(widget.competition.registrationDeadline),
                            icon: Icon(Icons.app_registration, size: widget.iconSize),
                            titleFontSize: widget.titleFontSizeBlock,
                            valueFontSize: widget.valueFontSizeBlock,
                            innerPadding: widget.innerPaddingBlock,
                          ),
                      ],
                    ),
                  ),
                  // Map with activity
                ),
                // Optional Description under stats
              ),
              SizedBox(height: 7),
              if (meetingPlace != null)
                SizedBox(
                  width: double.infinity,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: "Meeting place: ",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextSpan(
                          text: meetingPlace,
                          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              // Photos from the run
              if (widget.competition.photos.isNotEmpty && AppData.instance.images)
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
    );
  }
}

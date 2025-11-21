import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/app/config/app_data.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/enums/competition_role.dart';
import '../../../../core/enums/enter_context.dart';
import '../../../../core/enums/mode.dart';
import '../../data/models/competition.dart';
import '../../../../core/widgets/custom_button.dart' show CustomButton;
import '../../../../core/widgets/section.dart';

class LocationAndParticipantsSection extends StatefulWidget {
  final CompetitionContext enterContext;
  final Competition competition;
  final TextEditingController meetingPlaceController;
  final bool saved;

  const LocationAndParticipantsSection({
    super.key,
    required this.competition,
    required this.meetingPlaceController,
    required this.enterContext,
    required this.saved,
  });

  @override
  State<LocationAndParticipantsSection> createState() => _LocationAndParticipantsSectionState();
}

class _LocationAndParticipantsSectionState extends State<LocationAndParticipantsSection> {
  /// Add place where runners can meet
  Future<void> onTapAddMeetingPlace() async {
    LatLng? latLngBefore = widget.competition.location;

    LatLng? latLngArg;
    if (widget.competition.location != null) {
      latLngArg = LatLng(
        widget.competition.location!.latitude,
        widget.competition.location!.longitude,
      );
    }

    Mode mode = Mode.view;
    if (AppData.instance.currentUser?.uid == widget.competition.organizerUid) {
      mode = Mode.edit;
    }

    final result = await Navigator.pushNamed(
      context,
      AppRoutes.meetingPlaceMap,
      arguments: {'mode': mode, "latLng": latLngArg},
    );

    if (result != null && result is LatLng) {
      String latStr = result.latitude.toStringAsFixed(4);
      String lngStr = result.longitude.toStringAsFixed(4);

      try {
        final placeNames = await placemarkFromCoordinates(result.latitude, result.longitude);

        if (placeNames.isNotEmpty) {
          final place = placeNames.first;
          String newLocationName = "${place.locality ?? ''}, ${place.thoroughfare ?? ''}".trim();

          if (widget.competition.locationName != newLocationName) {
            widget.competition.locationName = newLocationName;

            setState(() {
              widget.meetingPlaceController.text = "$newLocationName\nLat: $latStr, Lng: $lngStr";
            });
          }
        } else {
          setState(() {
            widget.meetingPlaceController.text = "Lat: $latStr, Lng: $lngStr";
          });
        }
      } catch (e) {
        setState(() {
          widget.meetingPlaceController.text = "Lat: $latStr, Lng: $lngStr";
        });
      }

      if (latLngBefore != result) {
        widget.competition.location = result;
      }
    }
  }

  /// On pressed list participants
  void onPressedListParticipants(BuildContext context) async {
    EnterContextUsersList enterContext = EnterContextUsersList.participantsModify;
    if (widget.enterContext != CompetitionContext.ownerModify &&
        widget.enterContext != CompetitionContext.ownerCreate) {
      enterContext = EnterContextUsersList.participantsReadOnly;
    }

    await Navigator.pushNamed(
      context,
      AppRoutes.usersList,
      arguments: {
        "users": AppData.instance.currentCompetition?.participantsUid ?? {},
        "enterContext": enterContext,
      },
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Section(
      title: "Location and participants",
      children: [
        TextFormField(
          controller: widget.meetingPlaceController,
          readOnly: true,
          maxLines: 2,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.add_location_alt, color: Colors.white),
            labelText: "Meeting place",
          ),
          onTap: () async {
            onTapAddMeetingPlace();
          },
        ),
        SizedBox(height: AppUiConstants.verticalSpacingButtons),

        CustomButton(
          text: "Participants (${widget.competition.participantsUid.length})",
          onPressed: !widget.saved && widget.enterContext == CompetitionContext.ownerCreate
              ? null
              : () => onPressedListParticipants(context),
          backgroundColor: !widget.saved && widget.enterContext == CompetitionContext.ownerCreate
              ? AppColors.gray
              : AppColors.primary,
        ),
      ],
    );
  }
}

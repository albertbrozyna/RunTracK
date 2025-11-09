

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/enums/competition_role.dart';
import '../../../../core/enums/enter_context.dart';
import '../../../../core/models/competition.dart';
import '../../../../core/widgets/custom_button.dart' show CustomButton;
import '../../../../core/widgets/section.dart';

class LocationAndParticipantsSection extends StatefulWidget{
  final CompetitionContext enterContext;
  final Competition competition;
  final TextEditingController meetingPlaceController;
  const LocationAndParticipantsSection({super.key,required this.competition,required this.meetingPlaceController,required this.enterContext});

  @override
  State<LocationAndParticipantsSection>  createState() => _LocationAndParticipantsSectionState();
}

class _LocationAndParticipantsSectionState extends State<LocationAndParticipantsSection> {

  /// Add place where runners can meet
  Future<void> onTapAddMeetingPlace() async {
    LatLng? latLng;
    final location = widget.competition.location;

    if (location?.latitude != null && location?.longitude != null) {
      latLng = LatLng(location!.latitude, location.longitude);
    }
    final result = await Navigator.pushNamed(context, AppRoutes.meetingPlaceMap,arguments : {"latLng":latLng});

    if (result != null && result is LatLng) {
      widget.competition.location = result;
      String? latStr = widget.competition.location?.latitude.toStringAsFixed(4);
      String? lngStr = widget.competition.location?.longitude.toStringAsFixed(4);

      final placeNames = await placemarkFromCoordinates(result.latitude, result.longitude);

      if (placeNames.isNotEmpty) {
        final place = placeNames.first;
        widget.competition.locationName = "${place.locality ?? ''}, ${place.thoroughfare ?? ''}".trim();

        setState(() {
          widget.meetingPlaceController.text = "${widget.competition.locationName}\nLat: ${latStr ?? ''}, Lng: ${lngStr ?? ''}";
        });
      } else {
        widget.meetingPlaceController.text = "Lat: $latStr, Lng: $lngStr";
      }
    }
  }

  /// On pressed list participants
  void onPressedListParticipants(BuildContext context) async {
    EnterContextUsersList enterContext = EnterContextUsersList.participantsModify;
    if (widget.enterContext != CompetitionContext.ownerModify && widget.enterContext != CompetitionContext.ownerCreate) {
      enterContext = EnterContextUsersList.participantsReadOnly;
    }

    final result = await Navigator.pushNamed(context,
        AppRoutes.usersList, arguments: {
          "usersUid": widget.competition.participantsUid,
          "usersUid2": widget.competition.invitedParticipantsUid,
          "usersUid3": <String>{},
          "enterContext": enterContext,
        });
    if (result != null && result is Map<String, dynamic>) {
      // Set invited participants
      setState(() {
        widget.competition.invitedParticipantsUid = result['usersUid2'] ?? {};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return       Section(
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

        // Invited competitors
        CustomButton(
          text: "Participants (${widget.competition.participantsUid.length})",
          onPressed: () => onPressedListParticipants(context),
        ),
      ],
    );
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/core/enums/competition_role.dart';
import 'package:run_track/core/models/competition.dart';

import '../../../../app/config/app_data.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/enums/visibility.dart';
import '../../../../core/widgets/custom_button.dart';

class BottomButtons extends StatefulWidget {
  final Competition competition;
  final CompetitionContext enterContext;
  final VoidCallback handleSaveCompetition;
  final VoidCallback closeCompetition;
  final VoidCallback acceptInvitation;
  final VoidCallback declineInvitation;
  final VoidCallback joinCompetition;
  final VoidCallback resignFromCompetition;

  const BottomButtons({
    super.key,
    required this.enterContext,
    required this.competition,
    required this.handleSaveCompetition,
    required this.closeCompetition,
    required this.acceptInvitation,
    required this.declineInvitation,
    required this.joinCompetition,
    required this.resignFromCompetition,
  });

  @override
  State<BottomButtons> createState() => _BottomButtonsState();
}

class _BottomButtonsState extends State<BottomButtons> {
  bool canClose = false; // Can we close competition
  String buttonText = "";
  bool invited = false;
  bool open = false;
  bool alreadyParticipate = false;
  bool weAreOwner = false;
  bool weParticipate = false;
  @override
  void initState() {
    super.initState();

    if (widget.enterContext == CompetitionContext.ownerCreate) {
      buttonText = "Add competition";
    } else {
      buttonText = "Save changes";
    }

    DateTime now = DateTime.now();
    if (widget.enterContext == CompetitionContext.ownerModify &&
        (widget.competition.startDate?.isBefore(now) ?? false) &&
        (widget.competition.endDate?.isAfter(now) ?? false)) {
      canClose = true; // We can close competition
    }

    weAreOwner = widget.competition.organizerUid == (FirebaseAuth.instance.currentUser?.uid ?? false);
    weParticipate = widget.competition.participantsUid.contains(FirebaseAuth.instance.currentUser!.uid);

    if(!weAreOwner && !weParticipate){
      if(widget.competition.visibility == ComVisibility.everyone){
        open = true;
      } else if((AppData.instance.currentUser?.friends.contains(widget.competition.organizerUid) ?? false) &&
          widget.competition.visibility == ComVisibility.friends) { // If we are friends and
        open = true;
      }
    }

    if (widget.competition.invitedParticipantsUid.contains(FirebaseAuth.instance.currentUser!.uid)) {
      invited = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: AppUiConstants.verticalSpacingButtons),
        if (widget.enterContext == CompetitionContext.ownerCreate || widget.enterContext == CompetitionContext.ownerModify)
          CustomButton(text: buttonText, onPressed: widget.handleSaveCompetition),
        if (canClose) ...[
          SizedBox(height: AppUiConstants.verticalSpacingButtons),
          CustomButton(text: "Close competition", backgroundColor: AppColors.gray, onPressed: widget.closeCompetition),
        ],
        if (invited && !weAreOwner && !weParticipate) ...[
          SizedBox(height: AppUiConstants.verticalSpacingButtons),
          CustomButton(text: "Accept invitation", onPressed: widget.acceptInvitation),
          SizedBox(height: AppUiConstants.verticalSpacingButtons),
          CustomButton(text: "Decline invitation", onPressed: widget.declineInvitation),
          SizedBox(height: AppUiConstants.verticalSpacingButtons),
        ],

        if (open && !invited && !weAreOwner && !weParticipate) ...[
          SizedBox(height: AppUiConstants.verticalSpacingButtons),
          CustomButton(text: "Join competition", onPressed: widget.acceptInvitation),
          SizedBox(height: AppUiConstants.verticalSpacingButtons),
        ],

        if (open && !invited && !weAreOwner && weParticipate) ...[
          SizedBox(height: AppUiConstants.verticalSpacingButtons),
          CustomButton(text: "Resign from competition", onPressed: widget.declineInvitation),
          SizedBox(height: AppUiConstants.verticalSpacingButtons),
        ],
      ],
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/core/models/competition.dart';

import '../../../../app/config/app_data.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/enums/competition_role.dart';
import '../../../../core/enums/tracking_state.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../track/data/models/track_state.dart';
import '../pages/competition_det.dart';


class TopInfoBanner extends StatefulWidget {
  final Competition competition;
  final CompetitionContext enterContext;

  const TopInfoBanner({
    super.key,
    required this.competition,
    required this.enterC,
  });

  @override
  State<TopInfoBanner> createState() => _TopInfoBannerState();
}

class _TopInfoBannerState extends State<TopInfoBanner> {

  void _setAsCurrentCompetition() {
    if (AppData.instance.currentUser != null &&
        widget.competition.startDate!.isBefore(DateTime.now()) &&
        widget.competition.endDate!.isAfter(DateTime.now())) {

      AppData.instance.currentCompetition = widget.competition;
      AppData.instance.currentUser?.currentCompetition = widget.competition.competitionId;
      UserService.updateUser(AppData.instance.currentUser!);
      setState(() {});
    }
  }

  /// Clear the current competition
  void _clearCurrentCompetition() {
    // Setting the global state
    AppData.instance.currentCompetition = null;
    AppData.instance.currentUser?.currentCompetition = "";
    UserService.updateUser(AppData.instance.currentUser!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    CompetitionState? competitionState;
    String message = "";

    final bool isActive = widget.competition.startDate != null &&
        widget.competition.endDate != null &&
        widget.competition.startDate!.isBefore(DateTime.now()) &&
        widget.competition.endDate!.isAfter(DateTime.now());

    final bool isFinished = widget.competition.results?.containsKey(FirebaseAuth.instance.currentUser?.uid) ?? false;

    final bool isCurrent = AppData.instance.currentCompetition?.competitionId == widget.competition.competitionId;

    final bool ownerCreate = widget.enterContext != CompetitionContext.ownerCreate;

    final bool inProgress = isCurrent &&
        TrackState.trackStateInstance.trackingState != TrackingState.stopped;

    if (inProgress) {
      competitionState = CompetitionState.inProgress;
      message = "Competition in progress!";
    } else if (isFinished) {
      competitionState = CompetitionState.finished;
      message = "You have finished this competition.";
    } else if (isActive && !isFinished && !ownerCreate && !isCurrent) {
      competitionState = CompetitionState.canStart;
      message = "You can join this competition.";
    } else if (isCurrent && !inProgress && !isFinished) {
      competitionState = CompetitionState.canStart;
      message = "This is your current competition.";
    }

    if (competitionState == null) {
      return const SizedBox.shrink();
    }

    Color bannerColor = AppColors.primary;
    IconData bannerIcon = Icons.info_outline;

    if (competitionState == CompetitionState.inProgress) {
      bannerColor = Colors.green.shade700;
      bannerIcon = Icons.directions_run;
    } else if (competitionState == CompetitionState.finished) {
      bannerColor = Colors.grey.shade600;
      bannerIcon = Icons.check_circle_outline;
    } else if (competitionState == CompetitionState.canStart) {
      bannerColor = AppColors.primary;
      bannerIcon = Icons.flag_outlined;
    }

    return Card(
      margin: EdgeInsets.symmetric(
        vertical: AppUiConstants.verticalSpacingButtons,
        horizontal: 12.0,
      ),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
      ),
      child: Column(
        children: [
          Container(
            color: bannerColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(bannerIcon, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Button section
          if (competitionState != CompetitionState.finished)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildActionButtons(competitionState, isCurrent),
            ),
        ],
      ),
    );
  }

  /// Helper for building action buttons
  Widget _buildActionButtons(CompetitionState state, bool isCurrent) {
    if (isCurrent) {
      return CustomButton(
        text: "Clear current competition",
        onPressed: _clearCurrentCompetition,
      );
    } else if (state == CompetitionState.canStart) {
      return CustomButton(
        text: "Set as current competition",
        onPressed: _setAsCurrentCompetition,
        backgroundColor: AppColors.green,
      );
    }

    return const SizedBox.shrink();
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:run_track/app/navigation/app_routes.dart';
import 'package:run_track/features/competitions/data/models/competition.dart';
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

  const TopInfoBanner({super.key, required this.competition, required this.enterContext});

  @override
  State<TopInfoBanner> createState() => _TopInfoBannerState();
}

class _TopInfoBannerState extends State<TopInfoBanner> {
  void _setAsCurrentCompetition() {
    final now = DateTime.now();
    final start = widget.competition.startDate;
    final end = widget.competition.endDate;

    if (AppData.instance.currentUser != null &&
        start != null &&
        end != null &&
        start.isBefore(now) &&
        end.isAfter(now)) {
      setState(() {
        AppData.instance.currentUserCompetition = widget.competition;
        AppData.instance.currentUser?.currentCompetition = widget.competition.competitionId;
      });
      UserService.updateUser(AppData.instance.currentUser!);
    }
  }

  void _clearCurrentCompetition() {
    setState(() {
      AppData.instance.currentUserCompetition = null;
      AppData.instance.currentUser?.currentCompetition = "";
    });
    UserService.updateUser(AppData.instance.currentUser!);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = widget.competition.startDate;
    final end = widget.competition.endDate;

    final bool isActive = start != null && end != null && start.isBefore(now) && end.isAfter(now);

    final bool isFinished = widget.competition.usersThatFinished.contains(
      AppData.instance.currentUser?.uid,
    );

    final String currentCompId = AppData.instance.currentUser?.currentCompetition ?? "";
    final bool isCurrent =
        currentCompId == widget.competition.competitionId &&
        widget.competition.competitionId.isNotEmpty;

    final bool ownerCreate = widget.enterContext == CompetitionContext.ownerCreate;

    final bool inProgress =
        isCurrent && TrackState.trackStateInstance.trackingState != TrackingState.stopped;

    CompetitionState calculatedState;
    String message = "";

    if (ownerCreate) {
      return const SizedBox.shrink();
    }

    if (inProgress) {
      calculatedState = CompetitionState.inProgress;
      message = "Competition in progress!";
    } else if (isFinished) {
      calculatedState = CompetitionState.finished;
      message = "You have finished this competition.";
    } else if (isCurrent) {
      calculatedState = CompetitionState.currentlyAssigned;
      message = "This is your current active competition.";
    } else if (isActive) {
      calculatedState = CompetitionState.notAssigned;
      message = "You can set this competition as current to start it.";
    } else {
      return const SizedBox.shrink();
    }

    Color bannerColor = AppColors.primary;
    IconData bannerIcon = Icons.info_outline;

    switch (calculatedState) {
      case CompetitionState.inProgress:
        bannerColor = Colors.green.shade700;
        bannerIcon = Icons.directions_run;
        break;
      case CompetitionState.finished:
        bannerColor = Colors.grey.shade600;
        bannerIcon = Icons.check_circle_outline;
        break;
      case CompetitionState.currentlyAssigned:
        bannerColor = Colors.blue.shade700;
        bannerIcon = Icons.flag;
        break;
      case CompetitionState.notAssigned: // lub canStart
      case CompetitionState.canStart:
        bannerColor = AppColors.primary;
        bannerIcon = Icons.flag_outlined;
        break;
    }

    return Card(
      color: Colors.transparent,
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

          if (calculatedState != CompetitionState.finished &&
              calculatedState != CompetitionState.inProgress)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildActionButtons(calculatedState),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CompetitionState state) {
    if (state == CompetitionState.currentlyAssigned) {
      return CustomButton(
        text: "Clear current competition",
        onPressed: _clearCurrentCompetition,
        backgroundColor: Colors.grey,
      );
    } else if (state == CompetitionState.notAssigned || state == CompetitionState.canStart) {
      return CustomButton(
        text: "Set as current competition",
        onPressed: _setAsCurrentCompetition,
        backgroundColor: AppColors.green,
      );
    }

    return const SizedBox.shrink();
  }
}

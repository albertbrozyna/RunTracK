import 'package:flutter/material.dart';
import 'package:run_track/app/navigation/app_routes.dart';
import 'package:run_track/app/theme/ui_constants.dart';
import 'package:run_track/core/enums/competition_role.dart';

import '../../../../app/config/app_data.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../competitions/data/services/competition_service.dart';

class CurrentCompetitionBanner extends StatefulWidget {
  final bool canCheckDetails;

  const CurrentCompetitionBanner({super.key,required this.canCheckDetails});

  @override
  State<CurrentCompetitionBanner> createState() => _CurrentCompetitionBannerState();
}

class _CurrentCompetitionBannerState extends State<CurrentCompetitionBanner> {


  @override
  void initState() {
    super.initState();
    fetchCurrentCompetition();
  }

  void fetchCurrentCompetition() async{
    if((AppData.instance.currentUser?.currentCompetition.isNotEmpty ?? false) && AppData.instance.currentUserCompetition == null){
      AppData.instance.currentUserCompetition = await CompetitionService.fetchCompetition(AppData.instance.currentUser!.currentCompetition);
      if(AppData.instance.currentUserCompetition != null){
        setState(() {

        });
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    if ((AppData.instance.currentUser?.currentCompetition.isNotEmpty ?? false) && AppData.instance.currentUserCompetition != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(color: AppColors.primary),
        child: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.yellow[600], size: 32),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You are currently participating in:",
                    style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        AppData.instance.currentUserCompetition!.name,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(width: AppUiConstants.horizontalSpacingTextFields,),

                      Visibility(
                        visible: widget.canCheckDetails,
                        child: ElevatedButton(onPressed: (){
                          Navigator.of(context).pushNamed(AppRoutes.competitionDetails,arguments: {
                            "competitionData": AppData.instance.currentUserCompetition,
                            "initTab": 3,
                            "enterContext": CompetitionContext.participant
                          });
                        },
                          style: ButtonStyle(
                            padding: WidgetStatePropertyAll(EdgeInsets.all(2.0))
                          ),
                        child: Text("View details",style: TextStyle(
                          fontSize: 15
                        ),),),
                      ),
                    ],
                  ),
                  Text(
                    "Distance to go: ${AppData.instance.currentUserCompetition!.distanceToGo}",
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    else{
      return Container();
    }
  }
}

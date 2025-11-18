import 'package:flutter/material.dart';

import '../../../../app/config/app_data.dart';
import '../../../../app/theme/app_colors.dart';

class CurrentCompetitionBanner extends StatefulWidget {
  const CurrentCompetitionBanner({super.key});

  @override
  State<CurrentCompetitionBanner> createState() => _CurrentCompetitionBannerState();
}

class _CurrentCompetitionBannerState extends State<CurrentCompetitionBanner> {


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
                  Text(
                    AppData.instance.currentUserCompetition!.name,
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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

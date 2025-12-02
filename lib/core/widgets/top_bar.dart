import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/navigation/app_routes.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool shouldHideButtons;
  final int selectedIndex;

  const TopBar({super.key, this.title = "", this.shouldHideButtons = false,required this.selectedIndex});

  void handleUserStats(BuildContext context){
    Navigator.of(context).pushNamed(AppRoutes.userStats,arguments: {
      'uid': FirebaseAuth.instance.currentUser?.uid ?? ""
    });
  }

  void handleCompetitionMapIcon(BuildContext context){
    Navigator.of(context).pushNamed(AppRoutes.competitionMap);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leadingWidth: 100,

      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if(selectedIndex == 1)
            IconButton(
              onPressed: () => handleUserStats(context),
              icon: Icon(Icons.stacked_line_chart_sharp),
            ),

          if(selectedIndex == 2)
            IconButton(
              onPressed: () => handleCompetitionMapIcon(context),
              icon: Icon(Icons.map_outlined),
            ),
        ],
      ),
      actions: [
        Visibility(
          visible:!shouldHideButtons,
          child:
        IconButton(
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.notifications);
          },
          icon: Icon(Icons.notifications, color: Colors.white),
        ),
        )
      ],
    );
  }

  @override
  // Default height 56.0
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

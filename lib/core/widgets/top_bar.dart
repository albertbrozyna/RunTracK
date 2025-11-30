import 'package:flutter/material.dart';

import '../../app/navigation/app_routes.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool shouldHideButtons;
  final int selectedIndex;

  const TopBar({super.key, this.title = "", this.shouldHideButtons = false,required this.selectedIndex});


  void handleFilterIcon(BuildContext context){
    if(selectedIndex == 1){ // Filters for activities

    }else if(selectedIndex == 2){ // For competitions

    }

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
          if(selectedIndex == 1 || selectedIndex == 2)
            IconButton(
              onPressed: () => handleFilterIcon(context),
              icon: Icon(Icons.filter_alt),
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

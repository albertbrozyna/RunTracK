import 'package:flutter/material.dart';

import '../../app/navigation/app_routes.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool shouldHideButtons;
  final int selectedIndex;

  const TopBar({super.key, this.title = "", this.shouldHideButtons = false,required this.selectedIndex});


  void handleFilterIcon(){

  }

  void handleCompetitionMapIcon(){

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
              onPressed: handleFilterIcon,
              icon: Icon(Icons.filter_alt),
            ),
          if(selectedIndex == 2)
            IconButton(
              onPressed: handleCompetitionMapIcon,
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

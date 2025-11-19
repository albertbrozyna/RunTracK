import 'package:flutter/material.dart';
import 'package:run_track/app/test_data.dart';

import '../../app/navigation/app_routes.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool shouldHideButtons;

  const TopBar({super.key, this.title = "", this.shouldHideButtons = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: IconButton(onPressed: (){
        generate100CompetitionRecords("t0YW98Ax8TRwrWntSLa0");
      }, icon: Icon(Icons.abc)),
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

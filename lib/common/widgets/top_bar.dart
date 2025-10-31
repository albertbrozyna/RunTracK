import 'package:flutter/material.dart';

import '../../config/routes/app_routes.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const TopBar({super.key, this.title = ""});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.notifications);
          },
          icon: Icon(Icons.notifications, color: Colors.white),
        ),
      ],
    );
  }

  @override
  // Default height 56.0
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

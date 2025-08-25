import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;

  const TopBar({
    this.title = "",
    required this.backgroundColor,
  });

  void handleMenuButton(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      centerTitle: true,
      title: Text(title),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
    );
  }

  @override
  // Default height 56.0
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

import 'package:flutter/material.dart';

import '../../../theme/colors.dart';

class AppSettingsTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData iconData;
  final Widget trailing;

  const AppSettingsTile({super.key, required this.title, required this.description, required this.iconData, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(iconData, color: AppColors.gray),
      title: Text(title, style: TextStyle(color: Colors.white)),
      subtitle: Text(description, style: TextStyle(color: Colors.grey)),
      trailing: trailing,
    );
  }
}
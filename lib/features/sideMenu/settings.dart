import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:run_track/theme/colors.dart';
import 'package:run_track/theme/ui_constants.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SettingsPageState();
  }
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(AppUiConstants.scaffoldBodyPadding),
          child: SingleChildScrollView(child: Column()),
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:run_track/theme/app_colors.dart';
import 'package:run_track/theme/ui_constants.dart';

class Section extends StatelessWidget {
  final List<Widget> children;
  final String title;

  const Section({required this.children, required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp), color: AppColors.section),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, color: AppColors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppUiConstants.verticalSpacingTextFields),

                Column(children: children),
              ],
            ),
          ),
        ),
        SizedBox(height: AppUiConstants.verticalSpacingTextFields),
      ],
    );
  }
}

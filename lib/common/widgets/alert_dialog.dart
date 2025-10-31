import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/ui_constants.dart';

/// Custom alert dialog
class AppAlertDialog extends StatelessWidget {
  final void Function()? onPressedLeft;
  final void Function()? onPressedRight;
  final String titleText;
  final String contentText;
  final String textLeft;
  final String textRight;
  final Color colorButtonForegroundLeft;
  final Color colorButtonForegroundRight;
  final Color colorBackgroundButtonRight;
  final Color colorBackgroundButtonLeft;

  const AppAlertDialog({
    required this.titleText,
    required this.contentText,
    required this.textLeft,
    required this.textRight,
    required this.onPressedLeft,
    required this.onPressedRight,
    this.colorButtonForegroundLeft = Colors.black,
    this.colorButtonForegroundRight = AppColors.primary,
    this.colorBackgroundButtonRight = Colors.transparent,
    this.colorBackgroundButtonLeft = Colors.transparent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.alertDialogColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp)),
      title: Text(
        titleText,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: AppUiConstants.textSizeApp,fontWeight: FontWeight.w700),
      ),
      content: Text(
        contentText,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: AppUiConstants.textSizeApp),
      ),
      alignment: Alignment.center,
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorButtonForegroundLeft,
                  backgroundColor: colorBackgroundButtonLeft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
                    side: BorderSide(color: Colors.white24),
                  ),
                ),
                onPressed: onPressedLeft,
                child: Text(
                  textLeft,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: AppUiConstants.textSizeApp),
                ),
              ),
            ),

            SizedBox(width: AppUiConstants.horizontalSpacingButtons),
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorButtonForegroundRight,
                  backgroundColor: colorBackgroundButtonRight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
                    side: BorderSide(color: Colors.white24),
                  ),
                ),
                onPressed: onPressedRight,
                child: Text(
                  textRight,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: AppUiConstants.textSizeApp),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

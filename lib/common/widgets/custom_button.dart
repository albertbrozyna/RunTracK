import 'package:flutter/material.dart';
import 'package:run_track/theme/app_colors.dart';

import '../../theme/ui_constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final double textSize;
  final double width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textSize = AppUiConstants.textSizeApp,
    this.borderRadius = AppUiConstants.borderRadiusButtons,
    this.backgroundColor = AppColors.secondary,
    this.textColor = AppColors.textPrimary,
    this.width = double.infinity,
    this.height = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(backgroundColor),
          foregroundColor: WidgetStateProperty.all(textColor),
          elevation: WidgetStateProperty.all(0),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: textSize),
        ),
      ),
    );
  }
}

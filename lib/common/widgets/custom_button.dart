import 'package:flutter/material.dart';
import 'package:run_track/theme/colors.dart';

import '../../theme/ui_constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final double textSize;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textSize = AppUiConstants.textSize,
    this.borderRadius = AppUiConstants.borderRadiusButtons,
    this.backgroundColor = AppColors.secondary,
    this.textColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white24,
          width: 1.0,
        ),
      ),
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

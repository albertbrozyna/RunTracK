import 'package:flutter/material.dart';
import 'package:run_track/theme/colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final List<Color> gradientColors;
  final Color textColor;
  final double borderRadius;
  final double textSize;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.textSize = 16.0,
    this.borderRadius = 8.0,
    this.backgroundColor = AppColors.primary,
    this.gradientColors = const [Colors.white30, Colors.transparent],
    this.textColor = AppColors.textPrimary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,

          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor,fontSize: textSize),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

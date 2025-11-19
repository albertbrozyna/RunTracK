import 'package:flutter/material.dart';

class AppColors {
  AppColors._();


  // Primary app UI colors
  static const Color primary = Color(0xFF678FE3);
  static const Color secondary = Color(0xFF5374C8);
  static const Color third = Color(0xFF4BB8DF);
  static const Color gray = Color(0xFF9E9E9E);
  static const Color green =  Colors.green;
  static const Color danger = Color(0xFFC13D34);
  static const Color warning = Color(0xFFF2FA3A);
  static const Color background = Color(0xFFF2F2F7);
  static const Color textPrimary = Color(0xFFF2F2F7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color pageHeaderColor = AppColors.primary; // Page header color

  static Color section = Colors.black.withAlpha(40);

  // Primary app text colors
  static Color textPrimaryColor = Colors.white;


  // Form
  static Color formBackgroundOverlay = Colors.white.withValues( alpha:  0.4);

  // TextFields
  static Color textFieldsBackground = Colors.black.withValues( alpha:  0.5);
  static Color textFieldsBorder = Colors.white24;
  static Color textFieldsLabel = Colors.white;
  static Color textFieldsText = Colors.white;
  static Color textFieldsHints = Colors.white24;

  // Buttons
  // Stat cards
  static Color statCardBackground = Colors.white.withValues( alpha:  0.9);

  // Dropdown entries
  static Color dropdownEntryBackground = Colors.white.withValues( alpha:  0.9);

  // Dropdown menu

  // Blocks competition / activity
  static Color blockColor = Colors.white;


  // Alert dialogs
  static Color alertDialogColor = Colors.white;


  // Scaffold messenger colors
  static Color scaffoldMessengerInfoColor = AppColors.primary;
  static Color scaffoldMessengerErrorColor = AppColors.danger;
  static Color scaffoldMessengerSuccessColor = AppColors.green;
  static Color scaffoldMessengerWarningColor = AppColors.warning;



}

import 'package:flutter/material.dart';
import 'package:run_track/app/theme/ui_constants.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light),
      scaffoldBackgroundColor: AppColors.white,
      // App font
      fontFamily: "sans-serif",
      textTheme: TextTheme(
        bodySmall: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 16),
        bodyLarge: TextStyle(fontSize: 16),
        headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
          borderSide: BorderSide(color: Colors.white24),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
          borderSide: BorderSide(color: AppColors.white),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
          borderSide: BorderSide(color: AppColors.danger),
        ),

        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return Colors.white24;
          if (states.contains(WidgetState.focused)) return Colors.white;
          return Colors.white;
        }),
        suffixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return Colors.white24;
          if (states.contains(WidgetState.focused)) return Colors.white;
          return Colors.white;
        }),

        labelStyle: TextStyle(fontSize: 16,color: AppColors.white),
        hintStyle: TextStyle(fontSize: 16,color: Colors.white24),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
            borderSide: BorderSide(color: Colors.white24),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
            borderSide: BorderSide(color: Colors.redAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
            borderSide: BorderSide(color: AppColors.white),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
            borderSide: BorderSide(color: AppColors.danger),
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
            borderSide: BorderSide(color: Colors.white24),
          ),
        ),
        textStyle: TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.primary),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
            ),
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppUiConstants.borderRadiusApp),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),




    );


  }
}

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppUiConstants {
  static const double scaffoldBodyPadding = 16.0;
  static const double paddingTextFields = 8.0;

  // ALL APP
  // -----------------------------------------------------------------
  static const double textSizeApp = 16.0;  // Text size of the all app
  static const double textSizeTitlesApp = 20.0;  // Text size of the all app
  static const double borderRadiusApp = 8.0;
  static const double iconSizeApp = 24.0;


  // Text fields
  // -----------------------------------------------------------------
  // Borders
  static const BorderRadius borderRadiusTextFields = BorderRadius.all(
    Radius.circular(8.0),
  );
  static const EdgeInsets contentPaddingTextFields = EdgeInsets.symmetric(
    vertical: 16,
    horizontal: 16,
  );
  static const OutlineInputBorder borderTextFields = OutlineInputBorder(
      borderRadius: AppUiConstants.borderRadiusTextFields,
      borderSide: BorderSide(
          color: Colors.white70,
          width: 1
      )
  );
  static const OutlineInputBorder focusedBorderTextFields = OutlineInputBorder(
      borderRadius: AppUiConstants.borderRadiusTextFields,
      borderSide: BorderSide(
          color: Colors.white24,
          width: 1
      )
  );

  static const OutlineInputBorder enabledBorderTextFields = OutlineInputBorder(
      borderRadius: AppUiConstants.borderRadiusTextFields,
      borderSide: BorderSide(
          color: Colors.white70,
          width: 1
      )
  );
  static const OutlineInputBorder errorBorderTextFields = OutlineInputBorder(
      borderRadius: AppUiConstants.borderRadiusTextFields,
      borderSide: BorderSide(
          color: Colors.red,
          width: 1
      )
  );
  static const OutlineInputBorder focusedErrorBorderTextFields = OutlineInputBorder(
      borderRadius: AppUiConstants.borderRadiusTextFields,
      borderSide: BorderSide(
          color: Colors.red,
          width: 1
      )
  );

  // Text styles
  static TextStyle labelStyleTextFields = TextStyle(
    color: AppColors.textFieldsLabel,
    fontSize: 18,
  );

  static TextStyle textStyleTextFields = TextStyle(
    color: AppColors.textFieldsText,
    fontSize: 18,
  );


  // Spacing
  static const horizontalSpacingTextFields = 8.0;
  static const verticalSpacingTextFields = 8.0;

  // Box shadow
  static const BoxShadow boxShadowTextFields =    BoxShadow(
    color: Colors.black26, // Shadow color
    blurRadius: 10, // How blurry the shadow is
    offset: Offset(0, 4), // Position of the shadow
  );


  // Buttons
  // -----------------------------------------------------------------
  static const double horizontalSpacingButtons = 16.0;
  static const double verticalSpacingButtons = 16.0;
  static const double borderRadiusButtons = 8.0;







  // Forms by form i understand a Container with Column a text fields
  static const EdgeInsets paddingOutsideForm = EdgeInsets.all(16.0);
  static const EdgeInsets paddingInsideForm = EdgeInsets.all(16.0);

  static const BorderRadius borderRadiusForm = BorderRadius.all(
    Radius.circular(12.0),
  );

  static const List<BoxShadow> boxShadowForm = [
    BoxShadow(
      color: Colors.black26, // Shadow color
      blurRadius: 10, // How blurry the shadow is
      offset: Offset(0, 4), // Position of the shadow
    ),
  ];

  static final BoxBorder boxBorder = Border.all(
      color: Colors.white70,
      width: 1,
  );

  // Pages with block Competitions or
  static const pageBlockInsideContentPadding = 12.0;
  static const pageBlockSpacingBetweenElements = 12.0;

  // Blocks with activities and competitions
  // -----------------------------------------------------------------
  static BoxDecoration decorationBlock = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadiusApp),
      border: Border.all(color: Colors.white24, width: 1, style: BorderStyle.solid),
  );

  static const blockInsideContentPadding = 8.0;


  // Exit forms, i mean alert dialog by this
  // -----------------------------------------------------------------
  static const double alertDialogBorderRadius = borderRadiusApp;

  // Flutter map
  static const double flutterMapInnerPaddingRectangleBounds = 40;
}

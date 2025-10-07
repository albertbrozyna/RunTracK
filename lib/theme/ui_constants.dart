import 'package:flutter/material.dart';

class AppUiConstants {
  static const double scaffoldBodyPadding = 16.0;
  static const double borderRadiusButtons = 8.0;
  static const double paddingTextFields = 8.0;



  // Text fields
  static const BorderRadius borderRadiusTextFields = BorderRadius.all(
    Radius.circular(12.0),
  );
  static const EdgeInsets contentPaddingTextFields = EdgeInsets.symmetric(
    vertical: 16,
    horizontal: 16,
  );

  static const horizontalSpacingTextFields = 8.0;
  static const verticalSpacingTextFields = 8.0;

  static const BoxShadow boxShadowTextFields =    BoxShadow(
    color: Colors.black26, // Shadow color
    blurRadius: 10, // How blurry the shadow is
    offset: Offset(0, 4), // Position of the shadow
  );

  // Buttons

  static const double horizontalSpacingButtons = 16.0;
  static const double verticalSpacingButtons = 16.0;


  static const OutlineInputBorder focusedBorderTextfields = OutlineInputBorder(
    borderRadius: AppUiConstants.borderRadiusTextFields,
      borderSide: BorderSide(
          color: Colors.white24,
          width: 1
      )
  );

  static const OutlineInputBorder enabledBorderTextfields = OutlineInputBorder(
    borderRadius: AppUiConstants.borderRadiusTextFields,
    borderSide: BorderSide(
      color: Colors.white70,
      width: 1
    )
  );
  static const OutlineInputBorder errorBorderTextfields = OutlineInputBorder(
      borderRadius: AppUiConstants.borderRadiusTextFields,
      borderSide: BorderSide(
          color: Colors.red,
          width: 1
      )
  );

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

}

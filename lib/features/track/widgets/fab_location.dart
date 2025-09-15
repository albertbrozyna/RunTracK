import 'package:flutter/material.dart';

class CustomFabLocation extends FloatingActionButtonLocation {
  final double xOffset;
  final double yOffset;

  const CustomFabLocation({required this.xOffset, required this.yOffset});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Bottom-right calculation
    final double fabX = scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width - xOffset;
    final double fabY = scaffoldGeometry.scaffoldSize.height - scaffoldGeometry.floatingActionButtonSize.height - yOffset;
    return Offset(fabX, fabY);
  }
}

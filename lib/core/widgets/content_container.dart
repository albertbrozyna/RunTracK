import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/ui_constants.dart';


class ContentContainer extends StatelessWidget {
  final Widget? child;
  final double padding;
  final Color backgroundColor;
  final double borderRadius;
  final double width;

  const ContentContainer({super.key, this.child, this.padding = 10,this.backgroundColor = AppColors.primary,this.borderRadius = AppUiConstants.borderRadiusApp,this.width = double.infinity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    );
  }
}

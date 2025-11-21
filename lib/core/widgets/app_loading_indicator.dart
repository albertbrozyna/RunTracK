import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double? strokeWidth;
  final double? size;
  final String? message;
  final TextStyle? messageStyle;
  final EdgeInsetsGeometry? padding;
  final Color indicatorColor;

  const AppLoadingIndicator({
    super.key,
    this.color,
    this.strokeWidth,
    this.size,
    this.message,
    this.messageStyle,
    this.padding,
    this.indicatorColor =  AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size ?? 20,
              height: size ?? 20,
              child: CircularProgressIndicator(
                color: indicatorColor,
                strokeWidth:strokeWidth,
              ),
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: messageStyle ?? TextStyle(
                  color: AppColors.white
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
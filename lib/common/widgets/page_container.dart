import 'package:flutter/material.dart';

import '../../theme/colors.dart';

class PageContainer extends StatelessWidget {
  final Widget? child;
  final String? assetPath;
  final Color? backgroundColor;
  final double padding;

  const PageContainer({super.key, this.child, this.assetPath, this.padding = 10,this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor != null ? backgroundColor : Colors.transparent,
        image: assetPath == null
            ? null
            : DecorationImage(
                image: AssetImage(assetPath!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.50), BlendMode.darken),
              ),
      ),
      height: double.infinity,
      width: double.infinity,
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    );
  }
}

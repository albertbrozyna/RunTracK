import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Icon icon;
  final double valueFontSize;
  final double titleFontSize;
  final double innerPadding;
  final double? cardWidth;
  final double cardHeight;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.valueFontSize = 18,
    this.titleFontSize = 14,
    this.innerPadding = 12,
    this.cardWidth,
    this.cardHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cardWidth,
      height: cardHeight,
      padding: EdgeInsets.all(innerPadding),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: titleFontSize, color: Colors.grey),
              ),
              SizedBox(height: 4),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

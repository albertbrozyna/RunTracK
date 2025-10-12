import 'package:flutter/material.dart';

import '../../../theme/colors.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Icon icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120, // fixed width for uniformity
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statCardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          icon,
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: Colors.grey)),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

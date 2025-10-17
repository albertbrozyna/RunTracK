import 'package:flutter/material.dart';

import '../../theme/colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.gray,
      backgroundColor: Colors.white,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.timer_outlined), label: "Track activity"),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          label: "Activities",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_run_outlined),
          label: "Competitions",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: "My profile",
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

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
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        // TODO Icons here
        BottomNavigationBarItem(icon: Icon(Icons.timer_outlined), label: "Track activity"),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          label: "Activities",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_run_outlined),
          label: "Competitions",
        ),
      ],
    );
  }
}

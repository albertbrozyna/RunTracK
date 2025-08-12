import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        // TODO Icons here
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time),
          label: "Home"
        ),
        BottomNavigationBarItem(
            icon: Icon(Icons.ac_unit_sharp),
            label: "History"
        ),
        BottomNavigationBarItem(
            icon: Icon(Icons.accessibility_rounded),
            label: "races"
        ),
      ],
    );
  }
}

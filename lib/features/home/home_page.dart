import 'package:flutter/material.dart';
import 'package:run_track/common/utils/firestore_utils.dart';
import 'package:run_track/features/competitions/pages/competition_page.dart';
import 'package:run_track/features/track/pages/track_screen.dart';

import '../../common/widgets/navigation_bar.dart';
import '../../common/widgets/side_menu.dart';
import '../../common/widgets/top_bar.dart';
import '../../theme/colors.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // TODO To learn
  late List<Widget> _pages;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  void initState() {
    super.initState();
    fetchCurrentUserAndSave();
  }

  @override
  Widget build(BuildContext context) {
    _pages = [
      TrackScreen(),
      Center(child: Text('Search Page')),
      Competitions()
    ];
    return Scaffold(
      drawer: SideMenu(),
      appBar: TopBar(backgroundColor: AppColors.secondary),
      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:run_track/common/utils/utils.dart';
import 'package:run_track/features/activities/widgets/activity_block.dart';
import 'package:run_track/features/track/widgets/fab_location.dart';
import 'package:run_track/models/competition.dart';
import 'package:run_track/services/activity_service.dart';
import 'package:run_track/services/competition_service.dart';
import 'package:run_track/theme/colors.dart';

import '../../../common/enums/competition_role.dart';
import '../../../common/utils/app_data.dart';
import '../../../models/activity.dart';
import '../../../models/user.dart';
import '../../../services/user_service.dart';
import '../widgets/competition_block.dart';
import 'compeption_add.dart';

class CompetitionsPage extends StatefulWidget {
  @override
  _CompetitionsState createState() => _CompetitionsState();
}

class _CompetitionsState extends State<CompetitionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? currentUser = AppData.currentUser;


  final List<Competition> _myCompetitions = [];
  final List<Competition> _friendsCompetitions = [];
  final List<Competition> _allCompetitions = [];

  final ScrollController _scrollControllerMy = ScrollController();
  final ScrollController _scrollControllerFriends = ScrollController();
  final ScrollController _scrollControllerAll = ScrollController();

  // Loading state for every page
  bool _isLoadingMy = false;
  bool _isLoadingFriends = false;
  bool _isLoadingAll = false;

  // If there are more pages
  bool _hasMoreMy = true;
  bool _hasMoreFriends = true;
  bool _hasMoreAll = true;

  DocumentSnapshot? _lastPageMyCompetitions;
  DocumentSnapshot? _lastPageFriendsCompetitions;
  DocumentSnapshot? _lastPageAllCompetitions;

  final int _limit = 10; // Competitions per page


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    initialize();
  }

  Future<void> initialize()  async{
    if (!UserService.isUserLoggedIn()) {
      UserService.signOutUser();
      Navigator.of(context).pushNamedAndRemoveUntil('/start', (route) => false);
    }

    CompetitionService.lastFetchedDocumentMyCompetitions = null;
    CompetitionService.lastFetchedDocumentFriendsCompetitions = null;
    CompetitionService.lastFetchedDocumentAllCompetitions = null;

    _loadMyCompetitions();
    _loadFriendsCompetitions();
    _loadAllCompetitions();

    // Listeners for scroll controller to load more activities
    _scrollControllerMy.addListener(() {
      if (_scrollControllerMy.position.pixels >= _scrollControllerMy.position.maxScrollExtent - 200) {
        _loadMyCompetitions();
      }
    });

    _scrollControllerFriends.addListener(() {
      if (_scrollControllerFriends.position.pixels >= _scrollControllerFriends.position.maxScrollExtent - 200) {
        _loadFriendsCompetitions();
      }
    });

    _scrollControllerAll.addListener(() {
      if (_scrollControllerAll.position.pixels >= _scrollControllerAll.position.maxScrollExtent - 200) {
        _loadAllCompetitions();
      }
    });

  }

  Future<void> initializeAsync() async {}

  /// Load my activities
  Future<void> _loadMyCompetitions() async {
    if (_isLoadingMy == true || _hasMoreMy == false) {
      return;
    }
    setState(() {
      _isLoadingMy = true;
    });

    final competitions = await CompetitionService.fetchMyLatestCompetitionsPage(
      FirebaseAuth.instance.currentUser?.uid ?? "",
      _limit,
      _lastPageMyCompetitions,
    );

    setState(() {
      _myCompetitions.addAll(competitions);
      _lastPageMyCompetitions = competitions.isNotEmpty ? CompetitionService.lastFetchedDocumentMyCompetitions : null;
      _isLoadingMy = false;
      if (competitions.length < _limit) {
        _hasMoreMy = false;
      }
    });
  }

  Future<void> _loadFriendsCompetitions() async {
    if (_isLoadingFriends || !_hasMoreFriends) {
      return;
    }
    setState(() {
      _isLoadingFriends = true;
    });

    final competitions = await CompetitionService.fetchLastFriendsCompetitionsPage(
      _limit,
      _lastPageFriendsCompetitions,
      currentUser?.friendsUid ?? [],
    );


    setState(() {
      if (competitions.isEmpty) {
        _hasMoreFriends = false;
      } else {
        _friendsCompetitions.addAll(competitions);
        _lastPageFriendsCompetitions =CompetitionService.lastFetchedDocumentFriendsCompetitions;
        if (competitions.length < _limit) {
          _hasMoreFriends = false;
        }
      }
      _isLoadingFriends = false;
    });
  }

  Future<void> _loadAllCompetitions() async {
    if (_isLoadingAll == true|| _hasMoreAll == false) {
      return;
    }
    setState(() {
      _isLoadingAll = true;
    });

    final competitions = await CompetitionService.fetchLatestCompetitionsPage(_limit, _lastPageAllCompetitions);

    setState(() {
      _allCompetitions.addAll(competitions);
      _lastPageAllCompetitions = competitions.isNotEmpty ? CompetitionService.lastFetchedDocumentAllCompetitions : null;
      _isLoadingAll = false;
      if (competitions.length < _limit) {
        _hasMoreAll = false;
      }
    });
  }

  /// On pressed add competition button
  void onPressedAddCompetition(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddCompetition(role: CompetitionRole.owner,)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: CustomFabLocation(xOffset: 20,yOffset: 70),
      floatingActionButton: FloatingActionButton(
        onPressed: () => onPressedAddCompetition(context),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: Icon(Icons.add_card, color: Colors.white),
      ),
      backgroundColor: AppColors.primary,

      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background-start.jpg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.25),
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: AppColors.primary),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withAlpha(100),
                labelStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  backgroundColor: AppColors.primary,
                ),
                tabs: [
                  Tab(text: "My"),
                  Tab(text: "Friends"),
                  Tab(text: "All"),
                  Tab(text: "Invites"),
                  Tab(text: "Participating")
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 10),
                    child: _myCompetitions.isEmpty ? Center(child: Text("No competitions found")) : ListView.builder(
                      controller: _scrollControllerMy,
                      itemCount: _myCompetitions.length + (_hasMoreMy ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _myCompetitions.length) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final competition = _myCompetitions[index];
                        return CompetitionBlock(
                          key: ValueKey(competition.competitionId),
                          firstName: currentUser!.firstName,
                          lastName: currentUser!.lastName,
                          competition:  competition,
                        );
                      },
                    ),
                  ),
                  // Friends
                  Container(
                    padding: EdgeInsets.only(top: 10),
                    child: _friendsCompetitions.isEmpty ? Center(child: Text("No competitions found")) : ListView.builder(
                      controller: _scrollControllerFriends,
                      itemCount: _friendsCompetitions.length + (_hasMoreFriends ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _friendsCompetitions.length) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final competition = _friendsCompetitions[index];
                        return CompetitionBlock(key: ValueKey(competition.competitionId), competition: competition);
                      },
                    ),
                  ),
                  // All last activities
                  Container(
                    padding: EdgeInsets.only(top: 10),
                    child: _allCompetitions.isEmpty ? Center(child: Text("No activities found")) : ListView.builder(
                      controller: _scrollControllerAll,
                      itemCount: _allCompetitions.length + (_hasMoreAll ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _allCompetitions.length) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final competition = _allCompetitions[index];
                        return CompetitionBlock(key: ValueKey(competition.competitionId), firstName: "", lastName: "", competition: competition);
                      },
                    ),
                  ),

                  // Invites
                  Container(
                    padding: EdgeInsets.only(top: 10),
                    child: _allCompetitions.isEmpty ? Center(child: Text("No activities found")) : ListView.builder(
                      controller: _scrollControllerAll,
                      itemCount: _allCompetitions.length + (_hasMoreAll ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _allCompetitions.length) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final competition = _allCompetitions[index];
                        return CompetitionBlock(key: ValueKey(competition.competitionId), firstName: "", lastName: "", competition: competition);
                      },
                    ),
                  ),

                  // Participating currently
                  Container(
                    padding: EdgeInsets.only(top: 10),
                    child: _allCompetitions.isEmpty ? Center(child: Text("No activities found")) : ListView.builder(
                      controller: _scrollControllerAll,
                      itemCount: _allCompetitions.length + (_hasMoreAll ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _allCompetitions.length) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final competition = _allCompetitions[index];
                        return CompetitionBlock(key: ValueKey(competition.competitionId), firstName: "", lastName: "", competition: competition);
                      },
                    ),
                  ),


                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

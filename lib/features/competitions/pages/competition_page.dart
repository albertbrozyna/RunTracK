import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:run_track/common/widgets/page_container.dart';
import 'package:run_track/config/routes/app_routes.dart';
import 'package:run_track/features/track/widgets/fab_location.dart';
import 'package:run_track/models/competition.dart';
import 'package:run_track/services/competition_service.dart';
import 'package:run_track/theme/app_colors.dart';
import 'package:run_track/theme/ui_constants.dart';

import '../../../common/enums/competition_role.dart';
import '../../../common/utils/app_data.dart';
import '../../../config/assets/app_images.dart';
import '../../../models/user.dart';
import '../../../services/user_service.dart';
import '../widgets/competition_block.dart';
import '../../../common/widgets/no_items_msg.dart';

class CompetitionsPage extends StatefulWidget {
  const CompetitionsPage({super.key});

  @override
  State<CompetitionsPage> createState() => _CompetitionsPageState();
}

class _CompetitionsPageState extends State<CompetitionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? currentUser = AppData.currentUser;

  final List<Competition> _myCompetitions = [];
  final List<Competition> _friendsCompetitions = [];
  final List<Competition> _allCompetitions = [];
  final List<Competition> _invitedCompetitions = [];
  final List<Competition> _participatedCompetitions = [];

  final ScrollController _scrollControllerMy = ScrollController();
  final ScrollController _scrollControllerFriends = ScrollController();
  final ScrollController _scrollControllerAll = ScrollController();
  final ScrollController _scrollControllerInvites = ScrollController();
  final ScrollController _scrollControllerParticipated = ScrollController();

  // Loading state for every page
  bool _isLoadingMy = false;
  bool _isLoadingFriends = false;
  bool _isLoadingAll = false;
  bool _isLoadingInvites = false;
  bool _isLoadingParticipating = false;

  // If there are more pages
  bool _hasMoreMy = true;
  bool _hasMoreFriends = true;
  bool _hasMoreAll = true;
  bool _hasMoreInvites = true;
  bool _hasMoreParticipating = true;

  DocumentSnapshot? _lastPageMyCompetitions;
  DocumentSnapshot? _lastPageFriendsCompetitions;
  DocumentSnapshot? _lastPageAllCompetitions;
  DocumentSnapshot? _lastPageInvites;
  DocumentSnapshot? _lastPageParticipating;

  final int _limit = 10; // Competitions per page

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    initialize();
  }

  Future<void> initialize() async {
    UserService.checkAppUseState(context);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    // Load my competitions at start
    _loadMyCompetitions();
    _loadFriendsCompetitions();
    _loadAllCompetitions();
    _loadMyInvitedCompetitions();
    _loadMyParticipatedCompetitions();

    // Listeners for scroll controller to load more competitions
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

    _scrollControllerInvites.addListener(() {
      if (_scrollControllerInvites.position.pixels >= _scrollControllerInvites.position.maxScrollExtent - 200) {
        _loadMyInvitedCompetitions();
      }
    });

    _scrollControllerParticipated.addListener(() {
      if (_scrollControllerParticipated.position.pixels >= _scrollControllerParticipated.position.maxScrollExtent - 200) {
        _loadMyParticipatedCompetitions();
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

    final competitionFetchResult = await CompetitionService.fetchMyLatestCompetitionsPage(
      FirebaseAuth.instance.currentUser?.uid ?? "",
      _limit,
      _lastPageMyCompetitions,
    );

    setState(() {
      _myCompetitions.addAll(competitionFetchResult.competitions);
      _lastPageMyCompetitions = competitionFetchResult.lastDocument;
      _isLoadingMy = false;
      if (competitionFetchResult.competitions.length < _limit) {
        _hasMoreMy = false;
      }
    });
  }

  /// Load my friends competitions
  Future<void> _loadFriendsCompetitions() async {
    if (_isLoadingFriends || !_hasMoreFriends) {
      return;
    }
    setState(() {
      _isLoadingFriends = true;
    });

    final competitionFetchResult = await CompetitionService.fetchLastFriendsCompetitionsPage(
      _limit,
      _lastPageFriendsCompetitions,
      currentUser?.friendsUid ?? {},
    );

    setState(() {
      _friendsCompetitions.addAll(competitionFetchResult.competitions);
      _lastPageFriendsCompetitions = competitionFetchResult.lastDocument;
      _isLoadingFriends = false;
      if (competitionFetchResult.competitions.length < _limit) {
        _hasMoreFriends = false;
      }
    });
    _isLoadingFriends = false;
  }

  /// Load last competitions from all users
  Future<void> _loadAllCompetitions() async {
    if (_isLoadingAll == true || _hasMoreAll == false) {
      return;
    }
    setState(() {
      _isLoadingAll = true;
    });

    final competitionFetchResult = await CompetitionService.fetchLatestCompetitionsPage(_limit, _lastPageAllCompetitions);

    setState(() {
      _allCompetitions.addAll(competitionFetchResult.competitions);
      _lastPageAllCompetitions = competitionFetchResult.lastDocument;
      _isLoadingAll = false;
      if (competitionFetchResult.competitions.length < _limit) {
        _hasMoreAll = false;
      }
    });
  }

  /// Load competitions which user is invited
  Future<void> _loadMyInvitedCompetitions() async {
    if (_isLoadingInvites == true || _hasMoreInvites == false) {
      return;
    }
    setState(() {
      _isLoadingInvites = true;
    });

    final competitionFetchResult = await CompetitionService.fetchMyInvitedCompetitions(
      AppData.currentUser?.receivedInvitationsToCompetitions ?? {},
      _limit,
      _lastPageInvites,
    );

    setState(() {
      _invitedCompetitions.addAll(competitionFetchResult.competitions);
      _lastPageInvites = competitionFetchResult.lastDocument;
      _isLoadingInvites = false;
      if (competitionFetchResult.competitions.length < _limit) {
        _hasMoreInvites = false;
      }
    });
  }

  /// Load competitions which user is participating
  Future<void> _loadMyParticipatedCompetitions() async {
    if (_isLoadingParticipating == true || _hasMoreParticipating == false) {
      return;
    }
    setState(() {
      _isLoadingParticipating = true;
    });

    final competitionFetchResult = await CompetitionService.fetchMyParticipatedCompetitions(
      AppData.currentUser?.participatedCompetitions ?? {},
      _limit,
      _lastPageParticipating,
    );

    setState(() {
      _participatedCompetitions.addAll(competitionFetchResult.competitions);
      _lastPageParticipating = competitionFetchResult.lastDocument;
      _isLoadingParticipating = false;
      if (competitionFetchResult.competitions.length < _limit) {
        _hasMoreParticipating = false;
      }
    });
  }

  /// On pressed add competition button
  void onPressedAddCompetition(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.competitionDetails,
      arguments: {'enterContext': CompetitionContext.ownerCreate, 'competitionData': null, 'initTab': _tabController.index},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: CustomFabLocation(xOffset: 20, yOffset: 70),
      floatingActionButton: Visibility(
        visible: [0, 1, 2].contains(_tabController.index), // Show add button only for my friends and all
        child: FloatingActionButton(
          onPressed: () => onPressedAddCompetition(context),
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          child: Icon(Icons.add_card, color: Colors.white),
        ),
      ),
      body: PageContainer(
        assetPath: AppImages.appBg4,
        padding: 0,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: AppColors.primary),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withAlpha(100),
                labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, backgroundColor: AppColors.primary),
                tabs: [
                  Tab(text: "My"),
                  Tab(text: "Friends"),
                  Tab(text: "All"),
                  Tab(text: "Invites"),
                  Tab(text: "Participating"),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppUiConstants.pageBlockInsideContentPadding,
                  left: AppUiConstants.pageBlockInsideContentPadding,
                  right: AppUiConstants.pageBlockInsideContentPadding,
                ),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Container(
                      child: _myCompetitions.isEmpty
                          ? NoItemsMsg(textMessage: "No competitions found")
                          : ListView.builder(
                              controller: _scrollControllerMy,
                              itemCount: _myCompetitions.length + (_hasMoreMy ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _myCompetitions.length) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                final competition = _myCompetitions[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppUiConstants.pageBlockSpacingBetweenElements),
                                  child: CompetitionBlock(
                                    key: ValueKey(competition.competitionId),
                                    firstName: currentUser!.firstName,
                                    lastName: currentUser!.lastName,
                                    competition: competition,
                                    initIndex: 0,
                                  ),
                                );
                              },
                            ),
                    ),
                    // Friends
                    Container(
                      padding: EdgeInsets.only(top: 10),
                      child: _friendsCompetitions.isEmpty
                          ? NoItemsMsg(textMessage: "No competitions found")
                          : ListView.builder(
                              controller: _scrollControllerFriends,
                              itemCount: _friendsCompetitions.length + (_hasMoreFriends ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _friendsCompetitions.length) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                final competition = _friendsCompetitions[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppUiConstants.pageBlockSpacingBetweenElements),
                                  child: CompetitionBlock(key: ValueKey(competition.competitionId), competition: competition, initIndex: 1),
                                );
                              },
                            ),
                    ),
                    // All last activities
                    Container(
                      padding: EdgeInsets.only(top: 10),
                      child: _allCompetitions.isEmpty
                          ? NoItemsMsg(textMessage: "No competitions found")
                          : ListView.builder(
                              controller: _scrollControllerAll,
                              itemCount: _allCompetitions.length + (_hasMoreAll ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _allCompetitions.length) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                final competition = _allCompetitions[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppUiConstants.pageBlockSpacingBetweenElements),
                                  child: CompetitionBlock(
                                    key: ValueKey(competition.competitionId),
                                    firstName: "",
                                    lastName: "",
                                    competition: competition,
                                    initIndex: 2,
                                  ),
                                );
                              },
                            ),
                    ),

                    // Invites
                    Container(
                      padding: EdgeInsets.only(top: 10),
                      child: _invitedCompetitions.isEmpty
                          ? NoItemsMsg(textMessage: "No competitions found")
                          : ListView.builder(
                              controller: _scrollControllerInvites,
                              itemCount: _invitedCompetitions.length + (_hasMoreInvites ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _allCompetitions.length) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                final competition = _invitedCompetitions[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppUiConstants.pageBlockSpacingBetweenElements),
                                  child: CompetitionBlock(
                                    key: ValueKey(competition.competitionId),
                                    firstName: "",
                                    lastName: "",
                                    competition: competition,
                                    initIndex: 3,
                                  ),
                                );
                              },
                            ),
                    ),

                    // Participated competitions
                    Container(
                      padding: EdgeInsets.only(top: 10),
                      child: _participatedCompetitions.isEmpty
                          ? NoItemsMsg(textMessage: "No competitions found")
                          : ListView.builder(
                              controller: _scrollControllerParticipated,
                              itemCount: _participatedCompetitions.length + (_hasMoreParticipating ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _participatedCompetitions.length) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                final competition = _allCompetitions[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppUiConstants.pageBlockSpacingBetweenElements),
                                  child: CompetitionBlock(
                                    key: ValueKey(competition.competitionId),
                                    firstName: "",
                                    lastName: "",
                                    competition: competition,
                                    initIndex: 4,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

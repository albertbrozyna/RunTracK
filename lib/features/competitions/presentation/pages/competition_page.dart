import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:run_track/core/widgets/app_loading_indicator.dart';

import '../../../../app/config/app_data.dart';
import '../../../../app/config/app_images.dart';
import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/ui_constants.dart';
import '../../../../core/enums/competition_role.dart';
import '../../data/models/competition.dart';
import '../../../../core/models/user.dart';
import '../../data/services/competition_service.dart';
import '../../../../core/widgets/no_items_msg.dart';
import '../../../../core/widgets/page_container.dart';
import '../../../track/presentation/widgets/fab_location.dart';
import '../widgets/competition_block.dart';

class CompetitionsPage extends StatefulWidget {
  const CompetitionsPage({super.key});

  @override
  State<CompetitionsPage> createState() => _CompetitionsPageState();
}

class _CompetitionsPageState extends State<CompetitionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? currentUser = AppData.instance.currentUser;

  final List<Competition> _myCompetitions = [];
  final List<Competition> _friendsCompetitions = [];
  final List<Competition> _allCompetitions = [];
  final List<Competition> _invitedCompetitions = [];
  final List<Competition> _participatedCompetitions = [];

  List<String> participatedToFetch =
      AppData.instance.currentUser?.participatedCompetitions.toList() ?? [];

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
  int safetyCounter = 0;
  int maxLoops = 5;

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

  bool _isNavigating = false;

  final int _limit = 10; // Competitions per page

  @override
  void dispose() {
    _tabController.dispose();
    _scrollControllerMy.dispose();
    _scrollControllerFriends.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    initialize();
  }

  Future<void> initialize() async {
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(
          () {},
        ); // Do not load all tabs on start, load only when is active
        _loadCurrentTabData(_tabController.index);
      }
    });

    _loadMyCompetitions();

    // Listeners for scroll controller to load more competitions
    _scrollControllerMy.addListener(() {
      if (_scrollControllerMy.position.pixels >=
          _scrollControllerMy.position.maxScrollExtent - 200) {
        _loadMyCompetitions();
      }
    });

    _scrollControllerFriends.addListener(() {
      if (_scrollControllerFriends.position.pixels >=
          _scrollControllerFriends.position.maxScrollExtent - 200) {
        _loadFriendsCompetitions();
      }
    });

    _scrollControllerAll.addListener(() {
      if (_scrollControllerAll.position.pixels >=
          _scrollControllerAll.position.maxScrollExtent - 200) {
        _loadAllCompetitions();
      }
    });

    _scrollControllerInvites.addListener(() {
      if (_scrollControllerInvites.position.pixels >=
          _scrollControllerInvites.position.maxScrollExtent - 200) {
        _loadMyInvitedCompetitions();
      }
    });

    _scrollControllerParticipated.addListener(() {
      if (_scrollControllerParticipated.position.pixels >=
          _scrollControllerParticipated.position.maxScrollExtent - 200) {
        _loadMyParticipatedCompetitions();
      }
    });
  }

  void refreshCurrentTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        _lastPageMyCompetitions = null;
        _myCompetitions.clear();
        _hasMoreMy = true;
        _loadMyCompetitions();
        break;
      case 1:
        _lastPageFriendsCompetitions = null;
        _friendsCompetitions.clear();
        _hasMoreFriends = true;
        _loadFriendsCompetitions();
        break;
      case 2:
        _lastPageAllCompetitions = null;
        _allCompetitions.clear();
        _hasMoreAll = true;
        _loadAllCompetitions();
        break;
      case 3:
        _lastPageInvites = null;
        _invitedCompetitions.clear();
        _hasMoreInvites = true;
        _loadMyInvitedCompetitions();
        break;
      case 4:
        lastCompetitionIdParticipated = "";
        _participatedCompetitions.clear();
        _hasMoreParticipating = true;
        _loadMyParticipatedCompetitions();
        break;
    }
  }

  // Load current tab
  void _loadCurrentTabData(int index) {
    switch (index) {
      case 0:
        _lastPageMyCompetitions = null;
        _myCompetitions.clear();
        _hasMoreMy = true;
        _loadMyCompetitions();
        break;
      case 1:
        _lastPageFriendsCompetitions = null;
        _friendsCompetitions.clear();
        _hasMoreFriends = true;
        _loadFriendsCompetitions();
        break;
      case 2:
        _lastPageAllCompetitions = null;
        _allCompetitions.clear();
        _hasMoreAll = true;
        _loadAllCompetitions();
        break;
      case 3:
        _lastPageInvites = null;
        _invitedCompetitions.clear();
        _hasMoreInvites = true;
        _loadMyInvitedCompetitions();
        break;
      case 4:
        lastCompetitionIdParticipated = "";
        _participatedCompetitions.clear();
        _hasMoreParticipating = true;
        _loadMyParticipatedCompetitions();
        break;
    }
  }

  Future<void> initializeAsync() async {}

  /// Load my competitions
  Future<void> _loadMyCompetitions() async {
    if (_isLoadingMy == true || _hasMoreMy == false) {
      return;
    }
    setState(() {
      _isLoadingMy = true;
    });

    final competitionFetchResult =
        await CompetitionService.fetchMyLatestCompetitionsPage(
          FirebaseAuth.instance.currentUser?.uid ?? "",
          _limit,
          _lastPageMyCompetitions,
        );

    if (!mounted) return;
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

    final competitionFetchResult =
        await CompetitionService.fetchLastFriendsCompetitionsPage(
          _limit,
          _lastPageFriendsCompetitions,
          currentUser?.friends ?? {},
        );
    if (!mounted) return;

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

    final competitionFetchResult =
        await CompetitionService.fetchLatestCompetitionsPage(
          _limit,
          _lastPageAllCompetitions,
        );
    if (!mounted) return;

    setState(() {
      _allCompetitions.addAll(competitionFetchResult.competitions);
      _lastPageAllCompetitions = competitionFetchResult.lastDocument;

      _isLoadingAll = false;

      if (competitionFetchResult.lastDocument == null || competitionFetchResult.competitions.length < _limit) {
        _hasMoreAll = false;
      }
    });
    _isLoadingAll = false;
  }

  /// Load competitions which user is invited
  Future<void> _loadMyInvitedCompetitions() async {
    if (_isLoadingInvites == true || _hasMoreInvites == false) {
      return;
    }
    setState(() {
      _isLoadingInvites = true;
    });

    final competitionFetchResult =
        await CompetitionService.fetchMyInvitedCompetitions(
          AppData.instance.currentUser?.receivedInvitationsToCompetitions ?? {},
          _limit,
          _lastPageInvites,
        );
    if (!mounted) return;

    setState(() {
      _invitedCompetitions.addAll(competitionFetchResult.competitions);
      _lastPageInvites = competitionFetchResult.lastDocument;
      _isLoadingInvites = false;
      if (competitionFetchResult.competitions.length < _limit) {
        _hasMoreInvites = false;
      }
    });
  }

  String lastCompetitionIdParticipated = "";

  Future<void> _loadMyParticipatedCompetitions() async {
    if (_isLoadingParticipating || !_hasMoreParticipating) {
      return;
    }

    setState(() {
      _isLoadingParticipating = true;
    });

    final List<String> fullIdList =
        AppData.instance.currentUser?.participatedCompetitions.toList() ?? [];

    if (fullIdList.isEmpty) {
      setState(() {
        _isLoadingParticipating = false;
        _hasMoreParticipating = false;
      });
      return;
    }

    int startIndex = 0;
    if (lastCompetitionIdParticipated.isNotEmpty) {
      int lastIndex = fullIdList.indexOf(lastCompetitionIdParticipated);
      if (lastIndex == -1) {
        setState(() {
          _isLoadingParticipating = false;
          _hasMoreParticipating = false;
        });
        return;
      }
      startIndex = lastIndex + 1;
    }

    if (startIndex >= fullIdList.length) {
      setState(() {
        _isLoadingParticipating = false;
        _hasMoreParticipating = false;
      });
      return;
    }

    int endIndex = startIndex + _limit;
    bool hasMore = true;
    if (endIndex >= fullIdList.length) {
      endIndex = fullIdList.length;
      hasMore = false;
    }

    final List<String> sliceToFetch = fullIdList.sublist(startIndex, endIndex);

    if (sliceToFetch.isEmpty) {
      setState(() {
        _isLoadingParticipating = false;
        _hasMoreParticipating = false;
      });
      return;
    }

    try {
      final competitions =
          await CompetitionService.fetchMyParticipatedCompetitions(
            myParticipatedCompetitions: sliceToFetch.toSet(),
          );

      if (!mounted) return;

      setState(() {
        _participatedCompetitions.addAll(competitions);

        lastCompetitionIdParticipated = sliceToFetch.last;

        _hasMoreParticipating = hasMore;
      });
    } catch (e) {
      print("Error loading participated competitions: $e");
      if (mounted) {
        setState(() {
          _hasMoreParticipating = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingParticipating = false;
        });
      }
    }
  }

  /// On competition block tap
  void onTapBlock(BuildContext context, Competition competition) async {
    if (_isNavigating) {
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    CompetitionContext enterContext = CompetitionContext.viewerNotAbleToJoin;

    int tabIndex = _tabController.index;
    await Navigator.pushNamed(
      context,
      AppRoutes.competitionDetails,
      arguments: {
        'competitionData': competition,
        'initTab': tabIndex,
      },
    );

    if (!mounted) return;
    setState(() {
      _isNavigating = false;
    });
    refreshCurrentTab(tabIndex);
  }

  /// On pressed add competition button
  void onPressedAddCompetition(BuildContext context) async {
    if (_isNavigating) {
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    int tabIndex = _tabController.index;
    await Navigator.pushNamed(
      context,
      AppRoutes.competitionDetails,
      arguments: {
        'competitionData': null,
        'initTab': tabIndex,
      },
    );

    if (!mounted) return;
    setState(() {
      _isNavigating = false;
    });
    refreshCurrentTab(tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: CustomFabLocation(xOffset: 20, yOffset: 70),
      floatingActionButton: Visibility(
        visible: [0, 1, 2].contains(_tabController.index),
        child: FloatingActionButton(
          onPressed: _isNavigating
              ? null
              : () => onPressedAddCompetition(context),
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
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withAlpha(100),
                labelStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorColor: Colors.white,
                unselectedLabelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  backgroundColor: AppColors.primary,
                ),
                isScrollable: true,
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
                      child: _isLoadingMy && _myCompetitions.isEmpty
                          ? AppLoadingIndicator()
                          : _myCompetitions.isEmpty
                          ? NoItemsMsg(textMessage: "No competitions found")
                          : ListView.builder(
                              controller: _scrollControllerMy,
                              itemCount:
                                  _myCompetitions.length + (_hasMoreMy ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _myCompetitions.length) {
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                final competition = _myCompetitions[index];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppUiConstants
                                        .pageBlockSpacingBetweenElements,
                                  ),
                                  child: InkWell(
                                    onTap: () =>
                                        onTapBlock(context, competition),
                                    child: CompetitionBlock(
                                      key: ValueKey(competition.competitionId),
                                      firstName: currentUser?.firstName ?? "",
                                      lastName: currentUser?.lastName ?? "",
                                      profilePhotoUrl: currentUser?.profilePhotoUrl ?? "",
                                      competition: competition,
                                      initIndex: 0,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    // Friends
                    Container(
                      padding: EdgeInsets.only(top: 10),
                      child: _isLoadingFriends && _friendsCompetitions.isEmpty
                          ? AppLoadingIndicator()
                          : _friendsCompetitions.isEmpty
                          ? NoItemsMsg(textMessage: "No competitions found")
                          : ListView.builder(
                              controller: _scrollControllerFriends,
                              itemCount:
                                  _friendsCompetitions.length +
                                  (_hasMoreFriends ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _friendsCompetitions.length) {
                                  return Center(child: AppLoadingIndicator());
                                }
                                final competition = _friendsCompetitions[index];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppUiConstants
                                        .pageBlockSpacingBetweenElements,
                                  ),
                                  child: InkWell(
                                    onTap: () =>
                                        onTapBlock(context, competition),
                                    child: CompetitionBlock(
                                      key: ValueKey(competition.competitionId),
                                      competition: competition,
                                      initIndex: 1,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    // All last activities
                    Container(
                      padding: EdgeInsets.only(top: 10),
                      child: _isLoadingAll && _allCompetitions.isEmpty
                          ? AppLoadingIndicator()
                          : _allCompetitions.isEmpty
                          ? NoItemsMsg(textMessage: "No competitions found")
                          : ListView.builder(
                              controller: _scrollControllerAll,
                              itemCount:
                                  _allCompetitions.length +
                                  (_hasMoreAll ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _allCompetitions.length) {
                                  return Center(child: AppLoadingIndicator());
                                }
                                final competition = _allCompetitions[index];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppUiConstants
                                        .pageBlockSpacingBetweenElements,
                                  ),
                                  child: InkWell(
                                    onTap: () =>
                                        onTapBlock(context, competition),
                                    child: CompetitionBlock(
                                      key: ValueKey(competition.competitionId),
                                      firstName: "",
                                      lastName: "",
                                      competition: competition,
                                      initIndex: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Invites
                    Container(
                      padding: EdgeInsets.only(top: 10),
                      child: _isLoadingInvites  && _invitedCompetitions.isEmpty ? AppLoadingIndicator() : _invitedCompetitions.isEmpty
                          ? NoItemsMsg(textMessage: "No competitions found")
                          : ListView.builder(
                              controller: _scrollControllerInvites,
                              itemCount:
                                  _invitedCompetitions.length +
                                  (_hasMoreInvites ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _invitedCompetitions.length) {
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                final competition = _invitedCompetitions[index];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppUiConstants
                                        .pageBlockSpacingBetweenElements,
                                  ),
                                  child: InkWell(
                                    onTap: () =>
                                        onTapBlock(context, competition),
                                    child: CompetitionBlock(
                                      key: ValueKey(competition.competitionId),
                                      firstName: "",
                                      lastName: "",
                                      competition: competition,
                                      initIndex: 3,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Participated competitions
                    Container(
                      padding: EdgeInsets.only(top: 10),
                      child: _isLoadingParticipating && _participatedCompetitions.isEmpty ?
                          AppLoadingIndicator() : _participatedCompetitions.isEmpty
                          ? NoItemsMsg(textMessage: "No competitions found")
                          : ListView.builder(
                              controller: _scrollControllerParticipated,
                              itemCount:
                                  _participatedCompetitions.length +
                                  (_hasMoreParticipating ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _participatedCompetitions.length) {
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                final competition =
                                    _participatedCompetitions[index];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppUiConstants
                                        .pageBlockSpacingBetweenElements,
                                  ),
                                  child: InkWell(
                                    onTap: () =>
                                        onTapBlock(context, competition),
                                    child: CompetitionBlock(
                                      key: ValueKey(competition.competitionId),
                                      firstName: "",
                                      lastName: "",
                                      competition: competition,
                                      initIndex: 4,
                                    ),
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

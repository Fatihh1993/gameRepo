import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service_v2.dart';
import '../services/friend_service.dart';
import '../services/mission_service.dart';
import '../services/message_service.dart';
import '../utils/app_colors.dart';
import '../utils/language_manager.dart';
import '../utils/theme_manager.dart';
import 'friends_screen.dart';
import 'language_selection_screen.dart';
import 'leaderboard_screen.dart';
import 'login_screen_v2.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';

class HomeScreen extends StatefulWidget {
  final ThemeManager themeManager;
  final LanguageManager languageManager;

  const HomeScreen({
    super.key,
    required this.themeManager,
    required this.languageManager,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthServiceV2 _authService = AuthServiceV2();
  final MissionService _missionService = MissionService();
  final FriendService _friendService = FriendService();
  final MessageService _messageService = MessageService();
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isLoadingMissions = true;
  List<MissionProgress> _missions = const [];
  String? _claimingMissionId;
  Stream<List<FriendRequest>>? _incomingRequestsStream;
  Stream<int>? _unreadMessagesStream;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LoginScreenV2(
            themeManager: widget.themeManager,
            languageManager: widget.languageManager,
          ),
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingMissions = true;
      });
    }

    final profile = await _authService.getUserProfile(user.uid);
    final missions = await _missionService.fetchMissions(uid: user.uid);

    if (!mounted) return;

    setState(() {
      _incomingRequestsStream ??=
          _friendService.watchIncomingRequests(uid: user.uid);
      _unreadMessagesStream ??=
          _messageService.watchUnreadCount(uid: user.uid);
      _currentUser = profile ??
          UserModel(
            id: user.uid,
            username: user.email?.split('@').first ?? 'player',
            email: user.email ?? '',
            experience: 0,
            level: 1,
            highScore: 0,
            totalGamesPlayed: 0,
            unlockedAchievements: const [],
            passTokens: 0,
          );
      _missions = missions;
      _isLoading = false;
      _isLoadingMissions = false;
      _claimingMissionId = null;
    });
  }

  Future<void> _refreshUserProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final profile = await _authService.getUserProfile(user.uid);
    if (!mounted || profile == null) return;

    setState(() {
      _currentUser = profile;
    });
  }

  Future<void> _claimMission(MissionProgress mission) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final missionId = mission.definition.id;
    if (_claimingMissionId == missionId) return;

    final loc = AppLocalizations(widget.languageManager.currentLanguage);

    setState(() => _claimingMissionId = missionId);

    try {
      final updatedMission = await _missionService.claimMissionReward(
        uid: user.uid,
        missionId: missionId,
      );

      if (!mounted) return;

      setState(() {
        _missions = _missions.map((item) {
          return item.definition.id == updatedMission.definition.id
              ? updatedMission
              : item;
        }).toList();
        _claimingMissionId = null;
      });

      await _refreshUserProfile();

      if (!mounted) return;
      final rewardText = _missionRewardLabel(updatedMission.definition, loc);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(loc.missionClaimSuccess(rewardText)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!mounted) return;
      setState(() => _claimingMissionId = null);

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(loc.missionClaimError),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  String _missionRewardLabel(
    MissionDefinition definition,
    AppLocalizations loc,
  ) {
    switch (definition.rewardType) {
      case MissionRewardType.xp:
        return loc.missionRewardXp(definition.rewardValue);
      case MissionRewardType.pass:
        return loc.missionRewardPass(definition.rewardValue);
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreenV2(
          themeManager: widget.themeManager,
          languageManager: widget.languageManager,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    final user = _currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loc.userDataMissing),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserData,
                child: Text(loc.startQuiz),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                AppColors.backgroundLight,
              ],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _loadUserData,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                _buildHeader(context, loc, user),
                const SizedBox(height: 24),
                _buildHeroCard(context, loc),
                const SizedBox(height: 24),
                _buildStatsRow(context, loc, user),
                const SizedBox(height: 24),
                _buildQuickActions(context, loc, user),
                const SizedBox(height: 24),
                _buildMissionsSection(loc),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, AppLocalizations loc, UserModel user) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${loc.welcome},',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.neutral600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                user.username,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: widget.themeManager.toggleTheme,
          icon: Icon(
            widget.themeManager.isDark ? Icons.light_mode : Icons.dark_mode,
            color: AppColors.primary,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  themeManager: widget.themeManager,
                  languageManager: widget.languageManager,
                ),
              ),
            );
          },
          icon: const Icon(Icons.person_outline),
          color: AppColors.primary,
        ),
        IconButton(
          onPressed: _signOut,
          icon: const Icon(Icons.logout),
          color: AppColors.danger,
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context, AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.homeGreeting,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            loc.chooseLanguageCTA,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LanguageSelectionScreen(
                      themeManager: widget.themeManager,
                      languageManager: widget.languageManager,
                    ),
                  ),
                );
              },
              child: Text(
                loc.startQuiz,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    AppLocalizations loc,
    UserModel user,
  ) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up,
            label: loc.level,
            value: '${user.level}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.stars_rounded,
            label: loc.totalScore,
            value: '${user.highScore}',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.play_circle_fill,
            label: loc.totalGames,
            value: '${user.totalGamesPlayed}',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    AppLocalizations loc,
    UserModel user,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.quickStats,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniStat(
                  emoji: '🔥',
                  label: loc.accuracy,
                  value: user.totalGamesPlayed == 0 ? '0%' : '75%',
                ),
                _MiniStat(
                  emoji: '⚡',
                  label: loc.speed,
                  value: loc.good,
                ),
                _MiniStat(
                  emoji: '🎯',
                  label: loc.level,
                  value: '${user.level}',
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.backgroundLight, thickness: 1.2),
            const SizedBox(height: 12),
            Text(
              loc.inventory,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InventoryChip(
                  icon: Icons.skip_next_rounded,
                  label: loc.passesLabel,
                  value: '${user.passTokens}',
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.leaderboard_rounded),
                        label: Text(loc.leaderboardTitle),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LeaderboardScreen(
                                themeManager: widget.themeManager,
                                languageManager: widget.languageManager,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _unreadMessagesStream == null
                          ? OutlinedButton.icon(
                              icon: const Icon(Icons.mail_outline_rounded),
                              label: Text(loc.messagesTitle),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: null,
                            )
                          : StreamBuilder<int>(
                              stream: _unreadMessagesStream,
                              builder: (context, snapshot) {
                                final unreadCount = snapshot.data ?? 0;
                                final messagesLabel = unreadCount > 0
                                    ? '${loc.messagesTitle} ($unreadCount)'
                                    : loc.messagesTitle;

                                return OutlinedButton.icon(
                                  icon: const Icon(Icons.mail_outline_rounded),
                                  label: Text(messagesLabel),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                      color: AppColors.primary,
                                      width: 1.4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MessagesScreen(
                                          languageManager:
                                              widget.languageManager,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: StreamBuilder<List<FriendRequest>>(
                    stream: _incomingRequestsStream,
                    builder: (context, snapshot) {
                      final pendingCount = snapshot.data?.length ?? 0;
                      final friendsLabel = pendingCount > 0
                          ? '${loc.friendsTitle} ($pendingCount)'
                          : loc.friendsTitle;

                      return FilledButton.icon(
                        icon: const Icon(Icons.people_alt_rounded),
                        label: Text(friendsLabel),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FriendsScreen(
                                themeManager: widget.themeManager,
                                languageManager: widget.languageManager,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionsSection(AppLocalizations loc) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.missionsTitle,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (_isLoadingMissions)
              const Center(child: CircularProgressIndicator())
            else if (_missions.isEmpty)
              Text(
                loc.noMissions,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.neutral500),
              )
            else
              Column(
                children: _missions
                    .map(
                      (mission) => _MissionTile(
                        mission: mission,
                        loc: loc,
                        rewardLabel: _missionRewardLabel(mission.definition, loc),
                        onClaim: mission.isCompleted && !mission.isClaimed
                            ? () => _claimMission(mission)
                            : null,
                        isClaiming:
                            _claimingMissionId == mission.definition.id,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shadowColor: color.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  final MissionProgress mission;
  final AppLocalizations loc;
  final String rewardLabel;
  final VoidCallback? onClaim;
  final bool isClaiming;

  const _MissionTile({
    required this.mission,
    required this.loc,
    required this.rewardLabel,
    this.onClaim,
    this.isClaiming = false,
  });

  @override
  Widget build(BuildContext context) {
    final definition = mission.definition;
    final progress = mission.progress > definition.target
        ? definition.target
        : mission.progress;
    final ratio = mission.completionRatio;
    final isCompleted = mission.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: definition.type == MissionType.daily
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  definition.type == MissionType.daily
                      ? loc.missionDaily
                      : loc.missionWeekly,
                  style: TextStyle(
                    color: definition.type == MissionType.daily
                        ? AppColors.primary
                        : AppColors.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                isCompleted ? Icons.verified_rounded : Icons.flag_outlined,
                color: isCompleted ? AppColors.success : AppColors.neutral500,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            definition.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            definition.description,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.neutral600),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.backgroundLight,
              valueColor: AlwaysStoppedAnimation(
                isCompleted ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$progress / ${definition.target}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.neutral600),
              ),
              Text(
                rewardLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (onClaim != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isClaiming ? null : onClaim,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isClaiming
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        loc.missionClaim,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            )
          else if (mission.isClaimed)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      loc.missionClaimed,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _MiniStat({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.neutral500,
              ),
        ),
      ],
    );
  }
}

class _InventoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InventoryChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

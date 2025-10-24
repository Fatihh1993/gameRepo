import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service_v2.dart';
import '../utils/app_colors.dart';
import '../utils/language_manager.dart';
import '../utils/static_data.dart';
import '../utils/time_formatter.dart';

class FriendProfileScreen extends StatefulWidget {
  final String friendUid;
  final String friendUsername;
  final LanguageManager languageManager;

  const FriendProfileScreen({
    super.key,
    required this.friendUid,
    required this.friendUsername,
    required this.languageManager,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final AuthServiceV2 _authService = AuthServiceV2();

  UserModel? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final loc = AppLocalizations(widget.languageManager.currentLanguage);

    try {
      final profile = await _authService.getUserProfile(widget.friendUid);
      if (!mounted) return;

      if (profile == null) {
        setState(() {
          _profile = null;
          _isLoading = false;
          _errorMessage = loc.userDataMissing;
        });
        return;
      }

      final achievements = await _authService.getOrSyncAchievements(widget.friendUid);
      if (!mounted) return;

      setState(() {
        _profile = profile.copyWith(unlockedAchievements: achievements);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _isLoading = false;
        _errorMessage = error.toString();
      });
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(loc.error),
            backgroundColor: AppColors.danger,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);
    final displayName = _profile?.username.isNotEmpty == true
        ? _profile!.username
        : widget.friendUsername;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.friendProfileTitle(displayName)),
      ),
      body: _buildBody(loc),
    );
  }

  Widget _buildBody(AppLocalizations loc) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profile == null) {
      return RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 200),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage ?? loc.userDataMissing,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: _FriendProfileView(
        user: _profile!,
        loc: loc,
      ),
    );
  }
}

class _FriendProfileView extends StatelessWidget {
  final UserModel user;
  final AppLocalizations loc;

  const _FriendProfileView({
    required this.user,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _FriendHeaderCard(user: user, loc: loc),
        const SizedBox(height: 24),
        Text(
          loc.quickStats,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FriendStatTile(
                icon: Icons.trending_up,
                label: loc.level,
                value: '${user.level}',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FriendStatTile(
                icon: Icons.military_tech_rounded,
                label: loc.totalScore,
                value: '${user.highScore}',
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FriendStatTile(
                icon: Icons.play_circle_outline,
                label: loc.totalGames,
                value: '${user.totalGamesPlayed}',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FriendStatTile(
                icon: Icons.bolt,
                label: loc.experience,
                value: '${user.experience}',
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FriendStatTile(
                icon: Icons.airplane_ticket,
                label: loc.passesLabel,
                value: '${user.passTokens}',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FriendStatTile(
                icon: Icons.emoji_events_rounded,
                label: loc.achievements,
                value: '${user.unlockedAchievements.length}',
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          loc.achievements,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _FriendAchievementsList(
          unlockedIds: user.unlockedAchievements,
          loc: loc,
        ),
      ],
    );
  }
}

class _FriendHeaderCard extends StatelessWidget {
  final UserModel user;
  final AppLocalizations loc;

  const _FriendHeaderCard({
    required this.user,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                user.username.isNotEmpty
                    ? user.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _PresenceStatusRow(user: user, loc: loc),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FriendInfoChip(
                        icon: Icons.star_rate_rounded,
                        label: 'Lv ${user.level}',
                      ),
                      _FriendInfoChip(
                        icon: Icons.local_fire_department_rounded,
                        label: '${user.experience} XP',
                      ),
                      _FriendInfoChip(
                        icon: Icons.emoji_events_rounded,
                        label: '${user.unlockedAchievements.length} ⭐',
                      ),
                    ],
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

class _PresenceStatusRow extends StatelessWidget {
  final UserModel user;
  final AppLocalizations loc;

  const _PresenceStatusRow({
    required this.user,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    if (!user.shareOnlineStatus) {
      label = loc.friendStatusHidden;
      color = AppColors.neutral500;
    } else if (user.isOnline) {
      label = loc.friendOnline;
      color = AppColors.success;
    } else if (user.lastSeen != null) {
      label = loc.friendLastSeen(
        formatRelativeTime(user.lastSeen!, loc),
      );
      color = AppColors.neutral600;
    } else {
      label = loc.friendLastSeenUnknown;
      color = AppColors.neutral500;
    }

    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        );

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: textStyle,
          ),
        ),
      ],
    );
  }
}

class _FriendInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FriendInfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FriendStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _FriendStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.16),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.neutral500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
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

class _FriendAchievementsList extends StatelessWidget {
  final List<String> unlockedIds;
  final AppLocalizations loc;

  const _FriendAchievementsList({
    required this.unlockedIds,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final catalog = {
      for (final achievement in StaticData.achievements) achievement.id: achievement,
    };

    final unlocked = unlockedIds
        .map((id) => catalog[id])
        .whereType<Achievement>()
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    if (unlocked.isEmpty) {
      return Text(
        loc.noAchievements,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.neutral500),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: unlocked
          .map(
            (achievement) => Container(
              width: MediaQuery.of(context).size.width / 2 - 28,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: achievement.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    achievement.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    achievement.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.neutral600),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

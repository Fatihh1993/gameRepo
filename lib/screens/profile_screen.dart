import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service_v2.dart';
import '../utils/app_colors.dart';
import '../utils/language_manager.dart';
import '../utils/static_data.dart';
import '../utils/theme_manager.dart';
import 'login_screen_v2.dart';

class ProfileScreen extends StatefulWidget {
  final ThemeManager themeManager;
  final LanguageManager languageManager;

  const ProfileScreen({
    super.key,
    required this.themeManager,
    required this.languageManager,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthServiceV2 _authService = AuthServiceV2();
  UserModel? _user;
  bool _isLoading = true;
  bool _isUpdatingShareStatus = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final current = _authService.currentUser;
    if (current == null) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }
    final profile = await _authService.getUserProfile(current.uid);
    final achievements =
        await _authService.getOrSyncAchievements(current.uid);
    setState(() {
      _user = profile?.copyWith(unlockedAchievements: achievements);
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.signOut),
        content: Text(loc.signOutQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              loc.signOut,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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

  Future<void> _toggleOnlineVisibility(bool share) async {
    final user = _user;
    if (user == null || _isUpdatingShareStatus) return;

    final loc = AppLocalizations(widget.languageManager.currentLanguage);
    setState(() => _isUpdatingShareStatus = true);

    try {
      await _authService.updateShareOnlineStatus(share);
      if (!mounted) return;
      setState(() {
        _user = user.copyWith(
          shareOnlineStatus: share,
          isOnline: share ? user.isOnline : false,
          lastSeen: DateTime.now(),
        );
      });
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(loc.profileOnlineVisibilityUpdated),
            backgroundColor: AppColors.success,
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingShareStatus = false);
      }
    }
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

    final user = _user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.profileTitle),
        ),
        body: Center(
          child: Text(loc.userDataMissing),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.profileTitle),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
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
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.neutral500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: SwitchListTile.adaptive(
              value: user.shareOnlineStatus,
              onChanged: _isUpdatingShareStatus
                  ? null
                  : (value) => _toggleOnlineVisibility(value),
              title: Text(loc.profileOnlineVisibility),
              subtitle: Text(
                loc.profileOnlineVisibilityDesc,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.neutral600),
              ),
              secondary: Icon(
                user.shareOnlineStatus
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: AppColors.primary,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            loc.quickStats,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.trending_up,
                  label: loc.level,
                  value: '${user.level}',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.stars_rounded,
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
                child: _StatTile(
                  icon: Icons.play_circle_outline,
                  label: loc.totalGames,
                  value: '${user.totalGamesPlayed}',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.bolt,
                  label: loc.experience,
                  value: '${user.experience}',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            loc.achievements,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _AchievementsList(unlockedIds: user.unlockedAchievements, loc: loc),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
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

class _AchievementsList extends StatelessWidget {
  final List<String> unlockedIds;
  final AppLocalizations loc;

  const _AchievementsList({
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    achievement.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral600,
                        ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

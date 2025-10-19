import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service_v2.dart';
import '../utils/app_colors.dart';
import '../utils/language_manager.dart';
import '../utils/theme_manager.dart';
import 'language_selection_screen.dart';
import 'login_screen_v2.dart';
import 'profile_screen.dart';

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
  UserModel? _currentUser;
  bool _isLoading = true;

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

    final profile = await _authService.getUserProfile(user.uid);
    setState(() {
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
          );
      _isLoading = false;
    });
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

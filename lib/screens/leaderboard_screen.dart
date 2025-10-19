import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service_v2.dart';
import '../services/leaderboard_service.dart';
import '../utils/app_colors.dart';
import '../utils/language_manager.dart';
import '../utils/static_data.dart';
import '../utils/theme_manager.dart';

class LeaderboardScreen extends StatefulWidget {
  final ThemeManager themeManager;
  final LanguageManager languageManager;
  final ProgrammingLanguage? language;

  const LeaderboardScreen({
    super.key,
    required this.themeManager,
    required this.languageManager,
    this.language,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final LeaderboardService _leaderboardService = LeaderboardService();
  final AuthServiceV2 _authService = AuthServiceV2();

  LeaderboardEntry? _globalEntry;
  LeaderboardEntry? _languageEntry;
  bool _isLoadingUser = true;

  String get _languageKey => _mapLanguageKey(widget.language?.name ?? 'global');

  @override
  void initState() {
    super.initState();
    _loadUserRanks();
  }

  Future<void> _loadUserRanks() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _isLoadingUser = false);
      return;
    }

    final uid = user.uid;

    try {
      final results = await Future.wait<LeaderboardEntry?>([
        _leaderboardService.fetchUserEntry(uid: uid, language: 'global'),
        if (widget.language != null)
          _leaderboardService.fetchUserEntry(uid: uid, language: _languageKey)
        else
          Future.value(null),
      ]);

      setState(() {
        _globalEntry = results[0];
        _languageEntry = results.length > 1 ? results[1] : null;
        _isLoadingUser = false;
      });
    } catch (error) {
      debugPrint('Leaderboard user rank error: $error');
      setState(() => _isLoadingUser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);
    final languageName = widget.language?.name ?? loc.leaderboardLanguage;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.leaderboardTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: loc.leaderboardGlobal),
              Tab(text: languageName),
            ],
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 12),
            _buildUserSummary(loc),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  _buildLeaderboardList(loc, 'global'),
                  _buildLeaderboardList(loc, _languageKey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSummary(AppLocalizations loc) {
    if (_isLoadingUser) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: CircularProgressIndicator(),
      );
    }

    final entry = _languageEntry ?? _globalEntry;
    if (entry == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Text(
          loc.leaderboardNoData,
          style: const TextStyle(color: AppColors.neutral500),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                loc.leaderboardYou[0],
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.leaderboardYou,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${loc.leaderboardRank}: ${entry.rank > 0 ? entry.rank : '-'}',
                    style: const TextStyle(color: AppColors.neutral600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${loc.leaderboardScore}: ${entry.score}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.language == 'global'
                      ? loc.leaderboardGlobal
                      : _findLanguageName(entry.language),
                  style: const TextStyle(color: AppColors.neutral500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(AppLocalizations loc, String languageKey) {
    return StreamBuilder<List<LeaderboardEntry>>(
      stream: _leaderboardService.watchTopEntries(
        language: languageKey,
        limit: 50,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              loc.leaderboardNoData,
              style: const TextStyle(color: AppColors.neutral500),
            ),
          );
        }

        final userId = _authService.currentUser?.uid;
        final entries = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final rank = index + 1;
            final isYou = userId != null && userId == entry.userId;
            final languageLabel = _findLanguageName(entry.language);

            return _LeaderboardTile(
              entry: entry.copyWith(rank: rank),
              isCurrentUser: isYou,
              languageLabel: languageLabel,
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: entries.length,
        );
      },
    );
  }

  String _mapLanguageKey(String name) {
    switch (name.toLowerCase()) {
      case 'c#':
        return 'csharp';
      case 'javascript':
        return 'javascript';
      default:
        return name.toLowerCase();
    }
  }

  String _findLanguageName(String key) {
    if (key == 'global') return 'Global';
    final match = StaticData.languages.firstWhere(
      (lang) => _mapLanguageKey(lang.name) == key,
      orElse: () => ProgrammingLanguage(name: key, icon: '🏆', color: AppColors.primary),
    );
    return match.name;
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  final String languageLabel;

  const _LeaderboardTile({
    required this.entry,
    required this.isCurrentUser,
    required this.languageLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = _tileBackground(entry.rank, isCurrentUser);
    final textColor = isCurrentUser ? Colors.white : Colors.black87;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _RankBadge(rank: entry.rank, highlight: isCurrentUser),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              entry.username.isNotEmpty
                  ? entry.username[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                _LanguageLabel(
                  language: languageLabel,
                  highlight: isCurrentUser,
                ),
              ],
            ),
          ),
          Text(
            entry.score.toString(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _tileBackground(int rank, bool highlight) {
    if (highlight) {
      return AppColors.primary;
    }
    switch (rank) {
      case 1:
        return const Color(0xFFFFF4DC);
      case 2:
        return const Color(0xFFE6ECFF);
      case 3:
        return const Color(0xFFEFF7F0);
      default:
        return Colors.transparent;
    }
  }
}

class _LanguageLabel extends StatelessWidget {
  final String language;
  final bool highlight;

  const _LanguageLabel({
    required this.language,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final display = language;
    return Text(
      display,
      style: TextStyle(
        fontSize: 12,
        color: highlight
            ? Colors.white.withValues(alpha: 0.8)
            : AppColors.neutral500,
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final bool highlight;

  const _RankBadge({
    required this.rank,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = highlight ? Colors.white : AppColors.backgroundLight;
    final textColor = highlight ? AppColors.primary : Colors.black87;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        rank > 0 ? '$rank' : '-',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

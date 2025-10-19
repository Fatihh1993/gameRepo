import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/app_colors.dart';
import '../utils/language_manager.dart';
import '../utils/static_data.dart';
import '../utils/theme_manager.dart';
import 'game_screen.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int correctAnswers;
  final int wrongAnswers;
  final ProgrammingLanguage language;
  final int maxCombo;
  final int earnedXP;
  final List<String> newlyUnlockedAchievements;
  final ThemeManager themeManager;
  final LanguageManager languageManager;

  const ResultScreen({
    super.key,
    required this.score,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.language,
    required this.themeManager,
    required this.languageManager,
    this.maxCombo = 0,
    this.earnedXP = 0,
    this.newlyUnlockedAchievements = const [],
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(languageManager.currentLanguage);
    final totalQuestions = (correctAnswers + wrongAnswers).clamp(1, 9999);
    final percentage = (correctAnswers / totalQuestions * 100).round();
    final performanceText = loc.performanceMessage(percentage);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(loc.gameOver),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            _buildSummaryCard(loc, performanceText, totalQuestions),
            const SizedBox(height: 24),
            if (newlyUnlockedAchievements.isNotEmpty) ...[
              _buildAchievementsSection(loc),
              const SizedBox(height: 24),
            ],
            _buildStatsGrid(context, loc),
            const SizedBox(height: 24),
            _buildActionButtons(context, loc),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(AppLocalizations loc) {
    final catalog = {
      for (final achievement in StaticData.achievements) achievement.id: achievement,
    };

    final unlocked = newlyUnlockedAchievements
        .map((id) => catalog[id])
        .whereType<Achievement>()
        .toList();

    if (unlocked.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.achievementsUnlocked,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: unlocked
                .map(
                  (achievement) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: achievement.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          achievement.icon,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              achievement.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              achievement.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.neutral600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      AppLocalizations loc, String performanceText, int totalQuestions) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            language.color.withValues(alpha: 0.9),
            language.color,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: language.color.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.congratulations,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            performanceText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.yourScore,
                  style: TextStyle(
                    color: language.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$score',
                  style: TextStyle(
                    color: language.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${loc.correctAnswers}: $correctAnswers / $totalQuestions',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AppLocalizations loc) {
    final stats = [
      _StatItem(
        icon: Icons.done_all_rounded,
        label: loc.correctAnswers,
        value: correctAnswers.toString(),
        color: AppColors.success,
      ),
      _StatItem(
        icon: Icons.close_rounded,
        label: loc.wrongAnswers,
        value: wrongAnswers.toString(),
        color: AppColors.danger,
      ),
      _StatItem(
        icon: Icons.bolt_rounded,
        label: loc.maxCombo,
        value: '${maxCombo}x',
        color: AppColors.warning,
      ),
      _StatItem(
        icon: Icons.star_rounded,
        label: loc.earnedXP,
        value: '+$earnedXP',
        color: language.color,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: stats
          .map(
            (item) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: item.color.withValues(alpha: 0.15),
                    child: Icon(item.icon, color: item.color),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: item.color,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral500,
                        ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations loc) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: language.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => HomeScreen(
                    themeManager: themeManager,
                    languageManager: languageManager,
                  ),
                ),
                (route) => false,
              );
            },
            icon: const Icon(Icons.home_rounded),
            label: Text(
              loc.backToHome,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: language.color,
              side: BorderSide(color: language.color, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => GameScreen(
                    language: language,
                    themeManager: themeManager,
                    languageManager: languageManager,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              loc.playAgain,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

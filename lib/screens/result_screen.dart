import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/static_data.dart';
import '../utils/theme_manager.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final int correctAnswers;
  final int wrongAnswers;
  final ProgrammingLanguage language;
  final int maxCombo;
  final int earnedXP;
  final ThemeManager themeManager;

  const ResultScreen({
    super.key,
    required this.score,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.language,
    required this.themeManager,
    this.maxCombo = 0,
    this.earnedXP = 0,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  List<Achievement> _newAchievements = [];

  @override
  void initState() {
    super.initState();
    _checkAchievements();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkAchievements() {
    final totalQuestions = widget.correctAnswers + widget.wrongAnswers;
    final percentage = totalQuestions > 0 
        ? (widget.correctAnswers / totalQuestions * 100).round() 
        : 0;

    // İlk zafer
    if (StaticData.currentUser.totalGamesPlayed == 0) {
      final achievement = StaticData.achievements.firstWhere((a) => a.id == 'first_win');
      if (!StaticData.currentUser.unlockedAchievements.contains(achievement.id)) {
        _newAchievements.add(achievement);
      }
    }

    // Mükemmel oyun
    if (percentage == 100) {
      final achievement = StaticData.achievements.firstWhere((a) => a.id == 'perfect_game');
      if (!StaticData.currentUser.unlockedAchievements.contains(achievement.id)) {
        _newAchievements.add(achievement);
      }
    }

    // Combo başarıları
    if (widget.maxCombo >= 5) {
      final achievement = StaticData.achievements.firstWhere((a) => a.id == 'combo_5');
      if (!StaticData.currentUser.unlockedAchievements.contains(achievement.id)) {
        _newAchievements.add(achievement);
      }
    }
    if (widget.maxCombo >= 10) {
      final achievement = StaticData.achievements.firstWhere((a) => a.id == 'combo_10');
      if (!StaticData.currentUser.unlockedAchievements.contains(achievement.id)) {
        _newAchievements.add(achievement);
      }
    }

    // Yüksek skor başarıları
    if (widget.score >= 500) {
      final achievement = StaticData.achievements.firstWhere((a) => a.id == 'high_score_500');
      if (!StaticData.currentUser.unlockedAchievements.contains(achievement.id)) {
        _newAchievements.add(achievement);
      }
    }
    if (widget.score >= 1000) {
      final achievement = StaticData.achievements.firstWhere((a) => a.id == 'high_score_1000');
      if (!StaticData.currentUser.unlockedAchievements.contains(achievement.id)) {
        _newAchievements.add(achievement);
      }
    }
  }

  String _getPerformanceMessage() {
    final totalQuestions = widget.correctAnswers + widget.wrongAnswers;
    final percentage = (widget.correctAnswers / totalQuestions * 100).round();
    
    if (percentage >= 90) return 'Mükemmel! 🌟';
    if (percentage >= 70) return 'Harika! 🎉';
    if (percentage >= 50) return 'İyi! 👍';
    return 'Pratik yapmalısın! 💪';
  }

  @override
  Widget build(BuildContext context) {
    final totalQuestions = widget.correctAnswers + widget.wrongAnswers;
    final percentage = totalQuestions > 0 
        ? (widget.correctAnswers / totalQuestions * 100).round() 
        : 0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.language.color.withOpacity(0.8),
              widget.language.color,
              widget.language.color.withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => HomeScreen(themeManager: widget.themeManager)),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        'Oyun Bitti!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Animasyonlu skor
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: RotationTransition(
                          turns: _rotateAnimation,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  size: 60,
                                  color: Colors.amber,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.score.toString(),
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: widget.language.color,
                                  ),
                                ),
                                Text(
                                  'PUAN',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Performans mesajı
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getPerformanceMessage(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // İstatistikler
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(
                                '📊 Detaylı Sonuçlar',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              _buildStatRow(
                                icon: Icons.check_circle,
                                label: 'Doğru Cevap',
                                value: widget.correctAnswers.toString(),
                                color: Colors.green,
                              ),
                              const Divider(height: 24),
                              
                              _buildStatRow(
                                icon: Icons.cancel,
                                label: 'Yanlış Cevap',
                                value: widget.wrongAnswers.toString(),
                                color: Colors.red,
                              ),
                              const Divider(height: 24),
                              
                              _buildStatRow(
                                icon: Icons.percent,
                                label: 'Başarı Oranı',
                                value: '$percentage%',
                                color: Colors.blue,
                              ),
                              const Divider(height: 24),
                              
                              // 🔥 Combo göstergesi
                              if (widget.maxCombo >= 3)
                                _buildStatRow(
                                  icon: Icons.local_fire_department,
                                  label: 'En Yüksek Combo',
                                  value: '${widget.maxCombo}x 🔥',
                                  color: Colors.orange,
                                ),
                              if (widget.maxCombo >= 3) const Divider(height: 24),
                              
                              // ⭐ XP kazanımı
                              _buildStatRow(
                                icon: Icons.star,
                                label: 'Kazanılan XP',
                                value: '+${widget.earnedXP}',
                                color: Colors.amber,
                              ),
                              const Divider(height: 24),
                              
                              _buildStatRow(
                                icon: Icons.code,
                                label: 'Dil',
                                value: widget.language.name,
                                color: widget.language.color,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 🏆 Yeni başarılar
                      if (_newAchievements.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                                    SizedBox(width: 8),
                                    Text(
                                      'Yeni Rozetler Kazandın!',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ..._newAchievements.map((achievement) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        achievement.color.withOpacity(0.2),
                                        achievement.color.withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(achievement.icon, style: const TextStyle(fontSize: 32)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              achievement.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              achievement.description,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Butonlar
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => HomeScreen(themeManager: widget.themeManager)),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.home),
                          label: const Text(
                            'Ana Menü',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: widget.language.color,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text(
                            'Tekrar Oyna',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';

import '../models/models.dart';
import '../services/auth_service_v2.dart';
import '../services/question_service.dart';
import '../utils/app_colors.dart';
import '../utils/language_manager.dart';
import '../utils/theme_manager.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  final ProgrammingLanguage language;
  final ThemeManager themeManager;
  final LanguageManager languageManager;

  const GameScreen({
    super.key,
    required this.language,
    required this.themeManager,
    required this.languageManager,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final QuestionService _questionService = QuestionService();
  final AuthServiceV2 _authService = AuthServiceV2();

  late final AnimationController _timerController;

  List<Question> _questions = [];
  bool _isLoading = true;
  bool _isAnswering = false;
  int _currentIndex = 0;

  int _score = 0;
  int _lives = 3;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  int _currentCombo = 0;
  int _maxCombo = 0;
  int _earnedXp = 0;
  int _passCount = 1;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;

  @override
  void initState() {
    super.initState();

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..addListener(_handleTimerTick);

    _loadQuestions();
  }

  @override
  void dispose() {
    _timerController
      ..removeListener(_handleTimerTick)
      ..dispose();
    super.dispose();
  }

  void _handleTimerTick() {
    if (!_timerController.isAnimating) {
      return;
    }
    final progress = _timerController.value;
    final remaining = (_totalSeconds * (1 - progress)).ceil();
    if (remaining != _remainingSeconds && mounted) {
      setState(() => _remainingSeconds = max(0, remaining));
    }
    if (_timerController.isCompleted && !_isAnswering) {
      _onTimeUp();
    }
  }

  Future<void> _loadQuestions() async {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);
    try {
      final firestoreKey = _mapLanguageKey(widget.language.name);
      final fetched = await _questionService.getRandomQuestions(
        language: firestoreKey,
        count: 20,
      );

      if (!mounted) return;

      if (fetched.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.noQuestionsFound),
            backgroundColor: AppColors.warning,
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        _questions = fetched;
        _isLoading = false;
      });

      _prepareTimerForQuestion();
      _startTimer();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.error}: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _prepareTimerForQuestion() {
    if (_questions.isEmpty) return;
    final difficulty = _questions[_currentIndex].difficulty;
    switch (difficulty) {
      case 1:
        _totalSeconds = 30;
        break;
      case 3:
        _totalSeconds = 15;
        break;
      default:
        _totalSeconds = 20;
    }
    _remainingSeconds = _totalSeconds;
    _timerController.duration = Duration(seconds: _totalSeconds);
  }

  void _startTimer() {
    _timerController.forward(from: 0);
  }

  void _stopTimer() {
    if (_timerController.isAnimating) {
      _timerController.stop();
    }
  }

  void _onTimeUp() {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);
    _stopTimer();
    _handleWrongAnswer(loc.timeUp);
  }

  void _answerQuestion(bool userAnswer) {
    if (_isAnswering || _questions.isEmpty) return;

    final loc = AppLocalizations(widget.languageManager.currentLanguage);
    final question = _questions[_currentIndex];
    final isCorrect = userAnswer == question.isCorrect;

    _stopTimer();
    setState(() => _isAnswering = true);

    if (isCorrect) {
      final baseScore = 100 * question.difficulty;
      final comboBonus = _currentCombo >= 1 ? _currentCombo * 25 : 0;
      final total = baseScore + comboBonus;

      setState(() {
        _currentCombo += 1;
        _maxCombo = max(_maxCombo, _currentCombo);
        _score += total;
        _earnedXp += 50 * question.difficulty;
        _correctAnswers += 1;
      });

      if (_currentCombo > 0 && _currentCombo % 5 == 0) {
        setState(() => _passCount += 1);
        _showMessage(loc.passEarned(_passCount), AppColors.warning);
      }

      final explanation = question.explanation?.trim().isNotEmpty == true
          ? question.explanation!
          : '';
      final message = (explanation.isEmpty
              ? loc.correctAnswer('')
              : loc.correctAnswer(explanation))
          .trim();
      final feedback =
          _currentCombo >= 2 ? loc.comboMessage(_currentCombo, total) : message;
      _showMessage(feedback.trim(), AppColors.success);
    } else {
      final explanation = question.explanation?.trim().isNotEmpty == true
          ? question.explanation!
          : '';
      final message = (explanation.isEmpty
              ? loc.wrongAnswer('')
              : loc.wrongAnswer(explanation))
          .trim();
      _handleWrongAnswer(message);
      return;
    }

    Future.delayed(const Duration(milliseconds: 900), _goNextQuestion);
  }

  void _handleWrongAnswer(String message) {
    setState(() {
      _lives = max(0, _lives - 1);
      _currentCombo = 0;
      _isAnswering = true;
      _wrongAnswers += 1;
    });

    _showMessage(message, AppColors.danger);

    Future.delayed(const Duration(milliseconds: 900), _goNextQuestion);
  }

  void _passQuestion() {
    if (_isAnswering || _passCount <= 0) return;
    final loc = AppLocalizations(widget.languageManager.currentLanguage);
    _stopTimer();
    setState(() {
      _passCount -= 1;
      _currentCombo = 0;
      _isAnswering = true;
    });
    _showMessage(loc.questionSkipped(_passCount), AppColors.warning);
    Future.delayed(const Duration(milliseconds: 600), _goNextQuestion);
  }

  void _goNextQuestion() {
    if (!mounted) return;
    if (_lives <= 0) {
      _endGame();
      return;
    }

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex += 1;
        _isAnswering = false;
      });
      _prepareTimerForQuestion();
      _startTimer();
    } else {
      _endGame();
    }
  }

  Future<void> _endGame() async {
    _stopTimer();

    final user = _authService.currentUser;
    List<String> newlyUnlocked = [];
    if (user != null) {
      newlyUnlocked = await _authService.saveGameResult(
        uid: user.uid,
        language: _mapLanguageKey(widget.language.name),
        score: _score,
        earnedXP: _earnedXp,
        correctAnswers: _correctAnswers,
        wrongAnswers: _wrongAnswers,
        maxCombo: _maxCombo,
      );
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          score: _score,
          correctAnswers: _correctAnswers,
          wrongAnswers: _wrongAnswers,
          language: widget.language,
          themeManager: widget.themeManager,
          languageManager: widget.languageManager,
          maxCombo: _maxCombo,
          earnedXP: _earnedXp,
          newlyUnlockedAchievements: newlyUnlocked,
        ),
      ),
    );
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.language.name),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: widget.language.color),
              const SizedBox(height: 16),
              Text(loc.loadingQuestions),
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.language.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              backgroundColor: widget.language.color.withValues(alpha: 0.12),
              avatar: Text(widget.language.icon,
                  style: const TextStyle(fontSize: 16)),
              label: Text(
                '${loc.score}: $_score',
                style: TextStyle(
                  color: widget.language.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStatusHeader(context, loc, progress),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      loc.isThisCodeCorrect,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuestionCard(context, loc, question),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildAnswerButtons(context, loc),
            ),
            _buildTimerSection(loc),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(
    BuildContext context,
    AppLocalizations loc,
    double progress,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      index < _lives ? Icons.favorite : Icons.favorite_border,
                      color: index < _lives
                          ? AppColors.danger
                          : AppColors.neutral500.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${loc.question} ${_currentIndex + 1}/${_questions.length}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          '${(progress * 100).ceil()}%',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: widget.language.color,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.backgroundLight,
                        valueColor:
                            AlwaysStoppedAnimation(widget.language.color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_currentCombo >= 3) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                loc.comboMessage(_currentCombo, _currentCombo * 25),
                style: TextStyle(
                  color: AppColors.warning.darken(),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    AppLocalizations loc,
    Question question,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                backgroundColor: widget.language.color.withValues(alpha: 0.12),
                label: Text(
                  widget.language.name,
                  style: TextStyle(
                    color: widget.language.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  question.difficulty,
                  (index) => const Icon(
                    Icons.star,
                    color: AppColors.warning,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            loc.isThisCodeCorrect,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 220),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F24),
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minWidth: constraints.maxWidth),
                      child: HighlightView(
                        question.codeSnippet,
                        language: _mapHighlightLanguage(widget.language.name),
                        theme: _highlightTheme,
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                          fontFamily: 'SourceCodePro',
                          fontSize: 16,
                          height: 1.7,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButtons(BuildContext context, AppLocalizations loc) {
    return Row(
      children: [
        Expanded(
          child: _buildAnswerChoice(
            label: loc.wrong,
            color: AppColors.danger,
            icon: Icons.close_rounded,
            onPressed: _isAnswering ? null : () => _answerQuestion(false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildPassButton(loc)),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAnswerChoice(
            label: loc.correct,
            color: AppColors.success,
            icon: Icons.check_rounded,
            onPressed: _isAnswering ? null : () => _answerQuestion(true),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerChoice({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white70,
        disabledBackgroundColor: color.withValues(alpha: 0.35),
        minimumSize: const Size.fromHeight(66),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassButton(AppLocalizations loc) {
    final canUsePass = _passCount > 0 && !_isAnswering;
    final background = canUsePass
        ? AppColors.warning.withValues(alpha: 0.18)
        : AppColors.backgroundLight;
    final foreground = canUsePass
        ? AppColors.warning.darken(0.25)
        : AppColors.neutral600;

    return FilledButton(
      onPressed: canUsePass ? _passQuestion : null,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: AppColors.backgroundLight,
        disabledForegroundColor: AppColors.neutral500,
        minimumSize: const Size.fromHeight(66),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.skip_next_rounded,
            size: 24,
            color: canUsePass ? AppColors.warning.darken(0.1) : null,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${loc.pass} · ${_passCount}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection(AppLocalizations loc) {
    final isWarning = _remainingSeconds <= 5;
    final indicatorColor =
        isWarning ? AppColors.danger : widget.language.color;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                height: 68,
                width: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1 - _timerController.value,
                      strokeWidth: 6,
                      backgroundColor: AppColors.backgroundLight,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(indicatorColor),
                    ),
                    Text(
                      '$_remainingSeconds',
                      style: TextStyle(
                        fontSize: isWarning ? 22 : 20,
                        fontWeight: FontWeight.bold,
                        color:
                            isWarning ? AppColors.danger : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.timeRemaining,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _difficultyLabel(loc),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: indicatorColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: indicatorColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_remainingSeconds} ${loc.seconds}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: indicatorColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _difficultyLabel(AppLocalizations loc) {
    if (_questions.isEmpty) return '';
    final difficulty = _questions[_currentIndex].difficulty;
    switch (difficulty) {
      case 1:
        return loc.timerDifficultyLabel(loc.easy, 30);
      case 3:
        return loc.timerDifficultyLabel(loc.hard, 15);
      default:
        return loc.timerDifficultyLabel(loc.medium, 20);
    }
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

  String _mapHighlightLanguage(String name) {
    switch (name.toLowerCase()) {
      case 'c#':
        return 'cs';
      case 'javascript':
        return 'javascript';
      case 'sql':
        return 'sql';
      default:
        return name.toLowerCase();
    }
  }

  Map<String, TextStyle> get _highlightTheme => const {
        'root': TextStyle(
            backgroundColor: Color(0xFF1F1F24), color: Color(0xFFD4D4D4)),
        'keyword':
            TextStyle(color: Color(0xFF569CD6), fontWeight: FontWeight.bold),
        'built_in': TextStyle(color: Color(0xFF4EC9B0)),
        'type': TextStyle(color: Color(0xFF4EC9B0)),
        'literal': TextStyle(color: Color(0xFFB5CEA8)),
        'number': TextStyle(color: Color(0xFFB5CEA8)),
        'string': TextStyle(color: Color(0xFFD69D85)),
        'comment':
            TextStyle(color: Color(0xFF6A9955), fontStyle: FontStyle.italic),
        'function': TextStyle(color: Color(0xFFDCDCAA)),
        'title': TextStyle(color: Color(0xFFDCDCAA)),
        'params': TextStyle(color: Color(0xFF9CDCFE)),
        'operator': TextStyle(color: Color(0xFFD4D4D4)),
      };
}

extension ColorBrightness on Color {
  Color darken([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    final adjusted =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return adjusted.toColor();
  }
}

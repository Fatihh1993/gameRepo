import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/app_colors.dart';
import '../utils/language_manager.dart';
import '../utils/static_data.dart';
import '../utils/theme_manager.dart';
import 'game_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final ThemeManager themeManager;
  final LanguageManager languageManager;

  const LanguageSelectionScreen({
    super.key,
    required this.themeManager,
    required this.languageManager,
  });

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectLanguage(int index, ProgrammingLanguage language) {
    setState(() => _selectedIndex = index);
    _controller.forward().then((_) async {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GameScreen(
            language: language,
            themeManager: widget.themeManager,
            languageManager: widget.languageManager,
          ),
        ),
      );
      if (!mounted) return;
      setState(() => _selectedIndex = null);
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.languageSelectionAppBar),
        centerTitle: true,
      ),
      body: Container(
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
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.code,
                      size: 60,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.languageSelectionTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.languageSelectionSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.neutral500,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: StaticData.languages.length,
                  itemBuilder: (context, index) {
                    final language = StaticData.languages[index];
                    final isSelected = _selectedIndex == index;
                    final questions =
                        StaticData.questions[language.name]?.length ?? 0;

                    return AnimatedScale(
                      scale: isSelected ? 0.96 : 1,
                      duration: const Duration(milliseconds: 180),
                      child: Card(
                        elevation: isSelected ? 10 : 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => _selectLanguage(index, language),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  language.color.withValues(alpha: 0.85),
                                  language.color,
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    language.icon,
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                  const Spacer(),
                                  Text(
                                    language.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      loc.languageQuestionCount(questions),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
    );
  }
}

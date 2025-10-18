import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/static_data.dart';
import '../utils/theme_manager.dart';
import '../utils/language_manager.dart';
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
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectLanguage(int index, ProgrammingLanguage language) {
    setState(() => _selectedIndex = index);
    _animationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(
              language: language,
              themeManager: widget.themeManager,
              languageManager: widget.languageManager,
            ),
          ),
        ).then((_) {
          setState(() => _selectedIndex = null);
          _animationController.reverse();
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dil Seçimi'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.code,
                      size: 60,
                      color: Color(0xFF6C63FF),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hangi dilde test olmak istersin?',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bir programlama dili seç ve bilgini test et',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
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
                    
                    return AnimatedScale(
                      scale: isSelected ? 0.95 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Card(
                        elevation: isSelected ? 8 : 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          onTap: () => _selectLanguage(index, language),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  language.color.withOpacity(0.8),
                                  language.color,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  language.icon,
                                  style: const TextStyle(fontSize: 60),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  language.name,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${StaticData.questions[language.name]?.length ?? 0} Soru',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
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

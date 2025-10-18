import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import '../models/models.dart';
import '../utils/theme_manager.dart';
import '../utils/language_manager.dart';
import '../services/auth_service_v2.dart';
import '../services/question_service.dart';
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
  final AuthServiceV2 _authService = AuthServiceV2();
  final QuestionService _questionService = QuestionService();
  
  List<Question> _questions = [];
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _lives = 3;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  bool _isAnswering = false;
  int _currentCombo = 0; // 🔥 Combo sistemi
  int _maxCombo = 0; // En yüksek combo
  int _earnedXP = 0; // Kazanılan XP
  int _passCount = 1; // 🎯 PAS geçme hakkı (başlangıç 1)
  int _usedPasses = 0; // Kullanılan pas sayısı
  
  // ⏱️ Timer sistemi
  late AnimationController _timerController;
  int _remainingSeconds = 20;
  int _totalSeconds = 20;
  bool _isTimerRunning = false;
  
  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late AnimationController _comboController; // Combo animasyonu
  late Animation<double> _shakeAnimation;
  late Animation<double> _comboScaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _comboController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // ⏱️ Timer controller
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );
    
    // Timer listener - her saniye güncelle
    _timerController.addListener(() {
      if (!_timerController.value.isFinite) return; // Infinity kontrolü
      
      final remaining = (_totalSeconds * (1 - _timerController.value)).ceil();
      if (remaining != _remainingSeconds && remaining >= 0) {
        setState(() {
          _remainingSeconds = remaining;
        });
      }
      
      // Süre bitti
      if (_timerController.isCompleted && !_isAnswering) {
        _onTimeUp();
      }
    });
    
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    
    _comboScaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _comboController, curve: Curves.elasticOut),
    );
    
    _fadeController.forward();
  }

  // 🔤 Dil ismini Firestore key'ine çevir
  String _getLanguageKey(String languageName) {
    switch (languageName) {
      case 'C#':
        return 'csharp';
      case 'Python':
        return 'python';
      case 'JavaScript':
        return 'javascript';
      case 'SQL':
        return 'sql';
      default:
        return languageName.toLowerCase();
    }
  }

  // 🎨 Syntax highlighting için dil adını çevir
  String _getHighlightLanguage(String languageName) {
    switch (languageName) {
      case 'C#':
        return 'csharp';
      case 'Python':
        return 'python';
      case 'JavaScript':
        return 'javascript';
      case 'SQL':
        return 'sql';
      default:
        return languageName.toLowerCase();
    }
  }

  // 🌈 Özel renklendirme teması (VS Code benzeri)
  Map<String, TextStyle> _getCustomTheme() {
    return {
      'root': const TextStyle(
        backgroundColor: Color(0xFF1E1E1E),
        color: Color(0xFFD4D4D4), // Varsayılan metin rengi
      ),
      'keyword': const TextStyle(color: Color(0xFF569CD6), fontWeight: FontWeight.bold), // Mavi (int, var, class, return...)
      'built_in': const TextStyle(color: Color(0xFF4EC9B0)), // Turkuaz (Console, String, List...)
      'type': const TextStyle(color: Color(0xFF4EC9B0)), // Turkuaz (tip isimleri)
      'literal': const TextStyle(color: Color(0xFF569CD6)), // Mavi (true, false, null)
      'number': const TextStyle(color: Color(0xFFB5CEA8)), // Açık yeşil (sayılar)
      'string': const TextStyle(color: Color(0xFFCE9178)), // Turuncu (stringler)
      'comment': const TextStyle(color: Color(0xFF6A9955), fontStyle: FontStyle.italic), // Yeşil (yorumlar)
      'function': const TextStyle(color: Color(0xFFDCDCAA), fontWeight: FontWeight.bold), // Sarı (fonksiyon isimleri)
      'title': const TextStyle(color: Color(0xFFDCDCAA), fontWeight: FontWeight.bold), // Sarı (metot isimleri)
      'params': const TextStyle(color: Color(0xFF9CDCFE)), // Açık mavi (parametreler)
      'variable': const TextStyle(color: Color(0xFF9CDCFE)), // Açık mavi (değişkenler)
      'class': const TextStyle(color: Color(0xFF4EC9B0), fontWeight: FontWeight.bold), // Turkuaz (class isimleri)
      'operator': const TextStyle(color: Color(0xFFD4D4D4)), // Beyaz (=, +, -, ...)
      'punctuation': const TextStyle(color: Color(0xFFD4D4D4)), // Beyaz (;, {, }, ...)
      'attr': const TextStyle(color: Color(0xFF9CDCFE)), // Açık mavi (attribute)
      'meta': const TextStyle(color: Color(0xFFC586C0)), // Pembe (meta bilgiler)
      'tag': const TextStyle(color: Color(0xFF569CD6)), // Mavi (HTML tags)
      'attribute': const TextStyle(color: Color(0xFF9CDCFE)), // Açık mavi
      'selector-tag': const TextStyle(color: Color(0xFF569CD6)), // Mavi
      'selector-class': const TextStyle(color: Color(0xFFD7BA7D)), // Altın sarısı
      'selector-id': const TextStyle(color: Color(0xFFD7BA7D)), // Altın sarısı
      'regexp': const TextStyle(color: Color(0xFFD16969)), // Kırmızı (regex)
      'deletion': const TextStyle(color: Color(0xFFD16969)), // Kırmızı
      'addition': const TextStyle(color: Color(0xFFB5CEA8)), // Yeşil
      'emphasis': const TextStyle(fontStyle: FontStyle.italic),
      'strong': const TextStyle(fontWeight: FontWeight.bold),
    };
  }

  // 📚 Firestore'dan soruları yükle
  Future<void> _loadQuestions() async {
    try {
      print('📚 Sorular yükleniyor: ${widget.language.name}');
      
      // Dil ismini Firestore formatına çevir
      String languageKey = _getLanguageKey(widget.language.name);
      print('🔍 Firestore\'da aranacak dil: $languageKey');
      
      final questions = await _questionService.getRandomQuestions(
        language: languageKey,
        count: 20, // 20 rastgele soru
      );
      
      if (questions.isEmpty) {
        print('⚠️ Hiç soru bulunamadı!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu dil için henüz soru eklenmemiş!'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }
      
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
      
      print('✅ ${questions.length} soru yüklendi');
      
      // İlk soruyu yüklediğimizde timer'ı başlat
      _startTimer();
    } catch (e) {
      print('❌ Soru yükleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sorular yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    _shakeController.dispose();
    _fadeController.dispose();
    _comboController.dispose();
    super.dispose();
  }

  // ⏱️ Timer başlat
  void _startTimer() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return;
    }
    
    final question = _questions[_currentQuestionIndex];
    
    // Zorluk seviyesine göre süre belirle
    switch (question.difficulty) {
      case 1: // Kolay
        _totalSeconds = 30;
        break;
      case 2: // Orta
        _totalSeconds = 20;
        break;
      case 3: // Zor
        _totalSeconds = 15;
        break;
      default:
        _totalSeconds = 20;
    }
    
    setState(() {
      _remainingSeconds = _totalSeconds;
      _isTimerRunning = true;
    });
    
    _timerController.duration = Duration(seconds: _totalSeconds);
    _timerController.forward(from: 0);
  }
  
  // ⏱️ Timer durdur
  void _stopTimer() {
    if (_isTimerRunning && _timerController.isAnimating) {
      _timerController.stop();
      setState(() {
        _isTimerRunning = false;
      });
    }
  }
  
  // ⏱️ Süre bitti
  void _onTimeUp() {
    if (_isAnswering) return; // Zaten cevap verildiyse ignore et
    
    setState(() => _isAnswering = true);
    _stopTimer();
    
    // Yanlış cevap olarak işle
    final currentQuestion = _questions[_currentQuestionIndex];
    
    setState(() {
      _lives--;
      _wrongAnswers++;
      _currentCombo = 0;
    });
    
    _shakeController.forward().then((_) => _shakeController.reverse());
    _showFeedback(false, '⏱️ Süre doldu! ${currentQuestion.explanation ?? ""}');
    
    Future.delayed(const Duration(seconds: 2), () {
      if (_lives <= 0) {
        _endGame();
      } else if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _isAnswering = false;
        });
        _startTimer(); // Yeni soru için timer başlat
      } else {
        _endGame();
      }
    });
  }

  void _answerQuestion(bool userAnswer) async {
    if (_isAnswering) return;
    
    setState(() => _isAnswering = true);
    _stopTimer(); // Timer'ı durdur
    
    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = userAnswer == currentQuestion.isCorrect;
    
    if (isCorrect) {
      // Combo artır
      setState(() {
        _currentCombo++;
        if (_currentCombo > _maxCombo) {
          _maxCombo = _currentCombo;
        }
      });
      
      // Combo bonus hesapla
      int comboBonus = _currentCombo > 1 ? (_currentCombo - 1) * 20 : 0;
      int baseScore = 100 * currentQuestion.difficulty;
      int totalScore = baseScore + comboBonus;
      
      setState(() {
        _score += totalScore;
        _correctAnswers++;
        _earnedXP += 50 * currentQuestion.difficulty;
        
        // 🎯 Her 5 doğru cevapta +1 pas hakkı
        if (_correctAnswers % 5 == 0) {
          _passCount++;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Text('🎁'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Harika! +1 PAS Hakkı Kazandınız! (Toplam: $_passCount)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
      
      // Combo animasyonu
      _comboController.forward(from: 0);
      
      String comboMessage = currentQuestion.explanation ?? 'Doğru!';
      if (_currentCombo >= 3) {
        comboMessage = '🔥 ${_currentCombo}x COMBO! +$totalScore puan';
      }
      
      _showFeedback(true, comboMessage);
    } else {
      // Combo sıfırla
      setState(() {
        _lives--;
        _wrongAnswers++;
        _currentCombo = 0; // Yanlış cevapta combo sıfırlanır
      });
      
      _shakeController.forward().then((_) => _shakeController.reverse());
      _showFeedback(false, currentQuestion.explanation ?? 'Yanlış! Combo sıfırlandı 💔');
    }
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (_lives <= 0) {
      _endGame();
    } else if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswering = false;
      });
      _startTimer(); // Yeni soru için timer başlat
    } else {
      _endGame();
    }
  }

  // 🎯 PAS geçme fonksiyonu
  void _passQuestion() async {
    if (_isAnswering || _passCount <= 0) return;
    
    setState(() {
      _isAnswering = true;
      _passCount--;
      _usedPasses++;
    });
    
    // Timer'ı durdur ve sıfırla
    _stopTimer();
    _timerController.reset();
    
    _showFeedback(
      true, 
      '⏭️ Soru atlandı! Kalan pas hakkı: $_passCount',
    );
    
    await Future.delayed(const Duration(seconds: 1));
    
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswering = false;
      });
      _startTimer();
    } else {
      _endGame();
    }
  }

  // 🎯 Zorluk seviyesi metni
  String _getDifficultyText() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return '';
    }
    final difficulty = _questions[_currentQuestionIndex].difficulty;
    switch (difficulty) {
      case 1:
        return 'Kolay (30sn)';
      case 2:
        return 'Orta (20sn)';
      case 3:
        return 'Zor (15sn)';
      default:
        return '';
    }
  }

  void _showFeedback(bool isCorrect, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _endGame() async {
    // Firebase'e oyun sonuçlarını kaydet
    final user = _authService.currentUser;
    if (user != null) {
      try {
        await _authService.saveGameResult(
          uid: user.uid,
          score: _score,
          earnedXP: _earnedXP,
        );
      } catch (e) {
        print('Oyun sonucu kaydetme hatası: $e');
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            score: _score,
            correctAnswers: _correctAnswers,
            wrongAnswers: _wrongAnswers,
            language: widget.language,
            themeManager: widget.themeManager,
            maxCombo: _maxCombo,
            earnedXP: _earnedXP,
            // usedPasses: _usedPasses, // İleride eklenebilir
          ),
        ),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);
    
    // Kullanılan pas sayısını print edelim (ileride gösterilebilir)
    // ignore: unused_local_variable
    final pasInfo = 'Kullanılan PAS: $_usedPasses';
    
    // Loading ekranı
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA), // Daha yumuşak gri-mavi
        appBar: AppBar(
          title: Text(widget.language.name),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: widget.language.color,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: widget.language.color,
              ),
              const SizedBox(height: 24),
              Text(
                loc.loadingQuestions,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Soru yoksa
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Oyun')),
        body: Center(child: Text(loc.noQuestionsFound)),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Daha yumuşak gri-mavi
      appBar: AppBar(
        title: Text(widget.language.name),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: widget.language.color,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.language.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.language.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '💰',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_score',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: widget.language.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // İlerleme çubuğu ve canlar - daha yumuşak tasarım
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Canlar ve İlerleme yan yana
                Row(
                  children: [
                    // Canlar
                    ...List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: AnimatedScale(
                          scale: index < _lives ? 1.0 : 0.7,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            index < _lives ? Icons.favorite : Icons.favorite_border,
                            color: index < _lives ? Colors.red.shade400 : Colors.grey.shade300,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // İlerleme bilgisi
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${loc.question} ${_currentQuestionIndex + 1}/${_questions.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: widget.language.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(widget.language.color),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // 🔥 Combo göstergesi - daha küçük ve şık
                if (_currentCombo >= 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ScaleTransition(
                      scale: _comboScaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '🔥',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_currentCombo}x COMBO!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Soru alanı - daha temiz ve minimalist
          Expanded(
            child: AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                );
              },
              child: Column(
                children: [
                  // Soru kartı kısmı - scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Soru başlığı
                          Text(
                            loc.isThisCodeCorrect,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          // Soru kartı - daha modern ve temiz
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: widget.language.color.withOpacity(0.2),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Dil rozeti ve zorluk
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.language.color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: widget.language.color.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            widget.language.icon,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            widget.language.name,
                                            style: TextStyle(
                                              color: widget.language.color,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Zorluk yıldızları
                                    Row(
                                      children: List.generate(
                                        question.difficulty,
                                        (index) => Icon(
                                          Icons.star,
                                          color: Colors.amber.shade600,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                
                                // Kod bloğu - Syntax Highlighted
                                Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(
                                    minHeight: 150,
                                    maxHeight: 300,
                                  ),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: SingleChildScrollView(
                                    child: HighlightView(
                                      question.codeSnippet,
                                      language: _getHighlightLanguage(widget.language.name),
                                      theme: _getCustomTheme(),
                                      padding: EdgeInsets.zero,
                                      textStyle: const TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 18,
                                        height: 1.8,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Cevap butonları - Sorunun hemen altında
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildAnswerButton(
                                  context,
                                  label: loc.wrong,
                                  icon: Icons.close_rounded,
                                  color: Colors.red.shade400,
                                  onPressed: () => _answerQuestion(false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: _buildPassButton(context),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: _buildAnswerButton(
                                  context,
                                  label: loc.correct,
                                  icon: Icons.check_rounded,
                                  color: Colors.green.shade400,
                                  onPressed: () => _answerQuestion(true),
                                ),
                              ),
                            ],
                          ),
                          
                        ],
                      ),
                    ),
                  ),
                  
                  // En alt - Sadece Timer (fixed, tam ortalı)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFF5F7FA),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Timer circle
                          AnimatedBuilder(
                            animation: _timerController,
                            builder: (context, child) {
                              final progress = 1 - _timerController.value;
                              final isWarning = _remainingSeconds <= 5;
                              
                              return SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 7,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isWarning ? Colors.red.shade400 : widget.language.color,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Timer text
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: TextStyle(
                                  fontSize: _remainingSeconds <= 5 ? 32 : 28,
                                  fontWeight: FontWeight.bold,
                                  color: _remainingSeconds <= 5 
                                      ? Colors.red.shade600 
                                      : Colors.grey[800],
                                ),
                                child: Text('$_remainingSeconds'),
                              ),
                              Text(
                                _getDifficultyText(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildAnswerButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isAnswering ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _isAnswering ? 0 : 3,
          shadowColor: color.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 PAS butonu
  Widget _buildPassButton(BuildContext context) {
    final hasPass = _passCount > 0;
    
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: (_isAnswering || !hasPass) ? null : _passQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasPass ? Colors.amber.shade400 : Colors.grey.shade300,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: (_isAnswering || !hasPass) ? 0 : 3,
          shadowColor: Colors.amber.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.skip_next_rounded,
                size: 18,
                color: hasPass ? Colors.white : Colors.grey.shade400,
              ),
              const SizedBox(height: 2),
              Text(
                'PAS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: hasPass ? Colors.white : Colors.grey.shade400,
                ),
              ),
              if (hasPass)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_passCount',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

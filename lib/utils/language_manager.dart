import 'package:flutter/material.dart';

// 🌍 Dil yönetimi sınıfı
class LanguageManager extends ChangeNotifier {
  String _currentLanguage = 'tr'; // Varsayılan Türkçe

  String get currentLanguage => _currentLanguage;

  void setLanguage(String lang) {
    _currentLanguage = lang;
    notifyListeners();
  }

  bool get isTurkish => _currentLanguage == 'tr';
  bool get isEnglish => _currentLanguage == 'en';
}

// 🌍 Çeviri sınıfı
class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static AppLocalizations of(BuildContext context) {
    return AppLocalizations('tr'); // Varsayılan
  }

  // Genel
  String get appName => _getText('appName');
  String get welcome => _getText('welcome');
  String get selectLanguage => _getText('selectLanguage');
  String get turkish => _getText('turkish');
  String get english => _getText('english');
  String get continue_ => _getText('continue');
  String get back => _getText('back');
  String get yes => _getText('yes');
  String get no => _getText('no');
  
  // Login Screen
  String get login => _getText('login');
  String get register => _getText('register');
  String get email => _getText('email');
  String get username => _getText('username');
  String get password => _getText('password');
  String get forgotPassword => _getText('forgotPassword');
  String get dontHaveAccount => _getText('dontHaveAccount');
  String get alreadyHaveAccount => _getText('alreadyHaveAccount');
  String get resetPassword => _getText('resetPassword');
  
  // Home Screen
  String get selectProgrammingLanguage => _getText('selectProgrammingLanguage');
  String get profile => _getText('profile');
  String get startQuiz => _getText('startQuiz');
  String get level => _getText('level');
  String get totalScore => _getText('totalScore');
  String get totalGames => _getText('totalGames');
  String get logout => _getText('logout');
  
  // Game Screen
  String get question => _getText('question');
  String get isThisCodeCorrect => _getText('isThisCodeCorrect');
  String get wrong => _getText('wrong');
  String get correct => _getText('correct');
  String get pass => _getText('pass');
  String get timeRemaining => _getText('timeRemaining');
  String get seconds => _getText('seconds');
  String get easy => _getText('easy');
  String get medium => _getText('medium');
  String get hard => _getText('hard');
  String get combo => _getText('combo');
  String get score => _getText('score');
  String get lives => _getText('lives');
  
  // Result Screen
  String get gameOver => _getText('gameOver');
  String get congratulations => _getText('congratulations');
  String get yourScore => _getText('yourScore');
  String get correctAnswers => _getText('correctAnswers');
  String get wrongAnswers => _getText('wrongAnswers');
  String get maxCombo => _getText('maxCombo');
  String get earnedXP => _getText('earnedXP');
  String get playAgain => _getText('playAgain');
  String get backToHome => _getText('backToHome');
  
  // Feedback Messages
  String get correctAnswer => _getText('correctAnswer');
  String get wrongAnswer => _getText('wrongAnswer');
  String get timeUp => _getText('timeUp');
  String get questionSkipped => _getText('questionSkipped');
  String get remainingPass => _getText('remainingPass');
  String get passRightEarned => _getText('passRightEarned');
  String get comboLost => _getText('comboLost');
  String get loadingQuestions => _getText('loadingQuestions');
  String get noQuestionsFound => _getText('noQuestionsFound');
  
  // Difficulty
  String get easyTime => _getText('easyTime');
  String get mediumTime => _getText('mediumTime');
  String get hardTime => _getText('hardTime');

  // Çeviri verileri
  String _getText(String key) {
    final Map<String, Map<String, String>> _localizedValues = {
      'tr': {
        'appName': 'Kod Quiz Oyunu',
        'welcome': 'Hoş Geldiniz',
        'selectLanguage': 'Dil Seçin',
        'turkish': 'Türkçe',
        'english': 'İngilizce',
        'continue': 'Devam Et',
        'back': 'Geri',
        'yes': 'Evet',
        'no': 'Hayır',
        
        'login': 'Giriş Yap',
        'register': 'Kayıt Ol',
        'email': 'E-posta',
        'username': 'Kullanıcı Adı',
        'password': 'Şifre',
        'forgotPassword': 'Şifremi Unuttum',
        'dontHaveAccount': 'Hesabınız yok mu?',
        'alreadyHaveAccount': 'Zaten hesabınız var mı?',
        'resetPassword': 'Şifre Sıfırla',
        
        'selectProgrammingLanguage': 'Programlama Dili Seçin',
        'profile': 'Profil',
        'startQuiz': 'Quiz Başlat',
        'level': 'Seviye',
        'totalScore': 'Toplam Puan',
        'totalGames': 'Toplam Oyun',
        'logout': 'Çıkış Yap',
        
        'question': 'Soru',
        'isThisCodeCorrect': 'Bu kod doğru mu?',
        'wrong': 'YANLIŞ',
        'correct': 'DOĞRU',
        'pass': 'PAS',
        'timeRemaining': 'Kalan Süre',
        'seconds': 'saniye',
        'easy': 'Kolay',
        'medium': 'Orta',
        'hard': 'Zor',
        'combo': 'COMBO',
        'score': 'Puan',
        'lives': 'Can',
        
        'gameOver': 'Oyun Bitti',
        'congratulations': 'Tebrikler',
        'yourScore': 'Puanınız',
        'correctAnswers': 'Doğru Cevaplar',
        'wrongAnswers': 'Yanlış Cevaplar',
        'maxCombo': 'Maksimum Combo',
        'earnedXP': 'Kazanılan XP',
        'playAgain': 'Tekrar Oyna',
        'backToHome': 'Ana Sayfaya Dön',
        
        'correctAnswer': 'Doğru!',
        'wrongAnswer': 'Yanlış! Combo sıfırlandı 💔',
        'timeUp': '⏱️ Süre doldu!',
        'questionSkipped': '⏭️ Soru atlandı! Kalan pas hakkı:',
        'remainingPass': 'Kalan pas hakkı',
        'passRightEarned': '🎁 Harika! +1 PAS Hakkı Kazandınız! (Toplam:',
        'comboLost': 'Combo sıfırlandı',
        'loadingQuestions': 'Sorular yükleniyor...',
        'noQuestionsFound': 'Bu dil için henüz soru eklenmemiş!',
        
        'easyTime': 'Kolay (30sn)',
        'mediumTime': 'Orta (20sn)',
        'hardTime': 'Zor (15sn)',
      },
      'en': {
        'appName': 'Code Quiz Game',
        'welcome': 'Welcome',
        'selectLanguage': 'Select Language',
        'turkish': 'Turkish',
        'english': 'English',
        'continue': 'Continue',
        'back': 'Back',
        'yes': 'Yes',
        'no': 'No',
        
        'login': 'Login',
        'register': 'Register',
        'email': 'Email',
        'username': 'Username',
        'password': 'Password',
        'forgotPassword': 'Forgot Password',
        'dontHaveAccount': "Don't have an account?",
        'alreadyHaveAccount': 'Already have an account?',
        'resetPassword': 'Reset Password',
        
        'selectProgrammingLanguage': 'Select Programming Language',
        'profile': 'Profile',
        'startQuiz': 'Start Quiz',
        'level': 'Level',
        'totalScore': 'Total Score',
        'totalGames': 'Total Games',
        'logout': 'Logout',
        
        'question': 'Question',
        'isThisCodeCorrect': 'Is this code correct?',
        'wrong': 'WRONG',
        'correct': 'CORRECT',
        'pass': 'PASS',
        'timeRemaining': 'Time Remaining',
        'seconds': 'seconds',
        'easy': 'Easy',
        'medium': 'Medium',
        'hard': 'Hard',
        'combo': 'COMBO',
        'score': 'Score',
        'lives': 'Lives',
        
        'gameOver': 'Game Over',
        'congratulations': 'Congratulations',
        'yourScore': 'Your Score',
        'correctAnswers': 'Correct Answers',
        'wrongAnswers': 'Wrong Answers',
        'maxCombo': 'Max Combo',
        'earnedXP': 'Earned XP',
        'playAgain': 'Play Again',
        'backToHome': 'Back to Home',
        
        'correctAnswer': 'Correct!',
        'wrongAnswer': 'Wrong! Combo reset 💔',
        'timeUp': '⏱️ Time is up!',
        'questionSkipped': '⏭️ Question skipped! Remaining passes:',
        'remainingPass': 'Remaining passes',
        'passRightEarned': '🎁 Great! +1 PASS Right Earned! (Total:',
        'comboLost': 'Combo reset',
        'loadingQuestions': 'Loading questions...',
        'noQuestionsFound': 'No questions added for this language yet!',
        
        'easyTime': 'Easy (30s)',
        'mediumTime': 'Medium (20s)',
        'hardTime': 'Hard (15s)',
      },
    };

    return _localizedValues[languageCode]?[key] ?? key;
  }
}

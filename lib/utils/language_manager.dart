import 'package:flutter/material.dart';

class LanguageManager extends ChangeNotifier {
  String _currentLanguage = 'tr';

  String get currentLanguage => _currentLanguage;

  void setLanguage(String lang) {
    if (lang == _currentLanguage) return;
    _currentLanguage = lang;
    notifyListeners();
  }

  bool get isTurkish => _currentLanguage == 'tr';
  bool get isEnglish => _currentLanguage == 'en';
}

class AppLocalizations {
  final String languageCode;

  const AppLocalizations(this.languageCode);

  bool get _isTr => languageCode == 'tr';

  static AppLocalizations of(BuildContext context, {String fallback = 'tr'}) {
    return AppLocalizations(fallback);
  }

  // Common
  String get appName => _isTr ? 'Kod Quiz Oyunu' : 'Code Quiz Game';
  String get welcome => _isTr ? 'Hoş Geldiniz' : 'Welcome';
  String get turkish => _isTr ? 'Türkçe' : 'Turkish';
  String get english => _isTr ? 'İngilizce' : 'English';
  String get cancel => _isTr ? 'İptal' : 'Cancel';
  String get ok => _isTr ? 'Tamam' : 'OK';
  String get send => _isTr ? 'Gönder' : 'Send';
  String get yes => _isTr ? 'Evet' : 'Yes';
  String get no => _isTr ? 'Hayır' : 'No';
  String get error => _isTr ? 'Hata' : 'Error';
  String get success => _isTr ? 'Başarılı' : 'Success';
  String get loading => _isTr ? 'Yükleniyor...' : 'Loading...';

  // Auth
  String get login => _isTr ? 'Giriş Yap' : 'Login';
  String get register => _isTr ? 'Kayıt Ol' : 'Register';
  String get email => _isTr ? 'E-posta' : 'Email';
  String get username => _isTr ? 'Kullanıcı Adı' : 'Username';
  String get emailOrUsername =>
      _isTr ? 'E-posta / Kullanıcı Adı' : 'Email / Username';
  String get password => _isTr ? 'Şifre' : 'Password';
  String get forgotPassword => _isTr ? 'Şifremi Unuttum' : 'Forgot Password';
  String get dontHaveAccount =>
      _isTr ? 'Hesabınız yok mu?' : "Don't have an account?";
  String get alreadyHaveAccount =>
      _isTr ? 'Zaten hesabınız var mı?' : 'Already have an account?';
  String get resetPassword => _isTr ? 'Şifre Sıfırla' : 'Reset Password';
  String get enterEmailHint =>
      _isTr ? 'E-posta adresinizi girin' : 'Enter your email';
  String get loginMissingCredentials => _isTr
      ? 'Lütfen e-posta/kullanıcı adı ve şifre girin'
      : 'Please enter email/username and password';
  String get registerMissingFields =>
      _isTr ? 'Lütfen tüm alanları doldurun' : 'Please fill in every field';
  String passwordTooShort(int min) => _isTr
      ? 'Şifre en az $min karakter olmalıdır'
      : 'Password must be at least $min characters';
  String get loginFailed => _isTr ? 'Giriş başarısız' : 'Login failed';
  String get emailNotFound => _isTr
      ? 'Bu e-posta ile kayıtlı kullanıcı bulunamadı'
      : 'No user found with this email';
  String get usernameNotFound => _isTr
      ? 'Kullanıcı adı bulunamadı. Lütfen e-posta ile giriş yapın.'
      : 'Username not found. Please try logging in with email.';
  String get wrongCredentials => _isTr
      ? 'Yanlış şifre veya kullanıcı bilgisi'
      : 'Wrong password or credentials';
  String get invalidEmail =>
      _isTr ? 'Geçersiz e-posta formatı' : 'Invalid email format';
  String get tooManyRequests => _isTr
      ? 'Çok fazla deneme. Lütfen sonra tekrar deneyin.'
      : 'Too many attempts. Please try again later.';
  String get passwordResetSent => _isTr
      ? 'Şifre sıfırlama bağlantısı e-postanıza gönderildi!'
      : 'Password reset link sent to your email!';
  String get emailAlreadyUsed =>
      _isTr ? 'Bu e-posta zaten kullanılıyor' : 'This email is already in use';

  // Home
  String get homeGreeting => _isTr
      ? 'Kod bilgini keşfetmeye hazır mısın?'
      : 'Ready to test your coding skills?';
  String get selectProgrammingLanguage =>
      _isTr ? 'Programlama Dili Seçin' : 'Select Programming Language';
  String get startQuiz => _isTr ? 'Quiz Başlat' : 'Start Quiz';
  String get profile => _isTr ? 'Profil' : 'Profile';
  String get level => _isTr ? 'Seviye' : 'Level';
  String get totalScore => _isTr ? 'Toplam Puan' : 'Total Score';
  String get totalGames => _isTr ? 'Toplam Oyun' : 'Total Games';
  String get logout => _isTr ? 'Çıkış Yap' : 'Logout';
  String get userDataMissing =>
      _isTr ? 'Kullanıcı verisi yüklenemedi' : 'Failed to load user data';
  String get chooseLanguageCTA =>
      _isTr ? 'Dil seç ve başla!' : 'Pick a language and get started!';
  String get quickStats => _isTr ? 'Özet İstatistikler' : 'Quick Stats';
  String get accuracy => _isTr ? 'Doğruluk' : 'Accuracy';
  String get speed => _isTr ? 'Hız' : 'Speed';
  String get good => _isTr ? 'İyi' : 'Good';
  String languageQuestionCount(int count) =>
      _isTr ? '$count Soru' : '$count Questions';
  String get missionsTitle => _isTr ? 'Görevler' : 'Missions';
  String get noMissions =>
      _isTr ? 'Görev bulunamadı.' : 'No missions available yet.';
  String get missionDaily => _isTr ? 'Günlük' : 'Daily';
  String get missionWeekly => _isTr ? 'Haftalık' : 'Weekly';
  String missionRewardXp(int value) => '+$value XP';
  String missionRewardPass(int value) => _isTr ? '+$value Pas' : '+$value Pass';
  String get inventory => _isTr ? 'Envanter' : 'Inventory';
  String get passesLabel => _isTr ? 'Pas' : 'Passes';
  String get missionClaim => _isTr ? 'Ödülü Al' : 'Claim Reward';
  String get missionClaimed => _isTr ? 'Ödül Alındı' : 'Claimed';
  String missionClaimSuccess(String reward) =>
      _isTr ? 'Ödül kazandınız: $reward' : 'Reward earned: $reward';
  String get missionClaimError => _isTr
      ? 'Ödül alınamadı. Lütfen tekrar deneyin.'
      : 'Could not claim reward. Please try again.';
  String get passUseError => _isTr
      ? 'Pas hakkı kullanılamadı. Lütfen tekrar deneyin.'
      : 'Unable to use pass. Please try again.';
  String get friendsTitle => _isTr ? 'Arkadaşlar' : 'Friends';
  String get friendsTab => _isTr ? 'Arkadaşlar' : 'Friends';
  String get requestsTab => _isTr ? 'İstekler' : 'Requests';
  String get friendSearchLabel => _isTr ? 'Kullanıcı adı' : 'Username';
  String get friendSearchHint => _isTr ? 'ör. coder_ali' : 'e.g. coder_ali';
  String get friendSearchButton => _isTr ? 'Ara' : 'Search';
  String get friendAddButton => _isTr ? 'Ekle' : 'Add';
  String get friendEnterUsername =>
      _isTr ? 'Lütfen kullanıcı adı girin' : 'Please enter a username';
  String get friendSearchFirst =>
      _isTr ? 'Önce kullanıcıyı arayın' : 'Search for the player first';
  String get friendRequestSent =>
      _isTr ? 'Arkadaşlık isteği gönderildi' : 'Friend request sent';
  String get friendLoginRequired => _isTr
      ? 'Arkadaş eklemek için giriş yapmalısın'
      : 'You need to sign in to add friends';
  String get friendsEmpty => _isTr ? 'Henüz arkadaşın yok' : 'No friends yet';
  String get requestsEmpty =>
      _isTr ? 'Bekleyen istek yok' : 'No pending requests';
  String get friendIncomingHeader =>
      _isTr ? 'Gelen İstekler' : 'Incoming Requests';
  String get friendOutgoingHeader =>
      _isTr ? 'Gönderilen İstekler' : 'Sent Requests';
  String get friendOutgoingEmpty =>
      _isTr ? 'Gönderilmiş istek yok' : 'No sent requests yet';
  String get friendReject => _isTr ? 'Reddet' : 'Decline';
  String get friendAccept => _isTr ? 'Kabul Et' : 'Accept';
  String get friendPending => _isTr ? 'Beklemede' : 'Pending';
  String get friendViewProfile => _isTr ? 'Profili Gör' : 'View Profile';
  String get friendRemove => _isTr ? 'Arkadaşlığı Sil' : 'Remove Friend';
  String friendProfileTitle(String username) =>
      _isTr ? '$username Profili' : '$username Profile';
  String get friendOnline => _isTr ? 'Çevrim içi' : 'Online';
  String friendLastSeen(String time) =>
      _isTr ? 'Son görülme: $time' : 'Last seen: $time';
  String get friendLastSeenUnknown =>
      _isTr ? 'Son görülme bilinmiyor' : 'Last seen unknown';
  String get friendStatusHidden => _isTr ? 'Durum gizli' : 'Status hidden';
  String get profileOnlineVisibility =>
      _isTr ? 'Çevrim içi durumumu paylaş' : 'Share my online status';
  String get profileOnlineVisibilityDesc => _isTr
      ? 'Arkadaşların ne zaman çevrim içi olduğunuzu görebilir.'
      : 'Let friends see when you are online or last active.';
  String get profileOnlineVisibilityUpdated => _isTr
      ? 'Çevrim içi durum tercihi güncellendi'
      : 'Online status preference updated';
  String get messagesTitle => _isTr ? 'Mesajlar' : 'Messages';
  String get messagesInbox => _isTr ? 'Gelen Kutusu' : 'Inbox';
  String get messagesEmpty =>
      _isTr ? 'Henüz mesajın yok.' : 'You have no messages yet.';
  String get messagesUnread => _isTr ? 'Okunmamış' : 'Unread';
  String get messagesFriendsOnly => _isTr
      ? 'Mesajlaşma yalnızca arkadaşlar arasında kullanılabilir.'
      : 'Messaging is available only between friends.';
  String messagesFrom(String username) => _isTr
      ? '$username sana mesaj gönderdi.'
      : '$username sent you a message.';
  String get messagesYouPrefix => _isTr ? 'Sen:' : 'You:';
  String get messagesInputHint =>
      _isTr ? 'Bir mesaj yaz...' : 'Type a message...';
  String get messagesStartChat => _isTr
      ? 'Henüz konuşma yok. İlk mesajı sen gönder!'
      : 'No messages yet. Say hello!';

  // Language selection
  String get languageSelectionTitle => _isTr
      ? 'Hangi dilde test olmak istersin?'
      : 'Which language do you want to practise?';
  String get languageSelectionSubtitle => _isTr
      ? 'Bir programlama dili seç ve kendini test et'
      : 'Choose a programming language and challenge yourself';
  String get languageSelectionAppBar =>
      _isTr ? 'Dil Seçimi' : 'Language Selection';

  // Game
  String get question => _isTr ? 'Soru' : 'Question';
  String get isThisCodeCorrect =>
      _isTr ? 'Bu kod doğru mu?' : 'Is this code correct?';
  String get wrong => _isTr ? 'YANLIŞ' : 'WRONG';
  String get correct => _isTr ? 'DOĞRU' : 'CORRECT';
  String get pass => _isTr ? 'PAS' : 'PASS';
  String get timeRemaining => _isTr ? 'Kalan Süre' : 'Time Remaining';
  String get seconds => _isTr ? 'saniye' : 'seconds';
  String get easy => _isTr ? 'Kolay' : 'Easy';
  String get medium => _isTr ? 'Orta' : 'Medium';
  String get hard => _isTr ? 'Zor' : 'Hard';
  String get combo => _isTr ? 'COMBO' : 'COMBO';
  String get score => _isTr ? 'Puan' : 'Score';
  String get lives => _isTr ? 'Can' : 'Lives';
  String get loadingQuestions =>
      _isTr ? 'Sorular yükleniyor...' : 'Loading questions...';
  String get noQuestionsFound => _isTr
      ? 'Bu dil için henüz soru eklenmemiş!'
      : 'No questions available for this language yet!';
  String get timeUp => _isTr ? 'Süre doldu!' : 'Time is up!';
  String get comboLost => _isTr ? 'Combo sıfırlandı' : 'Combo reset';
  String passEarned(int total) => _isTr
      ? 'Harika! +1 PAS hakkı kazandınız! (Toplam: $total)'
      : 'Great! You earned +1 PASS! (Total: $total)';
  String comboMessage(int comboCount, int points) => _isTr
      ? '${comboCount}x COMBO! +$points puan'
      : '${comboCount}x COMBO! +$points points';
  String wrongAnswer(String explanation) =>
      _isTr ? 'Yanlış! $explanation' : 'Wrong! $explanation';
  String correctAnswer(String explanation) =>
      _isTr ? 'Doğru! $explanation' : 'Correct! $explanation';
  String timeUpWithExplanation(String explanation) =>
      _isTr ? 'Süre doldu! $explanation' : 'Time is up! $explanation';
  String questionSkipped(int remaining) => _isTr
      ? 'Soru atlandı! Kalan pas hakkı: $remaining'
      : 'Question skipped! Passes left: $remaining';
  String timerDifficultyLabel(String difficulty, int seconds) =>
      _isTr ? '$difficulty ($seconds sn)' : '$difficulty (${seconds}s)';
  String get learningViewCard =>
      _isTr ? 'Kod kartını aç' : 'Open learning card';
  String get learningCardTitle => _isTr ? 'Kod Kartı' : 'Learning Card';
  String get learningStatusCorrect => _isTr ? 'Doğru' : 'Correct';
  String get learningStatusIncorrect => _isTr ? 'Yanlış' : 'Incorrect';
  String get learningKeyPoints =>
      _isTr ? 'Öne çıkan noktalar' : 'Key takeaways';
  String get learningNoExplanation => _isTr
      ? 'Bu soru için açıklama henüz eklenmemiş.'
      : 'No explanation has been added yet.';
  String get learningTags => _isTr ? 'Etiketler' : 'Tags';
  String get learningClose => _isTr ? 'Anladım' : 'Got it';

  // Result
  String get gameOver => _isTr ? 'Oyun Bitti' : 'Game Over';
  String get congratulations => _isTr ? 'Tebrikler' : 'Congratulations';
  String get yourScore => _isTr ? 'Puanınız' : 'Your Score';
  String get correctAnswers => _isTr ? 'Doğru Cevaplar' : 'Correct Answers';
  String get wrongAnswers => _isTr ? 'Yanlış Cevaplar' : 'Wrong Answers';
  String get maxCombo => _isTr ? 'Maksimum Combo' : 'Max Combo';
  String get earnedXP => _isTr ? 'Kazanılan XP' : 'Earned XP';
  String get playAgain => _isTr ? 'Tekrar Oyna' : 'Play Again';
  String get backToHome => _isTr ? 'Ana Sayfaya Dön' : 'Back to Home';
  String get achievementsUnlocked =>
      _isTr ? 'Yeni başarımlar açıldı!' : 'New achievements unlocked!';
  String get leaderboardTitle => _isTr ? 'Liderlik Tablosu' : 'Leaderboard';
  String get leaderboardGlobal => _isTr ? 'Genel' : 'Global';
  String get leaderboardLanguage => _isTr ? 'Dil' : 'Language';
  String get leaderboardMyRank => _isTr ? 'Sıram' : 'My Rank';
  String get leaderboardNoData =>
      _isTr ? 'Henüz liderlik verisi yok.' : 'No leaderboard data yet.';
  String get leaderboardScore => _isTr ? 'Puan' : 'Score';
  String get leaderboardRank => _isTr ? 'Sıra' : 'Rank';
  String get leaderboardYou => _isTr ? 'Sen' : 'You';
  String leaderboardMessageTitle(String username) =>
      _isTr ? '$username oyuncusuna mesaj' : 'Message $username';
  String get leaderboardMessageHint =>
      _isTr ? 'Kısa bir mesaj yaz...' : 'Write a short message...';
  String get leaderboardMessageSend => _isTr ? 'Gönder' : 'Send';
  String get leaderboardMessageSent =>
      _isTr ? 'Mesaj gönderildi!' : 'Message sent!';
  String get leaderboardMessageTooShort => _isTr
      ? 'Mesaj en az 3 karakter olmalı'
      : 'Message must be at least 3 characters long.';
  String get leaderboardMessageAction =>
      _isTr ? 'Mesaj gönder' : 'Send message';
  String get relativeJustNow => _isTr ? 'az önce' : 'just now';
  String relativeMinutes(int minutes) => _isTr
      ? '$minutes dakika önce'
      : minutes == 1
          ? '1 minute ago'
          : '$minutes minutes ago';
  String relativeHours(int hours) => _isTr
      ? '$hours saat önce'
      : hours == 1
          ? '1 hour ago'
          : '$hours hours ago';
  String relativeDays(int days) => _isTr
      ? '$days gün önce'
      : days == 1
          ? '1 day ago'
          : '$days days ago';
  String relativeDate(String formatted) => formatted;
  String performanceMessage(int percentage) {
    if (percentage >= 90) {
      return _isTr ? 'Mükemmel!' : 'Excellent!';
    } else if (percentage >= 70) {
      return _isTr ? 'Harika!' : 'Great job!';
    } else if (percentage >= 50) {
      return _isTr ? 'İyi!' : 'Nice!';
    }
    return _isTr ? 'Pratik yapmaya devam!' : 'Keep practising!';
  }

  // Profile
  String get profileTitle => _isTr ? 'Profilim' : 'My Profile';
  String get signOut => _isTr ? 'Çıkış Yap' : 'Sign Out';
  String get signOutQuestion => _isTr
      ? 'Çıkış yapmak istediğinize emin misiniz?'
      : 'Are you sure you want to sign out?';
  String get experience => _isTr ? 'Deneyim' : 'Experience';
  String get achievements => _isTr ? 'Başarımlar' : 'Achievements';
  String get activity => _isTr ? 'Oyun Geçmişi' : 'Game Activity';
  String get noAchievements =>
      _isTr ? 'Henüz başarım bulunmuyor' : 'No achievements yet';
}

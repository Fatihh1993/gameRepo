import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import '../utils/static_data.dart';

/// Basit ve çalışan Firebase Authentication servisi
class AuthServiceV2 {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mevcut kullanıcı
  User? get currentUser => _auth.currentUser;
  
  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 🔐 EMAIL/ŞİFRE İLE KAYIT
  Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    User? user;
    bool usersCollectionSuccess = false;
    bool usernamesCollectionSuccess = false;

    try {
      print('📝 Kayıt başlıyor...');
      print('📧 Email: $email');
      print('👤 Username: $username');

      // Önce username'in kullanılıp kullanılmadığını kontrol et
      final existingUsername = await _firestore
          .collection('usernames')
          .doc(username)
          .get();

      if (existingUsername.exists) {
        throw Exception('Bu kullanıcı adı zaten kullanılıyor');
      }

      // Firebase Auth ile kayıt
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      user = credential.user!;
      print('✅ Firebase Auth başarılı! UID: ${user.uid}');

      // Firestore'a kullanıcı profili kaydet
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'username': username,
          'country': 'TR',
          'experience': 0,
          'currentLevel': 1,
          'highScore': 0,
          'totalGamesPlayed': 0,
          'unlockedAchievements': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
        usersCollectionSuccess = true;
        print('✅ Firestore users collection\'a yazıldı');
      } catch (firestoreError) {
        print('❌ Firestore users hatası: $firestoreError');
      }

      // Username mapping için ayrı collection (KRITIK!)
      try {
        await _firestore.collection('usernames').doc(username).set({
          'uid': user.uid,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        usernamesCollectionSuccess = true;
        print('✅ Firestore usernames collection\'a yazıldı');
      } catch (usernameError) {
        print('❌ Firestore usernames hatası: $usernameError');
      }

      // Eğer her iki collection'a yazma başarısız olduysa uyarı ver
      if (!usersCollectionSuccess || !usernamesCollectionSuccess) {
        print('⚠️ UYARI: Firestore yazma işlemi eksik!');
        print('   Users Collection: ${usersCollectionSuccess ? '✅' : '❌'}');
        print('   Usernames Collection: ${usernamesCollectionSuccess ? '✅' : '❌'}');
        
        // En az users collection başarılı olmalı
        if (!usersCollectionSuccess) {
          throw Exception('Profil oluşturulamadı, lütfen tekrar deneyin');
        }
        
        // Usernames başarısız ise kullanıcıyı uyar ama devam et
        if (!usernamesCollectionSuccess) {
          print('⚠️ Kullanıcı adı ile giriş şu an çalışmayabilir, email kullanın');
        }
      }

      print('🎉 Kayıt tamamlandı!');
      return user;
    } catch (e) {
      print('❌ Kayıt hatası: $e');
      
      // Eğer auth başarılı olmuşsa ama Firestore'a yazarken hata olduysa,
      // kullanıcıyı sil ve hatayı fırlat (tutarsız durum olmasın)
      if (user != null && !usersCollectionSuccess) {
        print('⚠️ Tutarsız durum! Kullanıcı siliniyor...');
        try {
          await user.delete();
          print('✅ Kullanıcı Firebase Auth\'tan silindi');
        } catch (deleteError) {
          print('❌ Kullanıcı silinemedi: $deleteError');
        }
      }
      
      rethrow;
    }
  }

  // 🔐 EMAIL/ŞİFRE İLE GİRİŞ (veya USERNAME/ŞİFRE)
  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Giriş yapılıyor...');
      print('📧 Email/Username: $email');

      String loginEmail = email.trim();
      
      // Eğer @ işareti yoksa, bu bir kullanıcı adı olabilir
      if (!loginEmail.contains('@')) {
        print('👤 Kullanıcı adı ile giriş deneniyor: $loginEmail');
        
        // Firestore'dan kullanıcı adına karşılık gelen email'i bul
        final usernameDoc = await _firestore
            .collection('usernames')
            .doc(loginEmail)
            .get();
        
        if (usernameDoc.exists) {
          final data = usernameDoc.data();
          if (data != null && data.containsKey('email')) {
            loginEmail = data['email'] as String;
            print('✅ Kullanıcı adı bulundu, email: $loginEmail');
          } else {
            print('❌ Username mapping verisi hatalı');
            throw Exception('Kullanıcı adı verisi hatalı. Lütfen email ile giriş yapın.');
          }
        } else {
          print('❌ Kullanıcı adı bulunamadı: $loginEmail');
          print('💡 İpucu: Email ile giriş yapmayı deneyin');
          throw Exception('Kullanıcı adı bulunamadı. Email ile giriş yapmayı deneyin.');
        }
      }

      print('🔑 Firebase Auth ile giriş yapılıyor: $loginEmail');
      final credential = await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      print('✅ Giriş başarılı! UID: ${credential.user?.uid}');
      return credential.user;
    } catch (e) {
      print('❌ Giriş hatası: $e');
      rethrow;
    }
  }

  // 🔑 ŞİFRE SIFIRLAMA
  Future<void> resetPassword(String email) async {
    try {
      print('📧 Şifre sıfırlama email\'i gönderiliyor: $email');
      
      await _auth.sendPasswordResetEmail(email: email);
      
      print('✅ Email gönderildi!');
    } catch (e) {
      print('❌ Şifre sıfırlama hatası: $e');
      rethrow;
    }
  }

  // 👤 KULLANICI PROFİLİNİ GETİR
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        print('⚠️ Kullanıcı profili bulunamadı: $uid');
        return null;
      }

      final data = doc.data()!;
      return UserModel(
        id: uid,
        username: data['username'] ?? '',
        email: data['email'] ?? '',
        experience: data['experience'] ?? 0,
        level: data['currentLevel'] ?? 1,
        highScore: data['highScore'] ?? 0,
        totalGamesPlayed: data['totalGamesPlayed'] ?? 0,
        unlockedAchievements: List<String>.from(data['unlockedAchievements'] ?? []),
      );
    } catch (e) {
      print('❌ Profil getirme hatası: $e');
      return null;
    }
  }

  // 💾 OYUN SONUCUNU KAYDET
  Future<List<String>> saveGameResult({
    required String uid,
    required String language,
    required int score,
    required int earnedXP,
    required int correctAnswers,
    required int wrongAnswers,
    required int maxCombo,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final newAchievements = <String>[];

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) {
          throw Exception('Kullanıcı profili bulunamadı');
        }

        final data = snapshot.data()!;

        final currentExperience = (data['experience'] ?? 0) as int;
        final currentGames = (data['totalGamesPlayed'] ?? 0) as int;
        final currentHighScore = (data['highScore'] ?? 0) as int;
        final currentTotalScore = (data['totalScore'] ?? 0) as int;
        final currentTotalCorrect = (data['totalCorrect'] ?? 0) as int;
        final currentTotalWrong = (data['totalWrong'] ?? 0) as int;
        final currentBestCombo = (data['bestCombo'] ?? 0) as int;
        final currentLevel = (data['currentLevel'] ?? 1) as int;

        final Set<String> languagesPlayed = {
          for (final item in (data['languagesPlayed'] as List<dynamic>? ?? []))
            item.toString().toLowerCase(),
        };
        languagesPlayed.add(language.toLowerCase());

        final Set<String> unlocked = {
          for (final item
              in (data['unlockedAchievements'] as List<dynamic>? ?? []))
            item.toString(),
        };

        final updatedGames = currentGames + 1;
        final updatedExperience = currentExperience + earnedXP;
        final updatedHighScore = max(currentHighScore, score);
        final updatedTotalScore = currentTotalScore + score;
        final updatedTotalCorrect = currentTotalCorrect + correctAnswers;
        final updatedTotalWrong = currentTotalWrong + wrongAnswers;
        final updatedBestCombo = max(currentBestCombo, maxCombo);
        final computedLevel = max(_calculateLevel(updatedExperience), currentLevel);

        final achieved = _evaluateAchievements(
          totalGames: updatedGames,
          highScore: updatedHighScore,
          bestCombo: updatedBestCombo,
          experience: updatedExperience,
          totalCorrect: updatedTotalCorrect,
          totalWrong: updatedTotalWrong,
          languagesPlayed: languagesPlayed,
          lastGameCorrect: correctAnswers,
          lastGameWrong: wrongAnswers,
          lastGameMaxCombo: maxCombo,
          lastGameScore: score,
        );

        for (final achievement in achieved) {
          if (unlocked.add(achievement)) {
            newAchievements.add(achievement);
          }
        }

        transaction.update(userRef, {
          'totalGamesPlayed': updatedGames,
          'experience': updatedExperience,
          'highScore': updatedHighScore,
          'totalScore': updatedTotalScore,
          'totalCorrect': updatedTotalCorrect,
          'totalWrong': updatedTotalWrong,
          'bestCombo': updatedBestCombo,
          'languagesPlayed': languagesPlayed.toList(),
          'unlockedAchievements': unlocked.toList(),
          'currentLevel': computedLevel,
          'lastGameAt': FieldValue.serverTimestamp(),
          'lastGame': {
            'correct': correctAnswers,
            'wrong': wrongAnswers,
            'score': score,
            'maxCombo': maxCombo,
            'playedAt': FieldValue.serverTimestamp(),
          },
        });
      });

      print('✅ Oyun sonucu kaydedildi');
      if (newAchievements.isNotEmpty) {
        print('🏆 Yeni başarımlar: $newAchievements');
      }
      return newAchievements;
    } catch (e) {
      print('❌ Oyun sonucu kaydetme hatası: $e');
      rethrow;
    }
  }

  Future<List<String>> getOrSyncAchievements(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      return [];
    }

    final data = doc.data()!;

    final totalGames = ((data['totalGamesPlayed'] ?? 0) as num).toInt();
    final highScore = ((data['highScore'] ?? 0) as num).toInt();
    final bestCombo = ((data['bestCombo'] ?? 0) as num).toInt();
    final experience = ((data['experience'] ?? 0) as num).toInt();
    final totalCorrect = ((data['totalCorrect'] ?? 0) as num).toInt();
    final totalWrong = ((data['totalWrong'] ?? 0) as num).toInt();
    final languagesPlayed = {
      for (final lang in (data['languagesPlayed'] as List<dynamic>? ?? []))
        lang.toString().toLowerCase(),
    };

    final lastGame =
        data['lastGame'] is Map<String, dynamic> ? data['lastGame'] as Map<String, dynamic> : <String, dynamic>{};
    final lastGameCorrect = ((lastGame['correct'] ?? 0) as num).toInt();
    final lastGameWrong = ((lastGame['wrong'] ?? 0) as num).toInt();
    final lastGameScore = ((lastGame['score'] ?? 0) as num).toInt();
    final lastGameMaxCombo = ((lastGame['maxCombo'] ?? 0) as num).toInt();

    final Set<String> unlocked = {
      for (final item
          in (data['unlockedAchievements'] as List<dynamic>? ?? []))
        item.toString(),
    };

    final achieved = _evaluateAchievements(
      totalGames: totalGames,
      highScore: highScore,
      bestCombo: bestCombo,
      experience: experience,
      totalCorrect: totalCorrect,
      totalWrong: totalWrong,
      languagesPlayed: languagesPlayed,
      lastGameCorrect: lastGameCorrect,
      lastGameWrong: lastGameWrong,
      lastGameMaxCombo: lastGameMaxCombo,
      lastGameScore: lastGameScore,
    );

    var changed = false;
    for (final id in achieved) {
      if (unlocked.add(id)) {
        changed = true;
      }
    }

    if (changed) {
      await doc.reference.update({'unlockedAchievements': unlocked.toList()});
    }

    return unlocked.toList();
  }

  int _calculateLevel(int experience) => (experience ~/ 1000) + 1;

  Set<String> _evaluateAchievements({
    required int totalGames,
    required int highScore,
    required int bestCombo,
    required int experience,
    required int totalCorrect,
    required int totalWrong,
    required Set<String> languagesPlayed,
    required int lastGameCorrect,
    required int lastGameWrong,
    required int lastGameMaxCombo,
    required int lastGameScore,
  }) {
    final unlocked = <String>{};
    final level = _calculateLevel(experience);

    if (totalGames >= 1) unlocked.add('first_win');
    if (totalGames >= 10) unlocked.add('games_10');
    if (totalGames >= 50) unlocked.add('games_50');

    if (lastGameWrong == 0 && lastGameCorrect > 0) {
      unlocked.add('perfect_game');
    }

    if (bestCombo >= 5 || lastGameMaxCombo >= 5) {
      unlocked.add('combo_5');
    }
    if (bestCombo >= 10 || lastGameMaxCombo >= 10) {
      unlocked.add('combo_10');
    }

    if (highScore >= 500 || lastGameScore >= 500) {
      unlocked.add('high_score_500');
    }
    if (highScore >= 1000 || lastGameScore >= 1000) {
      unlocked.add('high_score_1000');
    }

    if (level >= 10) unlocked.add('level_10');
    if (level >= 25) unlocked.add('level_25');

    if (languagesPlayed.length >= StaticData.languages.length) {
      unlocked.add('all_languages');
    }

    return unlocked;
  }

  // 🚪 ÇIKIŞ YAP
  Future<void> signOut() async {
    await _auth.signOut();
    print('👋 Çıkış yapıldı');
  }
}

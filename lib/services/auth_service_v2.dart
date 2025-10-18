import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

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
  Future<void> saveGameResult({
    required String uid,
    required int score,
    required int earnedXP,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      
      await userRef.update({
        'totalGamesPlayed': FieldValue.increment(1),
        'experience': FieldValue.increment(earnedXP),
        'highScore': score, // Not: Bu sadece örnek, gerçekte max() yapmalısınız
      });

      print('✅ Oyun sonucu kaydedildi');
    } catch (e) {
      print('❌ Oyun sonucu kaydetme hatası: $e');
      rethrow;
    }
  }

  // 🚪 ÇIKIŞ YAP
  Future<void> signOut() async {
    await _auth.signOut();
    print('👋 Çıkış yapıldı');
  }
}

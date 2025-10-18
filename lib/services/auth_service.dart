import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mevcut kullanıcı stream'i
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Mevcut kullanıcı
  User? get currentUser => _auth.currentUser;

  // Email/Password ile kayıt
  Future<UserCredential?> register(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Kayıt hatası: $e');
      rethrow;
    }
  }

  // Email/Password ile giriş
  Future<UserCredential?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Giriş başarılı, Firestore'da profil var mı kontrol et
      final uid = credential.user!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        print('⚠️ Firestore\'da profil yok, oluşturuluyor...');
        // Email'den username oluştur (@ işaretinden önceki kısım)
        final username = email.split('@')[0];
        
        await _firestore.collection('users').doc(uid).set({
          'username': username,
          'email': email,
          'country': 'TR',
          'experience': 0,
          'currentLevel': 1,
          'highScore': 0,
          'totalGamesPlayed': 0,
          'unlockedAchievements': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        await _firestore.collection('usernames').doc(username).set({
          'uid': uid,
          'email': email,
          'country': 'TR',
          'username': username,
        });
        
        print('✅ Firestore profili oluşturuldu: $username');
      }
      
      return credential;
    } catch (e) {
      print('Giriş hatası: $e');
      rethrow;
    }
  }

  // Username ile kayıt (Firestore'da profil oluştur)
  Future<UserCredential?> registerWithUsername({
    required String username,
    required String email,
    required String password,
    String country = 'TR',
  }) async {
    UserCredential? credential;
    try {
      print('📝 Kayıt başlıyor: $username / $email');
      
      // Kullanıcı adı kontrolü (hem users hem usernames'de)
      final usernameDoc = await _firestore
          .collection('usernames')
          .doc(username)
          .get();

      if (usernameDoc.exists) {
        throw Exception('Bu kullanıcı adı zaten kullanılıyor');
      }

      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw Exception('Bu kullanıcı adı zaten kullanılıyor');
      }

      print('✅ Kullanıcı adı uygun');
      
      // Firebase Auth ile kayıt
      print('🔐 Firebase Auth\'a kayıt yapılıyor...');
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      print('✅ Firebase Auth başarılı. UID: $uid');

      // Firestore'da users collection'a profil oluştur
      print('📄 Firestore users collection\'a yazılıyor...');
      await _firestore.collection('users').doc(uid).set({
        'username': username,
        'email': email,
        'country': country,
        'experience': 0,
        'currentLevel': 1,
        'highScore': 0,
        'totalGamesPlayed': 0,
        'unlockedAchievements': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ users collection\'a yazıldı');

      // usernames collection'a da ekle (hızlı arama için)
      print('📄 Firestore usernames collection\'a yazılıyor...');
      await _firestore.collection('usernames').doc(username).set({
        'uid': uid,
        'email': email,
        'country': country,
        'username': username,
      });
      print('✅ usernames collection\'a yazıldı');
      print('🎉 Kayıt tamamlandı!');

      return credential;
    } catch (e, stackTrace) {
      print('❌ Kayıt hatası: $e');
      print('📋 Stack trace: $stackTrace');
      
      // Eğer Firebase Auth'da kullanıcı oluşturulduysa ama Firestore'a yazılamadıysa
      if (credential != null && credential.user != null) {
        print('⚠️ Firebase Auth\'da kullanıcı oluşturuldu ama Firestore hatası var!');
        print('🔄 Firestore\'a tekrar yazılmaya çalışılıyor...');
        
        try {
          final uid = credential.user!.uid;
          
          await _firestore.collection('users').doc(uid).set({
            'username': username,
            'email': email,
            'country': country,
            'experience': 0,
            'currentLevel': 1,
            'highScore': 0,
            'totalGamesPlayed': 0,
            'unlockedAchievements': [],
            'createdAt': FieldValue.serverTimestamp(),
          });

          await _firestore.collection('usernames').doc(username).set({
            'uid': uid,
            'email': email,
            'country': country,
            'username': username,
          });
          
          print('✅ Firestore\'a tekrar yazma başarılı!');
          return credential;
        } catch (firestoreError) {
          print('❌ Firestore\'a tekrar yazma başarısız: $firestoreError');
        }
      }
      
      rethrow;
    }
  }

  // Username ile giriş (Firestore'dan email bul)
  Future<UserCredential?> loginWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      print('📝 Username ile giriş başlıyor: $username');
      String? email;
      
      // Önce usernames collection'ında ara
      print('🔍 usernames collection kontrol ediliyor...');
      final usernameDoc = await _firestore
          .collection('usernames')
          .doc(username)
          .get();

      if (usernameDoc.exists) {
        print('✅ usernames collection\'da bulundu');
        // usernames collection'ında bulundu
        final uid = usernameDoc.data()?['uid'] as String?;
        print('📋 UID: $uid');
        
        if (uid != null) {
          // uid ile users collection'ından email al
          final userDoc = await _firestore.collection('users').doc(uid).get();
          if (userDoc.exists) {
            email = userDoc.data()?['email'] as String?;
            print('📧 Email bulundu (users): $email');
          }
        } else {
          // Direkt email varsa al
          email = usernameDoc.data()?['email'] as String?;
          print('📧 Email bulundu (usernames): $email');
        }
      } else {
        print('❌ usernames collection\'da bulunamadı');
        // usernames'de bulunamadı, users collection'ında ara
        print('🔍 users collection kontrol ediliyor...');
        final usernameQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();

        if (usernameQuery.docs.isNotEmpty) {
          email = usernameQuery.docs.first.data()['email'] as String?;
          print('✅ users collection\'da bulundu');
          print('📧 Email: $email');
        } else {
          print('❌ users collection\'da da bulunamadı');
        }
      }

      if (email == null) {
        print('❌ Email bulunamadı! Kullanıcı mevcut değil.');
        throw Exception('Kullanıcı bulunamadı');
      }

      print('🔐 Firebase Auth ile giriş yapılıyor...');
      print('📧 Email: $email');
      
      // Firebase Auth ile giriş
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Giriş başarılı! UID: ${credential.user?.uid}');
      return credential;
    } catch (e) {
      print('❌ Giriş hatası detayı: $e');
      rethrow;
    }
  }

  // Şifre sıfırlama email'i gönder (username veya email ile)
  Future<void> resetPassword(String usernameOrEmail) async {
    try {
      String? email;

      // Email formatı kontrolü
      if (usernameOrEmail.contains('@')) {
        email = usernameOrEmail;
      } else {
        // Username ise, email'i Firestore'dan al
        final usernameDoc = await _firestore
            .collection('usernames')
            .doc(usernameOrEmail)
            .get();

        if (usernameDoc.exists) {
          email = usernameDoc.data()?['email'] as String?;
        } else {
          final usernameQuery = await _firestore
              .collection('users')
              .where('username', isEqualTo: usernameOrEmail)
              .limit(1)
              .get();

          if (usernameQuery.docs.isNotEmpty) {
            email = usernameQuery.docs.first.data()['email'] as String?;
          }
        }
      }

      if (email == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      await _auth.sendPasswordResetEmail(email: email);
      print('✅ Şifre sıfırlama email\'i gönderildi: $email');
    } catch (e) {
      print('❌ Şifre sıfırlama hatası: $e');
      rethrow;
    }
  }

  // Kullanıcı profilini getir
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (!doc.exists) return null;
      
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
      print('Profil getirme hatası: $e');
      return null;
    }
  }

  // Kullanıcı profili oluştur (Firebase Auth'da var ama Firestore'da yoksa)
  Future<void> createUserProfile({
    required String uid,
    required String username,
    required String email,
    String country = 'TR',
  }) async {
    try {
      print('📝 Firestore profili oluşturuluyor...');
      
      // users collection'a ekle
      await _firestore.collection('users').doc(uid).set({
        'username': username,
        'email': email,
        'country': country,
        'experience': 0,
        'currentLevel': 1,
        'highScore': 0,
        'totalGamesPlayed': 0,
        'unlockedAchievements': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // usernames collection'a ekle
      await _firestore.collection('usernames').doc(username).set({
        'uid': uid,
        'email': email,
        'country': country,
        'username': username,
      });
      
      print('✅ Firestore profili oluşturuldu!');
    } catch (e) {
      print('❌ Profil oluşturma hatası: $e');
      rethrow;
    }
  }

  // Kullanıcı profilini güncelle
  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      print('Profil güncelleme hatası: $e');
      rethrow;
    }
  }

  // Oyun sonucu kaydet
  Future<void> saveGameResult({
    required String uid,
    required int score,
    required int earnedXP,
    required String languageName,
    required int correctAnswers,
    required int wrongAnswers,
    required int maxCombo,
  }) async {
    try {
      // Kullanıcı verilerini getir
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data()!;
      
      final currentXP = userData['experience'] ?? 0;
      final currentHighScore = userData['highScore'] ?? 0;
      final currentGamesPlayed = userData['totalGamesPlayed'] ?? 0;
      
      // Güncellenecek veriler
      final updates = <String, dynamic>{
        'experience': currentXP + earnedXP,
        'totalGamesPlayed': currentGamesPlayed + 1,
      };
      
      // High score güncelle
      if (score > currentHighScore) {
        updates['highScore'] = score;
      }
      
      // Level hesapla (her 1000 XP = 1 level)
      final newLevel = ((currentXP + earnedXP) / 1000).floor() + 1;
      if (newLevel > (userData['currentLevel'] ?? 1)) {
        updates['currentLevel'] = newLevel;
      }
      
      // Kullanıcı verilerini güncelle
      await _firestore.collection('users').doc(uid).update(updates);
      
      // Oyun geçmişine ekle
      await _firestore.collection('gameHistory').add({
        'uid': uid,
        'score': score,
        'earnedXP': earnedXP,
        'language': languageName,
        'correctAnswers': correctAnswers,
        'wrongAnswers': wrongAnswers,
        'maxCombo': maxCombo,
        'playedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Oyun sonucu kaydetme hatası: $e');
      rethrow;
    }
  }

  // Başarı kilidi aç
  Future<void> unlockAchievement(String uid, String achievementId) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'unlockedAchievements': FieldValue.arrayUnion([achievementId]),
      });
    } catch (e) {
      print('Başarı kilidi açma hatası: $e');
      rethrow;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Mevcut kullanıcılar için username mapping'i oluşturan yardımcı fonksiyon
/// Sadece bir kez çalıştırılmalı, eksik username mapping'leri düzeltir
class UsernameFixer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tüm users collection'daki kullanıcıları tarayıp eksik username mapping'leri oluşturur
  Future<void> fixAllUsernames() async {
    print('🔧 Username mapping düzeltme başlıyor...');
    
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      print('📊 Toplam kullanıcı sayısı: ${usersSnapshot.docs.length}');

      int fixed = 0;
      int skipped = 0;
      int errors = 0;

      for (var doc in usersSnapshot.docs) {
        try {
          final data = doc.data();
          final uid = data['uid'] as String?;
          final email = data['email'] as String?;
          final username = data['username'] as String?;

          if (uid == null || email == null || username == null) {
            print('⚠️ Eksik veri, atlanıyor: ${doc.id}');
            skipped++;
            continue;
          }

          // Username mapping'in zaten var olup olmadığını kontrol et
          final usernameDoc = await _firestore
              .collection('usernames')
              .doc(username)
              .get();

          if (usernameDoc.exists) {
            print('✅ Username mapping zaten var: $username');
            skipped++;
            continue;
          }

          // Yeni username mapping oluştur
          await _firestore.collection('usernames').doc(username).set({
            'uid': uid,
            'email': email,
          });

          print('🔧 Username mapping oluşturuldu: $username -> $email');
          fixed++;
        } catch (e) {
          print('❌ Hata (${doc.id}): $e');
          errors++;
        }
      }

      print('');
      print('📊 İşlem tamamlandı!');
      print('✅ Düzeltilen: $fixed');
      print('⏭️ Atlanan: $skipped');
      print('❌ Hatalı: $errors');
    } catch (e) {
      print('❌ Genel hata: $e');
      rethrow;
    }
  }

  /// Tek bir kullanıcı için username mapping oluşturur
  Future<void> fixUsername(String uid) async {
    print('🔧 Username mapping düzeltiliyor: $uid');
    
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        print('❌ Kullanıcı bulunamadı: $uid');
        return;
      }

      final data = userDoc.data()!;
      final email = data['email'] as String?;
      final username = data['username'] as String?;

      if (email == null || username == null) {
        print('❌ Eksik email veya username: $uid');
        return;
      }

      await _firestore.collection('usernames').doc(username).set({
        'uid': uid,
        'email': email,
      });

      print('✅ Username mapping oluşturuldu: $username -> $email');
    } catch (e) {
      print('❌ Hata: $e');
      rethrow;
    }
  }

  /// Tüm username mapping'leri listeler (debug için)
  Future<void> listAllUsernameMappings() async {
    print('📋 Username mapping listesi:');
    
    try {
      final snapshot = await _firestore.collection('usernames').get();
      print('📊 Toplam mapping sayısı: ${snapshot.docs.length}');
      print('');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('👤 Username: ${doc.id}');
        print('   📧 Email: ${data['email']}');
        print('   🆔 UID: ${data['uid']}');
        print('');
      }
    } catch (e) {
      print('❌ Hata: $e');
      rethrow;
    }
  }
}

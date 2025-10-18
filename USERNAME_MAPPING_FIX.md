# 🔧 Username Mapping Sorun Giderme Rehberi

## Sorun Nedir?

Kullanıcılar **kullanıcı adı** ile giriş yapmaya çalıştığında "Kullanıcı adı bulunamadı" hatası alınıyor. Bu, Firestore'da `usernames` collection'ında ilgili username-email mapping'inin eksik olmasından kaynaklanıyor.

## Neden Oluyor?

1. **Kayıt sırasında Firestore hatası**: Kullanıcı Firebase Auth'a kaydolmuş ama Firestore'a profil yazılırken hata olmuş
2. **Eski kullanıcılar**: Username mapping özelliği eklenmeden önce kaydolmuş kullanıcılar
3. **Manuel veri silme**: Firestore'dan manuel olarak username mapping silinmiş

## Çözüm Adımları

### Yöntem 1: Uygulama İçi Debug Ekranı (Önerilen)

1. Uygulamayı çalıştırın
2. Herhangi bir kullanıcı ile giriş yapın (email ile)
3. Ana ekranda sağ üstteki **🐛 (bug)** ikonuna tıklayın
4. Debug ekranında şu butonları kullanın:

   - **Mevcut Kullanıcı**: Oturum açık kullanıcının bilgilerini ve mapping durumunu gösterir
   - **Tüm Kullanıcılar**: Tüm kullanıcıları ve mapping durumlarını listeler
   - **Tüm Mappings**: Mevcut tüm username mapping'leri gösterir
   - **Beni Düzelt** 🔧: Sadece oturum açık kullanıcı için mapping oluşturur
   - **Hepsini Düzelt** 🔴: Tüm kullanıcılar için eksik mapping'leri oluşturur

### Yöntem 2: Firebase Console'dan Manuel Kontrol

1. [Firebase Console](https://console.firebase.google.com/) açın
2. Projenizi seçin
3. **Firestore Database** bölümüne gidin
4. `users` collection'ını inceleyin
5. `usernames` collection'ını kontrol edin
6. Her kullanıcı için username mapping'in olup olmadığını kontrol edin

**Username mapping formatı:**
```
usernames/
  ├── johndoe/
  │   ├── uid: "abc123..."
  │   └── email: "john@example.com"
  ├── janedoe/
  │   ├── uid: "xyz789..."
  │   └── email: "jane@example.com"
```

### Yöntem 3: Kod ile Manuel Düzeltme

`lib/utils/username_fixer.dart` dosyasını kullanarak terminal'den de çalıştırabilirsiniz:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'lib/utils/username_fixer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final fixer = UsernameFixer();
  
  // Tüm kullanıcıları düzelt
  await fixer.fixAllUsernames();
  
  // Veya sadece listele
  // await fixer.listAllUsernameMappings();
}
```

## Değişiklikler ve İyileştirmeler

### 1. AuthServiceV2 İyileştirmeleri

**✅ Kayıt sırasında username kontrolü:**
- Kayıt olmadan önce username'in kullanılıp kullanılmadığı kontrol ediliyor
- Hata durumunda Firebase Auth'daki kullanıcı siliniyor (tutarsız durum önleniyor)
- Her iki collection'a (users ve usernames) yazma başarılı olmalı

**✅ Giriş sırasında detaylı kontrol:**
- Username mapping'in varlığı ve içeriği kontrol ediliyor
- Hata durumunda daha açıklayıcı mesajlar veriliyor
- Kullanıcıya "email ile giriş yap" önerisi gösteriliyor

### 2. LoginScreenV2 İyileştirmeleri

**✅ Daha iyi hata mesajları:**
- "Kullanıcı adı bulunamadı" → "Kullanıcı adı bulunamadı. Email ile giriş yapmayı deneyin."
- "Bu kullanıcı adı zaten kullanılıyor" hatası eklendi
- "Profil oluşturulamadı" hatası eklendi

### 3. Yeni Araçlar

**✅ Username Fixer Utility:**
- Tüm kullanıcılar için eksik mapping'leri bulup düzeltir
- Tek bir kullanıcı için düzeltme yapabilir
- Mevcut mapping'leri listeleyebilir

**✅ Debug Username Screen:**
- Gerçek zamanlı username mapping kontrolü
- Tek tıkla düzeltme
- Tüm kullanıcıların ve mapping'lerin listesi

## Test Senaryoları

### Senaryo 1: Yeni Kullanıcı Kaydı

1. Yeni bir kullanıcı oluşturun (email: test@example.com, username: testuser)
2. Debug ekranına gidin
3. "Mevcut Kullanıcı" butonuna tıklayın
4. Username mapping'in oluşturulduğunu kontrol edin ✅
5. Çıkış yapın
6. "testuser" kullanıcı adı ile giriş yapmayı deneyin ✅

### Senaryo 2: Eski Kullanıcı Düzeltme

1. Email ile giriş yapın
2. Debug ekranına gidin
3. "Mevcut Kullanıcı" butonuna tıklayın
4. Eğer "Username mapping eksik!" görüyorsanız:
5. "Beni Düzelt" butonuna tıklayın
6. Tekrar "Mevcut Kullanıcı" kontrol edin ✅
7. Çıkış yapın
8. Kullanıcı adı ile giriş yapmayı deneyin ✅

### Senaryo 3: Toplu Düzeltme

1. Email ile giriş yapın
2. Debug ekranına gidin
3. "Tüm Kullanıcılar" butonuna tıklayın
4. Kaç kullanıcıda mapping eksik olduğunu görün
5. "Hepsini Düzelt" butonuna tıklayın
6. Tekrar "Tüm Kullanıcılar" kontrol edin ✅
7. Tüm kullanıcılar için mapping'in oluşturulduğunu doğrulayın

## Firestore Kuralları

Username mapping'lerin doğru çalışması için Firestore kurallarınız şöyle olmalı:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Usernames collection (read-only after creation)
    match /usernames/{username} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if false; // Sadece oluşturma izni
    }
    
    // Questions collection
    match /questions/{questionId} {
      allow read: if request.auth != null;
      // Sadece admin write yapabilir (şimdilik herkese açık)
      allow write: if request.auth != null;
    }
  }
}
```

## Sık Karşılaşılan Hatalar

### Hata: "Kullanıcı adı bulunamadı"
**Çözüm:** Debug ekranından "Beni Düzelt" veya "Hepsini Düzelt" butonunu kullanın.

### Hata: "Bu kullanıcı adı zaten kullanılıyor"
**Çözüm:** Kayıt sırasında farklı bir kullanıcı adı deneyin. Username'ler benzersiz olmalıdır.

### Hata: "Profil oluşturulamadı"
**Çözüm:** 
1. İnternet bağlantınızı kontrol edin
2. Firestore kurallarınızı kontrol edin
3. Firebase Console'dan manuel profil oluşturmayı deneyin

### Hata: "Email ile giriş yapamıyorum ama kullanıcı var"
**Çözüm:** 
1. Şifreyi doğru girdiğinizden emin olun
2. Firebase Console'dan kullanıcının Authentication'da olup olmadığını kontrol edin
3. "Şifremi Unuttum" ile şifre sıfırlayın

## Production'a Geçerken

**⚠️ DİKKAT:** Debug ekranını production'da **KALDIRINIZ** veya **ADMIN KONTROLÜ** ekleyiniz!

1. `home_screen.dart`'daki debug butonunu kaldırın
2. Veya sadece admin kullanıcılara gösterin:

```dart
if (user.email == 'admin@example.com') {
  // Debug butonu
}
```

3. `username_fixer.dart`'ı sadece backend/admin panelden erişilebilir yapın

## İletişim ve Destek

Sorun devam ederse:
1. Firebase Console'dan logs kontrol edin
2. Flutter Console'da (Debug Console) error loglarını okuyun
3. `firebase_auth` ve `cloud_firestore` paketlerinin güncel olduğundan emin olun

```bash
flutter pub upgrade firebase_auth cloud_firestore
flutter clean
flutter pub get
```

---

**Son Güncelleme:** 2024
**Sürüm:** 1.0

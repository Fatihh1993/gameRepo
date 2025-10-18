# Code Quiz Game 🎮

Modern ve kullanıcı dostu bir programlama quiz oyunu.

## Özellikler

- 👤 Kullanıcı girişi ve kayıt
- 🎯 Profil yönetimi
- 📝 Programlama dili seçimi (C#, SQL, Python, JavaScript)
- ❓ Kod doğrulama soruları
- ❤️ 3 can sistemi
- 📊 Skor takibi ve liderlik tablosu
- 🔥 Firebase/Firestore entegrasyonu

## Kurulum

### Gereksinimler
1. [Flutter SDK](https://flutter.dev/docs/get-started/install) (en son kararlı sürüm)
2. Android Studio veya VS Code
3. Android Emulator veya fiziksel cihaz

### Adımlar

1. **Flutter SDK'yı yükleyin** (eğer yüklü değilse)
   - [Flutter Installation Guide](https://flutter.dev/docs/get-started/install)
   - PATH değişkenine Flutter'ı eklemeyi unutmayın

2. **Projeyi klonlayın veya indirin**
   ```bash
   git clone <repo-url>
   cd gameRepo
   ```

3. **Bağımlılıkları yükleyin**
   ```bash
   flutter pub get
   ```

4. **Android Emulator'ı başlatın** (eğer çalışmıyorsa)
   ```bash
   flutter emulators --launch <emulator-id>
   ```

5. **Uygulamayı çalıştırın**
   
   Terminal'den:
   ```bash
   flutter run
   ```
   
   Veya VS Code'da:
   - `F5` tuşuna basın
   - Veya Debug > Start Debugging
   - Veya Terminal > Run Task > "Flutter: Run on Android Emulator"
   
   Mevcut cihazları görmek için:
   ```bash
   flutter devices
   ```

### Demo Giriş Bilgileri
```
Kullanıcı Adı: admin
Şifre: 1234
```

## Teknolojiler

- Flutter
- Firebase (Firestore, Auth)
- Google Fonts
- Material Design 3

## Oyun Akışı

1. Kullanıcı giriş yapar
2. Ana menüde profil ve istatistikleri görür
3. "Oyna" butonuna basarak dil seçer
4. Seçilen dile göre kod soruları gelir
5. Doğru/Yanlış cevap vererek puan kazanır
6. 3 can hakkı tükendiğinde oyun biter
7. Skor kaydedilir ve liderlik tablosunda görüntülenir

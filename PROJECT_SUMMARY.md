# 🎮 Code Quiz Game - Proje Özeti

## 📱 Geliştirilen Oyun

Modern, renkli ve kullanıcı dostu bir **programlama quiz oyunu** geliştirildi.

## ✨ Özellikler

### 1. Giriş Sistemi
- Modern gradient tasarım
- Animasyonlu giriş ekranı
- Demo kullanıcı: `admin` / `1234`

### 2. Ana Menü (Home Screen)
- Hoş geldin mesajı
- İstatistik kartları (En yüksek skor, Toplam oyun)
- Büyük animasyonlu "OYNA" butonu
- Profil sayfasına hızlı erişim
- Özet istatistikler

### 3. Profil Sayfası
- Kullanıcı bilgileri
- Detaylı istatistikler
- Dil bazlı performans gösterimi
- Başarı rozetleri sistemi

### 4. Dil Seçimi
- 4 programlama dili:
  - 🎯 C# (Mor)
  - 🐍 Python (Mavi)
  - ⚡ JavaScript (Sarı)
  - 🗄️ SQL (Turkuaz)
- Grid layout ile modern görünüm
- Her dil için soru sayısı gösterimi

### 5. Quiz Ekranı
- Can sistemi (3 kalp)
- İlerleme çubuğu
- Kod parçacıkları (syntax highlighted)
- Doğru/Yanlış butonları
- Puan sistemi
- Animasyonlar (sallanma, fade)
- Anlık geri bildirim

### 6. Sonuç Ekranı
- Animasyonlu skor gösterimi
- Performans mesajı
- Detaylı istatistikler
- Tekrar oyna veya ana menüye dön

## 📂 Proje Yapısı

```
lib/
├── main.dart                              # Uygulama başlangıcı
├── models/
│   └── models.dart                        # Veri modelleri (User, Question, Score, etc.)
├── screens/
│   ├── login_screen.dart                  # Giriş ekranı
│   ├── home_screen.dart                   # Ana menü
│   ├── profile_screen.dart                # Profil sayfası
│   ├── language_selection_screen.dart     # Dil seçimi
│   ├── game_screen.dart                   # Quiz oyun ekranı
│   └── result_screen.dart                 # Sonuç ekranı
└── utils/
    └── static_data.dart                   # Statik veriler (sorular, kullanıcı)
```

## 🎨 Tasarım Özellikleri

- **Material Design 3** kullanıldı
- **Google Fonts** (Poppins) ile modern tipografi
- **Gradient** arka planlar
- **Smooth animations** (fade, scale, slide, shake)
- **Hero animations** (profil geçişleri)
- **Card-based** UI
- **Responsive** tasarım
- **Color-coded** her dil için farklı renk

## 📊 Veri Yönetimi

### Şu anki durum (Statik):
- 20+ örnek soru (her dil için 5)
- Demo kullanıcı
- Statik istatistikler

### Gelecekte (Firebase):
- Firestore'da:
  - Kullanıcı bilgileri
  - Sorular ve cevaplar
  - Skorlar ve liderlik tablosu
  - Arkadaşlık istekleri
- Firebase Authentication:
  - Google ile giriş
  - Email/Password giriş

## 🎯 Oyun Mekaniği

1. **Giriş** → Kullanıcı giriş yapar
2. **Ana Menü** → İstatistiklerini görür
3. **Dil Seçimi** → Bir programlama dili seçer
4. **Quiz** → Kod parçalarına doğru/yanlış cevap verir
5. **Puanlama**:
   - Doğru cevap: +100 × zorluk seviyesi
   - Yanlış cevap: -1 can
6. **Oyun Sonu** → 3 can biter ya da sorular biter
7. **Sonuç** → Skor kaydedilir, istatistikler gösterilir

## 🚀 Nasıl Çalıştırılır?

### Gereksinimler:
1. Flutter SDK yüklü olmalı
2. Android Studio veya VS Code
3. Android Emulator (Pixel 6) veya fiziksel cihaz

### Çalıştırma:
```bash
# 1. Paketleri indir
flutter pub get

# 2. Uygulamayı çalıştır
flutter run -d pixel_6

# Veya VS Code'da F5'e bas
```

## 🔮 Gelecek Geliştirmeler

- [ ] Firebase entegrasyonu
- [ ] Google ile giriş
- [ ] Gerçek zamanlı liderlik tablosu
- [ ] Arkadaş sistemi
- [ ] Daha fazla programlama dili (Java, C++, Go, Rust)
- [ ] Zorluk seviyeleri
- [ ] Günlük görevler
- [ ] Başarı rozetleri sistemi
- [ ] Ses efektleri
- [ ] Dark mode

## 🎨 Renk Paleti

- **Primary**: #6C63FF (Mor)
- **C#**: #9B4993
- **Python**: #3776AB
- **JavaScript**: #F7DF1E
- **SQL**: #00758F
- **Success**: Yeşil
- **Error**: Kırmızı
- **Warning**: Amber

## 📱 Test Edildi

- ✅ Android (Pixel 6 emulator için optimize edildi)
- ⏳ iOS (Flutter destekler, test edilmedi)
- ⏳ Web (Flutter web desteği var)

---

**Geliştirici Notları:**
- Tüm ekranlar responsive tasarlandı
- Animasyonlar optimize edildi
- Kod temiz ve modüler
- Firestore entegrasyonu için hazır model yapısı mevcut
- İleride genişletilebilir mimari kullanıldı

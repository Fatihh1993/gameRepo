# 📚 Soru Yönetim Sistemi

## Firestore Veritabanı Yapısı

### Collection: `questions`

Her soru belgesi şu alanları içerir:

```json
{
  "language": "csharp",           // "csharp", "python", "javascript", "sql" (KÜÇÜK HARF!)
  "codeSnippet": "kod parçacığı", // Gösterilecek kod
  "isCorrect": true,              // true (doğru) veya false (yanlış)
  "explanation": "Açıklama",      // Cevap sonrası gösterilecek açıklama
  "difficulty": 2,                // 1-5 arası zorluk seviyesi
  "tags": ["loops", "basic"],     // Kategoriler
  "isActive": true,               // Aktif mi?
  "createdAt": "timestamp"        // Oluşturulma tarihi
}
```

**⚠️ ÖNEMLİ:** `language` alanı **küçük harf** olmalıdır:
- `"csharp"` ✅ (C# için)
- `"python"` ✅ (Python için)
- `"javascript"` ✅ (JavaScript için)
- `"sql"` ✅ (SQL için)

---

## 🚀 İLK KURULUM (Örnek Sorular)

### Yöntem 1: Kod ile Otomatik Ekleme

`home_screen.dart` veya başka bir ekranda bir kere çalıştırın:

```dart
import '../utils/question_seeder.dart';

// Ekran içinde bir buton ile:
ElevatedButton(
  onPressed: () async {
    final seeder = QuestionSeeder();
    await seeder.seedAllQuestions();
    print('Sorular eklendi!');
  },
  child: Text('Örnek Soruları Ekle'),
)
```

**ÖNEMLİ:** Bu işlemi sadece bir kere yapın!

---

## ➕ YENİ SORU EKLEME

### Yöntem 1: Firebase Console ile (Manuel)

1. **Firebase Console**'a git: https://console.firebase.google.com/
2. **Firestore Database** → **questions** collection
3. **Add document** butonuna tıkla
4. Alanları doldur:

```
Document ID: (auto-generate)

Fields:
├─ language (string): "csharp"
├─ codeSnippet (string): "int x = 5;\nConsole.WriteLine(x);"
├─ isCorrect (boolean): true
├─ explanation (string): "Bu kod doğru çalışır"
├─ difficulty (number): 1
├─ tags (array): ["basic", "variables"]
├─ isActive (boolean): true
└─ createdAt (timestamp): (now)
```

5. **Save** ile kaydet!

### Yöntem 2: Kod ile (Programatik)

Uygulamanızda admin ekranı ekleyerek:

```dart
import '../services/question_service.dart';

final questionService = QuestionService();

await questionService.addQuestion(
  language: 'csharp',
  codeSnippet: '''int x = 5;
int y = 10;
Console.WriteLine(x + y);''',
  isCorrect: true,
  explanation: 'Bu kod ekrana 15 yazdırır.',
  difficulty: 1,
  tags: ['basic', 'math'],
);
```

---

## 📝 SORU GÜNCELLEME

```dart
await questionService.updateQuestion(
  questionId: 'soru_id_buraya',
  codeSnippet: 'yeni kod',
  difficulty: 3,
  isActive: false, // Devre dışı bırak
);
```

---

## 🗑️ SORU SİLME (Soft Delete)

Sorular kalıcı olarak silinmez, sadece devre dışı bırakılır:

```dart
await questionService.deactivateQuestion('soru_id');
```

---

## 🎮 OYUNDA KULLANIM

GameScreen'de sorular otomatik olarak çekilir:

```dart
final questionService = QuestionService();

// 10 rastgele C# sorusu
final questions = await questionService.getRandomQuestions(
  language: 'csharp',
  count: 10,
);

// Zorluk seviyesine göre
final easyQuestions = await questionService.getQuestionsByLanguage(
  language: 'python',
  difficulty: 1,
  limit: 20,
);
```

---

## 📊 İSTATİSTİKLER

```dart
final stats = await questionService.getQuestionStats();
print('Toplam soru: ${stats['total']}');
print('C# soruları: ${stats['csharp']}');
print('Python soruları: ${stats['python']}');
```

---

## 🏷️ TAG SİSTEMİ

Sorular tag'ler ile kategorize edilir:

**Önerilen Tag'ler:**
- `basic` - Temel seviye
- `loops` - Döngüler
- `arrays` / `lists` - Diziler/Listeler
- `functions` - Fonksiyonlar
- `conditionals` - Koşullu ifadeler
- `string` - String işlemleri
- `oop` - Nesne yönelimli programlama
- `error` - Hata içeren kod
- `syntax` - Syntax hataları

---

## 🔒 GÜVENLİK (Firestore Rules)

**Önerilen kurallar:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Sorular - Herkes okuyabilir, sadece admin yazabilir
    match /questions/{questionId} {
      allow read: if request.auth != null;
      allow write: if false; // Sadece Firebase Console'dan yönetin
    }
  }
}
```

**Not:** Admin paneli eklerseniz, write yetkisini admin kullanıcılar için açabilirsiniz.

---

## 💡 İPUÇLARI

1. **Her dilde en az 20-30 soru** bulundurun
2. **Zorluk seviyelerini dengeleyin** (kolay-orta-zor)
3. **Açıklamaları detaylı yazın** - öğretici olsun
4. **Tag'leri tutarlı kullanın** - arama kolaylaşır
5. **Test edin!** - Soruyu ekledikten sonra oyunda deneyin

---

## 🎯 ÖRNEK SORU FORMATI

### Doğru Kod Örneği
```json
{
  "language": "csharp",
  "codeSnippet": "int[] numbers = {1, 2, 3};\nConsole.WriteLine(numbers.Length);",
  "isCorrect": true,
  "explanation": "Array.Length property'si dizinin eleman sayısını döndürür. Ekrana 3 yazdırır.",
  "difficulty": 1,
  "tags": ["arrays", "basic", "properties"],
  "isActive": true
}
```

### Yanlış Kod Örneği
```json
{
  "language": "python",
  "codeSnippet": "numbers = [1, 2, 3]\nprint(numbers[3])",
  "isCorrect": false,
  "explanation": "IndexError! Liste 0-2 arasında index'lere sahip. Index 3 mevcut değil.",
  "difficulty": 2,
  "tags": ["lists", "index-error", "common-mistakes"],
  "isActive": true
}
```

---

## 🆘 SORUN GİDERME

**Sorular oyunda görünmüyor:**
- `isActive: true` olduğundan emin olun
- Firestore'da `questions` collection'ı var mı?
- Internet bağlantısı var mı?

**Hatalar:**
- Console'da Firebase hata loglarını kontrol edin
- Firestore kurallarını kontrol edin

---

## 📞 DESTEK

Sorularınız için: fatihkurt.1993@gmail.com

Keyifli kodlamalar! 🚀

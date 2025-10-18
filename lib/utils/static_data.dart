import 'package:flutter/material.dart';
import '../models/models.dart';

// Statik veriler - İleride Firestore'dan gelecek

class StaticData {
  // Örnek kullanıcı
  static UserModel currentUser = UserModel(
    id: '1',
    username: 'CodeMaster',
    email: 'codemaster@example.com',
    highScore: 850,
    totalGamesPlayed: 15,
    experience: 3500, // 3500 XP = Level 4
    level: 4,
    unlockedAchievements: ['first_win', 'games_10'],
  );

  // Başarı rozetleri
  static final List<Achievement> achievements = [
    Achievement(
      id: 'first_win',
      title: '🎮 İlk Zafer',
      description: 'İlk oyununu tamamla',
      icon: '🎮',
      color: Colors.blue,
      requiredValue: 1,
      type: AchievementType.firstWin,
    ),
    Achievement(
      id: 'perfect_game',
      title: '💯 Mükemmeliyetçi',
      description: 'Bir oyunu %100 doğrulukla bitir',
      icon: '💯',
      color: Colors.amber,
      requiredValue: 100,
      type: AchievementType.perfectGame,
    ),
    Achievement(
      id: 'combo_5',
      title: '🔥 Ateş Topu',
      description: '5 soru üst üste doğru cevapla',
      icon: '🔥',
      color: Colors.orange,
      requiredValue: 5,
      type: AchievementType.combo5,
    ),
    Achievement(
      id: 'combo_10',
      title: '⚡ İmkansız Combo',
      description: '10 soru üst üste doğru cevapla',
      icon: '⚡',
      color: Colors.purple,
      requiredValue: 10,
      type: AchievementType.combo10,
    ),
    Achievement(
      id: 'games_10',
      title: '📚 Acemi',
      description: '10 oyun oyna',
      icon: '📚',
      color: Colors.green,
      requiredValue: 10,
      type: AchievementType.gamesPlayed10,
    ),
    Achievement(
      id: 'games_50',
      title: '🚀 Veteran',
      description: '50 oyun oyna',
      icon: '🚀',
      color: Colors.red,
      requiredValue: 50,
      type: AchievementType.gamesPlayed50,
    ),
    Achievement(
      id: 'all_languages',
      title: '🌍 Polyglot',
      description: 'Tüm dillerde en az 1 oyun oyna',
      icon: '🌍',
      color: Colors.teal,
      requiredValue: 4,
      type: AchievementType.allLanguages,
    ),
    Achievement(
      id: 'high_score_500',
      title: '⭐ Yükselen Yıldız',
      description: 'Tek oyunda 500+ puan al',
      icon: '⭐',
      color: Colors.yellow,
      requiredValue: 500,
      type: AchievementType.highScore500,
    ),
    Achievement(
      id: 'high_score_1000',
      title: '👑 Efsane',
      description: 'Tek oyunda 1000+ puan al',
      icon: '👑',
      color: Colors.deepPurple,
      requiredValue: 1000,
      type: AchievementType.highScore1000,
    ),
    Achievement(
      id: 'level_10',
      title: '🎓 Uzman',
      description: 'Level 10\'a ulaş',
      icon: '🎓',
      color: Colors.indigo,
      requiredValue: 10,
      type: AchievementType.level10,
    ),
    Achievement(
      id: 'level_25',
      title: '💎 Master',
      description: 'Level 25\'e ulaş',
      icon: '💎',
      color: Colors.cyan,
      requiredValue: 25,
      type: AchievementType.level25,
    ),
  ];

  // Programlama dilleri
  static final List<ProgrammingLanguage> languages = [
    ProgrammingLanguage(
      name: 'C#',
      icon: '🎯',
      color: const Color(0xFF9B4993),
    ),
    ProgrammingLanguage(
      name: 'Python',
      icon: '🐍',
      color: const Color(0xFF3776AB),
    ),
    ProgrammingLanguage(
      name: 'JavaScript',
      icon: '⚡',
      color: const Color(0xFFF7DF1E),
    ),
    ProgrammingLanguage(
      name: 'SQL',
      icon: '🗄️',
      color: const Color(0xFF00758F),
    ),
  ];

  // Statik sorular - Her dil için örnek sorular
  static final Map<String, List<Question>> questions = {
    'C#': [
      Question(
        id: 'cs1',
        language: 'C#',
        codeSnippet: '''int x = 5;
int y = 10;
int z = x + y;
Console.WriteLine(z);
// Output: 15''',
        isCorrect: true,
        explanation: 'Kod doğru. 5 + 10 = 15',
        difficulty: 1,
      ),
      Question(
        id: 'cs2',
        language: 'C#',
        codeSnippet: '''string name = "Ali";
int age = 25;
Console.WriteLine(name + age);
// Output: Ali25''',
        isCorrect: true,
        explanation: 'String concatenation doğru çalışır',
        difficulty: 1,
      ),
      Question(
        id: 'cs3',
        language: 'C#',
        codeSnippet: '''int[] numbers = {1, 2, 3};
Console.WriteLine(numbers[3]);
// IndexOutOfRangeException''',
        isCorrect: false,
        explanation: 'Array index 0\'dan başlar, 3. eleman yok',
        difficulty: 2,
      ),
      Question(
        id: 'cs4',
        language: 'C#',
        codeSnippet: '''bool isTrue = true;
if (isTrue = false) {
    Console.WriteLine("True");
}
// Çıktı yok''',
        isCorrect: false,
        explanation: '== yerine = kullanılmış, atama yapıyor',
        difficulty: 2,
      ),
      Question(
        id: 'cs5',
        language: 'C#',
        codeSnippet: '''var list = new List<int> {1, 2, 3};
list.Add(4);
Console.WriteLine(list.Count);
// Output: 4''',
        isCorrect: true,
        explanation: 'List\'e eleman ekleme doğru',
        difficulty: 1,
      ),
    ],
    'Python': [
      Question(
        id: 'py1',
        language: 'Python',
        codeSnippet: '''x = [1, 2, 3]
y = x
y.append(4)
print(x)
# [1, 2, 3, 4]''',
        isCorrect: true,
        explanation: 'Liste referans tipi, y x\'i işaret eder',
        difficulty: 2,
      ),
      Question(
        id: 'py2',
        language: 'Python',
        codeSnippet: '''def greet(name):
    return f"Merhaba {name}"
    
print(greet("Ali"))
# Merhaba Ali''',
        isCorrect: true,
        explanation: 'F-string doğru kullanılmış',
        difficulty: 1,
      ),
      Question(
        id: 'py3',
        language: 'Python',
        codeSnippet: '''numbers = [1, 2, 3, 4, 5]
result = sum(numbers) / len(numbers)
print(result)
# 3.0''',
        isCorrect: true,
        explanation: 'Ortalama hesaplama doğru',
        difficulty: 1,
      ),
      Question(
        id: 'py4',
        language: 'Python',
        codeSnippet: '''x = "10"
y = 5
print(x + y)
# TypeError''',
        isCorrect: false,
        explanation: 'String ve int toplanamaz',
        difficulty: 2,
      ),
      Question(
        id: 'py5',
        language: 'Python',
        codeSnippet: '''dict = {'a': 1, 'b': 2}
print(dict['c'])
# KeyError''',
        isCorrect: false,
        explanation: '\'c\' anahtarı dictionary\'de yok',
        difficulty: 2,
      ),
    ],
    'JavaScript': [
      Question(
        id: 'js1',
        language: 'JavaScript',
        codeSnippet: '''const arr = [1, 2, 3];
arr.push(4);
console.log(arr);
// [1, 2, 3, 4]''',
        isCorrect: true,
        explanation: 'const array mutate edilebilir',
        difficulty: 2,
      ),
      Question(
        id: 'js2',
        language: 'JavaScript',
        codeSnippet: '''let x = "5";
let y = 5;
console.log(x == y);
// true''',
        isCorrect: true,
        explanation: '== tip dönüşümü yapar',
        difficulty: 2,
      ),
      Question(
        id: 'js3',
        language: 'JavaScript',
        codeSnippet: '''let x = "5";
let y = 5;
console.log(x === y);
// false''',
        isCorrect: true,
        explanation: '=== tip kontrolü yapar',
        difficulty: 2,
      ),
      Question(
        id: 'js4',
        language: 'JavaScript',
        codeSnippet: '''function test() {
    return
    {
        value: 42
    }
}
console.log(test());
// undefined''',
        isCorrect: true,
        explanation: 'Otomatik semicolon insertion',
        difficulty: 3,
      ),
      Question(
        id: 'js5',
        language: 'JavaScript',
        codeSnippet: '''const obj = {x: 1};
obj = {x: 2};
// TypeError''',
        isCorrect: false,
        explanation: 'const obje yeniden atanamaz',
        difficulty: 2,
      ),
    ],
    'SQL': [
      Question(
        id: 'sql1',
        language: 'SQL',
        codeSnippet: '''SELECT COUNT(*) 
FROM users 
WHERE age > 18;''',
        isCorrect: true,
        explanation: 'Temel COUNT sorgusu doğru',
        difficulty: 1,
      ),
      Question(
        id: 'sql2',
        language: 'SQL',
        codeSnippet: '''SELECT name, age 
FROM users 
ORDER BY age DESC;''',
        isCorrect: true,
        explanation: 'DESC ile azalan sıralama doğru',
        difficulty: 1,
      ),
      Question(
        id: 'sql3',
        language: 'SQL',
        codeSnippet: '''DELETE FROM users;''',
        isCorrect: true,
        explanation: 'WHERE olmadan tüm kayıtları siler',
        difficulty: 1,
      ),
      Question(
        id: 'sql4',
        language: 'SQL',
        codeSnippet: '''SELECT * FROM users
WHERE name = NULL;''',
        isCorrect: false,
        explanation: 'NULL kontrolü IS NULL ile yapılır',
        difficulty: 2,
      ),
      Question(
        id: 'sql5',
        language: 'SQL',
        codeSnippet: '''SELECT DISTINCT city 
FROM users 
GROUP BY city;''',
        isCorrect: false,
        explanation: 'DISTINCT ve GROUP BY gereksiz',
        difficulty: 2,
      ),
    ],
  };

  // Giriş kontrolü (statik)
  static bool login(String username, String password) {
    // Basit statik kontrol
    return username == 'admin' && password == '1234';
  }
}

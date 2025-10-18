import '../services/question_service.dart';

/// Firestore'a örnek sorular eklemek için yardımcı sınıf
/// NOT: Bu sadece ilk kurulum için kullanılır!
class QuestionSeeder {
  final QuestionService _questionService = QuestionService();

  // 🌱 TÜM ÖRNEK SORULARI EKLE
  Future<void> seedAllQuestions() async {
    print('🌱 Örnek sorular ekleniyor...');
    
    await _seedCSharpQuestions();
    await _seedPythonQuestions();
    await _seedJavaScriptQuestions();
    await _seedSQLQuestions();
    
    print('🎉 Tüm örnek sorular eklendi!');
  }

  // C# Soruları
  Future<void> _seedCSharpQuestions() async {
    final csharpQuestions = [
      {
        'language': 'csharp',
        'codeSnippet': '''int x = 5;
int y = 10;
int result = x + y;
Console.WriteLine(result);''',
        'isCorrect': true,
        'explanation': 'Bu kod doğru çalışır ve ekrana 15 yazdırır.',
        'difficulty': 1,
        'tags': ['basic', 'variables', 'console'],
      },
      {
        'language': 'csharp',
        'codeSnippet': '''string name = "John";
int age = 25;
Console.WriteLine(name + age);''',
        'isCorrect': true,
        'explanation': 'String concatenation doğru çalışır: "John25"',
        'difficulty': 1,
        'tags': ['string', 'concatenation'],
      },
      {
        'language': 'csharp',
        'codeSnippet': '''for (int i = 0; i <= 5; i++) {
    Console.WriteLine(i);
}''',
        'isCorrect': false,
        'explanation': 'i <= 5 olduğu için 0\'dan 5\'e kadar (6 sayı) yazdırır, genelde i < 5 kullanılır.',
        'difficulty': 2,
        'tags': ['loops', 'for'],
      },
      {
        'language': 'csharp',
        'codeSnippet': '''int[] numbers = new int[3];
numbers[0] = 10;
numbers[1] = 20;
numbers[2] = 30;''',
        'isCorrect': true,
        'explanation': 'Array tanımlama ve değer atama doğru.',
        'difficulty': 2,
        'tags': ['arrays', 'basic'],
      },
      {
        'language': 'csharp',
        'codeSnippet': '''if (5 > 3 && 2 < 1) {
    Console.WriteLine("True");
} else {
    Console.WriteLine("False");
}''',
        'isCorrect': false,
        'explanation': '&& operatörü her iki koşulun da doğru olmasını ister. 2 < 1 yanlış olduğu için False yazdırır.',
        'difficulty': 2,
        'tags': ['conditional', 'operators'],
      },
    ];

    for (var question in csharpQuestions) {
      await _questionService.addQuestion(
        language: question['language'] as String,
        codeSnippet: question['codeSnippet'] as String,
        isCorrect: question['isCorrect'] as bool,
        explanation: question['explanation'] as String?,
        difficulty: question['difficulty'] as int,
        tags: List<String>.from(question['tags'] as List),
      );
    }
    
    print('✅ C# soruları eklendi (${csharpQuestions.length} adet)');
  }

  // Python Soruları
  Future<void> _seedPythonQuestions() async {
    final pythonQuestions = [
      {
        'language': 'python',
        'codeSnippet': '''x = 5
y = 10
print(x + y)''',
        'isCorrect': true,
        'explanation': 'Python\'da değişken tanımlama ve toplama işlemi doğru.',
        'difficulty': 1,
        'tags': ['basic', 'variables', 'print'],
      },
      {
        'language': 'python',
        'codeSnippet': '''name = "Alice"
age = 25
print(name + age)''',
        'isCorrect': false,
        'explanation': 'TypeError: str ve int birleştirilemez. str(age) kullanılmalı.',
        'difficulty': 2,
        'tags': ['string', 'type-error'],
      },
      {
        'language': 'python',
        'codeSnippet': '''for i in range(5):
    print(i)''',
        'isCorrect': true,
        'explanation': 'range(5) 0\'dan 4\'e kadar sayılar üretir.',
        'difficulty': 1,
        'tags': ['loops', 'range'],
      },
      {
        'language': 'python',
        'codeSnippet': '''numbers = [1, 2, 3]
numbers[3] = 4
print(numbers)''',
        'isCorrect': false,
        'explanation': 'IndexError: list index out of range. Index 3 yoktur.',
        'difficulty': 2,
        'tags': ['lists', 'index-error'],
      },
      {
        'language': 'python',
        'codeSnippet': '''def greet(name):
    return f"Hello, {name}!"
    
print(greet("World"))''',
        'isCorrect': true,
        'explanation': 'f-string kullanımı doğru. "Hello, World!" yazdırır.',
        'difficulty': 2,
        'tags': ['functions', 'f-string'],
      },
    ];

    for (var question in pythonQuestions) {
      await _questionService.addQuestion(
        language: question['language'] as String,
        codeSnippet: question['codeSnippet'] as String,
        isCorrect: question['isCorrect'] as bool,
        explanation: question['explanation'] as String?,
        difficulty: question['difficulty'] as int,
        tags: List<String>.from(question['tags'] as List),
      );
    }
    
    print('✅ Python soruları eklendi (${pythonQuestions.length} adet)');
  }

  // JavaScript Soruları
  Future<void> _seedJavaScriptQuestions() async {
    final jsQuestions = [
      {
        'language': 'javascript',
        'codeSnippet': '''let x = 5;
let y = 10;
console.log(x + y);''',
        'isCorrect': true,
        'explanation': 'JavaScript\'te let ile değişken tanımlama ve toplama doğru.',
        'difficulty': 1,
        'tags': ['basic', 'variables', 'console'],
      },
      {
        'language': 'javascript',
        'codeSnippet': '''const name = "John";
name = "Jane";
console.log(name);''',
        'isCorrect': false,
        'explanation': 'TypeError: const ile tanımlanan değişken yeniden atanamaz.',
        'difficulty': 2,
        'tags': ['const', 'error'],
      },
      {
        'language': 'javascript',
        'codeSnippet': '''for (let i = 0; i < 5; i++) {
    console.log(i);
}''',
        'isCorrect': true,
        'explanation': '0\'dan 4\'e kadar sayıları yazdırır.',
        'difficulty': 1,
        'tags': ['loops', 'for'],
      },
      {
        'language': 'javascript',
        'codeSnippet': '''const arr = [1, 2, 3];
arr.push(4);
console.log(arr);''',
        'isCorrect': true,
        'explanation': 'const array\'in içeriği değiştirilebilir, yeniden atama yapılamaz.',
        'difficulty': 2,
        'tags': ['arrays', 'const'],
      },
      {
        'language': 'javascript',
        'codeSnippet': '''const greet = (name) => {
    return \`Hello, \${name}!\`;
}
console.log(greet("World"));''',
        'isCorrect': true,
        'explanation': 'Arrow function ve template literal kullanımı doğru.',
        'difficulty': 2,
        'tags': ['arrow-function', 'template-literal'],
      },
    ];

    for (var question in jsQuestions) {
      await _questionService.addQuestion(
        language: question['language'] as String,
        codeSnippet: question['codeSnippet'] as String,
        isCorrect: question['isCorrect'] as bool,
        explanation: question['explanation'] as String?,
        difficulty: question['difficulty'] as int,
        tags: List<String>.from(question['tags'] as List),
      );
    }
    
    print('✅ JavaScript soruları eklendi (${jsQuestions.length} adet)');
  }

  // SQL Soruları
  Future<void> _seedSQLQuestions() async {
    final sqlQuestions = [
      {
        'language': 'sql',
        'codeSnippet': '''SELECT * FROM users;''',
        'isCorrect': true,
        'explanation': 'Temel SELECT sorgusu doğru.',
        'difficulty': 1,
        'tags': ['select', 'basic'],
      },
      {
        'language': 'sql',
        'codeSnippet': '''SELECT name, age 
FROM users 
WHERE age > 18;''',
        'isCorrect': true,
        'explanation': 'WHERE koşulu ile filtreleme doğru.',
        'difficulty': 1,
        'tags': ['select', 'where'],
      },
      {
        'language': 'sql',
        'codeSnippet': '''SELECT * FROM users
ORDER BY name DESC;''',
        'isCorrect': true,
        'explanation': 'ORDER BY ile azalan sıralama doğru.',
        'difficulty': 2,
        'tags': ['select', 'order-by'],
      },
      {
        'language': 'sql',
        'codeSnippet': '''UPDATE users 
SET age = 30 
WHERE name = "John"''',
        'isCorrect': false,
        'explanation': 'SQL\'de string için tek tırnak (\'John\') kullanılmalı.',
        'difficulty': 2,
        'tags': ['update', 'syntax-error'],
      },
      {
        'language': 'sql',
        'codeSnippet': '''INSERT INTO users (name, age) 
VALUES ('Alice', 25);''',
        'isCorrect': true,
        'explanation': 'INSERT INTO kullanımı doğru.',
        'difficulty': 2,
        'tags': ['insert', 'basic'],
      },
    ];

    for (var question in sqlQuestions) {
      await _questionService.addQuestion(
        language: question['language'] as String,
        codeSnippet: question['codeSnippet'] as String,
        isCorrect: question['isCorrect'] as bool,
        explanation: question['explanation'] as String?,
        difficulty: question['difficulty'] as int,
        tags: List<String>.from(question['tags'] as List),
      );
    }
    
    print('✅ SQL soruları eklendi (${sqlQuestions.length} adet)');
  }
}

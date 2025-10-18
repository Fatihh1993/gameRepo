import 'package:flutter/material.dart';

// Data Models

// Kullanıcı modeli
class UserModel {
  final String id;
  final String username;
  final String email;
  final int highScore;
  final int totalGamesPlayed;
  final String? profileImageUrl;
  final int experience; // XP
  final int level; // Seviye
  final List<String> unlockedAchievements; // Açılan rozetler

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.highScore = 0,
    this.totalGamesPlayed = 0,
    this.profileImageUrl,
    this.experience = 0,
    this.level = 1,
    this.unlockedAchievements = const [],
  });

  // Seviye hesaplama (her 1000 XP = 1 level)
  int get currentLevel => (experience / 1000).floor() + 1;
  
  // Mevcut seviye için gereken XP
  int get xpForCurrentLevel => (currentLevel - 1) * 1000;
  
  // Sonraki seviye için gereken XP
  int get xpForNextLevel => currentLevel * 1000;
  
  // Mevcut seviyedeki ilerleme (0.0 - 1.0)
  double get levelProgress {
    final currentLevelXp = experience - xpForCurrentLevel;
    final xpNeeded = xpForNextLevel - xpForCurrentLevel;
    return currentLevelXp / xpNeeded;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'highScore': highScore,
      'totalGamesPlayed': totalGamesPlayed,
      'profileImageUrl': profileImageUrl,
      'experience': experience,
      'level': level,
      'unlockedAchievements': unlockedAchievements,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      highScore: map['highScore'] ?? 0,
      totalGamesPlayed: map['totalGamesPlayed'] ?? 0,
      profileImageUrl: map['profileImageUrl'],
      experience: map['experience'] ?? 0,
      level: map['level'] ?? 1,
      unlockedAchievements: List<String>.from(map['unlockedAchievements'] ?? []),
    );
  }

  // copyWith metodu - kullanıcı güncellemeleri için
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    int? highScore,
    int? totalGamesPlayed,
    String? profileImageUrl,
    int? experience,
    int? level,
    List<String>? unlockedAchievements,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      highScore: highScore ?? this.highScore,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      experience: experience ?? this.experience,
      level: level ?? this.level,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
    );
  }
}

// Soru modeli (Firestore uyumlu)
class Question {
  final String id;
  final String language; // 'csharp', 'python', 'javascript', 'sql'
  final String codeSnippet; // Kod parçacığı
  final bool isCorrect; // Doğru mu yanlış mı?
  final String? explanation; // Açıklama
  final int difficulty; // 1-5 (kolay-zor)
  final List<String> tags; // ['loops', 'arrays', 'functions', vs.]
  final DateTime? createdAt;
  final bool isActive; // Aktif mi? (yayında mı?)

  Question({
    required this.id,
    required this.language,
    required this.codeSnippet,
    required this.isCorrect,
    this.explanation,
    this.difficulty = 1,
    this.tags = const [],
    this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'language': language,
      'codeSnippet': codeSnippet,
      'isCorrect': isCorrect,
      'explanation': explanation,
      'difficulty': difficulty,
      'tags': tags,
      'createdAt': createdAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map, String docId) {
    return Question(
      id: docId,
      language: map['language'] ?? '',
      codeSnippet: map['codeSnippet'] ?? '',
      isCorrect: map['isCorrect'] ?? false,
      explanation: map['explanation'],
      difficulty: map['difficulty'] ?? 1,
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : null,
      isActive: map['isActive'] ?? true,
    );
  }

  // Firestore için
  factory Question.fromFirestore(Map<String, dynamic> data, String docId) {
    return Question(
      id: docId,
      language: data['language'] ?? '',
      codeSnippet: data['codeSnippet'] ?? '',
      isCorrect: data['isCorrect'] ?? false,
      explanation: data['explanation'],
      difficulty: data['difficulty'] ?? 1,
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as dynamic).toDate() 
          : null,
      isActive: data['isActive'] ?? true,
    );
  }
}

// Programlama dili modeli
class ProgrammingLanguage {
  final String name;
  final String icon;
  final Color color;

  ProgrammingLanguage({
    required this.name,
    required this.icon,
    required this.color,
  });
}

// Skor modeli
class GameScore {
  final String id;
  final String userId;
  final String language;
  final int score;
  final int correctAnswers;
  final int wrongAnswers;
  final DateTime timestamp;

  GameScore({
    required this.id,
    required this.userId,
    required this.language,
    required this.score,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'language': language,
      'score': score,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GameScore.fromMap(Map<String, dynamic> map) {
    return GameScore(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      language: map['language'] ?? '',
      score: map['score'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      wrongAnswers: map['wrongAnswers'] ?? 0,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

// Başarı rozeti modeli
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final Color color;
  final int requiredValue;
  final AchievementType type;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.requiredValue,
    required this.type,
  });
}

enum AchievementType {
  firstWin,        // İlk zafer
  perfectGame,     // Mükemmel oyun
  combo5,          // 5x combo
  combo10,         // 10x combo
  gamesPlayed10,   // 10 oyun
  gamesPlayed50,   // 50 oyun
  allLanguages,    // Tüm dillerde oyna
  highScore500,    // 500+ skor
  highScore1000,   // 1000+ skor
  level10,         // Level 10
  level25,         // Level 25
}

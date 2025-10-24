import 'package:cloud_firestore/cloud_firestore.dart';
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
  final int passTokens;
  final bool isOnline;
  final bool shareOnlineStatus;
  final DateTime? lastSeen;

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
    this.passTokens = 0,
    this.isOnline = false,
    this.shareOnlineStatus = true,
    this.lastSeen,
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
      'passTokens': passTokens,
      'isOnline': isOnline,
      'shareOnlineStatus': shareOnlineStatus,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime? lastSeen;
    final rawLastSeen = map['lastSeen'];
    if (rawLastSeen is Timestamp) {
      lastSeen = rawLastSeen.toDate();
    } else if (rawLastSeen is String) {
      lastSeen = DateTime.tryParse(rawLastSeen);
    } else if (rawLastSeen is DateTime) {
      lastSeen = rawLastSeen;
    }

    return UserModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      highScore: _readInt(map['highScore']),
      totalGamesPlayed: _readInt(map['totalGamesPlayed']),
      profileImageUrl: map['profileImageUrl'],
      experience: _readInt(map['experience']),
      level: _readInt(map['level'], fallback: 1),
      unlockedAchievements: List<String>.from(map['unlockedAchievements'] ?? []),
      passTokens: _readInt(map['passTokens']),
      isOnline: (map['isOnline'] ?? false) as bool,
      shareOnlineStatus: (map['shareOnlineStatus'] ?? true) as bool,
      lastSeen: lastSeen,
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
    int? passTokens,
    bool? isOnline,
    bool? shareOnlineStatus,
    DateTime? lastSeen,
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
      passTokens: passTokens ?? this.passTokens,
      isOnline: isOnline ?? this.isOnline,
      shareOnlineStatus: shareOnlineStatus ?? this.shareOnlineStatus,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
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
    final dynamic rawCreatedAt = data['createdAt'];
    DateTime? createdAt;
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt);
    }

    return Question(
      id: docId,
      language: data['language'] ?? '',
      codeSnippet: data['codeSnippet'] ?? '',
      isCorrect: data['isCorrect'] ?? false,
      explanation: data['explanation'],
      difficulty: data['difficulty'] ?? 1,
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: createdAt,
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

class LeaderboardEntry {
  final String userId;
  final String username;
  final String language;
  final int score;
  final int rank;
  final String? photoUrl;
  final DateTime? updatedAt;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.language,
    required this.score,
    this.rank = 0,
    this.photoUrl,
    this.updatedAt,
  });

  LeaderboardEntry copyWith({
    int? rank,
  }) {
    return LeaderboardEntry(
      userId: userId,
      username: username,
      language: language,
      score: score,
      rank: rank ?? this.rank,
      photoUrl: photoUrl,
      updatedAt: updatedAt,
    );
  }

  factory LeaderboardEntry.fromFirestore(
    Map<String, dynamic> data,
    String userId,
  ) {
    return LeaderboardEntry(
      userId: userId,
      username: data['username'] ?? 'Unknown',
      language: data['language'] ?? 'global',
      score: ((data['score'] ?? 0) as num).toInt(),
      photoUrl: data['photoUrl'] as String?,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'language': language,
      'score': score,
      'photoUrl': photoUrl,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class InboxMessage {
  final String id;
  final String senderUid;
  final String senderUsername;
  final String? senderPhotoUrl;
  final String text;
  final DateTime? createdAt;
  final bool isRead;

  const InboxMessage({
    required this.id,
    required this.senderUid,
    required this.senderUsername,
    this.senderPhotoUrl,
    required this.text,
    this.createdAt,
    this.isRead = false,
  });

  factory InboxMessage.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    DateTime? createdAt;
    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt);
    }

    return InboxMessage(
      id: docId,
      senderUid: data['senderUid'] as String? ?? '',
      senderUsername: data['senderUsername'] as String? ?? 'Player',
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      text: data['text'] as String? ?? '',
      createdAt: createdAt,
      isRead: (data['isRead'] ?? false) as bool,
    );
  }
}

class ConversationMessage {
  final String id;
  final String senderUid;
  final String receiverUid;
  final String text;
  final DateTime? createdAt;

  const ConversationMessage({
    required this.id,
    required this.senderUid,
    required this.receiverUid,
    required this.text,
    this.createdAt,
  });

  factory ConversationMessage.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    DateTime? createdAt;
    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt);
    }

    return ConversationMessage(
      id: docId,
      senderUid: data['senderUid'] as String? ?? '',
      receiverUid: data['receiverUid'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: createdAt,
    );
  }
}

class ConversationPreview {
  final String friendUid;
  final String friendUsername;
  final String? friendPhotoUrl;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastMessageSenderUid;
  final int unreadCount;

  const ConversationPreview({
    required this.friendUid,
    required this.friendUsername,
    required this.lastMessage,
    required this.lastMessageSenderUid,
    this.friendPhotoUrl,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  bool get hasUnread => unreadCount > 0;

  factory ConversationPreview.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    DateTime? lastMessageAt;
    final rawLastMessageAt = data['lastMessageAt'];
    if (rawLastMessageAt is Timestamp) {
      lastMessageAt = rawLastMessageAt.toDate();
    } else if (rawLastMessageAt is DateTime) {
      lastMessageAt = rawLastMessageAt;
    } else if (rawLastMessageAt is String) {
      lastMessageAt = DateTime.tryParse(rawLastMessageAt);
    }

    return ConversationPreview(
      friendUid: data['friendUid'] as String? ?? docId,
      friendUsername: data['friendUsername'] as String? ?? 'player',
      friendPhotoUrl: data['friendPhotoUrl'] as String?,
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: lastMessageAt,
      lastMessageSenderUid: data['lastMessageSenderUid'] as String? ?? '',
      unreadCount: (data['unreadCount'] ?? 0) is int
          ? data['unreadCount'] as int
          : int.tryParse(data['unreadCount'].toString()) ?? 0,
    );
  }
}

enum MissionType {
  daily,
  weekly,
}

enum MissionMetric {
  gamesPlayed,
  scoreAccumulated,
  perfectGame,
  combo,
}

enum MissionRewardType {
  xp,
  pass,
}

class MissionDefinition {
  final String id;
  final MissionType type;
  final String title;
  final String description;
  final MissionMetric metric;
  final int target;
  final MissionRewardType rewardType;
  final int rewardValue;

  const MissionDefinition({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.metric,
    required this.target,
    required this.rewardType,
    required this.rewardValue,
  });
}

class MissionProgress {
  final MissionDefinition definition;
  final int progress;
  final bool isCompleted;
  final bool isClaimed;
  final DateTime? updatedAt;

  const MissionProgress({
    required this.definition,
    required this.progress,
    required this.isCompleted,
    required this.isClaimed,
    this.updatedAt,
  });

  double get completionRatio =>
      (progress / definition.target).clamp(0, 1).toDouble();

  MissionProgress copyWith({
    int? progress,
    bool? isCompleted,
    bool? isClaimed,
    DateTime? updatedAt,
  }) {
    return MissionProgress(
      definition: definition,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FriendSummary {
  final String uid;
  final String username;
  final String? photoUrl;
  final int level;
  final int highScore;
  final DateTime addedAt;
  final bool isOnline;
  final bool shareOnlineStatus;
  final DateTime? lastSeen;

  const FriendSummary({
    required this.uid,
    required this.username,
    required this.level,
    required this.highScore,
    required this.addedAt,
    this.photoUrl,
    this.isOnline = false,
    this.shareOnlineStatus = true,
    this.lastSeen,
  });
}

class FriendUserPreview {
  final String uid;
  final String username;
  final String? photoUrl;
  final int level;
  final int highScore;

  const FriendUserPreview({
    required this.uid,
    required this.username,
    required this.level,
    required this.highScore,
    this.photoUrl,
  });
}

enum FriendRequestStatus { pending, accepted, rejected }

class FriendRequest {
  final String uid;
  final String username;
  final String? photoUrl;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final bool isOutgoing;

  const FriendRequest({
    required this.uid,
    required this.username,
    required this.status,
    required this.createdAt,
    this.photoUrl,
    this.isOutgoing = false,
  });

  FriendRequest copyWith({
    FriendRequestStatus? status,
    bool? isOutgoing,
  }) {
    return FriendRequest(
      uid: uid,
      username: username,
      photoUrl: photoUrl,
      createdAt: createdAt,
      status: status ?? this.status,
      isOutgoing: isOutgoing ?? this.isOutgoing,
    );
  }
}

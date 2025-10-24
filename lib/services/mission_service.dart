import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';

class MissionService {
  MissionService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _dailyDefinitions = <MissionDefinition>[
    MissionDefinition(
      id: 'daily_play_games',
      type: MissionType.daily,
      title: '3 Oyun Oyna',
      description: 'Bugün 3 oyunu tamamla.',
      metric: MissionMetric.gamesPlayed,
      target: 3,
      rewardType: MissionRewardType.pass,
      rewardValue: 1,
    ),
    MissionDefinition(
      id: 'daily_score_1500',
      type: MissionType.daily,
      title: '1500 Puan Topla',
      description: 'Toplam 1500 puan kazandığında ödül senin.',
      metric: MissionMetric.scoreAccumulated,
      target: 1500,
      rewardType: MissionRewardType.xp,
      rewardValue: 200,
    ),
    MissionDefinition(
      id: 'daily_perfect_game',
      type: MissionType.daily,
      title: 'Hatasız Oyun',
      description: 'Hiç yanlış yapmadan bir oyun bitir.',
      metric: MissionMetric.perfectGame,
      target: 1,
      rewardType: MissionRewardType.xp,
      rewardValue: 250,
    ),
  ];

  static const _weeklyDefinitions = <MissionDefinition>[
    MissionDefinition(
      id: 'weekly_combo_master',
      type: MissionType.weekly,
      title: 'Combo Ustası',
      description: 'Toplamda 30 combo puanına ulaş.',
      metric: MissionMetric.combo,
      target: 30,
      rewardType: MissionRewardType.xp,
      rewardValue: 500,
    ),
  ];

  List<MissionDefinition> get definitions => [
        ..._dailyDefinitions,
        ..._weeklyDefinitions,
      ];

  CollectionReference<Map<String, dynamic>> _missionCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('missions');
  }

  Future<List<MissionProgress>> fetchMissions({
    required String uid,
  }) async {
    final snapshot = await _missionCollection(uid).get();
    final docs = {
      for (final doc in snapshot.docs) doc.id: doc,
    };

    final now = DateTime.now();
    final missions = <MissionProgress>[];
    final updates = <DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>{};

    for (final definition in definitions) {
      final doc = docs[definition.id];
      int progress = 0;
      bool isCompleted = false;
      bool isClaimed = false;
      DateTime? updatedAt;

      if (doc != null && doc.exists) {
        final data = doc.data();
        progress = ((data['progress'] ?? 0) as num).toInt();
        isCompleted = data['completed'] as bool? ?? false;
        isClaimed = data['claimed'] as bool? ?? false;
        if (data['updatedAt'] is Timestamp) {
          updatedAt = (data['updatedAt'] as Timestamp).toDate();
        }

        final shouldReset = _shouldReset(definition.type, updatedAt, now);
        if (shouldReset) {
          progress = 0;
          isCompleted = false;
          isClaimed = false;
          updatedAt = now;
          updates[doc.reference] = {
            'progress': 0,
            'completed': false,
            'claimed': false,
            'updatedAt': Timestamp.fromDate(now),
          };
        }
      }

      missions.add(MissionProgress(
        definition: definition,
        progress: progress,
        isCompleted: isCompleted,
        isClaimed: isClaimed,
        updatedAt: updatedAt,
      ));
    }

    if (updates.isNotEmpty) {
      final batch = _firestore.batch();
      updates.forEach(batch.update);
      await batch.commit();
    }

    return missions;
  }

  Future<void> updateMissionsOnGameResult({
    required String uid,
    required int score,
    required int wrongAnswers,
    required int maxCombo,
  }) async {
    final now = DateTime.now();
    for (final definition in definitions) {
      final delta = _calculateDelta(
        definition: definition,
        score: score,
        wrongAnswers: wrongAnswers,
        maxCombo: maxCombo,
      );

      if (delta <= 0) continue;
      await _applyProgress(
        uid: uid,
        definition: definition,
        delta: delta,
        forceComplete:
            definition.metric == MissionMetric.perfectGame && wrongAnswers == 0,
        now: now,
      );
    }
  }

  Future<MissionProgress> claimMissionReward({
    required String uid,
    required String missionId,
  }) async {
    final definition = definitions.firstWhere(
      (item) => item.id == missionId,
      orElse: () =>
          throw Exception('Mission definition bulunamadı: $missionId'),
    );

    final missionRef = _missionCollection(uid).doc(missionId);
    final userRef = _firestore.collection('users').doc(uid);
    final now = DateTime.now();

    final updatedData = await _firestore.runTransaction((transaction) async {
      final missionSnap = await transaction.get(missionRef);
      if (!missionSnap.exists) {
        throw Exception('Görev kaydı bulunamadı');
      }

      final missionData = missionSnap.data()!;
      final completed = missionData['completed'] as bool? ?? false;
      final claimed = missionData['claimed'] as bool? ?? false;

      if (!completed) {
        throw Exception('Görev henüz tamamlanmamış');
      }
      if (claimed) {
        throw Exception('Görev ödülü zaten alınmış');
      }

      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final userData = userSnap.data()!;
      final rewardValue = definition.rewardValue;

      final Map<String, dynamic> userUpdates = {};

      switch (definition.rewardType) {
        case MissionRewardType.xp:
          final currentXp = (userData['experience'] ?? 0) as int;
          final currentLevel = (userData['currentLevel'] ?? 1) as int;
          final newXp = currentXp + rewardValue;
          final computedLevel = max(_calculateLevel(newXp), currentLevel);
          userUpdates['experience'] = newXp;
          userUpdates['currentLevel'] = computedLevel;
          break;
        case MissionRewardType.pass:
          final currentPasses = (userData['passTokens'] ?? 0) as int;
          userUpdates['passTokens'] = currentPasses + rewardValue;
          break;
      }

      if (userUpdates.isNotEmpty) {
        transaction.update(userRef, userUpdates);
      }

      transaction.update(missionRef, {
        'claimed': true,
        'progress': definition.target,
        'updatedAt': Timestamp.fromDate(now),
        'claimedAt': Timestamp.fromDate(now),
      });

      return {
        'progress': definition.target,
        'completed': true,
        'claimed': true,
        'updatedAt': now,
      };
    });

    return MissionProgress(
      definition: definition,
      progress: updatedData['progress'] as int? ?? definition.target,
      isCompleted: updatedData['completed'] as bool? ?? true,
      isClaimed: updatedData['claimed'] as bool? ?? true,
      updatedAt: updatedData['updatedAt'] as DateTime?,
    );
  }

  int _calculateDelta({
    required MissionDefinition definition,
    required int score,
    required int wrongAnswers,
    required int maxCombo,
  }) {
    switch (definition.metric) {
      case MissionMetric.gamesPlayed:
        return 1;
      case MissionMetric.scoreAccumulated:
        return score;
      case MissionMetric.perfectGame:
        return wrongAnswers == 0 ? definition.target : 0;
      case MissionMetric.combo:
        return maxCombo;
    }
  }

  Future<void> _applyProgress({
    required String uid,
    required MissionDefinition definition,
    required int delta,
    required bool forceComplete,
    required DateTime now,
  }) async {
    final docRef = _missionCollection(uid).doc(definition.id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      var progress = 0;
      var completed = false;
      var claimed = false;
      DateTime? updatedAt;

      if (snapshot.exists) {
        final data = snapshot.data()!;
        progress = ((data['progress'] ?? 0) as num).toInt();
        completed = data['completed'] as bool? ?? false;
        claimed = data['claimed'] as bool? ?? false;
        if (data['updatedAt'] is Timestamp) {
          updatedAt = (data['updatedAt'] as Timestamp).toDate();
        }
      }

      if (_shouldReset(definition.type, updatedAt, now)) {
        progress = 0;
        completed = false;
        claimed = false;
      }

      if (completed && !forceComplete) {
        return;
      }

      progress = (progress + delta).clamp(0, definition.target);
      if (forceComplete) {
        progress = definition.target;
      }

      completed = progress >= definition.target;

      transaction.set(docRef, {
        'type': definition.type.name,
        'metric': definition.metric.name,
        'target': definition.target,
        'progress': progress,
        'completed': completed,
        'claimed': claimed,
        'rewardType': definition.rewardType.name,
        'rewardValue': definition.rewardValue,
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: false));
    });
  }

  bool _shouldReset(MissionType type, DateTime? lastUpdated, DateTime now) {
    if (lastUpdated == null) return false;

    switch (type) {
      case MissionType.daily:
        final lastDay = DateTime(lastUpdated.year, lastUpdated.month, lastUpdated.day);
        final today = DateTime(now.year, now.month, now.day);
        return today.isAfter(lastDay);
      case MissionType.weekly:
        return now.difference(lastUpdated).inDays >= 7;
    }
  }

  int _calculateLevel(int experience) => (experience ~/ 1000) + 1;
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';

class LeaderboardService {
  LeaderboardService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _entries(String language) {
    final normalized = language.toLowerCase();
    return _firestore
        .collection('leaderboards')
        .doc(normalized)
        .collection('entries');
  }

  Stream<List<LeaderboardEntry>> watchTopEntries({
    required String language,
    int limit = 50,
  }) {
    return _entries(language)
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      var rank = 1;
      return snapshot.docs.map((doc) {
        final entry = LeaderboardEntry.fromFirestore(doc.data(), doc.id);
        final ranked = entry.copyWith(rank: rank);
        rank += 1;
        return ranked;
      }).toList();
    });
  }

  Future<void> submitScore({
    required String uid,
    required String username,
    required String language,
    required int score,
    String? photoUrl,
  }) async {
    await _updateLeaderboard(
      uid: uid,
      username: username,
      language: language,
      score: score,
      photoUrl: photoUrl,
    );

    // Global leaderboard da güncellensin
    await _updateLeaderboard(
      uid: uid,
      username: username,
      language: 'global',
      score: score,
      photoUrl: photoUrl,
    );
  }

  Future<LeaderboardEntry?> fetchUserEntry({
    required String uid,
    required String language,
  }) async {
    final doc = await _entries(language).doc(uid).get();
    if (!doc.exists) return null;

    final entry = LeaderboardEntry.fromFirestore(doc.data()!, doc.id);
    final rank = await _calculateRank(language, entry.score);
    return entry.copyWith(rank: rank);
  }

  Future<int> _calculateRank(String language, int score) async {
    final aggregate = await _entries(language)
        .where('score', isGreaterThan: score)
        .count()
        .get();
    final betterCount = aggregate.count ?? 0;
    return betterCount + 1;
  }

  Future<void> _updateLeaderboard({
    required String uid,
    required String username,
    required String language,
    required int score,
    String? photoUrl,
  }) async {
    final entries = _entries(language);
    final docRef = entries.doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final currentScore = snapshot.exists
          ? (snapshot.data()?['score'] as int? ?? 0)
          : 0;
      if (score <= currentScore) {
        return;
      }

      transaction.set(docRef, {
        'username': username,
        'language': language.toLowerCase(),
        'score': score,
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

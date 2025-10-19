import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// Firestore'dan soru yönetimi için servis
class QuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 📚 DİL İÇİN SORULARI GETİR
  Future<List<Question>> getQuestionsByLanguage({
    required String language,
    int? limit,
    int? difficulty,
  }) async {
    try {
      final normalizedLanguage = language.trim().toLowerCase();
      print('📚 Sorular getiriliyor: $normalizedLanguage');

    Query<Map<String, dynamic>> query = _firestore
      .collection('questions')
          .where('language', isEqualTo: normalizedLanguage)
          .where('isActive', isEqualTo: true);

      // Zorluk seviyesi filtresi
      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty);
      }

      // Limit
      if (limit != null) {
        query = query.limit(limit);
      }

    var snapshot = await query.get();

    var questions = snapshot.docs
      .map((doc) => Question.fromFirestore(
        doc.data(),
        doc.id,
        ))
      .toList();

    // Firestore'da language field'ı farklı formatta tutulmuşsa esnek dönüşüm
    if (questions.isEmpty) {
    print('⚠️ Doğrudan sorguda sonuç yok. Esnek filtre uygulanıyor...');
    final fallbackSnapshot = await _firestore
      .collection('questions')
      .where('isActive', isEqualTo: true)
      .get();

    questions = fallbackSnapshot.docs
        .map((doc) => Question.fromFirestore(
          doc.data(),
          doc.id,
          ))
      .where((question) =>
        question.language.trim().toLowerCase() == normalizedLanguage ||
        question.language.trim().toLowerCase() ==
          _fallbackLanguageAlias(normalizedLanguage))
      .toList();
    }

      // Karıştır (random sıralama)
      questions.shuffle();

      print('✅ ${questions.length} soru bulundu');
      return questions;
    } catch (e) {
      print('❌ Soru getirme hatası: $e');
      return [];
    }
  }

  String _fallbackLanguageAlias(String normalizedLanguage) {
    switch (normalizedLanguage) {
      case 'csharp':
        return 'c#';
      case 'c#':
        return 'csharp';
      default:
        return normalizedLanguage;
    }
  }

  // 🎲 RASTGELE SORULAR GETİR
  Future<List<Question>> getRandomQuestions({
    required String language,
    required int count,
  }) async {
    try {
      final allQuestions = await getQuestionsByLanguage(
        language: language,
        limit: count * 3, // Daha fazla çek, sonra rastgele seç
      );

      allQuestions.shuffle();
      
      return allQuestions.take(count).toList();
    } catch (e) {
      print('❌ Rastgele soru hatası: $e');
      return [];
    }
  }

  // ➕ YENİ SORU EKLE (Admin için)
  Future<String?> addQuestion({
    required String language,
    required String codeSnippet,
    required bool isCorrect,
    String? explanation,
    int difficulty = 1,
    List<String> tags = const [],
  }) async {
    try {
      print('➕ Yeni soru ekleniyor...');
      
      final docRef = await _firestore.collection('questions').add({
        'language': language.toLowerCase(),
        'codeSnippet': codeSnippet,
        'isCorrect': isCorrect,
        'explanation': explanation,
        'difficulty': difficulty,
        'tags': tags,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Soru eklendi: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Soru ekleme hatası: $e');
      return null;
    }
  }

  // 📝 SORU GÜNCELLE (Admin için)
  Future<bool> updateQuestion({
    required String questionId,
    String? codeSnippet,
    bool? isCorrect,
    String? explanation,
    int? difficulty,
    List<String>? tags,
    bool? isActive,
  }) async {
    try {
      print('📝 Soru güncelleniyor: $questionId');
      
      Map<String, dynamic> updates = {};
      
      if (codeSnippet != null) updates['codeSnippet'] = codeSnippet;
      if (isCorrect != null) updates['isCorrect'] = isCorrect;
      if (explanation != null) updates['explanation'] = explanation;
      if (difficulty != null) updates['difficulty'] = difficulty;
      if (tags != null) updates['tags'] = tags;
      if (isActive != null) updates['isActive'] = isActive;
      
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('questions')
          .doc(questionId)
          .update(updates);

      print('✅ Soru güncellendi');
      return true;
    } catch (e) {
      print('❌ Soru güncelleme hatası: $e');
      return false;
    }
  }

  // 🗑️ SORU SİL (Soft delete - sadece devre dışı bırak)
  Future<bool> deactivateQuestion(String questionId) async {
    try {
      await _firestore
          .collection('questions')
          .doc(questionId)
          .update({'isActive': false});
      
      print('✅ Soru devre dışı bırakıldı: $questionId');
      return true;
    } catch (e) {
      print('❌ Soru silme hatası: $e');
      return false;
    }
  }

  // 📊 İSTATİSTİKLER
  Future<Map<String, int>> getQuestionStats() async {
    try {
      final snapshot = await _firestore
          .collection('questions')
          .where('isActive', isEqualTo: true)
          .get();

      Map<String, int> stats = {
        'total': snapshot.docs.length,
        'csharp': 0,
        'python': 0,
        'javascript': 0,
        'sql': 0,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final language = data['language'] as String;
        stats[language] = (stats[language] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('❌ İstatistik hatası: $e');
      return {'total': 0};
    }
  }

  // 🔍 SORU ARA (Tag veya içerik ile)
  Future<List<Question>> searchQuestions({
    String? tag,
    String? searchText,
  }) async {
    try {
      Query query = _firestore
          .collection('questions')
          .where('isActive', isEqualTo: true);

      if (tag != null && tag.isNotEmpty) {
        query = query.where('tags', arrayContains: tag);
      }

      final snapshot = await query.get();
      
      var questions = snapshot.docs
          .map((doc) => Question.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      // Metin araması (client-side)
      if (searchText != null && searchText.isNotEmpty) {
        questions = questions.where((q) => 
          q.codeSnippet.toLowerCase().contains(searchText.toLowerCase()) ||
          (q.explanation?.toLowerCase().contains(searchText.toLowerCase()) ?? false)
        ).toList();
      }

      return questions;
    } catch (e) {
      print('❌ Arama hatası: $e');
      return [];
    }
  }
}

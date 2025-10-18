import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service_v2.dart';
import '../utils/username_fixer.dart';

/// Username mapping'lerini kontrol ve düzeltmek için debug ekranı
/// Sadece geliştirme/test aşamasında kullanılmalı
class DebugUsernameScreen extends StatefulWidget {
  const DebugUsernameScreen({super.key});

  @override
  State<DebugUsernameScreen> createState() => _DebugUsernameScreenState();
}

class _DebugUsernameScreenState extends State<DebugUsernameScreen> {
  final _authService = AuthServiceV2();
  final _fixer = UsernameFixer();
  final _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  String _output = 'Username mapping kontrol ekranı\n\n';

  void _addOutput(String text) {
    setState(() {
      _output += '$text\n';
    });
  }

  Future<void> _checkCurrentUser() async {
    _addOutput('\n=== MEVCUT KULLANICI ===');
    
    final user = _authService.currentUser;
    if (user == null) {
      _addOutput('❌ Oturum açık kullanıcı yok');
      return;
    }

    _addOutput('✅ Email: ${user.email}');
    _addOutput('🆔 UID: ${user.uid}');

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final username = userDoc.data()?['username'];
        _addOutput('👤 Username: $username');

        // Username mapping kontrolü
        if (username != null) {
          final usernameDoc = await _firestore
              .collection('usernames')
              .doc(username)
              .get();
          
          if (usernameDoc.exists) {
            _addOutput('✅ Username mapping mevcut');
          } else {
            _addOutput('❌ Username mapping eksik!');
          }
        }
      } else {
        _addOutput('❌ Firestore profili yok');
      }
    } catch (e) {
      _addOutput('❌ Hata: $e');
    }
  }

  Future<void> _listAllUsers() async {
    _addOutput('\n=== TÜM KULLANICILAR ===');
    
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      _addOutput('📊 Toplam: ${usersSnapshot.docs.length} kullanıcı\n');

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final username = data['username'] ?? 'N/A';
        final email = data['email'] ?? 'N/A';
        
        _addOutput('👤 $username ($email)');
        
        // Username mapping kontrolü
        final usernameDoc = await _firestore
            .collection('usernames')
            .doc(username)
            .get();
        
        if (usernameDoc.exists) {
          _addOutput('   ✅ Mapping OK');
        } else {
          _addOutput('   ❌ Mapping eksik!');
        }
      }
    } catch (e) {
      _addOutput('❌ Hata: $e');
    }
  }

  Future<void> _listAllMappings() async {
    _addOutput('\n=== TÜM USERNAME MAPPINGS ===');
    
    try {
      final snapshot = await _firestore.collection('usernames').get();
      _addOutput('📊 Toplam: ${snapshot.docs.length} mapping\n');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        _addOutput('👤 ${doc.id}');
        _addOutput('   📧 ${data['email']}');
        _addOutput('   🆔 ${data['uid']}\n');
      }
    } catch (e) {
      _addOutput('❌ Hata: $e');
    }
  }

  Future<void> _fixAllMappings() async {
    _addOutput('\n=== MAPPING DÜZELTME ===');
    
    try {
      await _fixer.fixAllUsernames();
      _addOutput('✅ İşlem tamamlandı!');
      
      // Tekrar kontrol et
      await _listAllUsers();
    } catch (e) {
      _addOutput('❌ Hata: $e');
    }
  }

  Future<void> _fixCurrentUserMapping() async {
    _addOutput('\n=== MEVCUT KULLANICI İÇİN DÜZELTME ===');
    
    final user = _authService.currentUser;
    if (user == null) {
      _addOutput('❌ Oturum açık kullanıcı yok');
      return;
    }

    try {
      await _fixer.fixUsername(user.uid);
      _addOutput('✅ İşlem tamamlandı!');
      
      // Tekrar kontrol et
      await _checkCurrentUser();
    } catch (e) {
      _addOutput('❌ Hata: $e');
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _output = '';
    });

    try {
      await action();
    } catch (e) {
      _addOutput('\n❌ Genel hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Username Debug'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Butonlar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _runAction(_checkCurrentUser),
                  icon: const Icon(Icons.person),
                  label: const Text('Mevcut Kullanıcı'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _runAction(_listAllUsers),
                  icon: const Icon(Icons.people),
                  label: const Text('Tüm Kullanıcılar'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _runAction(_listAllMappings),
                  icon: const Icon(Icons.list),
                  label: const Text('Tüm Mappings'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _runAction(_fixCurrentUserMapping),
                  icon: const Icon(Icons.build),
                  label: const Text('Beni Düzelt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _runAction(_fixAllMappings),
                  icon: const Icon(Icons.build_circle),
                  label: const Text('Hepsini Düzelt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          
          // Loading
          if (_isLoading)
            const LinearProgressIndicator(),
          
          // Output
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _output,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

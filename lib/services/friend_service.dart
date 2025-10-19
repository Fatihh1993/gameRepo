import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';

class FriendService {
  FriendService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userCollection() =>
      _firestore.collection('users');

  Future<void> sendFriendRequest({
    required String fromUid,
    required String fromUsername,
    String? fromPhotoUrl,
    required String targetUsername,
  }) async {
    final normalizedTarget = targetUsername.trim().toLowerCase();
    if (normalizedTarget.isEmpty) {
      throw Exception('Kullanıcı adı boş olamaz');
    }

    // Kullanıcı adı mapping koleksiyonu
    final usernameDoc = await _firestore
        .collection('usernames')
        .doc(normalizedTarget)
        .get();

    if (!usernameDoc.exists) {
      throw Exception('Kullanıcı bulunamadı');
    }

    final data = usernameDoc.data() as Map<String, dynamic>;
    final targetUid = (data['uid'] ?? '').toString();
    if (targetUid.isEmpty) {
      throw Exception('Kullanıcı bulunamadı');
    }

    if (targetUid == fromUid) {
      throw Exception('Kendi kendinize istek gönderemezsiniz');
    }

    // Zaten arkadaş olup olmadığını kontrol et
    final existingFriend = await _userCollection()
        .doc(fromUid)
        .collection('friends')
        .doc(targetUid)
        .get();
    if (existingFriend.exists) {
      throw Exception('Bu kullanıcı zaten arkadaşınız');
    }

    final incomingFromTarget = await _userCollection()
        .doc(fromUid)
        .collection('friendRequests')
        .doc(targetUid)
        .get();
    if (incomingFromTarget.exists) {
      final status = (incomingFromTarget.data()?['status'] ?? 'pending')
          .toString()
          .toLowerCase();
      if (status == 'pending') {
        throw Exception('Bu kullanıcı size zaten istek gönderdi');
      }
    }

    final outgoingRef = _userCollection()
        .doc(fromUid)
        .collection('sentFriendRequests')
        .doc(targetUid);
    final existingOutgoing = await outgoingRef.get();
    if (existingOutgoing.exists) {
      final status = (existingOutgoing.data()?['status'] ?? 'pending')
          .toString()
          .toLowerCase();
      if (status == 'pending') {
        throw Exception('Bu kullanıcıya zaten istek gönderdiniz');
      }
    }

    final targetUserDoc = await _userCollection().doc(targetUid).get();
    if (!targetUserDoc.exists) {
      throw Exception('Kullanıcı bulunamadı');
    }
    final targetUserData = targetUserDoc.data() ?? {};

    final requestRef = _userCollection()
        .doc(targetUid)
        .collection('friendRequests')
        .doc(fromUid);

    final existingRequest = await requestRef.get();
    if (existingRequest.exists) {
      final status = (existingRequest.data()?['status'] ?? 'pending')
          .toString()
          .toLowerCase();
      if (status == 'pending') {
        throw Exception('Davet zaten beklemede');
      }
    }

    await requestRef.set({
      'requesterUid': fromUid,
      'requesterUsername': fromUsername,
      'requesterPhotoUrl': fromPhotoUrl,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await outgoingRef.set({
      'targetUid': targetUid,
      'targetUsername': targetUserData['username'] ?? targetUsername,
      'targetPhotoUrl': targetUserData['profileImageUrl'],
      'level': _readInt(targetUserData['currentLevel'], 1),
      'highScore': _readInt(targetUserData['highScore'], 0),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<FriendRequest>> watchIncomingRequests({
    required String uid,
  }) {
    return _userCollection()
        .doc(uid)
        .collection('friendRequests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map((doc) {
        final data = doc.data();
        final statusString = (data['status'] ?? 'pending').toString();
        final timestamp = data['createdAt'];
        DateTime createdAt = DateTime.now();
        if (timestamp is Timestamp) {
          createdAt = timestamp.toDate();
        } else if (timestamp is String) {
          createdAt = DateTime.tryParse(timestamp) ?? DateTime.now();
        }

        return FriendRequest(
          uid: data['requesterUid'] ?? doc.id,
          username: data['requesterUsername'] ?? 'player',
          photoUrl: data['requesterPhotoUrl'] as String?,
          status: _mapStatus(statusString),
          createdAt: createdAt,
          isOutgoing: false,
        );
      }).where((request) => request.status == FriendRequestStatus.pending).toList();

      return requests;
    });
  }

  Stream<List<FriendSummary>> watchFriends({
    required String uid,
  }) {
    return _userCollection()
        .doc(uid)
        .collection('friends')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['addedAt'];
        DateTime addedAt = DateTime.now();
        if (timestamp is Timestamp) {
          addedAt = timestamp.toDate();
        } else if (timestamp is String) {
          addedAt = DateTime.tryParse(timestamp) ?? DateTime.now();
        }
        return FriendSummary(
          uid: doc.id,
          username: data['username'] ?? 'player',
          level: (data['level'] ?? 1) is int
              ? data['level'] as int
              : int.tryParse(data['level'].toString()) ?? 1,
          highScore: (data['highScore'] ?? 0) is int
              ? data['highScore'] as int
              : int.tryParse(data['highScore'].toString()) ?? 0,
          addedAt: addedAt,
          photoUrl: data['photoUrl'] as String?,
        );
      }).toList();
    });
  }

  Stream<List<FriendRequest>> watchOutgoingRequests({
    required String uid,
  }) {
    return _userCollection()
        .doc(uid)
        .collection('sentFriendRequests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map((doc) {
        final data = doc.data();
        final statusString = (data['status'] ?? 'pending').toString();
        final timestamp = data['createdAt'];
        DateTime createdAt = DateTime.now();
        if (timestamp is Timestamp) {
          createdAt = timestamp.toDate();
        } else if (timestamp is String) {
          createdAt = DateTime.tryParse(timestamp) ?? DateTime.now();
        }

        return FriendRequest(
          uid: data['targetUid'] ?? doc.id,
          username: data['targetUsername'] ?? 'player',
          photoUrl: data['targetPhotoUrl'] as String?,
          status: _mapStatus(statusString),
          createdAt: createdAt,
          isOutgoing: true,
        );
      }).where((request) => request.status == FriendRequestStatus.pending).toList();

      return requests;
    });
  }

  Future<FriendUserPreview> findUserByUsername({
    required String currentUid,
    required String username,
  }) async {
    final normalizedTarget = username.trim().toLowerCase();
    if (normalizedTarget.isEmpty) {
      throw Exception('Kullanıcı adı boş olamaz');
    }

    final usernameDoc = await _firestore
        .collection('usernames')
        .doc(normalizedTarget)
        .get();

    if (!usernameDoc.exists) {
      throw Exception('Kullanıcı bulunamadı');
    }

    final data = usernameDoc.data() as Map<String, dynamic>;
    final targetUid = (data['uid'] ?? '').toString();
    if (targetUid.isEmpty) {
      throw Exception('Kullanıcı bulunamadı');
    }

    if (targetUid == currentUid) {
      throw Exception('Kendi kullanıcı adınızı arıyorsunuz');
    }

    final currentFriendsDoc = await _userCollection()
        .doc(currentUid)
        .collection('friends')
        .doc(targetUid)
        .get();
    if (currentFriendsDoc.exists) {
      throw Exception('Bu kullanıcı zaten arkadaşınız');
    }

    final incomingFromTarget = await _userCollection()
        .doc(currentUid)
        .collection('friendRequests')
        .doc(targetUid)
        .get();
    if (incomingFromTarget.exists) {
      final status = (incomingFromTarget.data()?['status'] ?? 'pending')
          .toString()
          .toLowerCase();
      if (status == 'pending') {
        throw Exception('Bu kullanıcı size zaten istek gönderdi');
      }
    }

    final existingOutgoing = await _userCollection()
        .doc(currentUid)
        .collection('sentFriendRequests')
        .doc(targetUid)
        .get();
    if (existingOutgoing.exists) {
      final status = (existingOutgoing.data()?['status'] ?? 'pending')
          .toString()
          .toLowerCase();
      if (status == 'pending') {
        throw Exception('Bu kullanıcıya zaten istek gönderdiniz');
      }
    }

    final targetUserDoc = await _userCollection().doc(targetUid).get();
    if (!targetUserDoc.exists) {
      throw Exception('Kullanıcı bulunamadı');
    }

    final targetUserData = targetUserDoc.data() ?? {};

    return FriendUserPreview(
      uid: targetUid,
      username: targetUserData['username'] ?? username,
      photoUrl: targetUserData['profileImageUrl'] as String?,
      level: _readInt(targetUserData['currentLevel'], 1),
      highScore: _readInt(targetUserData['highScore'], 0),
    );
  }

  Future<void> respondToFriendRequest({
    required String uid,
    required String requesterUid,
    required bool accept,
  }) async {
    final requestRef = _userCollection()
        .doc(uid)
        .collection('friendRequests')
        .doc(requesterUid);

    String? errorMessage;

    await _firestore.runTransaction((transaction) async {
      final requestSnap = await transaction.get(requestRef);
      if (!requestSnap.exists) {
        errorMessage = 'Arkadaşlık isteği bulunamadı';
        return;
      }

      final requestData = requestSnap.data()!;
      final status = (requestData['status'] ?? 'pending').toString();
      if (status != 'pending') {
        errorMessage = 'İstek zaten yanıtlanmış';
        return;
      }

      final currentUserRef = _userCollection().doc(uid);
      final requesterRef = _userCollection().doc(requesterUid);
      final requesterOutgoingRef =
          requesterRef.collection('sentFriendRequests').doc(uid);

      final requesterOutgoingSnap = await transaction.get(requesterOutgoingRef);

      if (!accept) {
        transaction.delete(requestRef);
        if (requesterOutgoingSnap.exists) {
          transaction.delete(requesterOutgoingRef);
        }
        return;
      }

      final requesterSnap = await transaction.get(requesterRef);
      if (!requesterSnap.exists) {
        errorMessage = 'Gönderen kullanıcı bulunamadı';
        return;
      }

      final currentUserSnap = await transaction.get(currentUserRef);

      final currentData = currentUserSnap.data() ?? {};
      final requesterData = requesterSnap.data() ?? {};

      final currentFriendRef =
          currentUserRef.collection('friends').doc(requesterUid);
      final requesterFriendRef =
          requesterRef.collection('friends').doc(uid);
      final nowTimestamp = Timestamp.now();

      transaction.set(currentFriendRef, {
        'username': requesterData['username'] ?? 'player',
        'photoUrl': requesterData['profileImageUrl'],
        'level': _readInt(requesterData['currentLevel'], 1),
        'highScore': _readInt(requesterData['highScore'], 0),
        'addedAt': nowTimestamp,
      });

      transaction.set(requesterFriendRef, {
        'username': currentData['username'] ?? 'player',
        'photoUrl': currentData['profileImageUrl'],
        'level': _readInt(currentData['currentLevel'], 1),
        'highScore': _readInt(currentData['highScore'], 0),
        'addedAt': nowTimestamp,
      });

      transaction.delete(requestRef);
      if (requesterOutgoingSnap.exists) {
        transaction.delete(requesterOutgoingRef);
      }
    });

    if (errorMessage != null) {
      throw Exception(errorMessage);
    }
  }

  Future<void> removeFriend({
    required String uid,
    required String friendUid,
  }) async {
    final userFriendRef =
        _userCollection().doc(uid).collection('friends').doc(friendUid);
    final friendRef =
        _userCollection().doc(friendUid).collection('friends').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final userFriendSnap = await transaction.get(userFriendRef);
      final friendSnap = await transaction.get(friendRef);

      if (userFriendSnap.exists) {
        transaction.delete(userFriendRef);
      }

      if (friendSnap.exists) {
        transaction.delete(friendRef);
      }
    });
  }

  int _readInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  FriendRequestStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return FriendRequestStatus.accepted;
      case 'rejected':
        return FriendRequestStatus.rejected;
      default:
        return FriendRequestStatus.pending;
    }
  }
}

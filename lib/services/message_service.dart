import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';

class MessageService {
  MessageService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _conversationId(String uidA, String uidB) {
    if (uidA.compareTo(uidB) < 0) {
      return '${uidA}_$uidB';
    }
    return '${uidB}_$uidA';
  }

  Future<void> sendMessage({
    required String fromUid,
    required String fromUsername,
    String? fromPhotoUrl,
    required String toUid,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw Exception('Mesaj boş olamaz');
    }

    if (fromUid == toUid) {
      throw Exception('Kendinize mesaj gönderemezsiniz');
    }

    final senderFriendRef = _firestore
        .collection('users')
        .doc(fromUid)
        .collection('friends')
        .doc(toUid);
    final receiverFriendRef = _firestore
        .collection('users')
        .doc(toUid)
        .collection('friends')
        .doc(fromUid);

    final conversationId = _conversationId(fromUid, toUid);
    final conversationRef =
        _firestore.collection('conversations').doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc();
    final messageId = messageRef.id;

    final senderConversationRef = _firestore
        .collection('users')
        .doc(fromUid)
        .collection('conversations')
        .doc(toUid);
    final receiverConversationRef = _firestore
        .collection('users')
        .doc(toUid)
        .collection('conversations')
        .doc(fromUid);

    final incomingRef = _firestore
        .collection('users')
        .doc(toUid)
        .collection('inbox')
        .doc(messageId);

    final outgoingRef = _firestore
        .collection('users')
        .doc(fromUid)
        .collection('outbox')
        .doc(messageId);

    await _firestore.runTransaction((transaction) async {
      final senderFriendSnap = await transaction.get(senderFriendRef);
      final receiverFriendSnap = await transaction.get(receiverFriendRef);

      if (!senderFriendSnap.exists || !receiverFriendSnap.exists) {
        throw Exception('Mesaj göndermek için önce arkadaş olmalısınız');
      }

      final senderFriendData = senderFriendSnap.data()!;
      final receiverFriendData = receiverFriendSnap.data()!;
      final now = FieldValue.serverTimestamp();

      transaction.set(messageRef, {
        'id': messageId,
        'senderUid': fromUid,
        'receiverUid': toUid,
        'text': trimmed,
        'createdAt': now,
      });

      transaction.set(
        conversationRef,
        {
          'participants': [fromUid, toUid],
          'updatedAt': now,
          'lastMessage': trimmed,
          'lastMessageSenderUid': fromUid,
          'lastMessageAt': now,
        },
        SetOptions(merge: true),
      );

      transaction.set(
        senderConversationRef,
        {
          'friendUid': toUid,
          'friendUsername': senderFriendData['username'] ?? '',
          'friendPhotoUrl': senderFriendData['photoUrl'],
          'lastMessage': trimmed,
          'lastMessageAt': now,
          'lastMessageSenderUid': fromUid,
          'unreadCount': 0,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );

      transaction.set(
        receiverConversationRef,
        {
          'friendUid': fromUid,
          'friendUsername': receiverFriendData['username'] ?? fromUsername,
          'friendPhotoUrl': receiverFriendData['photoUrl'],
          'lastMessage': trimmed,
          'lastMessageAt': now,
          'lastMessageSenderUid': fromUid,
          'unreadCount': FieldValue.increment(1),
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );

      transaction.set(incomingRef, {
        'id': messageId,
        'senderUid': fromUid,
        'senderUsername': fromUsername,
        'senderPhotoUrl': fromPhotoUrl,
        'text': trimmed,
        'createdAt': now,
        'isRead': false,
      });

      transaction.set(outgoingRef, {
        'id': messageId,
        'receiverUid': toUid,
        'text': trimmed,
        'createdAt': now,
      });
    });
  }

  Stream<List<ConversationPreview>> watchConversations({required String uid}) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('conversations')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ConversationPreview.fromFirestore(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Stream<int> watchUnreadCount({required String uid}) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('conversations')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.fold<int>(0, (sum, doc) {
        final data = doc.data();
        final unread = (data['unreadCount'] ?? 0);
        if (unread is int) {
          return sum + unread;
        }
        if (unread is num) {
          return sum + unread.toInt();
        }
        if (unread is String) {
          return sum + (int.tryParse(unread) ?? 0);
        }
        return sum;
      });
    });
  }

  Stream<List<ConversationMessage>> watchConversationMessages({
    required String uid,
    required String friendUid,
  }) {
    final conversationId = _conversationId(uid, friendUid);
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ConversationMessage.fromFirestore(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Future<void> markConversationAsRead({
    required String uid,
    required String friendUid,
  }) async {
    final conversationRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('conversations')
        .doc(friendUid);

    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();

    batch.set(
      conversationRef,
      {
        'unreadCount': 0,
        'lastReadAt': timestamp,
      },
      SetOptions(merge: true),
    );

    final inboxQuery = await _firestore
        .collection('users')
        .doc(uid)
        .collection('inbox')
        .where('senderUid', isEqualTo: friendUid)
        .where('isRead', isEqualTo: false)
        .limit(50)
        .get();

    for (final doc in inboxQuery.docs) {
      batch.set(
        doc.reference,
        {
          'isRead': true,
          'readAt': timestamp,
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }
}

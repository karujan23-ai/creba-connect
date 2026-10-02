import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/conversation.dart';
import 'firestore_paths.dart';

/// Real-time chat. A conversation document holds the summary (last message,
/// unread counts) and its `messages` sub-collection holds the messages.
class ChatService {
  ChatService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection(FirestorePaths.conversations);

  CollectionReference<Map<String, dynamic>> _messages(String conversationId) =>
      _conversations.doc(conversationId).collection(FirestorePaths.messages);

  /// Every conversation the user takes part in, live.
  Stream<List<Conversation>> watchConversations(String uid) => _conversations
      .where('participants', arrayContains: uid)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Conversation.fromJson(doc.data(), doc.id))
            .toList(),
      );

  /// The latest messages of one conversation, oldest first, live.
  /// Firestore pushes each new message to both phones as soon as it is saved.
  Stream<List<Message>> watchMessages(String conversationId) =>
      _messages(conversationId)
          .orderBy('createdAt')
          .limitToLast(200)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Message.fromJson(doc.data(), doc.id))
                .toList(),
          );

  /// Saves the message and updates the conversation summary in one step.
  /// If this is the first message, the conversation is created here too.
  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String text,
  }) {
    final conversationId = Conversation.idFor(senderId, receiverId);
    final participants = [senderId, receiverId]..sort();
    final batch = _db.batch();

    batch.set(
      _conversations.doc(conversationId),
      {
        'participants': participants,
        'participantNames': {senderId: senderName, receiverId: receiverName},
        'lastMessage': text,
        'lastSenderId': senderId,
        'unreadCounts': {receiverId: FieldValue.increment(1)},
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(_messages(conversationId).doc(), {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
    return batch.commit();
  }

  /// Clears the user's unread counter and marks the messages they received
  /// as read, so the sender sees the read status.
  Future<void> markRead(String conversationId, String uid) async {
    final unread = await _messages(conversationId)
        .where('receiverId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    batch.update(_conversations.doc(conversationId), {'unreadCounts.$uid': 0});
    await batch.commit();
  }
}

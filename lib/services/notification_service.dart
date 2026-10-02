import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';
import 'firestore_paths.dart';

/// In-app notifications stored in Firestore.
///
/// These are written by the app of the person who caused the event (for
/// example, the creator who applied). A production system would create them
/// from a backend instead; that is listed as a future improvement.
class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection(FirestorePaths.notifications);

  Future<void> send({
    required String recipientId,
    required String senderId,
    required String type,
    required String title,
    required String body,
    String? relatedId,
  }) =>
      _notifications.add({
        'recipientId': recipientId,
        'senderId': senderId,
        'type': type,
        'title': title,
        'body': body,
        'relatedId': relatedId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

  /// A user's notifications, live.
  Stream<List<AppNotification>> watchFor(String uid) => _notifications
      .where('recipientId', isEqualTo: uid)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromJson(doc.data(), doc.id))
            .toList(),
      );

  Future<void> markRead(String id) => _notifications.doc(id).update({'read': true});

  Future<void> markAllRead(List<String> ids) {
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(_notifications.doc(id), {'read': true});
    }
    return batch.commit();
  }

  Future<void> delete(String id) => _notifications.doc(id).delete();
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enums.dart';
import '../models/promotion.dart';
import 'firestore_paths.dart';

/// Promotion requests and subscription plans.
///
/// A user can only *request* a promotion. Making it active is an admin (or,
/// later, payment-backend) action, enforced by the security rules.
class PromotionService {
  PromotionService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _promotions =>
      _db.collection(FirestorePaths.promotions);

  Future<void> request(Promotion promotion) => _promotions.add({
        ...promotion.toJson(),
        'status': PromotionStatus.requested.value,
        'startsAt': null,
        'endsAt': null,
        'paymentId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Stream<List<Promotion>> watchForOwner(String ownerId) => _promotions
      .where('ownerId', isEqualTo: ownerId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Promotion.fromJson(doc.data(), doc.id))
            .toList(),
      );

  /// A request can be cancelled only while it is still waiting.
  Future<void> cancel(String id) => _promotions.doc(id).delete();

  /// The user's plan. No document means the Free plan.
  Stream<Subscription> watchSubscription(String uid) => _db
      .collection(FirestorePaths.subscriptions)
      .doc(uid)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? Subscription.fromJson(snapshot.data()!, uid)
            : Subscription(userId: uid),
      );
}

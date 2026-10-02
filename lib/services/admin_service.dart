import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/promotion.dart';
import 'firestore_paths.dart';

/// Headline numbers for the admin dashboard.
class AdminCounts {
  const AdminCounts({
    this.creators = 0,
    this.brands = 0,
    this.hiringPosts = 0,
    this.availabilityPosts = 0,
    this.applications = 0,
    this.activeUsers = 0,
    this.revenueNpr = 0,
  });

  final int creators;
  final int brands;
  final int hiringPosts;
  final int availabilityPosts;
  final int applications;

  /// Users who opened the app in the last 7 days.
  final int activeUsers;

  /// Sum of recorded payments. Stays 0 until a payment backend exists.
  final num revenueNpr;
}

/// Admin-only operations. Every write here is also checked by the Firestore
/// security rules, so a normal user calling these would simply be refused.
class AdminService {
  AdminService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _collection(String path) =>
      _db.collection(path);

  // ---------------------------------------------------------------- reading

  Stream<List<AppUser>> watchUsers({required int limit}) =>
      _collection(FirestorePaths.users)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AppUser.fromJson(doc.data(), doc.id))
                .toList(),
          );

  Stream<List<Promotion>> watchPromotions({required int limit}) =>
      _collection(FirestorePaths.promotions)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Promotion.fromJson(doc.data(), doc.id))
                .toList(),
          );

  Stream<List<Payment>> watchPayments({required int limit}) =>
      _collection(FirestorePaths.payments)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Payment.fromJson(doc.data(), doc.id))
                .toList(),
          );

  Stream<List<Subscription>> watchSubscriptions() =>
      _collection(FirestorePaths.subscriptions).snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => Subscription.fromJson(doc.data(), doc.id))
                .toList(),
          );

  /// Uses Firestore's count queries, which read no documents and so cost
  /// far less than downloading whole collections.
  Future<AdminCounts> loadCounts() async {
    Future<int> count(Query<Map<String, dynamic>> query) async =>
        (await query.count().get()).count ?? 0;

    final users = _collection(FirestorePaths.users);
    final weekAgo = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 7)),
    );

    final results = await Future.wait([
      count(users.where('role', isEqualTo: UserRole.creator.value)),
      count(users.where('role', isEqualTo: UserRole.brand.value)),
      count(_collection(FirestorePaths.hiringPosts)),
      count(_collection(FirestorePaths.availabilityPosts)),
      count(_collection(FirestorePaths.applications)),
      count(users.where('lastActiveAt', isGreaterThan: weekAgo)),
    ]);

    final payments = await _collection(FirestorePaths.payments).get();
    final revenue = payments.docs.fold<num>(
      0,
      (total, doc) => total + (doc.data()['amount'] is num ? doc.data()['amount'] as num : 0),
    );

    return AdminCounts(
      creators: results[0],
      brands: results[1],
      hiringPosts: results[2],
      availabilityPosts: results[3],
      applications: results[4],
      activeUsers: results[5],
      revenueNpr: revenue,
    );
  }

  // ----------------------------------------------------------- verification

  /// Marks a brand verified or rejected, updates the badge on all of its
  /// posts, tells the brand, and records who did it.
  Future<void> setVerification({
    required String brandId,
    required String brandName,
    required VerificationStatus status,
    required String adminId,
    String? rejectionReason,
  }) async {
    final posts = await _collection(FirestorePaths.hiringPosts)
        .where('brandId', isEqualTo: brandId)
        .get();
    final brandDoc = _collection(FirestorePaths.brandProfiles).doc(brandId);
    final isVerified = status == VerificationStatus.verified;

    final batch = _db.batch();
    batch.update(brandDoc, {
      'verificationStatus': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      brandDoc
          .collection(FirestorePaths.brandPrivate)
          .doc(FirestorePaths.brandVerificationDoc),
      {
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': isVerified ? null : rejectionReason,
      },
      SetOptions(merge: true),
    );
    for (final post in posts.docs) {
      batch.update(post.reference, {'brandVerified': isVerified});
    }
    batch.set(_collection(FirestorePaths.notifications).doc(), {
      'recipientId': brandId,
      'senderId': adminId,
      'type': NotificationType.verification,
      'title': isVerified ? 'Business verified' : 'Verification not approved',
      'body': isVerified
          ? 'Your business is now shown with a verified badge.'
          : (rejectionReason?.isNotEmpty ?? false)
              ? 'Reason: $rejectionReason'
              : 'Please check your PAN details and submit again.',
      'relatedId': brandId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _addLog(batch, adminId, 'brand_${status.value}', brandId, brandName);
    await batch.commit();
  }

  // ------------------------------------------------------------- moderation

  Future<void> setUserActive({
    required String uid,
    required String name,
    required bool isActive,
    required String adminId,
  }) {
    final batch = _db.batch();
    batch.update(_collection(FirestorePaths.users).doc(uid), {'isActive': isActive});
    _addLog(batch, adminId, isActive ? 'user_reactivated' : 'user_suspended', uid, name);
    return batch.commit();
  }

  Future<void> deleteContent({
    required String collection,
    required String id,
    required String label,
    required String adminId,
  }) {
    final batch = _db.batch();
    batch.delete(_collection(collection).doc(id));
    _addLog(batch, adminId, 'content_deleted', id, label);
    return batch.commit();
  }

  // -------------------------------------------------- promotions and plans

  /// Activates a promotion by hand. No payment is collected or recorded;
  /// this exists so the "Promoted" feature can be demonstrated before a
  /// payment backend is connected.
  Future<void> approvePromotion(Promotion promotion, String adminId) {
    final endsAt = Timestamp.fromDate(
      DateTime.now().add(Duration(days: promotion.packageDays)),
    );
    final isPost = promotion.targetType == TargetType.hiringPost;

    final batch = _db.batch();
    batch.update(_collection(FirestorePaths.promotions).doc(promotion.id), {
      'status': PromotionStatus.active.value,
      'startsAt': FieldValue.serverTimestamp(),
      'endsAt': endsAt,
    });
    batch.update(
      _collection(isPost ? FirestorePaths.hiringPosts : FirestorePaths.creatorProfiles)
          .doc(promotion.targetId),
      {isPost ? 'promotedUntil' : 'boostedUntil': endsAt},
    );
    batch.set(_collection(FirestorePaths.notifications).doc(), {
      'recipientId': promotion.ownerId,
      'senderId': adminId,
      'type': NotificationType.promotion,
      'title': 'Promotion approved',
      'body': '"${promotion.targetLabel}" is promoted for ${promotion.packageDays} days.',
      'relatedId': promotion.targetId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _addLog(batch, adminId, 'promotion_approved', promotion.id, promotion.targetLabel);
    return batch.commit();
  }

  Future<void> rejectPromotion(Promotion promotion, String adminId) {
    final batch = _db.batch();
    batch.update(_collection(FirestorePaths.promotions).doc(promotion.id), {
      'status': PromotionStatus.rejected.value,
    });
    _addLog(batch, adminId, 'promotion_rejected', promotion.id, promotion.targetLabel);
    return batch.commit();
  }

  /// Sets a user's plan by hand. Real billing is not connected.
  Future<void> setPlan({
    required String uid,
    required String name,
    required SubscriptionPlan plan,
    required String adminId,
  }) {
    final batch = _db.batch();
    batch.set(_collection(FirestorePaths.subscriptions).doc(uid), {
      'userId': uid,
      'plan': plan.value,
      'status': plan == SubscriptionPlan.free ? 'cancelled' : 'active',
      'startedAt': FieldValue.serverTimestamp(),
      'expiresAt': null,
    });
    _addLog(batch, adminId, 'plan_set_${plan.value}', uid, name);
    return batch.commit();
  }

  void _addLog(
    WriteBatch batch,
    String adminId,
    String action,
    String targetId,
    String details,
  ) {
    batch.set(_collection(FirestorePaths.adminLogs).doc(), {
      'adminId': adminId,
      'action': action,
      'targetId': targetId,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

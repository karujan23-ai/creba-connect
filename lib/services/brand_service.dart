import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/brand_profile.dart';
import '../models/enums.dart';
import 'firestore_paths.dart';

/// Firestore access for brand profiles (`brandProfiles/{uid}`) and their
/// private verification details.
class BrandService {
  BrandService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _db.collection(FirestorePaths.brandProfiles);

  DocumentReference<Map<String, dynamic>> _verificationDoc(String uid) =>
      _profiles
          .doc(uid)
          .collection(FirestorePaths.brandPrivate)
          .doc(FirestorePaths.brandVerificationDoc);

  BrandProfile _fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) =>
      BrandProfile.fromJson(snapshot.data()!, snapshot.id);

  /// CREATE — every new brand starts as "pending". The PAN number goes into
  /// the private sub-document so other users cannot read it.
  Future<void> createProfile(BrandProfile profile, {String panNumber = ''}) {
    final batch = _db.batch();
    batch.set(_profiles.doc(profile.uid), {
      ...profile.toEditableJson(),
      'verificationStatus': VerificationStatus.pending.value,
      'viewCount': 0,
      'saveCount': 0,
      'isDemo': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_verificationDoc(profile.uid), {
      'panNumber': panNumber,
      'submittedAt': panNumber.isEmpty ? null : FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  Stream<BrandProfile?> watchProfile(String uid) =>
      _profiles.doc(uid).snapshots().map(
            (snapshot) => snapshot.exists ? _fromSnapshot(snapshot) : null,
          );

  Future<BrandProfile?> getProfile(String uid) async {
    final snapshot = await _profiles.doc(uid).get();
    return snapshot.exists ? _fromSnapshot(snapshot) : null;
  }

  Stream<List<BrandProfile>> watchBrands({required int limit}) => _profiles
      .orderBy('updatedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(_fromSnapshot).toList());

  Future<void> updateProfile(BrandProfile profile) =>
      _profiles.doc(profile.uid).update({
        ...profile.toEditableJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Stream<BrandVerification?> watchVerification(String uid) =>
      _verificationDoc(uid).snapshots().map(
            (snapshot) => snapshot.exists
                ? BrandVerification.fromJson(snapshot.data()!)
                : null,
          );

  Future<BrandVerification?> getVerification(String uid) async {
    final snapshot = await _verificationDoc(uid).get();
    return snapshot.exists ? BrandVerification.fromJson(snapshot.data()!) : null;
  }

  /// Saves the PAN details and puts the brand back in the "pending" queue
  /// for an admin to review. Because the brand is no longer verified, the
  /// badge is also removed from its existing posts in the same step.
  Future<void> submitVerification(
    String uid, {
    required String panNumber,
    String? panDocumentUrl,
  }) async {
    final posts = await _db
        .collection(FirestorePaths.hiringPosts)
        .where('brandId', isEqualTo: uid)
        .get();

    final batch = _db.batch();
    for (final post in posts.docs) {
      batch.update(post.reference, {'brandVerified': false});
    }
    batch.set(
      _verificationDoc(uid),
      {
        'panNumber': panNumber,
        'panDocumentUrl': panDocumentUrl,
        'submittedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
      },
      SetOptions(merge: true),
    );
    batch.update(_profiles.doc(uid), {
      'verificationStatus': VerificationStatus.pending.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> recordView(String uid) =>
      _profiles.doc(uid).update({'viewCount': FieldValue.increment(1)});
}

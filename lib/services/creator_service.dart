import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/creator_profile.dart';
import 'firestore_paths.dart';

/// Firestore access for creator profiles (`creatorProfiles/{uid}`).
class CreatorService {
  CreatorService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _db.collection(FirestorePaths.creatorProfiles);

  CreatorProfile _fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) =>
      CreatorProfile.fromJson(snapshot.data()!, snapshot.id);

  /// CREATE — the document ID is the creator's own UID.
  Future<void> createProfile(CreatorProfile profile) =>
      _profiles.doc(profile.uid).set({
        ...profile.toEditableJson(),
        'viewCount': 0,
        'saveCount': 0,
        'isDemo': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// READ — live updates for one profile.
  Stream<CreatorProfile?> watchProfile(String uid) =>
      _profiles.doc(uid).snapshots().map(
            (snapshot) => snapshot.exists ? _fromSnapshot(snapshot) : null,
          );

  Future<CreatorProfile?> getProfile(String uid) async {
    final snapshot = await _profiles.doc(uid).get();
    return snapshot.exists ? _fromSnapshot(snapshot) : null;
  }

  /// READ — the most recently updated creators, live.
  Stream<List<CreatorProfile>> watchCreators({required int limit}) => _profiles
      .orderBy('updatedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(_fromSnapshot).toList());

  /// UPDATE — only the fields the owner is allowed to change.
  Future<void> updateProfile(CreatorProfile profile) =>
      _profiles.doc(profile.uid).update({
        ...profile.toEditableJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setAvailability(String uid, {required bool isAvailable}) =>
      _profiles.doc(uid).update({
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Adds one to the profile's view counter.
  Future<void> recordView(String uid) =>
      _profiles.doc(uid).update({'viewCount': FieldValue.increment(1)});
}

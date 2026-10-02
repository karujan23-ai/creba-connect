import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/availability_post.dart';
import 'firestore_paths.dart';

/// Firestore access for creator availability posts.
class AvailabilityService {
  AvailabilityService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection(FirestorePaths.availabilityPosts);

  List<AvailabilityPost> _fromQuery(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map((doc) => AvailabilityPost.fromJson(doc.data(), doc.id))
          .toList();

  /// CREATE
  Future<void> createPost(AvailabilityPost post) => _posts.add({
        ...post.toEditableJson(),
        'creatorId': post.creatorId,
        'creatorName': post.creatorName,
        'isDemo': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// READ — one creator's own posts, live.
  Stream<List<AvailabilityPost>> watchByCreator(String creatorId) => _posts
      .where('creatorId', isEqualTo: creatorId)
      .snapshots()
      .map(_fromQuery);

  /// READ — the newest posts from everyone, for brands to browse.
  Stream<List<AvailabilityPost>> watchLatest({required int limit}) => _posts
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(_fromQuery);

  /// UPDATE
  Future<void> updatePost(AvailabilityPost post) => _posts.doc(post.id).update({
        ...post.toEditableJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setActive(String id, {required bool isActive}) =>
      _posts.doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// DELETE
  Future<void> deletePost(String id) => _posts.doc(id).delete();
}

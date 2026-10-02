import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enums.dart';
import '../models/hiring_post.dart';
import 'firestore_paths.dart';

/// Firestore access for hiring posts (`hiringPosts/{id}`).
/// This one collection demonstrates all four CRUD operations.
class HiringPostService {
  HiringPostService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection(FirestorePaths.hiringPosts);

  HiringPost _fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) =>
      HiringPost.fromJson(snapshot.data()!, snapshot.id);

  List<HiringPost> _fromQuery(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs.map(_fromSnapshot).toList();

  /// CREATE — `brandId` ties the post to the signed-in brand's UID.
  Future<String> createPost(HiringPost post) async {
    final reference = await _posts.add({
      ...post.toEditableJson(),
      'brandId': post.brandId,
      'brandName': post.brandName,
      'brandVerified': post.brandVerified,
      'viewCount': 0,
      'applicationCount': 0,
      'isDemo': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }

  /// READ — the newest posts, live. New posts appear without refreshing.
  Stream<List<HiringPost>> watchLatest({required int limit}) => _posts
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(_fromQuery);

  /// READ — every post owned by one brand, live.
  Stream<List<HiringPost>> watchByBrand(String brandId) =>
      _posts.where('brandId', isEqualTo: brandId).snapshots().map(_fromQuery);

  Future<List<HiringPost>> getOpenPostsByBrand(String brandId) async {
    final snapshot = await _posts.where('brandId', isEqualTo: brandId).get();
    return _fromQuery(snapshot).where((post) => post.isOpen).toList();
  }

  Future<HiringPost?> getPost(String id) async {
    final snapshot = await _posts.doc(id).get();
    return snapshot.exists ? _fromSnapshot(snapshot) : null;
  }

  /// UPDATE — only the fields the owner may edit.
  Future<void> updatePost(HiringPost post) => _posts.doc(post.id).update({
        ...post.toEditableJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setStatus(String id, PostStatus status) => _posts.doc(id).update({
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// DELETE
  Future<void> deletePost(String id) => _posts.doc(id).delete();

  Future<void> recordView(String id) =>
      _posts.doc(id).update({'viewCount': FieldValue.increment(1)});
}

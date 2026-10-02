import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enums.dart';
import '../models/favorite.dart';
import 'firestore_paths.dart';

/// Saved creators, brands and opportunities (`favorites/{userId_targetId}`).
class FavoritesService {
  FavoritesService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _favorites =>
      _db.collection(FirestorePaths.favorites);

  /// A user's saved items, live.
  Stream<List<Favorite>> watchFor(String userId) => _favorites
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Favorite.fromJson(doc.data(), doc.id))
            .toList(),
      );

  /// CREATE — also raises the "saves" counter on profiles.
  Future<void> save({
    required String userId,
    required String targetId,
    required TargetType targetType,
  }) {
    final batch = _db.batch();
    batch.set(_favorites.doc(Favorite.idFor(userId, targetId)), {
      'userId': userId,
      'targetId': targetId,
      'targetType': targetType.value,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _bumpSaveCount(batch, targetId, targetType, 1);
    return batch.commit();
  }

  /// DELETE
  Future<void> unsave({
    required String userId,
    required String targetId,
    required TargetType targetType,
  }) {
    final batch = _db.batch();
    batch.delete(_favorites.doc(Favorite.idFor(userId, targetId)));
    _bumpSaveCount(batch, targetId, targetType, -1);
    return batch.commit();
  }

  /// Removes only the saved record. Used when the saved item itself has
  /// been deleted, so there is no counter left to change.
  Future<void> removeRecord(String userId, String targetId) =>
      _favorites.doc(Favorite.idFor(userId, targetId)).delete();

  void _bumpSaveCount(
    WriteBatch batch,
    String targetId,
    TargetType targetType,
    int change,
  ) {
    final collection = switch (targetType) {
      TargetType.creator => FirestorePaths.creatorProfiles,
      TargetType.brand => FirestorePaths.brandProfiles,
      _ => null,
    };
    if (collection == null) return;
    batch.update(
      _db.collection(collection).doc(targetId),
      {'saveCount': FieldValue.increment(change)},
    );
  }
}

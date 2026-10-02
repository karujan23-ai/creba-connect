import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/model_utils.dart';
import 'firestore_paths.dart';

/// The editable option lists (`categories/{name}` → `items`).
class CategoryService {
  CategoryService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const creatorTypes = 'creatorTypes';
  static const niches = 'niches';
  static const businessCategories = 'businessCategories';

  /// Returns the stored lists keyed by name. Missing lists are simply absent.
  Future<Map<String, List<String>>> loadAll() async {
    final snapshot = await _db.collection(FirestorePaths.categories).get();
    return {
      for (final doc in snapshot.docs)
        doc.id: readStringList(doc.data()['items']),
    };
  }

  /// Admin only.
  Future<void> save(String name, List<String> items) =>
      _db.collection(FirestorePaths.categories).doc(name).set({
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}

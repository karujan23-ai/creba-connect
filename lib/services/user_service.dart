import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import 'firestore_paths.dart';

/// Reads and writes the account record at `users/{uid}`.
class UserService {
  UserService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection(FirestorePaths.users).doc(uid);

  Future<void> createUser(AppUser user) => _doc(user.uid).set({
        ...user.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

  /// Emits null while the document does not exist yet.
  Stream<AppUser?> watchUser(String uid) => _doc(uid).snapshots().map(
        (snapshot) => snapshot.exists
            ? AppUser.fromJson(snapshot.data()!, snapshot.id)
            : null,
      );

  Future<void> updateUser(String uid, Map<String, dynamic> fields) =>
      _doc(uid).update(fields);

  Future<void> touchLastActive(String uid) =>
      _doc(uid).update({'lastActiveAt': FieldValue.serverTimestamp()});
}

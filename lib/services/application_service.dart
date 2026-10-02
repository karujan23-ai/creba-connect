import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enums.dart';
import '../models/job_application.dart';
import 'firestore_paths.dart';

/// Firestore access for job applications (`applications/{jobId_creatorId}`).
class ApplicationService {
  ApplicationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _applications =>
      _db.collection(FirestorePaths.applications);

  List<JobApplication> _fromQuery(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map((doc) => JobApplication.fromJson(doc.data(), doc.id))
          .toList();

  /// CREATE — saves the application and adds one to the job's application
  /// counter. Both happen together or not at all.
  Future<void> apply(JobApplication application) {
    final batch = _db.batch();
    batch.set(_applications.doc(application.id), {
      ...application.toJson(),
      'status': ApplicationStatus.applied.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(
      _db.collection(FirestorePaths.hiringPosts).doc(application.jobId),
      {'applicationCount': FieldValue.increment(1)},
    );
    return batch.commit();
  }

  /// UPDATE — a creator who withdrew can apply again with a new message.
  Future<void> reapply(String id, {required String message, num? proposedRate}) =>
      _applications.doc(id).update({
        'status': ApplicationStatus.applied.value,
        'message': message,
        'proposedRate': proposedRate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// READ — a creator's own applications, live.
  Stream<List<JobApplication>> watchForCreator(String creatorId) => _applications
      .where('creatorId', isEqualTo: creatorId)
      .snapshots()
      .map(_fromQuery);

  /// READ — every application sent to one brand's posts, live.
  Stream<List<JobApplication>> watchForBrand(String brandId) => _applications
      .where('brandId', isEqualTo: brandId)
      .snapshots()
      .map(_fromQuery);

  /// UPDATE — used by brands (shortlist, select, reject) and by creators
  /// (withdraw). Security rules decide who may set which status.
  Future<void> updateStatus(String id, ApplicationStatus status) =>
      _applications.doc(id).update({
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enums.dart';
import '../models/report.dart';
import 'firestore_paths.dart';

/// User reports about profiles and posts (`reports/{id}`).
class ReportService {
  ReportService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection(FirestorePaths.reports);

  Future<void> submit(Report report) => _reports.add({
        ...report.toJson(),
        'status': ReportStatus.open.value,
        'createdAt': FieldValue.serverTimestamp(),
      });

  /// Admin only: all reports, newest first.
  Stream<List<Report>> watchAll({required int limit}) => _reports
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Report.fromJson(doc.data(), doc.id))
            .toList(),
      );

  /// Admin only: mark a report resolved or dismissed.
  Future<void> setStatus(String id, ReportStatus status, String adminId) =>
      _reports.doc(id).update({
        'status': status.value,
        'resolvedBy': adminId,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
}

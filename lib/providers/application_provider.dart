import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/hiring_post.dart';
import '../models/job_application.dart';
import '../services/application_service.dart';
import '../services/notification_service.dart';
import '../utils/app_exception.dart';
import 'session_provider.dart';

/// Job applications, live. A creator sees the ones they sent; a brand sees
/// the ones sent to its posts.
class ApplicationProvider extends SessionProvider {
  ApplicationProvider(this._service, this._notifications);

  final ApplicationService _service;
  final NotificationService _notifications;

  List<JobApplication> _applications = [];
  bool _isLoading = false;
  String? _error;

  /// Newest first.
  List<JobApplication> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<JobApplication> withStatus(ApplicationStatus status) =>
      _applications.where((application) => application.status == status).toList();

  int countWithStatus(ApplicationStatus status) => withStatus(status).length;

  /// For a brand: the applicants of one post.
  List<JobApplication> forJob(String jobId) =>
      _applications.where((application) => application.jobId == jobId).toList();

  /// For a creator: their own application to a post, if they sent one.
  JobApplication? mineForJob(String jobId) {
    for (final application in _applications) {
      if (application.jobId == jobId) return application;
    }
    return null;
  }

  @override
  void onSessionStarted(AppUser user) {
    if (user.isAdmin) return;
    _isLoading = true;
    final stream = user.isCreator
        ? _service.watchForCreator(user.uid)
        : _service.watchForBrand(user.uid);
    listen(
      stream,
      (applications) {
        _applications = [...applications]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
        _error = null;
      },
      onError: (_) {
        _isLoading = false;
        _error = 'Unable to load applications.';
      },
    );
  }

  @override
  void onSessionEnded() {
    _applications = [];
    _isLoading = false;
    _error = null;
  }

  /// Creator applies to [post]. Applying again after withdrawing re-opens
  /// the same application instead of creating a second one.
  Future<String?> apply({
    required HiringPost post,
    required String creatorName,
    required String message,
    num? proposedRate,
  }) {
    final creatorId = uid!;
    final existing = mineForJob(post.id);
    if (existing != null && existing.status != ApplicationStatus.withdrawn) {
      return Future.value('You have already applied to this opportunity.');
    }

    return guard(() async {
      if (existing != null) {
        await _service.reapply(existing.id, message: message, proposedRate: proposedRate);
      } else {
        final now = DateTime.now();
        await _service.apply(
          JobApplication(
            id: JobApplication.idFor(post.id, creatorId),
            jobId: post.id,
            creatorId: creatorId,
            brandId: post.brandId,
            jobTitle: post.title,
            creatorName: creatorName,
            brandName: post.brandName,
            message: message,
            proposedRate: proposedRate,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      _notify(
        recipientId: post.brandId,
        type: NotificationType.newApplication,
        title: 'New application',
        body: '$creatorName applied to your ${post.title} opportunity.',
        relatedId: post.id,
      );
    });
  }

  /// Brand moves an application to a new stage and tells the creator.
  Future<String?> updateStatus(JobApplication application, ApplicationStatus status) =>
      guard(() async {
        await _service.updateStatus(application.id, status);
        _notify(
          recipientId: application.creatorId,
          type: NotificationType.applicationStatus,
          title: application.jobTitle,
          body: _statusMessage(application.brandName, status),
          relatedId: application.jobId,
        );
      });

  /// Creator takes their application back.
  Future<String?> withdraw(JobApplication application) => guard(
        () => _service.updateStatus(application.id, ApplicationStatus.withdrawn),
      );

  static String _statusMessage(String brandName, ApplicationStatus status) =>
      switch (status) {
        ApplicationStatus.shortlisted => '$brandName shortlisted you.',
        ApplicationStatus.discussion => '$brandName wants to discuss the details with you.',
        ApplicationStatus.selected => '$brandName selected you. Congratulations!',
        ApplicationStatus.rejected => '$brandName went with another creator this time.',
        _ => '$brandName updated your application.',
      };

  /// A failed notification must never undo the action that caused it.
  void _notify({
    required String recipientId,
    required String type,
    required String title,
    required String body,
    String? relatedId,
  }) {
    _notifications
        .send(
          recipientId: recipientId,
          senderId: uid!,
          type: type,
          title: title,
          body: body,
          relatedId: relatedId,
        )
        .ignore();
  }
}

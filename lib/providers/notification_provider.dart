import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../services/notification_service.dart';
import '../utils/app_exception.dart';
import 'session_provider.dart';

/// The signed-in user's in-app notifications, live.
class NotificationProvider extends SessionProvider {
  NotificationProvider(this._service);

  final NotificationService _service;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  /// Newest first.
  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.read).length;

  @override
  void onSessionStarted(AppUser user) {
    _isLoading = true;
    listen(
      _service.watchFor(user.uid),
      (notifications) {
        _notifications = [...notifications]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
        _error = null;
      },
      onError: (_) {
        _isLoading = false;
        _error = 'Unable to load notifications.';
      },
    );
  }

  @override
  void onSessionEnded() {
    _notifications = [];
    _isLoading = false;
    _error = null;
  }

  Future<String?> markRead(String id) => guard(() => _service.markRead(id));

  Future<String?> markAllRead() {
    final unreadIds =
        _notifications.where((n) => !n.read).map((n) => n.id).toList();
    if (unreadIds.isEmpty) return Future.value();
    return guard(() => _service.markAllRead(unreadIds));
  }

  Future<String?> delete(String id) => guard(() => _service.delete(id));
}

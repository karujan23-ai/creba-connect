import '../models/app_user.dart';
import '../models/availability_post.dart';
import '../services/availability_service.dart';
import '../utils/app_config.dart';
import '../utils/app_exception.dart';
import 'session_provider.dart';

/// Availability posts. Creators manage their own; brands browse active ones.
class AvailabilityProvider extends SessionProvider {
  AvailabilityProvider(this._service);

  final AvailabilityService _service;

  List<AvailabilityPost> _posts = [];
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// For a creator: every post they own, newest first.
  List<AvailabilityPost> get myPosts => _posts;

  /// For a brand: posts that are switched on and have not ended yet.
  List<AvailabilityPost> get activePosts =>
      _posts.where((post) => post.isActive && !post.hasEnded).toList();

  @override
  void onSessionStarted(AppUser user) {
    if (user.isAdmin) return;
    _isLoading = true;
    final stream = user.isCreator
        ? _service.watchByCreator(user.uid)
        : _service.watchLatest(limit: AppConfig.feedLimit);
    listen(
      stream,
      (posts) {
        _posts = [...posts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
        _error = null;
      },
      onError: (_) {
        _isLoading = false;
        _error = 'Unable to load availability posts.';
      },
    );
  }

  @override
  void onSessionEnded() {
    _posts = [];
    _isLoading = false;
    _error = null;
  }

  Future<String?> createPost(AvailabilityPost post) =>
      guard(() => _service.createPost(post));

  Future<String?> updatePost(AvailabilityPost post) =>
      guard(() => _service.updatePost(post));

  Future<String?> setActive(String id, {required bool isActive}) =>
      guard(() => _service.setActive(id, isActive: isActive));

  Future<String?> deletePost(String id) => guard(() => _service.deletePost(id));
}

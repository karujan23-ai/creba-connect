import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/filters.dart';
import '../models/hiring_post.dart';
import '../services/hiring_post_service.dart';
import '../utils/app_config.dart';
import '../utils/app_exception.dart';
import 'session_provider.dart';

/// Hiring posts. Creators get the live feed of open opportunities; brands
/// get the live list of their own posts.
class HiringPostProvider extends SessionProvider {
  HiringPostProvider(this._service);

  final HiringPostService _service;

  List<HiringPost> _posts = [];
  bool _isLoading = false;
  String? _error;
  JobFilter _filter = const JobFilter();
  final Set<String> _hiddenIds = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  JobFilter get filter => _filter;

  /// For a brand: all of its own posts, newest first.
  List<HiringPost> get myPosts => _posts;

  List<HiringPost> get myOpenPosts => _posts.where((post) => post.isOpen).toList();

  /// For a creator: open posts, with promoted ones first, minus any the
  /// creator marked "Not interested".
  List<HiringPost> get feed {
    final visible = _posts
        .where((post) => post.isOpen && !_hiddenIds.contains(post.id))
        .toList();
    final promoted = visible.where((post) => post.isPromoted);
    final regular = visible.where((post) => !post.isPromoted);
    return [...promoted, ...regular];
  }

  /// The feed after search and filters are applied.
  List<HiringPost> get filteredFeed => feed.where(_filter.matches).toList();

  @override
  void onSessionStarted(AppUser user) {
    if (user.isAdmin) return;
    _isLoading = true;
    final stream = user.isBrand
        ? _service.watchByBrand(user.uid)
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
        _error = 'Unable to load opportunities.';
      },
    );
  }

  @override
  void onSessionEnded() {
    _posts = [];
    _isLoading = false;
    _error = null;
    _filter = const JobFilter();
    _hiddenIds.clear();
  }

  void setFilter(JobFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setQuery(String query) => setFilter(_filter.withQuery(query));

  void clearFilter() => setFilter(JobFilter(query: _filter.query));

  /// "Not interested": hides the post for the rest of this session.
  void hide(String postId) {
    _hiddenIds.add(postId);
    notifyListeners();
  }

  void unhide(String postId) {
    _hiddenIds.remove(postId);
    notifyListeners();
  }

  HiringPost? findLoaded(String id) {
    for (final post in _posts) {
      if (post.id == id) return post;
    }
    return null;
  }

  Future<HiringPost?> getById(String id) async {
    final loaded = findLoaded(id);
    if (loaded != null) return loaded;
    try {
      return await _service.getPost(id);
    } catch (_) {
      return null;
    }
  }

  Future<List<HiringPost>> openPostsOf(String brandId) async {
    try {
      return await _service.getOpenPostsByBrand(brandId);
    } catch (_) {
      return [];
    }
  }

  Future<String?> createPost(HiringPost post) =>
      guard(() => _service.createPost(post));

  Future<String?> updatePost(HiringPost post) =>
      guard(() => _service.updatePost(post));

  Future<String?> setStatus(String id, PostStatus status) =>
      guard(() => _service.setStatus(id, status));

  Future<String?> deletePost(String id) => guard(() => _service.deletePost(id));

  void recordView(HiringPost post) {
    if (post.brandId == uid) return;
    _service.recordView(post.id).ignore();
  }
}

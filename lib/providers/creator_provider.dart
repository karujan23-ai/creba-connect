import '../models/app_user.dart';
import '../models/creator_profile.dart';
import '../models/filters.dart';
import '../services/creator_service.dart';
import '../utils/app_config.dart';
import '../utils/app_exception.dart';
import 'session_provider.dart';

/// Creator profiles: the signed-in creator's own profile, and the list of
/// creators that brands and admins browse.
class CreatorProvider extends SessionProvider {
  CreatorProvider(this._service);

  final CreatorService _service;

  CreatorProfile? _myProfile;
  bool _myProfileLoaded = false;
  List<CreatorProfile> _creators = [];
  bool _isLoading = false;
  String? _error;
  CreatorFilter _filter = const CreatorFilter();
  final Map<String, CreatorProfile> _cache = {};

  /// The signed-in creator's profile (null for brands and admins).
  CreatorProfile? get myProfile => _myProfile;
  bool get myProfileLoaded => _myProfileLoaded;

  /// Every loaded creator, newest activity first.
  List<CreatorProfile> get creators => _creators;
  bool get isLoading => _isLoading;
  String? get error => _error;
  CreatorFilter get filter => _filter;

  /// The list after search and filters are applied.
  List<CreatorProfile> get filteredCreators =>
      _creators.where(_filter.matches).toList();

  @override
  void onSessionStarted(AppUser user) {
    if (user.isCreator) {
      listen(_service.watchProfile(user.uid), (profile) {
        _myProfile = profile;
        _myProfileLoaded = true;
      });
    } else {
      _isLoading = true;
      listen(
        _service.watchCreators(limit: AppConfig.creatorListLimit),
        (creators) {
          _creators = creators;
          _isLoading = false;
          _error = null;
        },
        onError: (_) {
          _isLoading = false;
          _error = 'Unable to load creators.';
        },
      );
    }
  }

  @override
  void onSessionEnded() {
    _myProfile = null;
    _myProfileLoaded = false;
    _creators = [];
    _isLoading = false;
    _error = null;
    _filter = const CreatorFilter();
    _cache.clear();
  }

  void setFilter(CreatorFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setQuery(String query) => setFilter(_filter.withQuery(query));

  void clearFilter() => setFilter(CreatorFilter(query: _filter.query));

  /// Finds a creator in the loaded list, or fetches it once and remembers it.
  Future<CreatorProfile?> getById(String id) async {
    for (final creator in _creators) {
      if (creator.uid == id) return creator;
    }
    if (_cache.containsKey(id)) return _cache[id];
    try {
      final profile = await _service.getProfile(id);
      if (profile != null) _cache[id] = profile;
      return profile;
    } catch (_) {
      return null;
    }
  }

  Future<String?> createProfile(CreatorProfile profile) =>
      guard(() => _service.createProfile(profile));

  Future<String?> updateProfile(CreatorProfile profile) =>
      guard(() => _service.updateProfile(profile));

  Future<String?> setAvailability({required bool isAvailable}) =>
      guard(() => _service.setAvailability(uid!, isAvailable: isAvailable));

  /// Counts a profile view. A creator looking at their own profile is not
  /// counted, and a failure here is never shown to the user.
  void recordView(String creatorId) {
    if (creatorId == uid) return;
    _service.recordView(creatorId).ignore();
  }
}

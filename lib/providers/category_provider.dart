import '../models/app_user.dart';
import '../services/category_service.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';
import 'session_provider.dart';

/// The option lists shown in pickers: creator types, niches and business
/// categories. Loaded once per session from Firestore; the built-in defaults
/// are used for any list an admin has not customised.
class CategoryProvider extends SessionProvider {
  CategoryProvider(this._service);

  final CategoryService _service;

  Map<String, List<String>> _stored = const {};

  List<String> get creatorTypes =>
      _stored[CategoryService.creatorTypes] ?? AppConstants.defaultCreatorTypes;

  List<String> get niches =>
      _stored[CategoryService.niches] ?? AppConstants.defaultNiches;

  List<String> get businessCategories =>
      _stored[CategoryService.businessCategories] ??
      AppConstants.defaultBusinessCategories;

  @override
  void onSessionStarted(AppUser user) {
    _load();
  }

  @override
  void onSessionEnded() {
    _stored = const {};
  }

  Future<void> _load() async {
    try {
      final loaded = await _service.loadAll();
      // An empty list would leave pickers with nothing to choose from.
      _stored = {
        for (final entry in loaded.entries)
          if (entry.value.isNotEmpty) entry.key: entry.value,
      };
      notifySafely();
    } catch (_) {
      // Defaults stay in place; nothing for the user to act on.
    }
  }

  /// Admin only.
  Future<String?> save(String name, List<String> items) async {
    final error = await guard(() => _service.save(name, items));
    if (error == null) {
      _stored = {..._stored, name: items};
      notifySafely();
    }
    return error;
  }
}

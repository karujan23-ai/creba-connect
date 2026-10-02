import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/favorite.dart';
import '../services/favorites_service.dart';
import '../utils/app_exception.dart';
import 'session_provider.dart';

/// Saved items: brands save creators, creators save opportunities.
class FavoritesProvider extends SessionProvider {
  FavoritesProvider(this._service);

  final FavoritesService _service;

  List<Favorite> _favorites = [];

  /// Newest first.
  List<Favorite> get favorites => _favorites;

  bool isSaved(String targetId) =>
      _favorites.any((favorite) => favorite.targetId == targetId);

  List<String> savedIds(TargetType type) => _favorites
      .where((favorite) => favorite.targetType == type)
      .map((favorite) => favorite.targetId)
      .toList();

  int countOf(TargetType type) => savedIds(type).length;

  @override
  void onSessionStarted(AppUser user) {
    if (user.isAdmin) return;
    listen(_service.watchFor(user.uid), (favorites) {
      _favorites = [...favorites]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  @override
  void onSessionEnded() {
    _favorites = [];
  }

  /// Saves the item if it is not saved, otherwise removes it.
  Future<String?> toggle(String targetId, TargetType type) {
    final userId = uid!;
    return guard(
      () => isSaved(targetId)
          ? _service.unsave(userId: userId, targetId: targetId, targetType: type)
          : _service.save(userId: userId, targetId: targetId, targetType: type),
    );
  }

  /// Removes a saved record whose target no longer exists.
  Future<String?> removeRecord(String targetId) =>
      guard(() => _service.removeRecord(uid!, targetId));
}

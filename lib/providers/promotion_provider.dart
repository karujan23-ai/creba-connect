import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/promotion.dart';
import '../services/promotion_service.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';
import 'session_provider.dart';

/// The signed-in user's promotion requests and subscription plan.
/// (Payments are not connected; see `PaymentService`.)
class PromotionProvider extends SessionProvider {
  PromotionProvider(this._service);

  final PromotionService _service;

  List<Promotion> _promotions = [];
  Subscription? _subscription;

  /// Newest first.
  List<Promotion> get promotions => _promotions;

  SubscriptionPlan get plan => (_subscription?.isPro ?? false)
      ? _subscription!.plan
      : SubscriptionPlan.free;

  /// The latest request for one post or profile, if any.
  Promotion? latestFor(String targetId) {
    for (final promotion in _promotions) {
      if (promotion.targetId == targetId) return promotion;
    }
    return null;
  }

  @override
  void onSessionStarted(AppUser user) {
    if (user.isAdmin) return;
    listen(_service.watchForOwner(user.uid), (promotions) {
      _promotions = [...promotions]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
    listen(
      _service.watchSubscription(user.uid),
      (subscription) => _subscription = subscription,
    );
  }

  @override
  void onSessionEnded() {
    _promotions = [];
    _subscription = null;
  }

  /// Saves a promotion request with status "requested". It becomes active
  /// only when an admin (or, later, the payment backend) approves it.
  Future<String?> request({
    required String targetId,
    required TargetType targetType,
    required String targetLabel,
    required PromotionPackage package,
  }) {
    final owner = session!;
    return guard(
      () => _service.request(
        Promotion(
          id: '',
          ownerId: owner.uid,
          ownerName: owner.displayName,
          targetId: targetId,
          targetType: targetType,
          targetLabel: targetLabel,
          packageDays: package.days,
          priceNpr: package.priceNpr,
          createdAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<String?> cancel(String id) => guard(() => _service.cancel(id));
}

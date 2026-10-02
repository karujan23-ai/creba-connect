import '../models/promotion.dart';
import '../utils/app_exception.dart';

/// Online payments — NOT IMPLEMENTED YET.
///
/// This class is the single place where Stripe will be connected. Until then
/// every method refuses, so the app can never show a payment as successful
/// when no money moved.
///
/// Planned flow (see README, "Stripe integration"):
///
///   Flutter app ──► Cloud Function ──► Stripe
///        ▲          (holds the secret key)  │
///        │                                   ▼
///   Firestore ◄── Cloud Function ◄── Stripe webhook
///   (payment + promotion records written by the backend only)
///
/// The Stripe secret key must live in the backend. It must never be put in
/// this Flutter code, because anything shipped in an app can be extracted.
class PaymentService {
  /// Flip to true only when the backend above exists.
  static const bool isOnlinePaymentAvailable = false;

  static const String unavailableMessage =
      'Online payment is not available yet. Your request has been saved '
      'and an admin can review it.';

  Future<void> startCheckout(Promotion promotion) async {
    throw const AppException(unavailableMessage);
  }
}

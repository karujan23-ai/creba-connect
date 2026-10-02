import 'enums.dart';
import 'model_utils.dart';

/// A request to promote a hiring post or boost a creator profile,
/// stored at `promotions/{id}`.
///
/// A user can only create one with status "requested". Nothing here means
/// money was paid: online payment is not connected yet.
class Promotion {
  const Promotion({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.targetId,
    required this.targetType,
    required this.targetLabel,
    required this.packageDays,
    required this.priceNpr,
    this.status = PromotionStatus.requested,
    this.startsAt,
    this.endsAt,
    this.paymentId,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final String targetId;
  final TargetType targetType;
  final String targetLabel;
  final int packageDays;
  final int priceNpr;
  final PromotionStatus status;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// Filled in by the payment backend once Stripe is connected.
  final String? paymentId;
  final DateTime createdAt;

  factory Promotion.fromJson(Map<String, dynamic> json, String id) => Promotion(
        id: id,
        ownerId: readString(json['ownerId']),
        ownerName: readString(json['ownerName']),
        targetId: readString(json['targetId']),
        targetType: TargetType.fromValue(json['targetType'] as String?),
        targetLabel: readString(json['targetLabel']),
        packageDays: readInt(json['packageDays']),
        priceNpr: readInt(json['priceNpr']),
        status: PromotionStatus.fromValue(json['status'] as String?),
        startsAt: readDate(json['startsAt']),
        endsAt: readDate(json['endsAt']),
        paymentId: readOptionalString(json['paymentId']),
        createdAt: readDateOrNow(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'ownerId': ownerId,
        'ownerName': ownerName,
        'targetId': targetId,
        'targetType': targetType.value,
        'targetLabel': targetLabel,
        'packageDays': packageDays,
        'priceNpr': priceNpr,
        'status': status.value,
        'startsAt': writeDate(startsAt),
        'endsAt': writeDate(endsAt),
        'paymentId': paymentId,
        'createdAt': writeDate(createdAt),
      };
}

/// A user's plan, stored at `subscriptions/{uid}`. Written by admins only.
class Subscription {
  const Subscription({
    required this.userId,
    this.plan = SubscriptionPlan.free,
    this.status = 'active',
    this.startedAt,
    this.expiresAt,
  });

  final String userId;
  final SubscriptionPlan plan;

  /// "active" or "cancelled".
  final String status;
  final DateTime? startedAt;
  final DateTime? expiresAt;

  bool get isPro => plan != SubscriptionPlan.free && status == 'active';

  factory Subscription.fromJson(Map<String, dynamic> json, String userId) =>
      Subscription(
        userId: userId,
        plan: SubscriptionPlan.fromValue(json['plan'] as String?),
        status: readString(json['status'], 'active'),
        startedAt: readDate(json['startedAt']),
        expiresAt: readDate(json['expiresAt']),
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'plan': plan.value,
        'status': status,
        'startedAt': writeDate(startedAt),
        'expiresAt': writeDate(expiresAt),
      };
}

/// A payment record, stored at `payments/{id}`. Only a payment backend or an
/// admin may write these; the app never creates one itself.
class Payment {
  const Payment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.purpose,
    required this.provider,
    this.providerRef,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final num amount;
  final String currency;
  final String purpose;
  final String provider;
  final String? providerRef;
  final String status;
  final DateTime createdAt;

  factory Payment.fromJson(Map<String, dynamic> json, String id) => Payment(
        id: id,
        userId: readString(json['userId']),
        amount: readNum(json['amount']),
        currency: readString(json['currency'], 'NPR'),
        purpose: readString(json['purpose']),
        provider: readString(json['provider']),
        providerRef: readOptionalString(json['providerRef']),
        status: readString(json['status']),
        createdAt: readDateOrNow(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'amount': amount,
        'currency': currency,
        'purpose': purpose,
        'provider': provider,
        'providerRef': providerRef,
        'status': status,
        'createdAt': writeDate(createdAt),
      };
}

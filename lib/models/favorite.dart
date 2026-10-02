import 'enums.dart';
import 'model_utils.dart';

/// Something a user saved, stored at `favorites/{userId_targetId}`.
class Favorite {
  const Favorite({
    required this.id,
    required this.userId,
    required this.targetId,
    required this.targetType,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String targetId;
  final TargetType targetType;
  final DateTime createdAt;

  static String idFor(String userId, String targetId) => '${userId}_$targetId';

  factory Favorite.fromJson(Map<String, dynamic> json, String id) => Favorite(
        id: id,
        userId: readString(json['userId']),
        targetId: readString(json['targetId']),
        targetType: TargetType.fromValue(json['targetType'] as String?),
        createdAt: readDateOrNow(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'targetId': targetId,
        'targetType': targetType.value,
        'createdAt': writeDate(createdAt),
      };
}

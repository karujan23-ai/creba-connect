import 'model_utils.dart';

/// An in-app notification, stored at `notifications/{id}`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedId,
    this.read = false,
    required this.createdAt,
  });

  final String id;
  final String recipientId;
  final String senderId;

  /// One of the `NotificationType` constants below.
  final String type;
  final String title;
  final String body;

  /// The job or application this notification is about, if any.
  final String? relatedId;
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json, String id) =>
      AppNotification(
        id: id,
        recipientId: readString(json['recipientId']),
        senderId: readString(json['senderId']),
        type: readString(json['type']),
        title: readString(json['title']),
        body: readString(json['body']),
        relatedId: readOptionalString(json['relatedId']),
        read: readBool(json['read']),
        createdAt: readDateOrNow(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'recipientId': recipientId,
        'senderId': senderId,
        'type': type,
        'title': title,
        'body': body,
        'relatedId': relatedId,
        'read': read,
        'createdAt': writeDate(createdAt),
      };
}

class NotificationType {
  NotificationType._();

  static const newApplication = 'new_application';
  static const applicationStatus = 'application_status';
  static const verification = 'verification';
  static const promotion = 'promotion';
}

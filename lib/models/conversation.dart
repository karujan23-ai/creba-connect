import 'model_utils.dart';

/// A chat between two users, stored at `conversations/{uidA_uidB}`.
class Conversation {
  const Conversation({
    required this.id,
    required this.participants,
    this.participantNames = const {},
    this.lastMessage = '',
    this.lastSenderId = '',
    this.unreadCounts = const {},
    required this.updatedAt,
  });

  final String id;
  final List<String> participants;

  /// UID → display name, so the list can be shown without extra reads.
  final Map<String, String> participantNames;
  final String lastMessage;
  final String lastSenderId;

  /// UID → number of messages that user has not read yet.
  final Map<String, int> unreadCounts;
  final DateTime updatedAt;

  /// Sorting the two UIDs gives both people the same conversation ID.
  static String idFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return sorted.join('_');
  }

  String otherParticipantId(String myUid) =>
      participants.firstWhere((uid) => uid != myUid, orElse: () => myUid);

  String otherParticipantName(String myUid) =>
      participantNames[otherParticipantId(myUid)] ?? 'Unknown';

  int unreadFor(String uid) => unreadCounts[uid] ?? 0;

  factory Conversation.fromJson(Map<String, dynamic> json, String id) {
    final names = json['participantNames'];
    final unread = json['unreadCounts'];
    return Conversation(
      id: id,
      participants: readStringList(json['participants']),
      participantNames: names is Map
          ? names.map((key, value) => MapEntry('$key', readString(value)))
          : const {},
      lastMessage: readString(json['lastMessage']),
      lastSenderId: readString(json['lastSenderId']),
      unreadCounts: unread is Map
          ? unread.map((key, value) => MapEntry('$key', readInt(value)))
          : const {},
      updatedAt: readDateOrNow(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'participants': participants,
        'participantNames': participantNames,
        'lastMessage': lastMessage,
        'lastSenderId': lastSenderId,
        'unreadCounts': unreadCounts,
        'updatedAt': writeDate(updatedAt),
      };
}

/// One chat message, stored at `conversations/{id}/messages/{messageId}`.
class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final bool read;

  factory Message.fromJson(Map<String, dynamic> json, String id) => Message(
        id: id,
        senderId: readString(json['senderId']),
        receiverId: readString(json['receiverId']),
        text: readString(json['text']),
        createdAt: readDateOrNow(json['createdAt']),
        read: readBool(json['read']),
      );

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'createdAt': writeDate(createdAt),
        'read': read,
      };
}

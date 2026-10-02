import 'dart:async';

import '../models/app_user.dart';
import '../models/conversation.dart';
import '../services/chat_service.dart';
import '../utils/app_exception.dart';
import 'session_provider.dart';

/// Real-time chat state: the conversation list, and the messages of the
/// conversation that is currently open on screen.
class ChatProvider extends SessionProvider {
  ChatProvider(this._service);

  final ChatService _service;

  List<Conversation> _conversations = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<Message>>? _messagesSubscription;
  bool _messagesListening = false;
  String? _openOtherId;
  String _openOtherName = '';
  List<Message> _messages = [];
  bool _isLoadingMessages = false;

  /// Most recently active first.
  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Messages of the open conversation, oldest first.
  List<Message> get messages => _messages;
  bool get isLoadingMessages => _isLoadingMessages;

  /// Total unread messages across all conversations (shown on the tab).
  int get totalUnread {
    final me = uid;
    if (me == null) return 0;
    return _conversations.fold(0, (total, chat) => total + chat.unreadFor(me));
  }

  @override
  void onSessionStarted(AppUser user) {
    if (user.isAdmin) return;
    _isLoading = true;
    listen(
      _service.watchConversations(user.uid),
      (conversations) {
        _conversations = [...conversations]
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        _isLoading = false;
        _error = null;
      },
      onError: (_) {
        _isLoading = false;
        _error = 'Unable to load messages.';
      },
    );
  }

  @override
  void onSessionEnded() {
    _conversations = [];
    _isLoading = false;
    _error = null;
    _closeMessages();
  }

  /// Starts listening to the conversation with [otherId].
  /// Call [closeChat] when leaving the chat screen.
  void openChat({required String otherId, required String otherName}) {
    if (uid == null) return;
    _closeMessages();
    _openOtherId = otherId;
    _openOtherName = otherName;
    _isLoadingMessages = true;
    _listenToMessages();
  }

  void _listenToMessages() {
    final me = uid;
    final otherId = _openOtherId;
    if (me == null || otherId == null) return;

    final conversationId = Conversation.idFor(me, otherId);
    _messagesListening = true;
    _messagesSubscription?.cancel();
    _messagesSubscription = _service.watchMessages(conversationId).listen(
      (messages) {
        _messages = messages;
        _isLoadingMessages = false;
        notifySafely();
        final hasUnread = messages.any((m) => m.receiverId == me && !m.read);
        if (hasUnread) _service.markRead(conversationId, me).ignore();
      },
      onError: (Object _) {
        // The security rules refuse to list messages of a conversation
        // that does not exist yet. That simply means "no messages"; the
        // listener is restarted after the first message is sent.
        _messagesListening = false;
        _messages = [];
        _isLoadingMessages = false;
        notifySafely();
      },
    );
  }

  void closeChat() => _closeMessages();

  void _closeMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _messagesListening = false;
    _openOtherId = null;
    _openOtherName = '';
    _messages = [];
    _isLoadingMessages = false;
  }

  /// Sends [text] in the open conversation.
  Future<String?> send(String text) async {
    final me = session;
    final otherId = _openOtherId;
    final trimmed = text.trim();
    if (me == null || otherId == null || trimmed.isEmpty) return null;

    final error = await guard(
      () => _service.sendMessage(
        senderId: me.uid,
        senderName: me.displayName,
        receiverId: otherId,
        receiverName: _openOtherName,
        text: trimmed,
      ),
    );
    // The first message creates the conversation, so listening can start.
    if (error == null && !_messagesListening && _openOtherId == otherId) {
      _listenToMessages();
    }
    return error;
  }

  /// Sends a one-off message without opening the chat screen
  /// (used when a brand invites a creator to an opportunity).
  Future<String?> sendDirect({
    required String otherId,
    required String otherName,
    required String text,
  }) {
    final me = session!;
    return guard(
      () => _service.sendMessage(
        senderId: me.uid,
        senderName: me.displayName,
        receiverId: otherId,
        receiverName: otherName,
        text: text,
      ),
    );
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}

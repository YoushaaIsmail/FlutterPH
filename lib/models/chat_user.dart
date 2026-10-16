// models/chat_user.dart
class ChatUser {
  final int id;
  final String username;
  final String? photo;
  final bool isOnline;
  final LastMessage? lastMessage;
  final int unreadCount;

  ChatUser({
    required this.id,
    required this.username,
    this.photo,
    required this.isOnline,
    this.lastMessage,
    required this.unreadCount,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      photo: json['photo'],
      isOnline: json['is_online'] ?? false,
      lastMessage: json['last_message'] != null
          ? LastMessage.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class LastMessage {
  final String content;
  final DateTime timestamp;
  final String sender;
  final bool isRead;

  LastMessage({
    required this.content,
    required this.timestamp,
    required this.sender,
    required this.isRead,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      sender: json['sender'] ?? '',
      isRead: json['is_read'] ?? false,
    );
  }
}

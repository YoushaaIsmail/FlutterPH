// models/chat_message.dart
class ChatMessage {
  final int id;
  final String sender;
  final int senderId;
  final String recipient;
  final int recipientId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.senderId,
    required this.recipient,
    required this.recipientId,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch,
      sender: json['sender'] ?? '',
      senderId: json['sender_id'] ?? 0,
      recipient: json['recipient'] ?? '',
      recipientId: json['recipient_id'] ?? 0,
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
    );
  }
}

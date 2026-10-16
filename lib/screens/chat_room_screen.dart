// screens/chat_room_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../models/chat_user.dart';
import '../models/chat_message.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatUser otherUser;
  const ChatRoomScreen({super.key, required this.otherUser});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  final int _currentUserId = 2; // Your user ID

  // Store listener reference to prevent duplicates
  late final void Function(ChatMessage) _messageListener;

  String get _token {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.token ?? '';
  }

  @override
  void initState() {
    super.initState();

    // Initialize listener
    _messageListener = _onNewMessage;

    print('🚀 [ChatRoom] فتح شاشة المحادثة مع: ${widget.otherUser.username}');
    print('🚀 [ChatRoom] معرف المستخدم الآخر (Admin): ${widget.otherUser.id}');
    print('🚀 [ChatRoom] معرف المستخدم الحالي (أنا): $_currentUserId');
    print('🚀 [ChatRoom] Token موجود: ${_token.isNotEmpty ? "نعم" : "لا"}');

    _loadMessages();
    _connectWebSocket();

    // Add listener
    ChatService.addMessageListener(_messageListener);
  }

  @override
  void dispose() {
    print('🔚 [ChatRoom] إغلاق شاشة المحادثة');

    // Remove the correct listener
    ChatService.removeMessageListener(_messageListener);
    ChatService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _connectWebSocket() {
    print('🔌 [ChatRoom] محاولة اتصال WebSocket...');
    print(
      '🔌 [ChatRoom] المعرفات: أنا=$_currentUserId, Admin=${widget.otherUser.id}',
    );

    if (_token.isNotEmpty && _currentUserId != 0) {
      ChatService.connectWebSocket(_token, _currentUserId, widget.otherUser.id);
    } else {
      print('❌ [ChatRoom] لا يمكن الاتصال');
    }
  }

  void _onNewMessage(ChatMessage message) {
    print('📨 [ChatRoom] رسالة جديدة من WebSocket');
    print('   المرسل: ${message.sender} (ID: ${message.senderId})');
    print('   المحتوى: ${message.content}');

    if (message.senderId == widget.otherUser.id ||
        message.recipientId == widget.otherUser.id) {
      // Check for duplicates
      final bool messageExists = _messages.any(
        (msg) =>
            msg.id == message.id ||
            (msg.content == message.content &&
                msg.timestamp.difference(message.timestamp).abs().inSeconds <
                    5),
      );

      if (!messageExists) {
        print('✅ [ChatRoom] رسالة جديدة، جاري الإضافة');
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      } else {
        print('⚠️ [ChatRoom] رسالة مكررة، تم تجاهلها');
      }
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    print('📥 [ChatRoom] جاري تحميل الرسائل السابقة...');

    try {
      final response = await ApiService.getChatMessages(
        _token,
        widget.otherUser.id, // Admin ID
      );
      final List<dynamic> messagesData = response['data'] ?? [];

      setState(() {
        _messages = messagesData.map((e) => ChatMessage.fromJson(e)).toList();
        _isLoading = false;
      });

      print('✅ [ChatRoom] تم تحميل ${_messages.length} رسالة');
      _scrollToBottom();
    } catch (e) {
      print('❌ [ChatRoom] خطأ في تحميل الرسائل: $e');
      setState(() => _isLoading = false);
      _showSnackBar('Error loading messages: $e', isError: true);
    }
  }

  // ✅ WebSocket only - NO HTTP send
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    print('📤 [ChatRoom] محاولة إرسال رسالة عبر WebSocket: $content');

    if (!ChatService.isConnected) {
      print('❌ [ChatRoom] WebSocket غير متصل');
      _showSnackBar('Not connected to chat server', isError: true);
      return;
    }

    setState(() => _isSending = true);

    try {
      // Create temporary message for immediate UI update (optimistic)
      final tempMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
        sender: 'Me',
        senderId: _currentUserId,
        recipient: widget.otherUser.username,
        recipientId: widget.otherUser.id,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Add to UI immediately
      setState(() {
        _messages.add(tempMessage);
        _messageController.clear();
      });

      // Send via WebSocket only
      ChatService.sendMessage(content);
      print('✅ [ChatRoom] تم إرسال الرسالة عبر WebSocket');

      setState(() => _isSending = false);
      _scrollToBottom();
    } catch (e) {
      print('❌ [ChatRoom] فشل إرسال الرسالة: $e');
      setState(() => _isSending = false);
      _showSnackBar('Failed to send message: $e', isError: true);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: isError ? Colors.red.shade700 : Colors.green.shade700,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade50 : Colors.green.shade50,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.teal],
                ),
              ),
              child: Center(
                child: Text(
                  widget.otherUser.username.isNotEmpty
                      ? widget.otherUser.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.username,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Admin',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade800,
                Colors.green.shade600,
                Colors.teal.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi_find),
            onPressed: () {
              print('🔍 [TEST] حالة الاتصال: ${ChatService.isConnected}');
              _showSnackBar(
                ChatService.isConnected
                    ? '✅ WebSocket متصل'
                    : '❌ WebSocket غير متصل',
                isError: !ChatService.isConnected,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Send a message to start the conversation',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == _currentUserId;
                      return _buildMessageBubble(message, isMe);
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.teal],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.green.shade100 : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.content, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
                const SizedBox(width: 4),
                if (isMe)
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead
                        ? Colors.green.shade600
                        : Colors.grey.shade500,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

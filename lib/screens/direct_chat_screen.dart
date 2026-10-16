// screens/direct_chat_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';

class DirectChatScreen extends StatefulWidget {
  const DirectChatScreen({super.key});

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  // Admin ID is always 1
  final int _adminId = 1;
  final String _adminName = 'Admin';

  // Current user ID - will be fetched from auth
  int _currentUserId = 0;

  // Track message IDs to prevent duplicates
  final Set<int> _processedMessageIds = {};

  String get _token {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.token ?? '';
  }

  @override
  void initState() {
    super.initState();
    _getCurrentUserAndLoad();
  }

  Future<void> _getCurrentUserAndLoad() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Use the userId getter from AuthProvider
      _currentUserId = authProvider.userId;

      if (_currentUserId != 0) {
        print(
          '✅ [DirectChat] User found in AuthProvider: ID = $_currentUserId',
        );
      } else {
        // Try to refresh user data if userId is 0
        print('🔄 [DirectChat] User ID is 0, refreshing user data...');
        await authProvider.refreshUserData();
        _currentUserId = authProvider.userId;

        if (_currentUserId != 0) {
          print('✅ [DirectChat] User ID after refresh: $_currentUserId');
        } else {
          print('⚠️ [DirectChat] Could not get user ID, using fallback');
          _currentUserId =
              2; // Fallback user ID (change to your actual user ID)
        }
      }

      print('🚀 [DirectChat] Current User ID: $_currentUserId');
      print('🚀 [DirectChat] Admin ID: $_adminId');
      print('🚀 [DirectChat] Token exists: ${_token.isNotEmpty}');
      print(
        '🚀 [DirectChat] Token: ${_token.substring(0, min(20, _token.length))}...',
      );

      if (_currentUserId == 0) {
        throw Exception('Could not get current user ID');
      }

      await _loadMessages();
      _connectWebSocket();
      ChatService.addMessageListener(_onNewMessage);
    } catch (e) {
      print('❌ [DirectChat] Error: $e');
      setState(() => _isLoading = false);
      _showSnackBar('Error loading user data: $e', isError: true);
    }
  }

  void _connectWebSocket() {
    if (_token.isNotEmpty && _currentUserId != 0) {
      print('🔌 [DirectChat] Connecting WebSocket...');
      print('   Current User ID: $_currentUserId');
      print('   Admin ID: $_adminId');
      ChatService.connectWebSocket(_token, _currentUserId, _adminId);
    } else {
      print('❌ [DirectChat] Cannot connect - missing data');
      print('   Token empty: ${_token.isEmpty}');
      print('   Current User ID: $_currentUserId');
    }
  }

  void _onNewMessage(ChatMessage message) {
    print('📨 [DirectChat] New WebSocket message');
    print('   Message ID: ${message.id}');
    print('   Sender ID: ${message.senderId}');
    print('   Recipient ID: ${message.recipientId}');
    print('   Content: ${message.content}');
    print('   Current User ID: $_currentUserId');

    // Ignore messages sent by current user (they come back from WebSocket)
    if (message.senderId == _currentUserId) {
      print('⚠️ [DirectChat] Ignoring own message from WebSocket');
      return;
    }

    // Check if message is from/to Admin
    if (message.senderId == _adminId || message.recipientId == _adminId) {
      // Prevent duplicate by checking message ID
      if (!_processedMessageIds.contains(message.id)) {
        _processedMessageIds.add(message.id);
        print('✅ [DirectChat] Adding new message from Admin');
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      } else {
        print('⚠️ [DirectChat] Duplicate message ignored (ID: ${message.id})');
      }
    } else {
      print('⚠️ [DirectChat] Message not related to Admin, ignoring');
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    print('📥 [DirectChat] Loading messages...');

    try {
      final response = await ApiService.getChatMessages(_token, _adminId);
      final List<dynamic> messagesData = response['data'] ?? [];

      setState(() {
        _messages = [];
        _processedMessageIds.clear();

        for (var data in messagesData) {
          final message = ChatMessage.fromJson(data);
          _messages.add(message);
          _processedMessageIds.add(message.id);
        }

        // Sort by timestamp
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false;
      });

      print('✅ [DirectChat] Loaded ${_messages.length} messages');
      _scrollToBottom();
    } catch (e) {
      print('❌ [DirectChat] Error loading messages: $e');
      setState(() => _isLoading = false);
      _showSnackBar('Error loading messages: $e', isError: true);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    print('📤 [DirectChat] Sending message: $content');
    setState(() => _isSending = true);

    try {
      // Send to Admin (ID = 1)
      final response = await ApiService.sendChatMessage(
        _token,
        _adminId,
        content,
      );

      final messageData = response['data'] as Map<String, dynamic>;
      final newMessage = ChatMessage.fromJson(messageData);

      // Add to processed IDs to prevent WebSocket duplicate
      _processedMessageIds.add(newMessage.id);

      print('✅ [DirectChat] Message sent (ID: ${newMessage.id})');

      setState(() {
        _messages.add(newMessage);
        _messageController.clear();
        _isSending = false;
      });

      // Don't send via WebSocket - it causes duplicates!
      // The API already saved the message

      _scrollToBottom();
    } catch (e) {
      print('❌ [DirectChat] Failed to send message: $e');
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
              size: 20,
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
  void dispose() {
    print('🔚 [DirectChat] Closing chat screen');
    ChatService.removeMessageListener(_onNewMessage);
    ChatService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(
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
                  const Text(
                    'Admin',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ChatService.isConnected ? '● Online' : '○ Offline',
                    style: TextStyle(
                      fontSize: 11,
                      color: ChatService.isConnected
                          ? Colors.greenAccent
                          : Colors.white70,
                    ),
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMessages),
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

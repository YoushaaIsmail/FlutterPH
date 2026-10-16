// services/chat_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/chat_message.dart';

class ChatService {
  static WebSocket? _webSocket;
  static final List<Function(ChatMessage)> _messageListeners = [];
  static bool _isConnected = false;
  static int _currentUserId = 0;
  static int _otherUserId = 0;
  static String? _token;
  static Timer? _reconnectTimer;

  static Future<void> connectWebSocket(
    String token,
    int currentUserId,
    int otherUserId,
  ) async {
    _token = token;
    _currentUserId = currentUserId;
    _otherUserId = otherUserId;

    print('🟢 [WebSocket] محاولة الاتصال...');
    print('🟢 [WebSocket] عنوان الخادم: ws://192.168.125.112:8000');
    print('🟢 [WebSocket] معرف المستخدم الحالي: $_currentUserId');
    print('🟢 [WebSocket] معرف المستخدم الآخر: $_otherUserId');
    print('🟢 [WebSocket] Token موجود: ${token.isNotEmpty ? "نعم" : "لا"}');

    await _connect();
  }

  static Future<void> _connect() async {
    try {
      final wsUrl = Uri.parse(
        'ws://192.168.125.112:8000/ws/chat/$_otherUserId/?token=$_token',
      );

      print('🟡 [WebSocket] عنوان الاتصال: $wsUrl');

      _webSocket = await WebSocket.connect(wsUrl.toString());
      _isConnected = true;

      print('✅ [WebSocket] تم الاتصال بنجاح!');
      print('✅ [WebSocket] الحالة: متصل');

      _webSocket!.listen(
        (message) {
          print('📩 [WebSocket] رسالة واردة: $message');
          final data = jsonDecode(message as String);
          final chatMessage = ChatMessage(
            id: data['id'] ?? DateTime.now().millisecondsSinceEpoch,
            sender: data['sender'] ?? '',
            senderId: data['sender_id'] ?? _otherUserId,
            recipient: data['recipient'] ?? '',
            recipientId: data['recipient_id'] ?? _currentUserId,
            content: data['content'] ?? '',
            timestamp: data['timestamp'] != null
                ? DateTime.parse(data['timestamp'])
                : DateTime.now(),
            isRead: data['is_read'] ?? false,
          );

          for (var listener in _messageListeners) {
            listener(chatMessage);
          }
        },
        onError: (error) {
          print('❌ [WebSocket] خطأ: $error');
          _isConnected = false;
          _handleDisconnection();
        },
        onDone: () {
          print('🔴 [WebSocket] تم قطع الاتصال');
          _isConnected = false;
          _handleDisconnection();
        },
      );
    } catch (e) {
      print('❌ [WebSocket] فشل الاتصال: $e');
      _isConnected = false;
      _handleDisconnection();
    }
  }

  static void _handleDisconnection() {
    print('🟠 [WebSocket] جاري محاولة إعادة الاتصال خلال 5 ثوان...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_token != null && _currentUserId != 0 && _otherUserId != 0) {
        print('🔄 [WebSocket] محاولة إعادة الاتصال...');
        _connect();
      }
    });
  }

  static void sendMessage(String content) {
    if (_webSocket != null && _isConnected) {
      _webSocket!.add(jsonEncode({'content': content}));
      print('📤 [WebSocket] تم إرسال الرسالة: $content');
    } else {
      print('⚠️ [WebSocket] غير متصل، لم يتم إرسال الرسالة');
    }
  }

  static void addMessageListener(Function(ChatMessage) listener) {
    _messageListeners.add(listener);
    print(
      '👂 [WebSocket] تم إضافة مستمع جديد. عدد المستمعين: ${_messageListeners.length}',
    );
  }

  static void removeMessageListener(Function(ChatMessage) listener) {
    _messageListeners.remove(listener);
    print(
      '👂 [WebSocket] تم إزالة مستمع. عدد المستمعين: ${_messageListeners.length}',
    );
  }

  static Future<void> disconnect() async {
    print('🔌 [WebSocket] جاري قطع الاتصال...');
    _reconnectTimer?.cancel();
    if (_webSocket != null) {
      await _webSocket!.close();
      _webSocket = null;
    }
    _isConnected = false;
    print('🔌 [WebSocket] تم قطع الاتصال');
  }

  static bool get isConnected {
    print('📊 [WebSocket] حالة الاتصال: ${_isConnected ? "متصل" : "غير متصل"}');
    return _isConnected;
  }
}

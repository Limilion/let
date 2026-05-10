import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/notification_toast.dart';
import '../navigation/app_router.dart';
import 'package:go_router/go_router.dart';

class ChatProvider with ChangeNotifier {
  AuthProvider _authProvider;
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _messages = [];
  bool _loadingConversations = false;
  bool _loadingMessages = false;
  String? _currentChattingWithId;
  final Map<String, bool> _typingStatus = {}; // userId -> isTyping
  final Map<String, bool> _onlineStatus = {}; // userId -> isOnline
  int _unreadNotifications = 0;

  ChatProvider(this._authProvider) {
    _initSocket();
  }

  void updateAuth(AuthProvider auth) {
    if (_authProvider == auth) return;
    
    final wasAuthenticated = _authProvider.isAuthenticated;
    final oldUserId = wasAuthenticated ? (_authProvider.user?['id']?.toString()) : null;
    
    _authProvider = auth;
    
    final isNowAuthenticated = _authProvider.isAuthenticated;
    final newUserId = isNowAuthenticated ? (_authProvider.user?['id']?.toString()) : null;

    if (isNowAuthenticated) {
      if (!wasAuthenticated || oldUserId != newUserId) {
        SocketService.disconnect();
        _initSocket();
        fetchConversations();
      }
    } else if (wasAuthenticated) {
      SocketService.disconnect();
      _conversations = [];
      _messages = [];
      _onlineStatus.clear();
      notifyListeners();
    }
  }

  void _initSocket() {
    if (_authProvider.isAuthenticated) {
      SocketService.connect();
      SocketService.emit('join', _authProvider.user!['id'].toString());
      
      SocketService.on('new_message', (data) {
        final message = Map<String, dynamic>.from(data);
        final senderId = (message['senderId'] ?? message['sender_id']).toString();
        final msgId = message['id'].toString();
        
        if (_currentChattingWithId == senderId) {
          // Prevent duplicates
          if (!_messages.any((m) => m['id'].toString() == msgId)) {
            _messages.add(message);
            notifyListeners();
          }
        }
        fetchConversations();
      });

      SocketService.on('new_notification', (data) {
        final notification = Map<String, dynamic>.from(data);
        final actor = notification['actor'];
        final actorPhoto = actor != null ? ApiService.getImageUrl(actor['photo']) : null;
        
        NotificationService.showNotification(
          id: int.tryParse(notification['id'].toString()) ?? DateTime.now().millisecondsSinceEpoch,
          title: notification['title'] ?? 'إشعار جديد',
          body: notification['body'] ?? '',
          imageUrl: actorPhoto,
        );

        // In-App UI Feedback
        final context = AppRouter.rootNavigatorKey.currentContext;
        if (context != null) {
          NotificationToast.show(
            context,
            title: notification['title'] ?? 'إشعار جديد',
            body: notification['body'] ?? '',
            imageUrl: actorPhoto,
            onTap: () {
              // Navigation logic could be added here
            },
          );
        }
        
        _unreadNotifications++;
        notifyListeners();
      });

      SocketService.on('user_typing', (data) {
        final typingData = Map<String, dynamic>.from(data);
        final senderId = typingData['senderId'].toString();
        final isTyping = typingData['isTyping'] == true;
        
        _typingStatus[senderId] = isTyping;
        notifyListeners();
      });

      SocketService.on('user_status', (data) {
        final statusData = Map<String, dynamic>.from(data);
        final userId = statusData['userId'].toString();
        final status = statusData['status'];
        _onlineStatus[userId] = status == 'online';
        notifyListeners();
      });

      // --- Call Signaling Listeners ---
      SocketService.on('incoming_call', (data) {
        final callData = Map<String, dynamic>.from(data);
        // Navigate to incoming call screen
        final context = AppRouter.rootNavigatorKey.currentContext;
        if (context != null) {
          context.push('/incoming-call', extra: callData);
        }
      });

      SocketService.on('call_answered', (data) {
        // Handled directly in the CallScreen/IncomingCallScreen or via a global state if needed
        // We'll emit an event locally or just rely on the screen to handle its own socket listening for simplicity
      });

      SocketService.on('call_rejected', (data) {
        // Notification to the caller that it was rejected
      });

      SocketService.on('call_ended', (data) {
        // Ends the call
      });
    }
  }

  // --- Call Signaling Actions ---
  void callUser(String receiverId, String callerName, String callerPhoto, bool isVideo) {
    if (!_authProvider.isAuthenticated) return;
    SocketService.emit('call_user', {
      'receiverId': receiverId,
      'callerId': _authProvider.user!['id'].toString(),
      'callerName': callerName,
      'callerPhoto': callerPhoto,
      'isVideo': isVideo,
    });
  }

  void answerCall(String callerId) {
    if (!_authProvider.isAuthenticated) return;
    SocketService.emit('call_answered', {
      'callerId': callerId,
      'answererId': _authProvider.user!['id'].toString(),
    });
  }

  void rejectCall(String callerId) {
    if (!_authProvider.isAuthenticated) return;
    SocketService.emit('call_rejected', {
      'callerId': callerId,
      'rejecterId': _authProvider.user!['id'].toString(),
    });
  }

  void endCall(String otherUserId) {
    if (!_authProvider.isAuthenticated) return;
    SocketService.emit('end_call', {
      'otherUserId': otherUserId,
      'enderId': _authProvider.user!['id'].toString(),
    });
  }

  List<Map<String, dynamic>> get conversations => _conversations;
  List<Map<String, dynamic>> get messages => _messages;
  bool get loadingConversations => _loadingConversations;
  bool get loadingMessages => _loadingMessages;
  int get unreadNotifications => _unreadNotifications;

  void clearUnreadNotifications() {
    _unreadNotifications = 0;
    notifyListeners();
  }

  bool isTyping(String userId) => _typingStatus[userId] ?? false;

  Future<void> fetchConversations() async {
    if (!_authProvider.isAuthenticated) return;
    final userId = _authProvider.user!['id'];

    _loadingConversations = true;
    notifyListeners();

    try {
      final result = await ApiService.get('get_conversations?user_id=$userId');
      if (result['success']) {
        _conversations = List<Map<String, dynamic>>.from(result['data']);
      }
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
    } finally {
      _loadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String otherId) async {
    if (!_authProvider.isAuthenticated) return;
    _currentChattingWithId = otherId;
    final userId = _authProvider.user!['id'];

    _loadingMessages = true;
    notifyListeners();

    try {
      final result = await ApiService.get('get_messages?user_id=$userId&other_id=$otherId');
      if (result['success']) {
        _messages = List<Map<String, dynamic>>.from(result['data']);
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    } finally {
      _loadingMessages = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> sendMessage(
    String receiverId,
    String? message, {
    String? filePath,
    String type = 'text',
    String? replyToId,
  }) async {
    if (!_authProvider.isAuthenticated) return {'success': false};
    final userId = _authProvider.user!['id'];

    try {
      final Map<String, dynamic> data = {
        'sender_id': userId,
        'receiver_id': receiverId,
        'content': message,
        'type': type,
        if (replyToId != null) 'reply_to_id': replyToId,
      };

      final result = filePath != null 
          ? await ApiService.post('send_message', data, file: File(filePath), fileField: 'file')
          : await ApiService.post('send_message', data);

      if (result['success']) {
        final newMessage = Map<String, dynamic>.from(result['data']);
        _messages.add(newMessage);
        notifyListeners();
        fetchConversations();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'فشل إرسال الرسالة'};
    }
  }

  bool isOnline(String userId) => _onlineStatus[userId] ?? false;

  void setTyping(String receiverId, bool isTyping) {
    if (!_authProvider.isAuthenticated) return;
    SocketService.emit('typing', {
      'receiverId': receiverId,
      'senderId': _authProvider.user!['id'].toString(),
      'isTyping': isTyping,
    });
  }

  void setCurrentChat(String? otherId) {
    _currentChattingWithId = otherId;
  }

  @override
  void dispose() {
    SocketService.disconnect();
    super.dispose();
  }
}

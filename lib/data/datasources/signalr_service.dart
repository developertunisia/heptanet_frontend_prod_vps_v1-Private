import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../core/constants.dart';
import '../../domain/models/message_received_dto.dart';
import '../../domain/models/typing_indicator_dto.dart';
import '../../domain/models/message_read_receipt_dto.dart';
import '../repositories/auth_repository_impl.dart';

enum SignalRConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _hubConnection;
  final AuthRepositoryImpl _authRepository = AuthRepositoryImpl();
  
  SignalRConnectionState _connectionState = SignalRConnectionState.disconnected;
  SignalRConnectionState get connectionState => _connectionState;

  // Stream controllers for real-time events
  final _messageReceivedController = StreamController<MessageReceivedDto>.broadcast();
  final _typingIndicatorController = StreamController<TypingIndicatorDto>.broadcast();
  final _messageReadController = StreamController<MessageReadReceiptDto>.broadcast();
  final _userOnlineController = StreamController<int>.broadcast();
  final _userOfflineController = StreamController<int>.broadcast();
  final _connectionStateController = StreamController<SignalRConnectionState>.broadcast();
  final _messageEditedController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeletedController = StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<MessageReceivedDto> get onMessageReceived => _messageReceivedController.stream;
  Stream<TypingIndicatorDto> get onTypingIndicator => _typingIndicatorController.stream;
  Stream<MessageReadReceiptDto> get onMessageRead => _messageReadController.stream;
  Stream<int> get onUserOnline => _userOnlineController.stream;
  Stream<int> get onUserOffline => _userOfflineController.stream;
  Stream<SignalRConnectionState> get onConnectionStateChanged => _connectionStateController.stream;
  Stream<Map<String, dynamic>> get onMessageEdited => _messageEditedController.stream;
  Stream<Map<String, dynamic>> get onMessageDeleted => _messageDeletedController.stream;

String get _hubUrl {
  return ApiConstants.signalRHubUrl;
}

  Future<void> connect() async {
    if (_connectionState == SignalRConnectionState.connected ||
        _connectionState == SignalRConnectionState.connecting) {
      print('⚠️ SignalR already connected or connecting');
      return;
    }

    try {
      _updateConnectionState(SignalRConnectionState.connecting);
      print('🔌 Connecting to SignalR Hub: $_hubUrl');

      final token = await _authRepository.getAccessToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            _hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
            ),
          )
          .withAutomaticReconnect(
            retryDelays: [0, 2000, 5000, 10000, 30000], // Exponential backoff
          )
          .build();

      _setupEventHandlers();
      _setupConnectionHandlers();

      await _hubConnection!.start();
      
      _updateConnectionState(SignalRConnectionState.connected);
      print('✅ SignalR Connected');
    } catch (e) {
      _updateConnectionState(SignalRConnectionState.failed);
      print('❌ SignalR Connection Error: $e');
      rethrow;
    }
  }

  void _setupConnectionHandlers() {
    _hubConnection?.onclose(({error}) {
      print('🔌 SignalR Connection Closed: $error');
      _updateConnectionState(SignalRConnectionState.disconnected);
    });

    _hubConnection?.onreconnecting(({error}) {
      print('🔄 SignalR Reconnecting: $error');
      _updateConnectionState(SignalRConnectionState.reconnecting);
    });

    _hubConnection?.onreconnected(({connectionId}) {
      print('✅ SignalR Reconnected: $connectionId');
      _updateConnectionState(SignalRConnectionState.connected);
    });
  }

  void _setupEventHandlers() {
    // Receive Private Message
    _hubConnection?.on('ReceivePrivateMessage', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final message = MessageReceivedDto.fromJson(arguments[0] as Map<String, dynamic>);
          print('📨 Received Private Message: ${message.content}');
          _messageReceivedController.add(message);
        } catch (e) {
          print('❌ Error parsing private message: $e');
        }
      }
    });

    // Receive Group Message
    _hubConnection?.on('ReceiveGroupMessage', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final message = MessageReceivedDto.fromJson(arguments[0] as Map<String, dynamic>);
          print('📨 Received Group Message: ${message.content}');
          _messageReceivedController.add(message);
        } catch (e) {
          print('❌ Error parsing group message: $e');
        }
      }
    });

    // New Message (generic)
    _hubConnection?.on('NewMessage', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final message = MessageReceivedDto.fromJson(arguments[0] as Map<String, dynamic>);
          print('📨 New Message: ${message.content}');
          _messageReceivedController.add(message);
        } catch (e) {
          print('❌ Error parsing new message: $e');
        }
      }
    });

    // User Typing
    _hubConnection?.on('UserTyping', (arguments) {
      if (arguments != null && arguments.length >= 2) {
        try {
          final conversationId = arguments[0] as int;
          final userId = arguments[1] as int;
          final userName = arguments.length > 2 ? arguments[2] as String? ?? '' : '';
          
          final typing = TypingIndicatorDto(
            conversationId: conversationId,
            userId: userId,
            userName: userName,
            isTyping: true,
          );
          print('⌨️ User Typing: $userName in conversation $conversationId');
          _typingIndicatorController.add(typing);
        } catch (e) {
          print('❌ Error parsing typing indicator: $e');
        }
      }
    });

    // User Stopped Typing
    _hubConnection?.on('UserStoppedTyping', (arguments) {
      if (arguments != null && arguments.length >= 2) {
        try {
          final conversationId = arguments[0] as int;
          final userId = arguments[1] as int;
          final userName = arguments.length > 2 ? arguments[2] as String? ?? '' : '';
          
          final typing = TypingIndicatorDto(
            conversationId: conversationId,
            userId: userId,
            userName: userName,
            isTyping: false,
          );
          print('⌨️ User Stopped Typing: $userName in conversation $conversationId');
          _typingIndicatorController.add(typing);
        } catch (e) {
          print('❌ Error parsing stopped typing indicator: $e');
        }
      }
    });

    // Message Read
    _hubConnection?.on('MessageRead', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final receipt = MessageReadReceiptDto.fromJson(arguments[0] as Map<String, dynamic>);
          print('✅ Message Read: ${receipt.messageId} by ${receipt.userName}');
          _messageReadController.add(receipt);
        } catch (e) {
          print('❌ Error parsing read receipt: $e');
        }
      }
    });

    // Message Edited
    _hubConnection?.on('MessageEdited', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final data = arguments[0] as Map<String, dynamic>;
          print('✏️ Message Edited: ${data['messageId']}');
          _messageEditedController.add(data);
        } catch (e) {
          print('❌ Error parsing message edited event: $e');
        }
      }
    });

    // Message Deleted
    _hubConnection?.on('MessageDeleted', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final data = arguments[0] as Map<String, dynamic>;
          print('🗑️ Message Deleted: ${data['messageId']}');
          _messageDeletedController.add(data);
        } catch (e) {
          print('❌ Error parsing message deleted event: $e');
        }
      }
    });

    // User Online
    _hubConnection?.on('UserOnline', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final userId = arguments[0] as int;
          print('🟢 User Online: $userId');
          _userOnlineController.add(userId);
        } catch (e) {
          print('❌ Error parsing user online event: $e');
        }
      }
    });

    // User Offline
    _hubConnection?.on('UserOffline', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final userId = arguments[0] as int;
          print('⚫ User Offline: $userId');
          _userOfflineController.add(userId);
        } catch (e) {
          print('❌ Error parsing user offline event: $e');
        }
      }
    });
  }

  // ==================== HUB METHODS ====================

  /// Join a conversation room
  Future<void> joinConversation(int conversationId) async {
    try {
      // Check connection state before invoking
      if (_connectionState != SignalRConnectionState.connected) {
        print('⚠️ Cannot join conversation: SignalR not connected (state: $_connectionState)');
        return; // Silently return instead of throwing
      }
      
      await _hubConnection?.invoke('JoinConversation', args: [conversationId]);
      print('✅ Joined conversation: $conversationId');
    } catch (e) {
      print('❌ Failed to join conversation: $e');
    }
  }

  /// Leave a conversation room
  Future<void> leaveConversation(int conversationId) async {
    try {
      // Check connection state before invoking
      if (_connectionState != SignalRConnectionState.connected) {
        print('⚠️ Cannot leave conversation: SignalR not connected (state: $_connectionState)');
        return; // Silently return instead of throwing
      }
      
      await _hubConnection?.invoke('LeaveConversation', args: [conversationId]);
      print('✅ Left conversation: $conversationId');
    } catch (e) {
      print('❌ Failed to leave conversation: $e');
    }
  }

  /// Join a group
  Future<void> joinGroup(int groupId) async {
    try {
      await _hubConnection?.invoke('JoinGroup', args: [groupId]);
      print('✅ Joined group: $groupId');
    } catch (e) {
      print('❌ Failed to join group: $e');
    }
  }

  /// Leave a group
  Future<void> leaveGroup(int groupId) async {
    try {
      await _hubConnection?.invoke('LeaveGroup', args: [groupId]);
      print('✅ Left group: $groupId');
    } catch (e) {
      print('❌ Failed to leave group: $e');
    }
  }

  /// Send typing indicator
  Future<void> sendTypingIndicator(int conversationId, {bool isGroup = false, int? groupId}) async {
    try {
      final args = groupId != null 
          ? [conversationId, isGroup, groupId]
          : [conversationId, isGroup];
      await _hubConnection?.invoke('UserTyping', args: args);
      print('⌨️ Sent typing indicator for conversation: $conversationId');
    } catch (e) {
      print('❌ Failed to send typing indicator: $e');
    }
  }

  /// Send stopped typing indicator
  Future<void> sendStoppedTypingIndicator(int conversationId, {bool isGroup = false, int? groupId}) async {
    try {
      final args = groupId != null 
          ? [conversationId, isGroup, groupId]
          : [conversationId, isGroup];
      await _hubConnection?.invoke('UserStoppedTyping', args: args);
      print('⌨️ Sent stopped typing indicator for conversation: $conversationId');
    } catch (e) {
      print('❌ Failed to send stopped typing indicator: $e');
    }
  }

  /// Mark message as read via SignalR
  Future<void> markAsRead(int messageId, int conversationId, int senderId) async {
    try {
      await _hubConnection?.invoke('MarkAsRead', args: [messageId, conversationId, senderId]);
      print('✅ Marked message as read: $messageId');
    } catch (e) {
      print('❌ Failed to mark as read: $e');
    }
  }

  /// Send message delivered notification
  Future<void> messageDelivered(int messageId, int senderId) async {
    try {
      await _hubConnection?.invoke('MessageDelivered', args: [messageId, senderId]);
      print('✅ Message delivered: $messageId');
    } catch (e) {
      print('❌ Failed to send delivered notification: $e');
    }
  }

  void _updateConnectionState(SignalRConnectionState newState) {
    _connectionState = newState;
    _connectionStateController.add(newState);
  }

  Future<void> disconnect() async {
    try {
      await _hubConnection?.stop();
      _updateConnectionState(SignalRConnectionState.disconnected);
      print('🔌 SignalR Disconnected');
    } catch (e) {
      print('❌ Error disconnecting SignalR: $e');
    }
  }

  void dispose() {
    _messageReceivedController.close();
    _typingIndicatorController.close();
    _messageReadController.close();
    _userOnlineController.close();
    _userOfflineController.close();
    _connectionStateController.close();
    _messageEditedController.close();
    _messageDeletedController.close();
    disconnect();
  }
}


import 'dart:io';
import '../../domain/repositories/messaging_repository.dart';
import '../../domain/models/conversation_dto.dart';
import '../../domain/models/send_message_dto.dart';
import '../../domain/models/message_response_dto.dart';
import '../../domain/models/message_received_dto.dart';
import '../../domain/models/typing_indicator_dto.dart';
import '../../domain/models/message_read_receipt_dto.dart';
import '../datasources/messaging_api_client.dart';
import '../datasources/signalr_service.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  final MessagingApiClient _apiClient;
  final SignalRService _signalRService;

  MessagingRepositoryImpl({
    MessagingApiClient? apiClient,
    SignalRService? signalRService,
  })  : _apiClient = apiClient ?? MessagingApiClient(),
        _signalRService = signalRService ?? SignalRService();

  // ==================== CONVERSATIONS ====================

  @override
  Future<List<ConversationDto>> getConversations({bool includeArchived = false}) async {
    try {
      return await _apiClient.getConversations(includeArchived: includeArchived);
    } catch (e) {
      print('❌ Repository: Failed to get conversations: $e');
      rethrow;
    }
  }

  @override
  Future<ConversationDto> getConversation(int conversationId) async {
    try {
      return await _apiClient.getConversation(conversationId);
    } catch (e) {
      print('❌ Repository: Failed to get conversation: $e');
      rethrow;
    }
  }

  @override
  Future<ConversationDto> createPrivateConversation(int otherUserId) async {
    try {
      return await _apiClient.createPrivateConversation(otherUserId);
    } catch (e) {
      print('❌ Repository: Failed to create private conversation: $e');
      rethrow;
    }
  }

  @override
  Future<ConversationDto> createGroupConversation(int groupId) async {
    try {
      return await _apiClient.createGroupConversation(groupId);
    } catch (e) {
      print('❌ Repository: Failed to create group conversation: $e');
      rethrow;
    }
  }

  @override
  Future<void> archiveConversation(int conversationId) async {
    try {
      await _apiClient.archiveConversation(conversationId);
    } catch (e) {
      print('❌ Repository: Failed to archive conversation: $e');
      rethrow;
    }
  }

  @override
  Future<void> unarchiveConversation(int conversationId) async {
    try {
      await _apiClient.unarchiveConversation(conversationId);
    } catch (e) {
      print('❌ Repository: Failed to unarchive conversation: $e');
      rethrow;
    }
  }

  @override
  Future<void> pinConversation(int conversationId) async {
    try {
      await _apiClient.pinConversation(conversationId);
    } catch (e) {
      print('❌ Repository: Failed to pin conversation: $e');
      rethrow;
    }
  }

  @override
  Future<void> unpinConversation(int conversationId) async {
    try {
      await _apiClient.unpinConversation(conversationId);
    } catch (e) {
      print('❌ Repository: Failed to unpin conversation: $e');
      rethrow;
    }
  }

  @override
  Future<void> muteConversation(int conversationId) async {
    try {
      await _apiClient.muteConversation(conversationId);
    } catch (e) {
      print('❌ Repository: Failed to mute conversation: $e');
      rethrow;
    }
  }

  @override
  Future<void> unmuteConversation(int conversationId) async {
    try {
      await _apiClient.unmuteConversation(conversationId);
    } catch (e) {
      print('❌ Repository: Failed to unmute conversation: $e');
      rethrow;
    }
  }

  // ==================== MESSAGES ====================

  @override
  Future<MessageResponseDto> sendMessage(SendMessageDto dto) async {
    try {
      // Use REST API to ensure persistence - SignalR will broadcast automatically
      return await _apiClient.sendMessage(dto);
    } catch (e) {
      print('❌ Repository: Failed to send message: $e');
      rethrow;
    }
  }

  @override
  Future<MessageResponseDto> sendVoiceMessage({
    required int conversationId,
    required File audioFile,
    int? receiverId,
    int? groupId,
    int? replyToMessageId,
  }) async {
    try {
      return await _apiClient.sendVoiceMessage(
        conversationId: conversationId,
        audioFile: audioFile,
        receiverId: receiverId,
        groupId: groupId,
        replyToMessageId: replyToMessageId,
      );
    } catch (e) {
      print('❌ Repository: Failed to send voice message: $e');
      rethrow;
    }
  }

  @override
  Future<List<MessageResponseDto>> getConversationMessages(
    int conversationId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      return await _apiClient.getConversationMessages(
        conversationId,
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      print('❌ Repository: Failed to get conversation messages: $e');
      rethrow;
    }
  }

  @override
  Future<void> markMessageAsRead(int messageId) async {
    try {
      await _apiClient.markMessageAsRead(messageId);
    } catch (e) {
      print('❌ Repository: Failed to mark message as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> markConversationAsRead(int conversationId) async {
    try {
      await _apiClient.markConversationAsRead(conversationId);
    } catch (e) {
      print('❌ Repository: Failed to mark conversation as read: $e');
      rethrow;
    }
  }

  @override
  Future<MessageResponseDto> editMessage(int messageId, String newContent) async {
    try {
      return await _apiClient.editMessage(messageId, newContent);
    } catch (e) {
      print('❌ Repository: Failed to edit message: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(int messageId) async {
    try {
      await _apiClient.deleteMessage(messageId);
    } catch (e) {
      print('❌ Repository: Failed to delete message: $e');
      rethrow;
    }
  }

  // ==================== SIGNALR CONNECTION ====================

  @override
  Future<void> connectSignalR() async {
    try {
      await _signalRService.connect();
    } catch (e) {
      print('❌ Repository: Failed to connect SignalR: $e');
      rethrow;
    }
  }

  @override
  Future<void> disconnectSignalR() async {
    try {
      await _signalRService.disconnect();
    } catch (e) {
      print('❌ Repository: Failed to disconnect SignalR: $e');
      rethrow;
    }
  }

  @override
  SignalRConnectionState get signalRConnectionState => _signalRService.connectionState;

  // ==================== SIGNALR HUB METHODS ====================

  @override
  Future<void> joinConversation(int conversationId) async {
    await _signalRService.joinConversation(conversationId);
  }

  @override
  Future<void> leaveConversation(int conversationId) async {
    await _signalRService.leaveConversation(conversationId);
  }

  @override
  Future<void> sendTypingIndicator(
    int conversationId, {
    bool isGroup = false,
    int? groupId,
  }) async {
    await _signalRService.sendTypingIndicator(
      conversationId,
      isGroup: isGroup,
      groupId: groupId,
    );
  }

  @override
  Future<void> sendStoppedTypingIndicator(
    int conversationId, {
    bool isGroup = false,
    int? groupId,
  }) async {
    await _signalRService.sendStoppedTypingIndicator(
      conversationId,
      isGroup: isGroup,
      groupId: groupId,
    );
  }

  // ==================== REAL-TIME EVENT STREAMS ====================

  @override
  Stream<MessageReceivedDto> get onMessageReceived => _signalRService.onMessageReceived;

  @override
  Stream<TypingIndicatorDto> get onTypingIndicator => _signalRService.onTypingIndicator;

  @override
  Stream<MessageReadReceiptDto> get onMessageRead => _signalRService.onMessageRead;

  @override
  Stream<int> get onUserOnline => _signalRService.onUserOnline;

  @override
  Stream<int> get onUserOffline => _signalRService.onUserOffline;

  @override
  Stream<SignalRConnectionState> get onConnectionStateChanged =>
      _signalRService.onConnectionStateChanged;

  @override
  Stream<Map<String, dynamic>> get onMessageEdited => _signalRService.onMessageEdited;

  @override
  Stream<Map<String, dynamic>> get onMessageDeleted => _signalRService.onMessageDeleted;
}


import 'dart:io';
import '../models/conversation_dto.dart';
import '../models/send_message_dto.dart';
import '../models/message_response_dto.dart';
import '../models/message_received_dto.dart';
import '../models/typing_indicator_dto.dart';
import '../models/message_read_receipt_dto.dart';
import '../../data/datasources/signalr_service.dart';

abstract class MessagingRepository {
  // Conversations
  Future<List<ConversationDto>> getConversations({bool includeArchived = false});
  Future<ConversationDto> getConversation(int conversationId);
  Future<ConversationDto> createPrivateConversation(int otherUserId);
  Future<ConversationDto> createGroupConversation(int groupId);
  Future<void> archiveConversation(int conversationId);
  Future<void> unarchiveConversation(int conversationId);
  Future<void> pinConversation(int conversationId);
  Future<void> unpinConversation(int conversationId);
  Future<void> muteConversation(int conversationId);
  Future<void> unmuteConversation(int conversationId);

  // Messages
  Future<MessageResponseDto> sendMessage(SendMessageDto dto);
  Future<MessageResponseDto> sendVoiceMessage({
    required int conversationId,
    required File audioFile,
    int? receiverId,
    int? groupId,
    int? replyToMessageId,
  });
  Future<List<MessageResponseDto>> getConversationMessages(
    int conversationId, {
    int page = 1,
    int pageSize = 50,
  });
  Future<void> markMessageAsRead(int messageId);
  Future<void> markConversationAsRead(int conversationId);
  Future<MessageResponseDto> editMessage(int messageId, String newContent);
  Future<void> deleteMessage(int messageId);

  // SignalR Connection
  Future<void> connectSignalR();
  Future<void> disconnectSignalR();
  SignalRConnectionState get signalRConnectionState;
  
  // SignalR Hub Methods
  Future<void> joinConversation(int conversationId);
  Future<void> leaveConversation(int conversationId);
  Future<void> sendTypingIndicator(int conversationId, {bool isGroup = false, int? groupId});
  Future<void> sendStoppedTypingIndicator(int conversationId, {bool isGroup = false, int? groupId});

  // Real-time Event Streams
  Stream<MessageReceivedDto> get onMessageReceived;
  Stream<TypingIndicatorDto> get onTypingIndicator;
  Stream<MessageReadReceiptDto> get onMessageRead;
  Stream<int> get onUserOnline;
  Stream<int> get onUserOffline;
  Stream<SignalRConnectionState> get onConnectionStateChanged;
  Stream<Map<String, dynamic>> get onMessageEdited;
  Stream<Map<String, dynamic>> get onMessageDeleted;
}


import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../domain/models/conversation_dto.dart';
import '../../domain/models/conversation_type.dart';
import '../../domain/models/create_conversation_dto.dart';
import '../../domain/models/send_message_dto.dart';
import '../../domain/models/message_response_dto.dart';
import '../repositories/auth_repository_impl.dart';

class MessagingApiClient {
  final String baseUrl;
  final AuthRepositoryImpl authRepository;

  MessagingApiClient({
    String? baseUrl,
    AuthRepositoryImpl? authRepository,
  })  : baseUrl = baseUrl ?? AppConfig.baseUrl,
        authRepository = authRepository ?? AuthRepositoryImpl();

  // ==================== CONVERSATIONS ====================

  /// Get all conversations
  Future<List<ConversationDto>> getConversations({
    bool includeArchived = false,
  }) async {
    final headers = await authRepository.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final uri = Uri.parse('$baseUrl/conversations?includeArchived=$includeArchived');
    print('🔍 GET Conversations: $uri');

    final response = await http.get(uri, headers: headers).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final dynamic decodedBody = json.decode(response.body);
      
      // Handle different response formats
      List<dynamic> data;
      if (decodedBody is List) {
        data = decodedBody;
      } else if (decodedBody is Map && decodedBody.containsKey('data')) {
        data = decodedBody['data'] as List<dynamic>;
      } else if (decodedBody is Map) {
        // If it's a map but no 'data' key, try common alternatives
        data = (decodedBody['conversations'] ?? 
                decodedBody['items'] ?? 
                decodedBody['results'] ?? 
                []) as List<dynamic>;
      } else {
        data = [];
      }
      
      return data.map((json) => ConversationDto.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load conversations: ${response.body}');
    }
  }

  /// Get specific conversation
  Future<ConversationDto> getConversation(int conversationId) async {
    final headers = await authRepository.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final uri = Uri.parse('$baseUrl/conversations/$conversationId');
    print('🔍 GET Conversation: $uri');

    final response = await http.get(uri, headers: headers).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final dynamic decodedBody = json.decode(response.body);
      
      // Handle wrapped response format
      Map<String, dynamic> conversationData;
      if (decodedBody is Map && decodedBody.containsKey('data')) {
        conversationData = Map<String, dynamic>.from(decodedBody['data'] as Map);
      } else if (decodedBody is Map) {
        conversationData = Map<String, dynamic>.from(decodedBody);
      } else {
        throw Exception('Unexpected response format');
      }
      
      return ConversationDto.fromJson(conversationData);
    } else {
      throw Exception('Failed to load conversation: ${response.body}');
    }
  }

  /// Create private conversation
  Future<ConversationDto> createPrivateConversation(int otherUserId) async {
    final headers = await authRepository.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final uri = Uri.parse('$baseUrl/conversations/private');
    final dto = CreateConversationDto(
      type: ConversationType.private,
      otherUserId: otherUserId,
    );

    print('🚀 POST Create Private Conversation: $uri');
    print('📤 Body: ${json.encode(dto.toJson())}');

    final response = await http
        .post(
          uri,
          headers: headers,
          body: json.encode(dto.toJson()),
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic decodedBody = json.decode(response.body);
      
      // Handle wrapped response format
      Map<String, dynamic> conversationData;
      if (decodedBody is Map && decodedBody.containsKey('data')) {
        conversationData = Map<String, dynamic>.from(decodedBody['data'] as Map);
      } else if (decodedBody is Map) {
        conversationData = Map<String, dynamic>.from(decodedBody);
      } else {
        throw Exception('Unexpected response format');
      }
      
      return ConversationDto.fromJson(conversationData);
    } else {
      throw Exception('Failed to create conversation: ${response.body}');
    }
  }

  /// Create group conversation
  Future<ConversationDto> createGroupConversation(int groupId) async {
    final headers = await authRepository.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final uri = Uri.parse('$baseUrl/conversations/group');
    final dto = CreateConversationDto(
      type: ConversationType.group,
      groupId: groupId,
    );

    print('🚀 POST Create Group Conversation: $uri');
    print('📤 Body: ${json.encode(dto.toJson())}');

    final response = await http
        .post(
          uri,
          headers: headers,
          body: json.encode(dto.toJson()),
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic decodedBody = json.decode(response.body);
      
      // Handle wrapped response format
      Map<String, dynamic> conversationData;
      if (decodedBody is Map && decodedBody.containsKey('data')) {
        conversationData = Map<String, dynamic>.from(decodedBody['data'] as Map);
      } else if (decodedBody is Map) {
        conversationData = Map<String, dynamic>.from(decodedBody);
      } else {
        throw Exception('Unexpected response format');
      }
      
      return ConversationDto.fromJson(conversationData);
    } else {
      throw Exception('Failed to create conversation: ${response.body}');
    }
  }

  /// Archive conversation
  Future<void> archiveConversation(int conversationId) async {
    final headers = await authRepository.getAuthHeaders();
    final uri = Uri.parse('$baseUrl/conversations/$conversationId/archive');
    
    print('🚀 POST Archive Conversation: $uri');
    
    final response = await http.post(uri, headers: headers).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to archive conversation: ${response.body}');
    }
  }

  /// Unarchive conversation
  Future<void> unarchiveConversation(int conversationId) async {
    final headers = await authRepository.getAuthHeaders();
    final uri = Uri.parse('$baseUrl/conversations/$conversationId/unarchive');
    
    print('🚀 POST Unarchive Conversation: $uri');
    
    final response = await http.post(uri, headers: headers).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to unarchive conversation: ${response.body}');
    }
  }

  /// Pin conversation
  Future<void> pinConversation(int conversationId) async {
    final headers = await authRepository.getAuthHeaders();
    final uri = Uri.parse('$baseUrl/conversations/$conversationId/pin');
    
    print('🚀 POST Pin Conversation: $uri');
    
    final response = await http.post(uri, headers: headers).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to pin conversation: ${response.body}');
    }
  }

  /// Unpin conversation
  Future<void> unpinConversation(int conversationId) async {
    final headers = await authRepository.getAuthHeaders();
    final uri = Uri.parse('$baseUrl/conversations/$conversationId/unpin');
    
    print('🚀 POST Unpin Conversation: $uri');
    
    final response = await http.post(uri, headers: headers).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to unpin conversation: ${response.body}');
    }
  }

  /// Mute conversation
  Future<void> muteConversation(int conversationId) async {
    final headers = await authRepository.getAuthHeaders();
    final uri = Uri.parse('$baseUrl/conversations/$conversationId/mute');
    
    print('🚀 POST Mute Conversation: $uri');
    
    final response = await http.post(uri, headers: headers).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to mute conversation: ${response.body}');
    }
  }

  /// Unmute conversation
  Future<void> unmuteConversation(int conversationId) async {
    final headers = await authRepository.getAuthHeaders();
    final uri = Uri.parse('$baseUrl/conversations/$conversationId/unmute');
    
    print('🚀 POST Unmute Conversation: $uri');
    
    final response = await http.post(uri, headers: headers).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to unmute conversation: ${response.body}');
    }
  }

  // ==================== MESSAGES ====================

  /// Send message (REST API - ensures persistence, SignalR broadcasts automatically)
  Future<MessageResponseDto> sendMessage(SendMessageDto dto) async {
    final headers = await authRepository.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final uri = Uri.parse('$baseUrl/messages');
    print('🚀 POST Send Message: $uri');
    print('📤 Body: ${json.encode(dto.toJson())}');

    final response = await http
        .post(
          uri,
          headers: headers,
          body: json.encode(dto.toJson()),
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic decodedBody = json.decode(response.body);
      
      // Handle wrapped response format
      Map<String, dynamic> messageData;
      if (decodedBody is Map && decodedBody.containsKey('data')) {
        messageData = Map<String, dynamic>.from(decodedBody['data'] as Map);
      } else if (decodedBody is Map) {
        messageData = Map<String, dynamic>.from(decodedBody);
      } else {
        throw Exception('Unexpected response format');
      }
      
      return MessageResponseDto.fromJson(messageData);
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  /// Get conversation messages (paginated)
  Future<List<MessageResponseDto>> getConversationMessages(
    int conversationId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final headers = await authRepository.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final uri = Uri.parse(
      '$baseUrl/messages/conversation/$conversationId?page=$page&pageSize=$pageSize',
    );
    print('🔍 GET Messages: $uri');

    final response = await http.get(uri, headers: headers).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    print('📥 Response status: ${response.statusCode}');
    // Ne pas logger tout le body (peut être très long), mais logger un échantillon pour les messages audio
    if (response.statusCode == 200) {
      final dynamic decodedBody = json.decode(response.body);
      
      // Handle different response formats
      List<dynamic> data;
      if (decodedBody is List) {
        data = decodedBody;
      } else if (decodedBody is Map && decodedBody.containsKey('data')) {
        data = decodedBody['data'] as List<dynamic>;
      } else if (decodedBody is Map) {
        // If it's a map but no 'data' key, try common alternatives
        data = (decodedBody['messages'] ?? 
                decodedBody['items'] ?? 
                decodedBody['results'] ?? 
                []) as List<dynamic>;
      } else {
        data = [];
      }
      
      // DEBUG: Vérifier les messages audio et leur durée
      print('🔍 [API RESPONSE] Nombre de messages reçus: ${data.length}');
      for (var msgJson in data) {
        if (msgJson is Map<String, dynamic>) {
          final type = msgJson['type'];
          final messageId = msgJson['messageId'];
          if (type == 2 || (type is String && type.contains('audio'))) {
            final attachments = msgJson['attachments'] as List<dynamic>?;
            if (attachments != null && attachments.isNotEmpty) {
              final att = attachments[0] as Map<String, dynamic>;
              print('🔍 [API RESPONSE] ⚠️ Message audio $messageId - durationSeconds dans JSON: ${att['durationSeconds']} (type: ${att['durationSeconds']?.runtimeType})');
              print('   - Attachment complet: $att');
            } else {
              print('⚠️ [API RESPONSE] Message audio $messageId - PAS D\'ATTACHMENTS!');
            }
          }
        }
      }
      
      return data.map((json) => MessageResponseDto.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load messages: ${response.body}');
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(int messageId) async {
    final headers = await authRepository.getAuthHeaders();
    final uri = Uri.parse('$baseUrl/messages/$messageId/read');
    
    print('🚀 POST Mark Message as Read: $uri');
    
    final response = await http.post(uri, headers: headers).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to mark message as read: ${response.body}');
    }
  }

  /// Mark all messages in conversation as read
  Future<void> markConversationAsRead(int conversationId) async {
    final headers = await authRepository.getAuthHeaders();
    final uri = Uri.parse('$baseUrl/messages/conversation/$conversationId/read-all');
    
    print('🚀 POST Mark Conversation as Read: $uri');
    
    final response = await http.post(uri, headers: headers).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to mark conversation as read: ${response.body}');
    }
  }

  /// Edit message
  Future<MessageResponseDto> editMessage(int messageId, String newContent) async {
    final headers = await authRepository.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final uri = Uri.parse('$baseUrl/messages/$messageId');
    print('🚀 PUT Edit Message: $uri');
    print('📤 Body: ${json.encode({'content': newContent})}');

    final response = await http
        .put(
          uri,
          headers: headers,
          body: json.encode({'content': newContent}),
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    print('📥 Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      return MessageResponseDto.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to edit message: ${response.body}');
    }
  }

  /// Delete message
  Future<void> deleteMessage(int messageId) async {
    final headers = await authRepository.getAuthHeaders();
    final uri = Uri.parse('$baseUrl/messages/$messageId');
    
    print('🚀 DELETE Message: $uri');
    
    final response = await http.delete(uri, headers: headers).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete message: ${response.body}');
    }
  }

  /// Send voice message
  Future<MessageResponseDto> sendVoiceMessage({
    required int conversationId,
    required File audioFile,
    int? receiverId,
    int? groupId,
    int? replyToMessageId,
  }) async {
    final headers = await authRepository.getAuthHeaders();
    // Ne pas mettre Content-Type, Dio le fera automatiquement pour multipart

    final uri = Uri.parse('$baseUrl/messages/voice');
    print('🚀 POST Send Voice Message: $uri');

    final formData = FormData.fromMap({
      'conversationId': conversationId,
      if (receiverId != null) 'receiverId': receiverId,
      if (groupId != null) 'groupId': groupId,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      'audioFile': await MultipartFile.fromFile(
        audioFile.path,
        filename: audioFile.path.split('/').last,
      ),
    });

    final dio = Dio();
    final response = await dio.post(
      uri.toString(),
      data: formData,
      options: Options(
        headers: headers,
        sendTimeout: const Duration(seconds: 30), // Plus long pour les fichiers
      ),
    );

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.data}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic decodedBody = response.data;
      
      Map<String, dynamic> messageData;
      if (decodedBody is Map && decodedBody.containsKey('data')) {
        messageData = Map<String, dynamic>.from(decodedBody['data'] as Map);
      } else if (decodedBody is Map) {
        messageData = Map<String, dynamic>.from(decodedBody);
      } else {
        throw Exception('Unexpected response format');
      }
      
      // Debug: Vérifier les attachments et leur durée
      if (messageData.containsKey('attachments') && messageData['attachments'] is List) {
        final attachments = messageData['attachments'] as List;
        print('🔍 Attachments count: ${attachments.length}');
        for (var i = 0; i < attachments.length; i++) {
          final att = attachments[i] as Map<String, dynamic>;
          print('🔍 Attachment $i - durationSeconds: ${att['durationSeconds']}');
        }
      }
      
      final message = MessageResponseDto.fromJson(messageData);
      print('🔍 Message parsed - audioAttachment durationSeconds: ${message.audioAttachment?.durationSeconds}');
      return message;
    } else {
      throw Exception('Failed to send voice message: ${response.data}');
    }
  }
}


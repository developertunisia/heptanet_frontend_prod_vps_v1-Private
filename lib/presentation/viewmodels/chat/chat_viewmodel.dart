import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../domain/models/conversation_dto.dart';
import '../../../domain/models/message_response_dto.dart';
import '../../../domain/models/message_received_dto.dart';
import '../../../domain/models/send_message_dto.dart';
import '../../../domain/models/typing_indicator_dto.dart';
import '../../../domain/models/message_status.dart';
import '../../../domain/models/message_type.dart';
import '../../../domain/models/message_attachment_dto.dart';
import '../../../domain/repositories/messaging_repository.dart';
import '../../../data/repositories/messaging_repository_impl.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/datasources/audio_recorder_service.dart';
import '../../../data/datasources/audio_player_service.dart';
import '../../../data/datasources/voice_message_hive_datasource.dart';
import '../../../core/constants.dart';

enum ChatLoadingState {
  idle,
  loading,
  loaded,
  error,
  sending,
}

class ChatViewModel extends ChangeNotifier {
  final MessagingRepository _repository;
  final AuthRepositoryImpl _authRepository;
  final int conversationId;
  
  ConversationDto? _conversation;
  List<MessageResponseDto> _messages = [];
  ChatLoadingState _loadingState = ChatLoadingState.idle;
  String? _errorMessage;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  int _currentPage = 1;
  final int _pageSize = 50;
  
  // Typing indicators
  final Map<int, String> _typingUsers = {};
  Timer? _typingTimer;
  Timer? _stopTypingTimer;
  
  // Stream subscriptions
  StreamSubscription? _messageReceivedSubscription;
  StreamSubscription? _typingIndicatorSubscription;
  StreamSubscription? _messageReadSubscription;
  StreamSubscription? _messageEditedSubscription;
  StreamSubscription? _messageDeletedSubscription;

  int? _currentUserId;

  // Audio services
  final AudioRecorderService _audioRecorder = AudioRecorderService();
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  final VoiceMessageHiveDataSource _voiceCache = VoiceMessageHiveDataSource();
  
  // Audio state
  bool _isRecording = false;
  int? _currentlyPlayingMessageId;
  
  // Audio stream subscriptions
  StreamSubscription<Duration>? _audioPositionSubscription;
  StreamSubscription<Duration>? _audioDurationSubscription;
  StreamSubscription<PlayerState>? _audioStateSubscription;

  ChatViewModel({
    required this.conversationId,
    MessagingRepository? repository,
    AuthRepositoryImpl? authRepository,
  })  : _repository = repository ?? MessagingRepositoryImpl(),
        _authRepository = authRepository ?? AuthRepositoryImpl() {
    _init();
    _voiceCache.init();
    _initAudioStreams();
  }

  void _initAudioStreams() {
    _audioPositionSubscription = _audioPlayer.positionStream.listen((_) {
      notifyListeners();
    });
    _audioDurationSubscription = _audioPlayer.durationStream.listen((_) {
      notifyListeners();
    });
    _audioStateSubscription = _audioPlayer.stateStream.listen((_) {
      notifyListeners();
    });
  }

  // Getters
  ConversationDto? get conversation => _conversation;
  List<MessageResponseDto> get messages => _messages;
  ChatLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreMessages => _hasMoreMessages;
  List<String> get typingUserNames => _typingUsers.values.toList();
  bool get isAnyoneTyping => _typingUsers.isNotEmpty;
  
  // Audio getters
  bool get isRecording => _isRecording;
  int? get currentlyPlayingMessageId => _currentlyPlayingMessageId;
  
  // Audio streams
  Stream<Duration> get audioPositionStream => _audioPlayer.positionStream;
  Stream<Duration> get audioDurationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get audioStateStream => _audioPlayer.stateStream;

  Future<void> _init() async {
    await _loadCurrentUser();
    
    // Make sure we have the current user ID before continuing
    if (_currentUserId == null) {
      print('❌ WARNING: Current user ID is null! Attempting to reload...');
      await _authRepository.checkAuthStatus();
      final user = _authRepository.currentUser;
      _currentUserId = user?.id;
      print('🔍 After reload: Current user ID = $_currentUserId');
    } else {
      print('✅ Current user ID loaded: $_currentUserId');
    }
    
    await _joinConversation();
    _listenToSignalREvents();
    await loadMessages();
  }

  Future<void> _loadCurrentUser() async {
    // First try to get from currentUser
    var user = _authRepository.currentUser;
    
    // If null, try to load from storage
    if (user == null) {
      await _authRepository.checkAuthStatus();
      user = _authRepository.currentUser;
    }
    
    _currentUserId = user?.id;
    print('🔍 Loaded current user ID: $_currentUserId');
  }

  Future<void> _joinConversation() async {
    try {
      await _repository.joinConversation(conversationId);
      print('✅ Joined conversation: $conversationId');
    } catch (e) {
      print('❌ Failed to join conversation: $e');
    }
  }

  void _listenToSignalREvents() {
    // New messages
    _messageReceivedSubscription = _repository.onMessageReceived.listen(
      (message) {
        if (message.conversationId == conversationId) {
          _handleNewMessage(message);
        }
      },
    );

    // Typing indicators
    _typingIndicatorSubscription = _repository.onTypingIndicator.listen(
      (indicator) {
        if (indicator.conversationId == conversationId && 
            indicator.userId != _currentUserId) {
          _handleTypingIndicator(indicator);
        }
      },
    );

    // Message read receipts
    _messageReadSubscription = _repository.onMessageRead.listen(
      (receipt) {
        _handleMessageRead(receipt);
      },
    );

    // Message edited
    _messageEditedSubscription = _repository.onMessageEdited.listen(
      (data) {
        _handleMessageEdited(data);
      },
    );

    // Message deleted
    _messageDeletedSubscription = _repository.onMessageDeleted.listen(
      (data) {
        _handleMessageDeleted(data);
      },
    );
  }

  void _handleNewMessage(MessageReceivedDto message) {
    print('📨 Handling new message: ID=${message.messageId}, Sender=${message.senderId}, CurrentUser=$_currentUserId');
    
    // ALWAYS check if message with this ID already exists (most important check)
    final existingIndex = _messages.indexWhere((m) => m.messageId == message.messageId);
    if (existingIndex != -1) {
      print('⚠️ Message ${message.messageId} already exists at index $existingIndex - updating status only');
      // Message already exists, just update its status
      final existing = _messages[existingIndex];
      // Pour les messages vocaux, s'assurer que le contenu est vide
      String messageContent = message.content;
      if (message.type == MessageType.audio) {
        messageContent = ''; // Toujours vide pour les messages vocaux
      }
      
      _messages[existingIndex] = MessageResponseDto(
        messageId: message.messageId,
        senderId: message.senderId,
        senderName: message.senderName,
        senderAvatar: message.senderAvatar,
        receiverId: existing.receiverId,
        receiverName: existing.receiverName,
        groupId: existing.groupId,
        groupName: existing.groupName,
        content: messageContent,
        createdAt: message.createdAt.toLocal(),
        status: message.status,
        type: message.type,
        attachments: message.attachments,
      );
      notifyListeners();
      return;
    }

    // Check if this is from current user
    if (message.senderId == _currentUserId) {
      print('⚠️ Message from current user ${message.messageId} - checking for temp message');
      
      // Look for temp message with same content (negative ID)
      final tempIndex = _messages.indexWhere(
        (m) => m.messageId < 0 && 
               m.content == message.content
      );
      
      if (tempIndex != -1) {
        print('✅ Found temp message at $tempIndex - replacing with real message ${message.messageId}');
        // Replace temp message with real one
        // Pour les messages vocaux, s'assurer que le contenu est vide
        String messageContent = message.content;
        if (message.type == MessageType.audio) {
          messageContent = ''; // Toujours vide pour les messages vocaux
        }
        
        _messages[tempIndex] = MessageResponseDto(
          messageId: message.messageId,
          senderId: message.senderId,
          senderName: message.senderName,
          senderAvatar: message.senderAvatar,
          content: messageContent,
          createdAt: message.createdAt.toLocal(),
          status: message.status,
          type: message.type,
          attachments: message.attachments,
        );
        notifyListeners();
        return;
      }
      
      // No temp message found - this means REST API already added it
      // Skip to avoid duplicate
      print('⚠️ No temp message found for ${message.messageId} from self - skipping (already added via REST)');
      return;
    }

    // New message from another user - add it
    print('✅ Adding new message ${message.messageId} from user ${message.senderId}');
    
    // Pour les messages vocaux, s'assurer que le contenu est vide
    String messageContent = message.content;
    if (message.type == MessageType.audio) {
      messageContent = ''; // Toujours vide pour les messages vocaux
    }
    
    final messageResponse = MessageResponseDto(
      messageId: message.messageId,
      senderId: message.senderId,
      senderName: message.senderName,
      senderAvatar: message.senderAvatar,
      content: messageContent,
      createdAt: message.createdAt.toLocal(),
      status: message.status,
      type: message.type,
      attachments: message.attachments,
    );

    _messages.insert(0, messageResponse);
    notifyListeners();

    // Mark as read since it's from another user
    // TODO: Temporarily disabled
    // _markMessageAsRead(message.messageId);
  }

  void _handleTypingIndicator(TypingIndicatorDto indicator) {
    if (indicator.isTyping) {
      _typingUsers[indicator.userId] = indicator.userName;
      
      // Auto-clear after 5 seconds
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 5), () {
        _typingUsers.remove(indicator.userId);
        notifyListeners();
      });
    } else {
      _typingUsers.remove(indicator.userId);
    }
    notifyListeners();
  }

  void _handleMessageRead(receipt) {
    // Update message status to read
    final index = _messages.indexWhere((m) => m.messageId == receipt.messageId);
    if (index != -1) {
      final message = _messages[index];
      _messages[index] = MessageResponseDto(
        messageId: message.messageId,
        senderId: message.senderId,
        senderName: message.senderName,
        receiverId: message.receiverId,
        receiverName: message.receiverName,
        groupId: message.groupId,
        groupName: message.groupName,
        content: message.content,
        createdAt: message.createdAt,
        status: MessageStatus.read,
      );
      notifyListeners();
    }
  }

  void _handleMessageEdited(Map<String, dynamic> data) {
    final messageId = data['messageId'] as int;
    final newContent = data['newContent'] as String;
    
    final index = _messages.indexWhere((m) => m.messageId == messageId);
    if (index != -1) {
      final message = _messages[index];
      _messages[index] = MessageResponseDto(
        messageId: message.messageId,
        senderId: message.senderId,
        senderName: message.senderName,
        receiverId: message.receiverId,
        receiverName: message.receiverName,
        groupId: message.groupId,
        groupName: message.groupName,
        content: newContent,
        createdAt: message.createdAt,
        status: message.status,
      );
      notifyListeners();
    }
  }

  void _handleMessageDeleted(Map<String, dynamic> data) {
    final messageId = data['messageId'] as int;
    _messages.removeWhere((m) => m.messageId == messageId);
    notifyListeners();
  }

  Future<void> loadMessages({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreMessages = true;
      _messages.clear();
    }

    _loadingState = ChatLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final newMessages = await _repository.getConversationMessages(
        conversationId,
        page: _currentPage,
        pageSize: _pageSize,
      );

      // Nettoyer le contenu des messages vocaux et S'ASSURER que la durée est préservée
      // CRITIQUE: Si refresh, préserver les durées des messages existants si le serveur ne les retourne pas
      final cleanedMessages = newMessages.map((msg) {
        if (msg.type == MessageType.audio) {
          // CRITIQUE: Préserver les attachments avec leur durée - VÉRIFIER et LOGGER
          final audioAtt = msg.audioAttachment;
          
          // Si refresh, vérifier si on a déjà ce message avec une durée valide
          MessageAttachmentDto? preservedAttachment;
          if (refresh) {
            final existingMessage = _messages.firstWhere(
              (m) => m.messageId == msg.messageId,
              orElse: () => MessageResponseDto(
                messageId: 0,
                senderId: 0,
                senderName: '',
                content: '',
                createdAt: DateTime.now(),
                status: MessageStatus.sent,
                type: MessageType.text,
                attachments: [],
              ),
            );
            
            if (existingMessage.messageId == msg.messageId && 
                existingMessage.audioAttachment != null &&
                existingMessage.audioAttachment!.durationSeconds != null &&
                existingMessage.audioAttachment!.durationSeconds! > 0) {
              // Le message existant a une durée valide
              if (audioAtt == null || 
                  audioAtt.durationSeconds == null || 
                  audioAtt.durationSeconds == 0) {
                // Le serveur n'a pas retourné de durée, préserver celle du message existant
                preservedAttachment = existingMessage.audioAttachment;
                print('✅ [LOAD MESSAGES] Préservation de la durée existante: ${preservedAttachment!.durationSeconds} secondes pour message ${msg.messageId}');
              }
            }
          }
          
          if (audioAtt != null) {
            print('🔍 [LOAD MESSAGES] Message audio ${msg.messageId} - durationSeconds: ${audioAtt.durationSeconds}');
            print('   - attachmentId: ${audioAtt.attachmentId}');
            print('   - fileUrl: ${audioAtt.fileUrl}');
            print('   - contentType: ${audioAtt.contentType}');
          } else {
            print('⚠️ [LOAD MESSAGES] Message audio ${msg.messageId} - PAS D\'ATTACHMENT!');
            print('   - attachments.length: ${msg.attachments.length}');
            if (msg.attachments.isNotEmpty) {
              print('   - premier attachment: ${msg.attachments.first.toJson()}');
            }
          }
          
          // CRITIQUE: Préserver les attachments avec leur durée
          // Si on a une durée préservée, l'utiliser
          List<MessageAttachmentDto> finalAttachments = msg.attachments;
          if (preservedAttachment != null && finalAttachments.isNotEmpty) {
            // Mettre à jour l'attachment avec la durée préservée
            finalAttachments = [
              MessageAttachmentDto(
                attachmentId: finalAttachments.first.attachmentId,
                fileName: finalAttachments.first.fileName,
                contentType: finalAttachments.first.contentType,
                fileUrl: finalAttachments.first.fileUrl,
                fullFileUrl: finalAttachments.first.fullFileUrl,
                fileSize: finalAttachments.first.fileSize,
                durationSeconds: preservedAttachment.durationSeconds, // Préserver la durée
              ),
            ];
          }
          
          return MessageResponseDto(
            messageId: msg.messageId,
            senderId: msg.senderId,
            senderName: msg.senderName,
            senderAvatar: msg.senderAvatar,
            receiverId: msg.receiverId,
            receiverName: msg.receiverName,
            groupId: msg.groupId,
            groupName: msg.groupName,
            content: '', // Toujours vide pour les messages vocaux
            createdAt: msg.createdAt,
            status: msg.status,
            type: msg.type,
            attachments: finalAttachments, // Préserver les attachments avec leur durée
          );
        }
        return msg;
      }).toList();

      if (refresh) {
        _messages = cleanedMessages;
      } else {
        _messages.addAll(cleanedMessages);
      }

      _hasMoreMessages = cleanedMessages.length >= _pageSize;
      _loadingState = ChatLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _loadingState = ChatLoadingState.error;
      notifyListeners();
      print('❌ Failed to load messages: $e');
    }
  }

  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;

    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();

    try {
      final newMessages = await _repository.getConversationMessages(
        conversationId,
        page: _currentPage,
        pageSize: _pageSize,
      );

      // Nettoyer le contenu des messages vocaux et S'ASSURER que la durée est préservée
      final cleanedMessages = newMessages.map((msg) {
        if (msg.type == MessageType.audio) {
          // CRITIQUE: Préserver les attachments avec leur durée - VÉRIFIER et LOGGER
          final audioAtt = msg.audioAttachment;
          if (audioAtt != null) {
            print('🔍 [LOAD MORE] Message audio ${msg.messageId} - durationSeconds: ${audioAtt.durationSeconds}');
          } else {
            print('⚠️ [LOAD MORE] Message audio ${msg.messageId} - PAS D\'ATTACHMENT!');
          }
          
          // CRITIQUE: Préserver les attachments avec leur durée
          return MessageResponseDto(
            messageId: msg.messageId,
            senderId: msg.senderId,
            senderName: msg.senderName,
            senderAvatar: msg.senderAvatar,
            receiverId: msg.receiverId,
            receiverName: msg.receiverName,
            groupId: msg.groupId,
            groupName: msg.groupName,
            content: '', // Toujours vide pour les messages vocaux
            createdAt: msg.createdAt,
            status: msg.status,
            type: msg.type,
            attachments: msg.attachments, // Préserver les attachments avec leur durée
          );
        }
        return msg;
      }).toList();

      _messages.addAll(cleanedMessages);
      _hasMoreMessages = cleanedMessages.length >= _pageSize;
    } catch (e) {
      print('❌ Failed to load more messages: $e');
      _currentPage--; // Revert page increment on error
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content, {int? replyToMessageId}) async {
    if (content.trim().isEmpty) return;

    // Stop typing indicator
    await stopTyping();

    final dto = SendMessageDto(
      conversationId: conversationId,
      content: content.trim(),
      receiverId: _conversation?.otherUserId,
      groupId: _conversation?.groupId,
      replyToMessageId: replyToMessageId,
    );

    // Optimistic update with temporary negative ID
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final tempMessage = MessageResponseDto(
      messageId: tempId,
      senderId: _currentUserId ?? 0,
      senderName: 'You',
      content: dto.content,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    _messages.insert(0, tempMessage);
    notifyListeners();

    try {
      final sentMessage = await _repository.sendMessage(dto);
      
      print('✅ Message sent successfully: ID=${sentMessage.messageId}');
      
      // Check if SignalR already added this message (race condition)
      final realMessageExists = _messages.any((m) => m.messageId == sentMessage.messageId);
      if (realMessageExists) {
        print('✅ Message ${sentMessage.messageId} already exists (added by SignalR) - removing temp if present');
        // Remove temp message if it still exists
        _messages.removeWhere((m) => m.messageId == tempId);
        notifyListeners();
        return;
      }
      
      // Replace temporary message with real one from server
      final index = _messages.indexWhere((m) => m.messageId == tempId);
      if (index != -1) {
        print('✅ Replacing temp message $tempId with real message ${sentMessage.messageId} at index $index');
        _messages[index] = sentMessage;
        notifyListeners();
      } else {
        print('⚠️ Temp message $tempId not found - checking if real message exists');
        // Double-check one more time before adding
        if (!_messages.any((m) => m.messageId == sentMessage.messageId)) {
          print('✅ Adding sent message ${sentMessage.messageId}');
          _messages.insert(0, sentMessage);
          notifyListeners();
        } else {
          print('⚠️ Message ${sentMessage.messageId} already exists - skipping');
        }
      }
      
      // Note: We'll receive this message via SignalR too, but _handleNewMessage 
      // will detect it already exists and won't add it again
    } catch (e) {
      // Mark as failed
      final index = _messages.indexWhere((m) => m.messageId == tempId);
      if (index != -1) {
        _messages[index] = MessageResponseDto(
          messageId: tempId,
          senderId: tempMessage.senderId,
          senderName: tempMessage.senderName,
          content: tempMessage.content,
          createdAt: tempMessage.createdAt,
          status: MessageStatus.failed,
        );
        notifyListeners();
      }
      
      _errorMessage = 'Failed to send message: $e';
      notifyListeners();
      print('❌ Failed to send message: $e');
    }
  }

  Future<void> editMessage(int messageId, String newContent) async {
    try {
      await _repository.editMessage(messageId, newContent);
      // Message will be updated via SignalR event
    } catch (e) {
      _errorMessage = 'Failed to edit message: $e';
      notifyListeners();
    }
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      await _repository.deleteMessage(messageId);
      // Message will be removed via SignalR event
    } catch (e) {
      _errorMessage = 'Failed to delete message: $e';
      notifyListeners();
    }
  }

  void onTyping() {
    // Debounce: send typing indicator after 1 second of typing
    _stopTypingTimer?.cancel();
    
    if (_typingTimer == null || !_typingTimer!.isActive) {
      _sendTypingIndicator();
    }

    // Auto-stop typing after 3 seconds of no activity
    _stopTypingTimer = Timer(const Duration(seconds: 3), () {
      stopTyping();
    });
  }

  Future<void> _sendTypingIndicator() async {
    try {
      await _repository.sendTypingIndicator(
        conversationId,
        isGroup: _conversation?.groupId != null,
        groupId: _conversation?.groupId,
      );
      
      _typingTimer = Timer(const Duration(seconds: 3), () {
        // Timer expires
      });
    } catch (e) {
      print('❌ Failed to send typing indicator: $e');
    }
  }

  Future<void> stopTyping() async {
    _typingTimer?.cancel();
    _stopTypingTimer?.cancel();
    
    try {
      await _repository.sendStoppedTypingIndicator(
        conversationId,
        isGroup: _conversation?.groupId != null,
        groupId: _conversation?.groupId,
      );
    } catch (e) {
      print('❌ Failed to send stopped typing indicator: $e');
    }
  }

  // TODO: Temporarily disabled mark as read functionality
  Future<void> _markMessageAsRead(int messageId) async {
    // try {
    //   await _repository.markMessageAsRead(messageId);
    // } catch (e) {
    //   print('❌ Failed to mark message as read: $e');
    // }
  }

  Future<void> markAllAsRead() async {
    // try {
    //   await _repository.markConversationAsRead(conversationId);
    // } catch (e) {
    //   print('❌ Failed to mark all as read: $e');
    // }
  }

  Future<void> leaveConversation() async {
    try {
      await _repository.leaveConversation(conversationId);
      print('✅ Left conversation: $conversationId');
    } catch (e) {
      print('❌ Failed to leave conversation: $e');
    }
  }

  // ==================== VOICE MESSAGE METHODS ====================

  /// Démarrer l'enregistrement vocal
  Future<void> startRecording() async {
    try {
      final path = await _audioRecorder.startRecording();
      if (path != null) {
        _isRecording = true;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Impossible de démarrer l\'enregistrement: $e';
      notifyListeners();
    }
  }

  /// Arrêter l'enregistrement et envoyer
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    try {
      final file = await _audioRecorder.stopRecording();
      _isRecording = false;
      
      if (file != null) {
        // Envoyer le message vocal
        await _sendVoiceMessage(file);
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'arrêt de l\'enregistrement: $e';
      notifyListeners();
    }
  }

  /// Annuler l'enregistrement
  Future<void> cancelRecording() async {
    await _audioRecorder.cancelRecording();
    _isRecording = false;
    notifyListeners();
  }

  /// Envoyer un message vocal
  Future<void> _sendVoiceMessage(File audioFile) async {
    try {
      // Obtenir la taille du fichier
      final fileSize = await audioFile.length();

      // ÉTAPE 1: Calculer la durée locale AVANT d'envoyer (CRITIQUE pour l'affichage immédiat)
      int? localDurationSeconds;
      
      // Attendre que le fichier soit complètement écrit
      await Future.delayed(const Duration(milliseconds: 300));
      
      try {
        print('🔍 [ENVOI VOCAL] Calcul de la durée locale pour: ${audioFile.path}');
        
        // Vérifier que le fichier existe et a une taille > 0
        if (!await audioFile.exists()) {
          print('❌ [ENVOI VOCAL] Le fichier n\'existe pas!');
        } else {
          final fileSize = await audioFile.length();
          print('🔍 [ENVOI VOCAL] Taille du fichier: $fileSize bytes');
          
          if (fileSize == 0) {
            print('⚠️ [ENVOI VOCAL] Le fichier est vide, attente supplémentaire...');
            await Future.delayed(const Duration(milliseconds: 500));
          }
          
          // Essayer de calculer la durée avec la nouvelle méthode (stream)
          final duration = await _audioPlayer.getLocalDuration(audioFile.path);
          if (duration != null && duration.inSeconds > 0) {
            localDurationSeconds = duration.inSeconds;
            print('✅ [ENVOI VOCAL] Durée locale calculée: $localDurationSeconds secondes');
          } else {
            print('⚠️ [ENVOI VOCAL] Durée locale est null ou 0 - réessayer...');
            // Réessayer plusieurs fois avec des délais progressifs
            for (int attempt = 1; attempt <= 3; attempt++) {
              await Future.delayed(Duration(milliseconds: 300 * attempt));
              final retryDuration = await _audioPlayer.getLocalDuration(audioFile.path);
              if (retryDuration != null && retryDuration.inSeconds > 0) {
                localDurationSeconds = retryDuration.inSeconds;
                print('✅ [ENVOI VOCAL] Durée locale calculée à l\'essai $attempt: $localDurationSeconds secondes');
                break;
              }
            }
            
            // Si toujours pas de durée, estimer basée sur la taille du fichier
            if (localDurationSeconds == null || localDurationSeconds == 0) {
              final estimatedSeconds = (fileSize / 16000).round(); // ~16KB par seconde pour AAC 128kbps
              if (estimatedSeconds > 0) {
                localDurationSeconds = estimatedSeconds;
                print('✅ [ENVOI VOCAL] Durée estimée basée sur la taille: $localDurationSeconds secondes');
              }
            }
          }
        }
      } catch (e) {
        print('❌ [ENVOI VOCAL] Erreur lors du calcul de la durée locale: $e');
        // Essayer une estimation basée sur la taille en dernier recours
        try {
          final fileSize = await audioFile.length();
          if (fileSize > 0) {
            final estimatedSeconds = (fileSize / 16000).round();
            if (estimatedSeconds > 0) {
              localDurationSeconds = estimatedSeconds;
              print('✅ [ENVOI VOCAL] Durée estimée (fallback): $localDurationSeconds secondes');
            }
          }
        } catch (_) {}
      }
      
      // Vérification finale
      if (localDurationSeconds == null || localDurationSeconds == 0) {
        print('⚠️ [ENVOI VOCAL] ATTENTION: Aucune durée disponible après tous les essais');
      } else {
        print('✅ [ENVOI VOCAL] Durée finale déterminée: $localDurationSeconds secondes');
      }

      // Message temporaire avec un attachment simulé pour l'affichage
      // La durée locale est utilisée pour l'affichage immédiat, puis sera mise à jour par le serveur
      final tempId = -DateTime.now().millisecondsSinceEpoch;
      
      // CRITIQUE: S'assurer que la durée est disponible avant de créer le message temporaire
      // Si la durée n'est pas encore calculée, attendre un peu plus
      if (localDurationSeconds == null || localDurationSeconds == 0) {
        print('⚠️ [ENVOI VOCAL] Durée pas encore disponible, attente supplémentaire...');
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Réessayer le calcul de la durée
        try {
          final retryDuration = await _audioPlayer.getLocalDuration(audioFile.path);
          if (retryDuration != null && retryDuration.inSeconds > 0) {
            localDurationSeconds = retryDuration.inSeconds;
            print('✅ [ENVOI VOCAL] Durée récupérée après attente: $localDurationSeconds secondes');
          }
        } catch (e) {
          print('⚠️ [ENVOI VOCAL] Erreur lors du recalcul de la durée: $e');
        }
      }
      
      // Si toujours pas de durée, utiliser une estimation basée sur la taille
      if (localDurationSeconds == null || localDurationSeconds == 0) {
        try {
          final estimatedSeconds = (fileSize / 16000).round();
          if (estimatedSeconds > 0) {
            localDurationSeconds = estimatedSeconds;
            print('✅ [ENVOI VOCAL] Utilisation de la durée estimée pour le message temporaire: $localDurationSeconds secondes');
          }
        } catch (_) {}
      }
      
      final tempMessage = MessageResponseDto(
        messageId: tempId,
        senderId: _currentUserId ?? 0,
        senderName: 'You',
        content: '', // Contenu vide pour les messages vocaux - on n'affiche pas le texte
        createdAt: DateTime.now(),
        status: MessageStatus.sending,
        type: MessageType.audio,
        attachments: [
          MessageAttachmentDto(
            attachmentId: 0,
            fileName: audioFile.path.split(Platform.pathSeparator).last,
            contentType: 'audio/m4a',
            fileUrl: audioFile.path,
            fullFileUrl: audioFile.path,
            fileSize: fileSize,
            durationSeconds: localDurationSeconds, // Durée locale calculée - GARANTIE d'être disponible
          ),
        ],
      );

      _messages.insert(0, tempMessage);
      print('✅ [ENVOI VOCAL] Message temporaire créé avec durée: ${localDurationSeconds ?? 0} secondes');
      notifyListeners(); // Notifier immédiatement pour afficher la durée

      // Envoyer via l'API
      final sentMessage = await _repository.sendVoiceMessage(
        conversationId: conversationId,
        audioFile: audioFile,
        receiverId: _conversation?.otherUserId,
        groupId: _conversation?.groupId,
      );

      // Debug: Vérifier la durée dans la réponse du serveur
      print('🔍 Durée du serveur: ${sentMessage.audioAttachment?.durationSeconds}');
      print('🔍 Attachment complet: ${sentMessage.audioAttachment?.toJson()}');

      // ÉTAPE 2: Construire le message final avec le fichier local ET la durée garantie
      print('🔍 [ENVOI VOCAL] Construction du message final...');
      
      // Vérifier si le fichier local existe encore (CRITIQUE pour la lecture immédiate)
      final localFileExists = await audioFile.exists();
      final localFilePath = localFileExists ? audioFile.path : null;
      
      if (localFileExists) {
        print('✅ [ENVOI VOCAL] Fichier local préservé: $localFilePath');
      } else {
        print('⚠️ [ENVOI VOCAL] Fichier local n\'existe plus - utilisation de l\'URL serveur');
      }
      
      // Déterminer la durée finale (PRIORITÉ: serveur > locale > FORCER calcul si null)
      int? finalDurationSeconds = sentMessage.audioAttachment?.durationSeconds;
      
      // Si le serveur n'a pas renvoyé de durée ou elle est 0, utiliser la locale
      if (finalDurationSeconds == null || finalDurationSeconds == 0) {
        if (localDurationSeconds != null && localDurationSeconds! > 0) {
          finalDurationSeconds = localDurationSeconds;
          print('✅ [ENVOI VOCAL] Utilisation de la durée locale: $finalDurationSeconds secondes');
        } else {
          // DERNIER RECOURS: Recalculer la durée maintenant avec la nouvelle méthode
          print('⚠️ [ENVOI VOCAL] Aucune durée disponible - tentative de recalcul avec stream...');
          if (localFileExists) {
            try {
              // Attendre un peu pour que le fichier soit complètement écrit
              await Future.delayed(const Duration(milliseconds: 500));
              
              final recalcDuration = await _audioPlayer.getLocalDuration(audioFile.path);
              if (recalcDuration != null && recalcDuration.inSeconds > 0) {
                finalDurationSeconds = recalcDuration.inSeconds;
                print('✅ [ENVOI VOCAL] Durée recalculée avec succès: $finalDurationSeconds secondes');
              } else {
                // DERNIER DERNIER RECOURS: Essayer encore une fois après un délai plus long
                print('⚠️ [ENVOI VOCAL] Premier recalcul échoué, nouvelle tentative...');
                await Future.delayed(const Duration(milliseconds: 1000));
                final lastTryDuration = await _audioPlayer.getLocalDuration(audioFile.path);
                if (lastTryDuration != null && lastTryDuration.inSeconds > 0) {
                  finalDurationSeconds = lastTryDuration.inSeconds;
                  print('✅ [ENVOI VOCAL] Durée récupérée au dernier essai: $finalDurationSeconds secondes');
                }
              }
            } catch (e) {
              print('❌ [ENVOI VOCAL] Échec du recalcul de la durée: $e');
            }
          }
        }
      } else {
        print('✅ [ENVOI VOCAL] Utilisation de la durée du serveur: $finalDurationSeconds secondes');
      }
      
      // GARANTIR qu'on a une durée - si toujours null, utiliser une valeur par défaut basée sur la taille du fichier
      if (finalDurationSeconds == null || finalDurationSeconds == 0) {
        print('⚠️ [ENVOI VOCAL] ATTENTION: Aucune durée disponible après tous les essais');
        print('   - Tentative d\'estimation basée sur la taille du fichier...');
        
        // Estimation approximative: pour un fichier AAC/M4A à 128kbps, ~1 seconde = ~16KB
        try {
          final fileSize = await audioFile.length();
          final estimatedSeconds = (fileSize / 16000).round();
          if (estimatedSeconds > 0) {
            finalDurationSeconds = estimatedSeconds;
            print('✅ [ENVOI VOCAL] Durée estimée: $finalDurationSeconds secondes (basée sur ${fileSize} bytes)');
          }
        } catch (e) {
          print('❌ [ENVOI VOCAL] Impossible d\'estimer la durée: $e');
        }
      }
      
      // Construire l'attachment final avec TOUTES les informations nécessaires
      MessageAttachmentDto finalAttachment;
      
      if (sentMessage.audioAttachment != null) {
        // Le serveur a renvoyé un attachment - le mettre à jour avec fichier local et durée
        finalAttachment = MessageAttachmentDto(
          attachmentId: sentMessage.audioAttachment!.attachmentId,
          fileName: sentMessage.audioAttachment!.fileName,
          contentType: sentMessage.audioAttachment!.contentType,
          // CRITIQUE: Préserver le fichier local en PRIORITÉ pour lecture immédiate
          fileUrl: localFilePath ?? sentMessage.audioAttachment!.fileUrl,
          fullFileUrl: sentMessage.audioAttachment!.fullFileUrl,
          fileSize: sentMessage.audioAttachment!.fileSize,
          // CRITIQUE: Garantir que la durée est toujours définie
          durationSeconds: finalDurationSeconds,
        );
      } else {
        // Le serveur n'a pas renvoyé d'attachment - créer un avec le fichier local
        finalAttachment = MessageAttachmentDto(
          attachmentId: 0,
          fileName: audioFile.path.split(Platform.pathSeparator).last,
          contentType: 'audio/m4a',
          fileUrl: localFilePath ?? '',
          fullFileUrl: sentMessage.attachments.isNotEmpty 
              ? sentMessage.attachments.first.fullFileUrl 
              : '',
          fileSize: await audioFile.length(),
          durationSeconds: finalDurationSeconds,
        );
      }
      
      // Construire le message final
      final finalMessage = MessageResponseDto(
        messageId: sentMessage.messageId,
        senderId: sentMessage.senderId,
        senderName: sentMessage.senderName,
        senderAvatar: sentMessage.senderAvatar,
        receiverId: sentMessage.receiverId,
        receiverName: sentMessage.receiverName,
        groupId: sentMessage.groupId,
        groupName: sentMessage.groupName,
        content: '', // Toujours vide pour les messages vocaux
        createdAt: sentMessage.createdAt,
        status: sentMessage.status,
        type: MessageType.audio,
        attachments: [finalAttachment],
      );
      
      print('✅ [ENVOI VOCAL] Message final créé:');
      print('   - fileUrl: ${finalAttachment.fileUrl}');
      print('   - duration: ${finalAttachment.durationSeconds} secondes');
      print('   - fileExists: ${localFileExists}');
      print('   - messageId: ${finalMessage.messageId}');
      
      // ÉTAPE 3: Remplacer le message temporaire avec le message final
      // CRITIQUE: Ne remplacer QUE le message concerné, ne pas toucher aux autres
      final tempIndex = _messages.indexWhere((m) => m.messageId == tempId);
      if (tempIndex != -1) {
        // Remplacer uniquement le message temporaire
        _messages[tempIndex] = finalMessage;
        print('✅ [ENVOI VOCAL] Message temporaire remplacé à l\'index $tempIndex');
        print('   - Durée du message final: ${finalAttachment.durationSeconds} secondes');
      } else {
        // Si le message temporaire n'existe plus, vérifier s'il y a déjà un message avec le même ID
        final existingIndex = _messages.indexWhere((m) => m.messageId == finalMessage.messageId);
        if (existingIndex != -1) {
          // Mettre à jour le message existant sans affecter les autres
          _messages[existingIndex] = finalMessage;
          print('✅ [ENVOI VOCAL] Message existant mis à jour à l\'index $existingIndex');
          print('   - Durée du message final: ${finalAttachment.durationSeconds} secondes');
        } else {
          // Insérer au début seulement si le message n'existe pas
          _messages.insert(0, finalMessage);
          print('✅ [ENVOI VOCAL] Message final inséré au début');
          print('   - Durée du message final: ${finalAttachment.durationSeconds} secondes');
        }
      }
      
      // Vérifier que le message final a bien les bonnes valeurs
      final verifyIndex = _messages.indexWhere((m) => m.messageId == finalMessage.messageId);
      if (verifyIndex != -1) {
        final verifyMessage = _messages[verifyIndex];
        print('🔍 [ENVOI VOCAL] Vérification du message dans la liste:');
        print('   - messageId: ${verifyMessage.messageId}');
        print('   - hasAudio: ${verifyMessage.hasAudio}');
        print('   - audioAttachment.fileUrl: ${verifyMessage.audioAttachment?.fileUrl}');
        print('   - audioAttachment.durationSeconds: ${verifyMessage.audioAttachment?.durationSeconds}');
        
        // CRITIQUE: Vérifier que la durée est bien présente
        if (verifyMessage.audioAttachment?.durationSeconds == null || 
            verifyMessage.audioAttachment!.durationSeconds == 0) {
          print('⚠️ [ENVOI VOCAL] ATTENTION: La durée n\'est pas présente dans le message final!');
        } else {
          print('✅ [ENVOI VOCAL] Durée confirmée dans le message final: ${verifyMessage.audioAttachment!.durationSeconds} secondes');
        }
      }
      
      // Notifier les listeners pour mettre à jour l'UI immédiatement
      notifyListeners();
      
      // NE PAS recharger tous les messages - cela peut écraser les durées des autres messages
      // Le message final a déjà été mis à jour avec les bonnes informations
      print('✅ [ENVOI VOCAL] Message envoyé et mis à jour - prêt pour lecture immédiate');
    } catch (e) {
      // Marquer le message temporaire comme échoué
      final tempIndex = _messages.indexWhere((m) => m.messageId < 0 && m.type == MessageType.audio);
      if (tempIndex != -1) {
        final tempMsg = _messages[tempIndex];
        _messages[tempIndex] = MessageResponseDto(
          messageId: tempMsg.messageId,
          senderId: tempMsg.senderId,
          senderName: tempMsg.senderName,
          content: tempMsg.content,
          createdAt: tempMsg.createdAt,
          status: MessageStatus.failed,
          type: tempMsg.type,
          attachments: tempMsg.attachments,
        );
      }
      _errorMessage = 'Échec de l\'envoi du message vocal: $e';
      notifyListeners();
    }
  }

  /// Jouer un message vocal
  Future<void> playVoiceMessage(MessageResponseDto message) async {
    try {
      print('🎵 [LECTURE] Tentative de lecture du message ${message.messageId}');
      
      // Vérifier si c'est un message vocal
      if (message.type != MessageType.audio) {
        print('❌ [LECTURE] Ce n\'est pas un message audio');
        return;
      }
      
      // Protection: Vérifier que le player n'est pas bloqué
      if (_audioPlayer.isPlaying && _currentlyPlayingMessageId != message.messageId) {
        // Arrêter la lecture précédente avant de commencer une nouvelle
        try {
          await _audioPlayer.stop();
        } catch (e) {
          print('⚠️ [LECTURE] Erreur lors de l\'arrêt de la lecture précédente: $e');
        }
      }

      // Si c'est un message temporaire (en cours d'envoi) avec un fichier local
      if (message.messageId < 0 && message.attachments.isNotEmpty) {
        final attachment = message.attachments.first;
        if (attachment.fileUrl.isNotEmpty) {
          final localFile = File(attachment.fileUrl);
          if (localFile.existsSync()) {
            // Si déjà en lecture, arrêter
            if (_currentlyPlayingMessageId == message.messageId && _audioPlayer.isPlaying) {
              await _audioPlayer.stop();
              _currentlyPlayingMessageId = null;
              notifyListeners();
              return;
            }
            
            // Arrêter toute autre lecture en cours
            if (_currentlyPlayingMessageId != null) {
              await _audioPlayer.stop();
            }
            
            await _audioPlayer.playLocal(attachment.fileUrl);
            _currentlyPlayingMessageId = message.messageId;
            notifyListeners();
            return;
          }
        }
      }

      // Vérifier si le message a un attachment audio
      if (!message.hasAudio || message.audioAttachment == null) return;

      final attachment = message.audioAttachment!;
      
      // Si déjà en lecture, arrêter
      if (_currentlyPlayingMessageId == message.messageId && _audioPlayer.isPlaying) {
        await _audioPlayer.stop();
        _currentlyPlayingMessageId = null;
        notifyListeners();
        return;
      }

      // Arrêter toute autre lecture en cours
      if (_currentlyPlayingMessageId != null) {
        await _audioPlayer.stop();
      }

      // PRIORITÉ 1: Vérifier si c'est un fichier local (message récemment envoyé ou temporaire)
      // CRITIQUE: Détecter les fichiers locaux même si le serveur a renvoyé une URL
      if (attachment.fileUrl.isNotEmpty) {
        // Détecter si c'est un chemin local (pas une URL HTTP/HTTPS)
        final isLocalPath = !attachment.fileUrl.startsWith('http://') && 
                           !attachment.fileUrl.startsWith('https://') &&
                           (attachment.fileUrl.contains(Platform.pathSeparator) ||
                            attachment.fileUrl.startsWith('/') ||
                            attachment.fileUrl.contains('\\'));
        
        if (isLocalPath) {
          final localFile = File(attachment.fileUrl);
          final fileExists = await localFile.exists();
          
          if (fileExists) {
            print('✅ [LECTURE] Fichier local trouvé et lisible: ${attachment.fileUrl}');
            try {
              await _audioPlayer.playLocal(attachment.fileUrl);
              _currentlyPlayingMessageId = message.messageId;
              notifyListeners();
              return;
            } catch (e) {
              print('❌ [LECTURE] Erreur lors de la lecture du fichier local: $e');
              // Continuer avec les autres méthodes
            }
          } else {
            print('⚠️ [LECTURE] Fichier local n\'existe plus: ${attachment.fileUrl}');
          }
        } else {
          print('🔍 [LECTURE] fileUrl est une URL serveur: ${attachment.fileUrl}');
        }
      }

      // Vérifier le cache local
      String? localPath;
      if (_voiceCache.hasCachedVoiceMessage(message.messageId)) {
        localPath = _voiceCache.getLocalFilePath(message.messageId);
      }

      if (localPath != null && File(localPath).existsSync()) {
        // Lire depuis le cache local
        await _audioPlayer.playLocal(localPath);
      } else {
        // Essayer d'abord via l'endpoint API (plus fiable et gère l'authentification)
        try {
          final headers = await _authRepository.getAuthHeaders();
          localPath = await _voiceCache.downloadAndCacheVoiceMessageFromApi(
            messageId: message.messageId,
            headers: headers,
            durationSeconds: attachment.durationSeconds,
          );
          
          if (localPath != null) {
            await _audioPlayer.playLocal(localPath);
            _currentlyPlayingMessageId = message.messageId;
            notifyListeners();
            return;
          }
        } catch (e) {
          print('⚠️ Échec du téléchargement via API, tentative avec URL directe: $e');
        }
        
        // Fallback: Télécharger depuis l'URL directe si l'API échoue
        String? serverUrl;
        
        // Si fullFileUrl est une URL complète (http:// ou https://)
        if (attachment.fullFileUrl.isNotEmpty && 
            (attachment.fullFileUrl.startsWith('http://') || 
             attachment.fullFileUrl.startsWith('https://'))) {
          serverUrl = attachment.fullFileUrl;
        }
        // Si fullFileUrl est une URL relative (commence par /)
        else if (attachment.fullFileUrl.isNotEmpty && 
                 attachment.fullFileUrl.startsWith('/')) {
          // Construire l'URL complète avec le baseUrl
          final baseUrl = AppConfig.baseUrl.replaceAll('/api', '');
          serverUrl = '$baseUrl${attachment.fullFileUrl}';
        }
        // Si fileUrl est une URL relative
        else if (attachment.fileUrl.isNotEmpty && 
                 attachment.fileUrl.startsWith('/') &&
                 !attachment.fileUrl.contains(Platform.pathSeparator)) {
          final baseUrl = AppConfig.baseUrl.replaceAll('/api', '');
          serverUrl = '$baseUrl${attachment.fileUrl}';
        }
        // Si c'est un chemin local (contient le séparateur de chemin)
        else if (attachment.fileUrl.isNotEmpty && 
                 attachment.fileUrl.contains(Platform.pathSeparator)) {
          final localFile = File(attachment.fileUrl);
          if (localFile.existsSync()) {
            await _audioPlayer.playLocal(attachment.fileUrl);
            _currentlyPlayingMessageId = message.messageId;
            notifyListeners();
            return;
          }
        }
        
        // Télécharger et mettre en cache depuis le serveur si on a une URL
        if (serverUrl != null) {
          try {
            final headers = await _authRepository.getAuthHeaders();
            localPath = await _voiceCache.downloadAndCacheVoiceMessage(
              messageId: message.messageId,
              serverUrl: serverUrl,
              durationSeconds: attachment.durationSeconds,
              headers: headers,
            );
            
            if (localPath != null) {
              await _audioPlayer.playLocal(localPath);
            } else {
              // Dernier fallback: lire directement depuis l'URL
              await _audioPlayer.play(serverUrl);
            }
          } catch (e) {
            print('❌ Erreur lors du téléchargement depuis URL: $e');
            // Dernier essai: lecture directe
            try {
              await _audioPlayer.play(serverUrl!);
            } catch (playError) {
              _errorMessage = 'Impossible de lire le message vocal: $playError';
              notifyListeners();
            }
          }
        }
      }

      _currentlyPlayingMessageId = message.messageId;
      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ [LECTURE] Erreur lors de la lecture du message vocal: $e');
      print('❌ [LECTURE] Stack trace: $stackTrace');
      _errorMessage = 'Impossible de lire le message vocal: $e';
      _currentlyPlayingMessageId = null;
      notifyListeners();
      
      // S'assurer que le player n'est pas bloqué
      try {
        await _audioPlayer.stop();
      } catch (stopError) {
        print('⚠️ [LECTURE] Erreur lors de l\'arrêt du player: $stopError');
      }
    }
  }

  /// Arrêter la lecture
  Future<void> stopPlaying() async {
    await _audioPlayer.stop();
    _currentlyPlayingMessageId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _stopTypingTimer?.cancel();
    _messageReceivedSubscription?.cancel();
    _typingIndicatorSubscription?.cancel();
    _messageReadSubscription?.cancel();
    _messageEditedSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _audioPositionSubscription?.cancel();
    _audioDurationSubscription?.cancel();
    _audioStateSubscription?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    leaveConversation();
    super.dispose();
  }
}


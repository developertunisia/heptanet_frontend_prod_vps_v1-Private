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
      _messages[existingIndex] = MessageResponseDto(
        messageId: message.messageId,
        senderId: message.senderId,
        senderName: message.senderName,
        senderAvatar: message.senderAvatar,
        receiverId: existing.receiverId,
        receiverName: existing.receiverName,
        groupId: existing.groupId,
        groupName: existing.groupName,
        content: message.content,
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
        _messages[tempIndex] = MessageResponseDto(
          messageId: message.messageId,
          senderId: message.senderId,
          senderName: message.senderName,
          senderAvatar: message.senderAvatar,
          content: message.content,
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
    final messageResponse = MessageResponseDto(
      messageId: message.messageId,
      senderId: message.senderId,
      senderName: message.senderName,
      senderAvatar: message.senderAvatar,
      content: message.content,
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

      if (refresh) {
        _messages = newMessages;
      } else {
        _messages.addAll(newMessages);
      }

      _hasMoreMessages = newMessages.length >= _pageSize;
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

      _messages.addAll(newMessages);
      _hasMoreMessages = newMessages.length >= _pageSize;
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

      // Calculer la durée locale pour l'affichage immédiat
      int? localDurationSeconds;
      try {
        final duration = await _audioPlayer.getLocalDuration(audioFile.path);
        if (duration != null) {
          localDurationSeconds = duration.inSeconds;
        }
      } catch (e) {
        print('⚠️ Impossible de calculer la durée locale: $e');
        // Continuer sans la durée, elle sera calculée par le serveur
      }

      // Message temporaire avec un attachment simulé pour l'affichage
      // La durée locale est utilisée pour l'affichage immédiat, puis sera mise à jour par le serveur
      final tempId = -DateTime.now().millisecondsSinceEpoch;
      final tempMessage = MessageResponseDto(
        messageId: tempId,
        senderId: _currentUserId ?? 0,
        senderName: 'You',
        content: '🎤 Message vocal',
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
            durationSeconds: localDurationSeconds, // Durée locale calculée
          ),
        ],
      );

      _messages.insert(0, tempMessage);
      notifyListeners();

      // Envoyer via l'API
      final sentMessage = await _repository.sendVoiceMessage(
        conversationId: conversationId,
        audioFile: audioFile,
        receiverId: _conversation?.otherUserId,
        groupId: _conversation?.groupId,
      );

      // Remplacer le message temporaire avec le vrai message du serveur
      final index = _messages.indexWhere((m) => m.messageId == tempId);
      if (index != -1) {
        _messages[index] = sentMessage;
      } else {
        _messages.insert(0, sentMessage);
      }
      notifyListeners();
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
      // Vérifier si c'est un message vocal
      if (message.type != MessageType.audio) return;

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

      // Vérifier si c'est un message temporaire (en cours d'envoi) avec fichier local
      if (message.messageId < 0 && attachment.fileUrl.isNotEmpty) {
        // Message temporaire - utiliser le fichier local directement
        final localFile = File(attachment.fileUrl);
        if (localFile.existsSync()) {
          await _audioPlayer.playLocal(attachment.fileUrl);
          _currentlyPlayingMessageId = message.messageId;
          notifyListeners();
          return;
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
    } catch (e) {
      _errorMessage = 'Impossible de lire le message vocal: $e';
      notifyListeners();
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


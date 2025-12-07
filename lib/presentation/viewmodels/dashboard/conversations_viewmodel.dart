import 'dart:async';
import 'package:flutter/material.dart';
import '../../../domain/models/conversation_dto.dart';
import '../../../domain/models/message_received_dto.dart';
import '../../../domain/repositories/messaging_repository.dart';
import '../../../data/repositories/messaging_repository_impl.dart';
import '../../../data/datasources/signalr_service.dart';

enum ConversationsLoadingState {
  idle,
  loading,
  loaded,
  error,
}

class ConversationsViewModel extends ChangeNotifier {
  final MessagingRepository _repository;

  List<ConversationDto> _conversations = [];
  List<ConversationDto> _filteredConversations = [];
  ConversationsLoadingState _loadingState = ConversationsLoadingState.idle;
  String? _errorMessage;
  String _searchQuery = '';
  SignalRConnectionState _connectionState = SignalRConnectionState.disconnected;

  // Stream subscriptions
  StreamSubscription? _messageReceivedSubscription;
  StreamSubscription? _connectionStateSubscription;

  ConversationsViewModel({MessagingRepository? repository})
      : _repository = repository ?? MessagingRepositoryImpl() {
    _init();
  }

  // Getters
  List<ConversationDto> get conversations => _filteredConversations;
  ConversationsLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  SignalRConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == SignalRConnectionState.connected;
  bool get isLoading => _loadingState == ConversationsLoadingState.loading;

  void _init() {
    _listenToSignalREvents();
    _listenToConnectionState();
  }

  void _listenToSignalREvents() {
    // Listen for new messages and update conversation list
    _messageReceivedSubscription = _repository.onMessageReceived.listen(
      (message) {
        _handleNewMessage(message);
      },
      onError: (error) {
        print('❌ Error listening to messages: $error');
      },
    );
  }

  void _listenToConnectionState() {
    _connectionStateSubscription = _repository.onConnectionStateChanged.listen(
      (state) {
        _connectionState = state;
        notifyListeners();
      },
    );
  }

  void _handleNewMessage(MessageReceivedDto message) {
    // Find the conversation and update its last message
    final index = _conversations.indexWhere(
      (c) => c.conversationId == message.conversationId,
    );

    if (index != -1) {
      final conversation = _conversations[index];
      final updated = conversation.copyWith(
        lastMessageContent: message.content,
        lastMessageAt: message.createdAt,
        unreadCount: conversation.unreadCount + 1,
      );

      _conversations[index] = updated;
      
      // Move to top
      _conversations.removeAt(index);
      _conversations.insert(0, updated);

      _applyFilters();
      notifyListeners();
    } else {
      // New conversation - refresh the list
      loadConversations();
    }
  }

  Future<void> loadConversations({bool includeArchived = false}) async {
    _loadingState = ConversationsLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _conversations = await _repository.getConversations(
        includeArchived: includeArchived,
      );

      // Sort by pinned first, then by last message time
      _conversations.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        
        final aTime = a.lastMessageAt ?? DateTime(2000);
        final bTime = b.lastMessageAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      _applyFilters();
      _loadingState = ConversationsLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _loadingState = ConversationsLoadingState.error;
      notifyListeners();
      print('❌ Failed to load conversations: $e');
    }
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredConversations = List.from(_conversations);
    } else {
      _filteredConversations = _conversations.where((conversation) {
        final name = (conversation.conversationName ?? '').toLowerCase();
        final lastMessage = (conversation.lastMessageContent ?? '').toLowerCase();
        return name.contains(_searchQuery) || lastMessage.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> pinConversation(int conversationId) async {
    try {
      await _repository.pinConversation(conversationId);
      await loadConversations();
    } catch (e) {
      _errorMessage = 'Failed to pin conversation: $e';
      notifyListeners();
    }
  }

  Future<void> unpinConversation(int conversationId) async {
    try {
      await _repository.unpinConversation(conversationId);
      await loadConversations();
    } catch (e) {
      _errorMessage = 'Failed to unpin conversation: $e';
      notifyListeners();
    }
  }

  Future<void> muteConversation(int conversationId) async {
    try {
      await _repository.muteConversation(conversationId);
      
      // Update locally
      final index = _conversations.indexWhere((c) => c.conversationId == conversationId);
      if (index != -1) {
        _conversations[index] = _conversations[index].copyWith(isMuted: true);
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to mute conversation: $e';
      notifyListeners();
    }
  }

  Future<void> unmuteConversation(int conversationId) async {
    try {
      await _repository.unmuteConversation(conversationId);
      
      // Update locally
      final index = _conversations.indexWhere((c) => c.conversationId == conversationId);
      if (index != -1) {
        _conversations[index] = _conversations[index].copyWith(isMuted: false);
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to unmute conversation: $e';
      notifyListeners();
    }
  }

  Future<void> archiveConversation(int conversationId) async {
    try {
      await _repository.archiveConversation(conversationId);
      
      // Remove from local list
      _conversations.removeWhere((c) => c.conversationId == conversationId);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to archive conversation: $e';
      notifyListeners();
    }
  }

  Future<void> markConversationAsRead(int conversationId) async {
    try {
      await _repository.markConversationAsRead(conversationId);
      
      // Update unread count locally
      final index = _conversations.indexWhere((c) => c.conversationId == conversationId);
      if (index != -1) {
        _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      print('❌ Failed to mark conversation as read: $e');
    }
  }

  int get totalUnreadCount {
    return _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  @override
  void dispose() {
    _messageReceivedSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    super.dispose();
  }
}


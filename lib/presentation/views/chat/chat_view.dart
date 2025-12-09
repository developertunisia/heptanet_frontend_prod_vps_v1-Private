import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../viewmodels/chat/chat_viewmodel.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/message_input_field.dart';
import '../../widgets/chat/typing_indicator_widget.dart';
import '../../widgets/chat/date_separator.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/models/message_type.dart';

class ChatView extends StatefulWidget {
  final int conversationId;
  final String? conversationName;

  const ChatView({
    super.key,
    required this.conversationId,
    this.conversationName,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();
  late ChatViewModel _viewModel;
  int? _currentUserId;
  
  // Audio state
  Duration? _currentAudioPosition;
  Duration? _currentAudioDuration;
  PlayerState _currentAudioState = PlayerState.stopped;
  
  // Stream subscriptions
  StreamSubscription<Duration>? _audioPositionSubscription;
  StreamSubscription<Duration>? _audioDurationSubscription;
  StreamSubscription<PlayerState>? _audioStateSubscription;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _scrollController.addListener(_onScroll);
  }
  
  void _initAudioStreams(ChatViewModel viewModel) {
    _audioPositionSubscription?.cancel();
    _audioDurationSubscription?.cancel();
    _audioStateSubscription?.cancel();
    
    _audioPositionSubscription = viewModel.audioPositionStream.listen((position) {
      setState(() {
        _currentAudioPosition = position;
      });
    });
    
    _audioDurationSubscription = viewModel.audioDurationStream.listen((duration) {
      setState(() {
        _currentAudioDuration = duration;
      });
    });
    
    _audioStateSubscription = viewModel.audioStateStream.listen((state) {
      setState(() {
        _currentAudioState = state;
      });
    });
  }

  Future<void> _loadCurrentUser() async {
    final authRepo = AuthRepositoryImpl();
    await authRepo.checkAuthStatus();
    final user = authRepo.currentUser;
    setState(() {
      _currentUserId = user?.id;
    });
    print('🔍 ChatView: Current user ID = $_currentUserId');
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _viewModel.loadMoreMessages();
    }
  }

  @override
  void dispose() {
    _audioPositionSubscription?.cancel();
    _audioDurationSubscription?.cancel();
    _audioStateSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(conversationId: widget.conversationId),
      child: Consumer<ChatViewModel>(
        builder: (context, viewModel, _) {
          _viewModel = viewModel;
          _initAudioStreams(viewModel);

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversationName ?? 'Chat',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  if (viewModel.isAnyoneTyping)
                    Text(
                      viewModel.typingUserNames.length == 1
                          ? 'typing...'
                          : '${viewModel.typingUserNames.length} typing...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onPressed: () => _showOptionsMenu(context, viewModel),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: _buildMessagesList(viewModel),
                ),
                if (viewModel.isAnyoneTyping)
                  TypingIndicatorWidget(
                    typingUsers: viewModel.typingUserNames,
                  ),
                MessageInputField(
                  onSend: (text) => viewModel.sendMessage(text),
                  onTyping: () => viewModel.onTyping(),
                  onStartVoiceRecording: () => viewModel.startRecording(),
                  onStopVoiceRecording: () => viewModel.stopRecording(),
                  onCancelVoiceRecording: () => viewModel.cancelRecording(),
                  isRecordingVoice: viewModel.isRecording,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessagesList(ChatViewModel viewModel) {
    if (viewModel.loadingState == ChatLoadingState.loading &&
        viewModel.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    if (viewModel.loadingState == ChatLoadingState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage ?? 'Failed to load messages',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.loadMessages(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (viewModel.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to start the conversation',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadMessages(refresh: true),
      color: Colors.black,
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: viewModel.messages.length + (viewModel.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == viewModel.messages.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              ),
            );
          }

          final message = viewModel.messages[index];
          final isCurrentUser = message.senderId == _currentUserId;

          // Check if we need to show date separator
          final showDateSeparator = index == viewModel.messages.length - 1 ||
              !_isSameDay(message.createdAt,
                  viewModel.messages[index + 1].createdAt);

          final isPlaying = viewModel.currentlyPlayingMessageId == message.messageId &&
                           _currentAudioState == PlayerState.playing;
          
          // Utiliser la durée du message depuis son attachment, ou la durée actuelle si en cours de lecture
          Duration? messageDuration;
          
          // PRIORITÉ 1: Si en cours de lecture, utiliser la durée du lecteur (pour barre de progression en temps réel)
          if (isPlaying && _currentAudioDuration != null && _currentAudioDuration!.inSeconds > 0) {
            messageDuration = _currentAudioDuration;
          } 
          // PRIORITÉ 2: TOUJOURS utiliser la durée stockée dans l'attachment pour l'affichage
          // CRITIQUE: Passer la durée même si elle est 0 ou null, le widget doit l'afficher
          else {
            // Chercher la durée dans l'attachment audio
            final audioAtt = message.audioAttachment;
            if (audioAtt != null && audioAtt.durationSeconds != null && audioAtt.durationSeconds! > 0) {
              messageDuration = Duration(seconds: audioAtt.durationSeconds!);
            } 
            // Si pas trouvé dans audioAttachment, chercher dans tous les attachments
            else if (message.attachments.isNotEmpty) {
              for (var att in message.attachments) {
                if (att.contentType.startsWith('audio/') && att.durationSeconds != null && att.durationSeconds! > 0) {
                  messageDuration = Duration(seconds: att.durationSeconds!);
                  break;
                }
              }
            }
          }
          // Si toujours null, le widget utilisera directement attachment.durationSeconds depuis le message
          
          return Column(
            children: [
              MessageBubble(
                message: message,
                isCurrentUser: isCurrentUser,
                onLongPress: isCurrentUser
                    ? () => _showMessageOptions(context, viewModel, message.messageId)
                    : null,
                onPlayVoice: (message.hasAudio || message.type == MessageType.audio)
                    ? () => viewModel.playVoiceMessage(message)
                    : null,
                isPlayingVoice: isPlaying,
                voicePosition: isPlaying ? _currentAudioPosition : null,
                voiceDuration: messageDuration,
              ),
              if (showDateSeparator)
                DateSeparator(date: message.createdAt),
            ],
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _showMessageOptions(
    BuildContext context,
    ChatViewModel viewModel,
    int messageId,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, viewModel, messageId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, viewModel, messageId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    ChatViewModel viewModel,
    int messageId,
  ) {
    final message = viewModel.messages.firstWhere((m) => m.messageId == messageId);
    final controller = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Enter new message',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              viewModel.editMessage(messageId, controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ChatViewModel viewModel,
    int messageId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              viewModel.deleteMessage(messageId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, ChatViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TODO: Temporarily disabled mark as read
            // ListTile(
            //   leading: const Icon(Icons.done_all),
            //   title: const Text('Mark all as read'),
            //   onTap: () {
            //     viewModel.markAllAsRead();
            //     Navigator.pop(context);
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh'),
              onTap: () {
                viewModel.loadMessages(refresh: true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}


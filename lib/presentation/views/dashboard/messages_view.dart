import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard/conversations_viewmodel.dart';
import '../../widgets/dashboard/conversation_list_tile.dart';
import '../../widgets/dashboard/connection_status_banner.dart';
import '../../widgets/dashboard/new_conversation_dialog.dart';
import '../chat/chat_view.dart';
import '../../../domain/repositories/messaging_repository.dart';
import '../../../domain/models/conversation_type.dart';

class MessagesView extends StatefulWidget {
  const MessagesView({super.key});

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ConversationsViewModel>();
      viewModel.loadConversations();
    });
  }

  Future<void> _startNewConversation() async {
    final user = await showDialog(
      context: context,
      builder: (context) => const NewConversationDialog(),
    );

    if (user != null && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );

      try {
        final messagingRepo = context.read<MessagingRepository>();
        final conversation = await messagingRepo.createPrivateConversation(user.id);
        
        if (mounted) {
          // Close loading dialog
          Navigator.pop(context);
          
          // Navigate to chat
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatView(
                conversationId: conversation.conversationId,
                conversationName: conversation.conversationName,
              ),
            ),
          );
          
          // Refresh conversations list
          context.read<ConversationsViewModel>().loadConversations();
        }
      } catch (e) {
        if (mounted) {
          // Close loading dialog
          Navigator.pop(context);
          
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create conversation: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConversationsViewModel>(
      builder: (context, viewModel, _) {
        return Stack(
          children: [
            Column(
              children: [
                // Connection status banner
                ConnectionStatusBanner(
                  connectionState: viewModel.connectionState,
                ),
                
                // Conversations list
                Expanded(
                  child: _buildBody(viewModel),
                ),
              ],
            ),
            
            // Floating action button
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _startNewConversation,
                backgroundColor: Colors.black,
                child: const Icon(Icons.add_comment, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(ConversationsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.conversations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    if (viewModel.loadingState == ConversationsLoadingState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage ?? 'Failed to load conversations',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.loadConversations(),
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

    if (viewModel.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new conversation to get started',
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
      onRefresh: () => viewModel.loadConversations(),
      color: Colors.black,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: viewModel.conversations.length,
        itemBuilder: (context, index) {
          final conversation = viewModel.conversations[index];
          return ConversationListTile(
            conversation: conversation,
            onTap: () {
              // Mark conversation as read when opening
              if (conversation.unreadCount > 0) {
                viewModel.markConversationAsRead(conversation.conversationId);
              }
              
              // Navigate to chat
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatView(
                    conversationId: conversation.conversationId,
                    conversationName: conversation.conversationName,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

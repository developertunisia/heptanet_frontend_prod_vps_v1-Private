import 'package:flutter/material.dart';
import '../../../domain/models/message_response_dto.dart';
import '../../../domain/models/message_type.dart';

class VoiceMessageBubble extends StatefulWidget {
  final MessageResponseDto message;
  final bool isCurrentUser;
  final VoidCallback? onPlay;
  final bool isPlaying;
  final Duration? position;
  final Duration? duration;

  const VoiceMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onPlay,
    this.isPlaying = false,
    this.position,
    this.duration,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final attachment = widget.message.audioAttachment;
    
    // Afficher même si pas d'attachment pour les messages en cours d'envoi
    final durationSeconds = attachment?.durationSeconds ?? 0;
    final maxWidth = MediaQuery.of(context).size.width * 0.6;
    
    // Si pas d'attachment mais que c'est un message audio, afficher quand même avec un bouton play
    if (attachment == null && widget.message.type == MessageType.audio) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: widget.isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.isCurrentUser) ...[
              _buildAvatar(),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: BoxConstraints(maxWidth: maxWidth),
                decoration: BoxDecoration(
                  color: widget.isCurrentUser ? Colors.black : Colors.grey.shade200,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(widget.isCurrentUser ? 16 : 4),
                    bottomRight: Radius.circular(widget.isCurrentUser ? 4 : 16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton play même pour les messages en cours d'envoi
                    if (widget.onPlay != null)
                      GestureDetector(
                        onTap: widget.onPlay,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: widget.isCurrentUser
                                ? Colors.white.withOpacity(0.2)
                                : Colors.black.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: widget.isCurrentUser ? Colors.white : Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                    if (widget.onPlay != null) const SizedBox(width: 12),
                    Icon(
                      Icons.mic,
                      color: widget.isCurrentUser ? Colors.white : Colors.black87,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.isCurrentUser ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.isCurrentUser) ...[
              const SizedBox(width: 8),
              _buildAvatar(),
            ],
          ],
        ),
      );
    }
    
    if (attachment == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: widget.isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isCurrentUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(maxWidth: maxWidth),
              decoration: BoxDecoration(
                color: widget.isCurrentUser ? Colors.black : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(widget.isCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(widget.isCurrentUser ? 4 : 16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton play/pause
                  GestureDetector(
                    onTap: widget.onPlay,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.isCurrentUser
                            ? Colors.white.withOpacity(0.2)
                            : Colors.black.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: widget.isCurrentUser ? Colors.white : Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Barre de progression
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Barre de progression visuelle
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: widget.isCurrentUser
                                ? Colors.white.withOpacity(0.3)
                                : Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: widget.duration != null && widget.duration!.inSeconds > 0
                              ? FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: widget.position != null
                                      ? (widget.position!.inSeconds / widget.duration!.inSeconds).clamp(0.0, 1.0)
                                      : 0.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: widget.isCurrentUser
                                          ? Colors.white
                                          : Colors.black87,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 4),
                        
                        // Durée
                        Text(
                          widget.duration != null
                              ? _formatDuration(widget.duration)
                              : '${durationSeconds ~/ 60}:${(durationSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isCurrentUser
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.isCurrentUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = widget.message.senderAvatar;
    final initials = _getInitials(widget.message.senderName);
    
    return CircleAvatar(
      radius: 18,
      backgroundColor: widget.isCurrentUser ? Colors.black : Colors.grey.shade300,
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Text(
              initials,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.isCurrentUser ? Colors.white : Colors.grey.shade700,
              ),
            )
          : null,
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}


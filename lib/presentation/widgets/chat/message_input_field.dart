import 'package:flutter/material.dart';
import 'voice_record_button.dart';

class MessageInputField extends StatefulWidget {
  final Function(String) onSend;
  final VoidCallback? onTyping;
  final VoidCallback? onStartVoiceRecording;
  final VoidCallback? onStopVoiceRecording;
  final VoidCallback? onCancelVoiceRecording;
  final bool isRecordingVoice;

  const MessageInputField({
    super.key,
    required this.onSend,
    this.onTyping,
    this.onStartVoiceRecording,
    this.onStopVoiceRecording,
    this.onCancelVoiceRecording,
    this.isRecordingVoice = false,
  });

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    
    // Notify typing
    if (hasText && widget.onTyping != null) {
      widget.onTyping!();
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Bouton d'enregistrement vocal
            if (widget.onStartVoiceRecording != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: VoiceRecordButton(
                  onStartRecording: widget.onStartVoiceRecording!,
                  onStopRecording: widget.onStopVoiceRecording ?? () {},
                  onCancelRecording: widget.onCancelVoiceRecording ?? () {},
                  isRecording: widget.isRecordingVoice,
                ),
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _hasText ? Colors.black : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: _hasText ? _handleSend : null,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.send,
                    color: _hasText ? Colors.white : Colors.grey.shade500,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


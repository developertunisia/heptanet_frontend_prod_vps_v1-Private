import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VoiceRecordButton extends StatefulWidget {
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;
  final bool isRecording;

  const VoiceRecordButton({
    super.key,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
    required this.isRecording,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didUpdateWidget(VoiceRecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _animationController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        // Feedback haptique pour confirmer le début de l'enregistrement
        HapticFeedback.mediumImpact();
        widget.onStartRecording();
      },
      onLongPressEnd: (_) {
        if (widget.isRecording) {
          widget.onStopRecording();
        }
      },
      onLongPressCancel: () {
        if (widget.isRecording) {
          widget.onCancelRecording();
        }
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.isRecording
                  ? Colors.red.withOpacity(0.8 + _animationController.value * 0.2)
                  : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mic,
              color: widget.isRecording ? Colors.white : Colors.black87,
              size: 24,
            ),
          );
        },
      ),
    );
  }
}


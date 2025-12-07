import 'package:flutter/material.dart';

class MessagePreview {
  const MessagePreview({
    required this.sender,
    required this.snippet,
    required this.time,
    this.unread = false,
  });

  final String sender;
  final String snippet;
  final String time;
  final bool unread;
}

class MessagesViewModel extends ChangeNotifier {
  final List<MessagePreview> _messages = [];

  List<MessagePreview> get messages => List.unmodifiable(_messages);

  void setMessages(List<MessagePreview> messages) {
    _messages
      ..clear()
      ..addAll(messages);
    notifyListeners();
  }

  void clear() {
    if (_messages.isEmpty) return;
    _messages.clear();
    notifyListeners();
  }
}

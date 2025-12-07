import 'message_type.dart';

class SendMessageDto {
  final int conversationId;
  final String content;
  final int? receiverId;
  final int? groupId;
  final MessageType type;
  final int? replyToMessageId;

  SendMessageDto({
    required this.conversationId,
    required this.content,
    this.receiverId,
    this.groupId,
    this.type = MessageType.text,
    this.replyToMessageId,
  });

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'content': content,
      if (receiverId != null) 'receiverId': receiverId,
      if (groupId != null) 'groupId': groupId,
      'type': type.toInt(),
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
    };
  }

  factory SendMessageDto.fromJson(Map<String, dynamic> json) {
    return SendMessageDto(
      conversationId: json['conversationId'] as int,
      content: json['content'] as String,
      receiverId: json['receiverId'] as int?,
      groupId: json['groupId'] as int?,
      type: MessageType.fromJson(json['type']),
      replyToMessageId: json['replyToMessageId'] as int?,
    );
  }
}


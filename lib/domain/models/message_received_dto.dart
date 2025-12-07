import 'message_type.dart';
import 'message_status.dart';
import 'message_attachment_dto.dart';

class MessageReceivedDto {
  final int messageId;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final MessageType type;
  final String content;
  final DateTime createdAt;
  final int? replyToMessageId;
  final MessageStatus status;
  final List<MessageAttachmentDto> attachments;

  MessageReceivedDto({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    required this.content,
    required this.createdAt,
    this.replyToMessageId,
    required this.status,
    this.attachments = const [],
  });

  factory MessageReceivedDto.fromJson(Map<String, dynamic> json) {
    return MessageReceivedDto(
      messageId: json['messageId'] as int,
      conversationId: json['conversationId'] as int,
      senderId: json['senderId'] as int,
      senderName: json['senderName'] as String? ?? '',
      senderAvatar: json['senderAvatar'] as String?,
      type: MessageType.fromJson(json['type']),
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      replyToMessageId: json['replyToMessageId'] as int?,
      status: MessageStatus.fromJson(json['status']),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((a) => MessageAttachmentDto.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      if (senderAvatar != null) 'senderAvatar': senderAvatar,
      'type': type.toInt(),
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      'status': status.toInt(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }
}


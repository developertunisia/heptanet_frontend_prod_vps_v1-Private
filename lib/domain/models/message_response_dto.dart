import 'message_status.dart';
import 'message_type.dart';
import 'message_attachment_dto.dart';

class MessageResponseDto {
  final int messageId;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final int? receiverId;
  final String? receiverName;
  final int? groupId;
  final String? groupName;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;
  final MessageType type;
  final List<MessageAttachmentDto> attachments;

  MessageResponseDto({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.receiverId,
    this.receiverName,
    this.groupId,
    this.groupName,
    required this.content,
    required this.createdAt,
    required this.status,
    this.type = MessageType.text,
    this.attachments = const [],
  });

  // Propriétés calculées pour faciliter l'accès
  bool get hasAudio => attachments.any((a) => a.contentType.startsWith('audio/'));
  MessageAttachmentDto? get audioAttachment {
    try {
      return attachments.firstWhere(
        (a) => a.contentType.startsWith('audio/'),
        orElse: () => MessageAttachmentDto(
          attachmentId: 0,
          fileName: '',
          contentType: '',
          fileUrl: '',
          fullFileUrl: '',
          fileSize: 0,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  factory MessageResponseDto.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse int
    int? parseIntSafe(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return MessageResponseDto(
      messageId: parseIntSafe(json['messageId']) ?? 0,
      senderId: parseIntSafe(json['senderId']) ?? 0,
      senderName: json['senderName'] as String? ?? '',
      senderAvatar: json['senderAvatar'] as String?,
      receiverId: parseIntSafe(json['receiverId']),
      receiverName: json['receiverName'] as String?,
      groupId: parseIntSafe(json['groupId']),
      groupName: json['groupName'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String).toLocal()
          : DateTime.now(),
      status: MessageStatus.fromJson(json['status'] ?? 1),
      type: MessageType.fromJson(json['type'] ?? 0),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((a) => MessageAttachmentDto.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      if (senderAvatar != null) 'senderAvatar': senderAvatar,
      if (receiverId != null) 'receiverId': receiverId,
      if (receiverName != null) 'receiverName': receiverName,
      if (groupId != null) 'groupId': groupId,
      if (groupName != null) 'groupName': groupName,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toInt(),
      'type': type.toInt(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }
}


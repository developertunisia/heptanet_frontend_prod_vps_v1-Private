import 'message_status.dart';

class MessageStatusUpdateDto {
  final int messageId;
  final int conversationId;
  final MessageStatus status;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  MessageStatusUpdateDto({
    required this.messageId,
    required this.conversationId,
    required this.status,
    this.deliveredAt,
    this.readAt,
  });

  factory MessageStatusUpdateDto.fromJson(Map<String, dynamic> json) {
    return MessageStatusUpdateDto(
      messageId: json['messageId'] as int,
      conversationId: json['conversationId'] as int,
      status: MessageStatus.fromJson(json['status']),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'conversationId': conversationId,
      'status': status.toInt(),
      if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
      if (readAt != null) 'readAt': readAt!.toIso8601String(),
    };
  }
}


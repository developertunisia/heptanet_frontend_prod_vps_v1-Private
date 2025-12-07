import 'conversation_type.dart';

class CreateConversationDto {
  final ConversationType type;
  final int? otherUserId;
  final int? groupId;

  CreateConversationDto({
    required this.type,
    this.otherUserId,
    this.groupId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toInt(),
      if (otherUserId != null) 'otherUserId': otherUserId,
      if (groupId != null) 'groupId': groupId,
    };
  }

  factory CreateConversationDto.fromJson(Map<String, dynamic> json) {
    return CreateConversationDto(
      type: ConversationType.fromJson(json['type']),
      otherUserId: json['otherUserId'] as int?,
      groupId: json['groupId'] as int?,
    );
  }
}


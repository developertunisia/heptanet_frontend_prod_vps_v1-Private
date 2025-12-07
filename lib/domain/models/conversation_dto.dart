import 'conversation_type.dart';

class ConversationDto {
  final int conversationId;
  final ConversationType type;
  final String? conversationName;
  final String? avatarUrl;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;
  final int? otherUserId;
  final int? groupId;

  ConversationDto({
    required this.conversationId,
    required this.type,
    this.conversationName,
    this.avatarUrl,
    this.lastMessageContent,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
    this.otherUserId,
    this.groupId,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse int
    int? parseIntSafe(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return ConversationDto(
      conversationId: parseIntSafe(json['conversationId']) ?? 0,
      type: ConversationType.fromJson(json['type']),
      conversationName: json['conversationName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      lastMessageContent: json['lastMessageContent'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'] as String)?.toLocal()
          : null,
      unreadCount: parseIntSafe(json['unreadCount']) ?? 0,
      isMuted: json['isMuted'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      otherUserId: parseIntSafe(json['otherUserId']),
      groupId: parseIntSafe(json['groupId']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'type': type.toInt(),
      if (conversationName != null) 'conversationName': conversationName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (lastMessageContent != null) 'lastMessageContent': lastMessageContent,
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt!.toIso8601String(),
      'unreadCount': unreadCount,
      'isMuted': isMuted,
      'isPinned': isPinned,
      if (otherUserId != null) 'otherUserId': otherUserId,
      if (groupId != null) 'groupId': groupId,
    };
  }

  ConversationDto copyWith({
    int? conversationId,
    ConversationType? type,
    String? conversationName,
    String? avatarUrl,
    String? lastMessageContent,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isMuted,
    bool? isPinned,
    int? otherUserId,
    int? groupId,
  }) {
    return ConversationDto(
      conversationId: conversationId ?? this.conversationId,
      type: type ?? this.type,
      conversationName: conversationName ?? this.conversationName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      otherUserId: otherUserId ?? this.otherUserId,
      groupId: groupId ?? this.groupId,
    );
  }
}


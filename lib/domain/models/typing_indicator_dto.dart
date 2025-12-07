class TypingIndicatorDto {
  final int conversationId;
  final int userId;
  final String userName;
  final bool isTyping;

  TypingIndicatorDto({
    required this.conversationId,
    required this.userId,
    required this.userName,
    required this.isTyping,
  });

  factory TypingIndicatorDto.fromJson(Map<String, dynamic> json) {
    return TypingIndicatorDto(
      conversationId: json['conversationId'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String? ?? '',
      isTyping: json['isTyping'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'userId': userId,
      'userName': userName,
      'isTyping': isTyping,
    };
  }
}


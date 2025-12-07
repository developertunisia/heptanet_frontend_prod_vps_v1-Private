class MessageReadReceiptDto {
  final int messageId;
  final int userId;
  final String userName;
  final DateTime readAt;

  MessageReadReceiptDto({
    required this.messageId,
    required this.userId,
    required this.userName,
    required this.readAt,
  });

  factory MessageReadReceiptDto.fromJson(Map<String, dynamic> json) {
    return MessageReadReceiptDto(
      messageId: json['messageId'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String? ?? '',
      readAt: DateTime.parse(json['readAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'userId': userId,
      'userName': userName,
      'readAt': readAt.toIso8601String(),
    };
  }
}


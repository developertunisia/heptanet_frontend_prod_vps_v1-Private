class BroadcastResponseDto {
  final int broadcastId;
  final int senderId;
  final String senderName;
  final String title;
  final String content;
  final DateTime createdAt;

  BroadcastResponseDto({
    required this.broadcastId,
    required this.senderId,
    required this.senderName,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory BroadcastResponseDto.fromJson(Map<String, dynamic> json) {
    return BroadcastResponseDto(
      broadcastId: json['broadcastId'] as int,
      senderId: json['senderId'] as int,
      senderName: json['senderName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'broadcastId': broadcastId,
      'senderId': senderId,
      'senderName': senderName,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}


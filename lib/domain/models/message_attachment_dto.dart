class MessageAttachmentDto {
  final int attachmentId;
  final String fileName;
  final String contentType;
  final String fileUrl;
  final String fullFileUrl; // URL complète pour téléchargement
  final int fileSize;
  final int? durationSeconds; // Durée en secondes pour audio

  MessageAttachmentDto({
    required this.attachmentId,
    required this.fileName,
    required this.contentType,
    required this.fileUrl,
    required this.fullFileUrl,
    required this.fileSize,
    this.durationSeconds,
  });

  factory MessageAttachmentDto.fromJson(Map<String, dynamic> json) {
    return MessageAttachmentDto(
      attachmentId: json['attachmentId'] as int? ?? 0,
      fileName: json['fileName'] as String? ?? '',
      contentType: json['contentType'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      fullFileUrl: json['fullFileUrl'] as String? ?? json['fileUrl'] ?? '',
      fileSize: json['fileSize'] as int? ?? 0,
      durationSeconds: json['durationSeconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attachmentId': attachmentId,
      'fileName': fileName,
      'contentType': contentType,
      'fileUrl': fileUrl,
      'fullFileUrl': fullFileUrl,
      'fileSize': fileSize,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
    };
  }
}


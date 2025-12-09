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
    // Helper pour parser durationSeconds de manière robuste
    int? parseDurationSeconds(dynamic value) {
      if (value == null) return null;
      if (value is int) return value > 0 ? value : null;
      if (value is double) return value > 0 ? value.toInt() : null;
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed != null && parsed > 0 ? parsed : null;
      }
      return null;
    }
    
    final durationSeconds = parseDurationSeconds(json['durationSeconds']);
    
    // Debug pour vérifier le parsing - TOUJOURS logger pour les audio
    if (json['contentType'] != null && (json['contentType'] as String).startsWith('audio/')) {
      print('🔍 [PARSING] ⚠️ Attachment audio - durationSeconds RAW: ${json['durationSeconds']} (type: ${json['durationSeconds']?.runtimeType}) -> parsed: $durationSeconds');
      if (durationSeconds == null) {
        print('   ❌ [PARSING] PROBLÈME: durationSeconds est NULL après parsing!');
        print('   - JSON complet: $json');
      }
    }
    
    return MessageAttachmentDto(
      attachmentId: json['attachmentId'] as int? ?? 0,
      fileName: json['fileName'] as String? ?? '',
      contentType: json['contentType'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      fullFileUrl: json['fullFileUrl'] as String? ?? json['fileUrl'] ?? '',
      fileSize: json['fileSize'] as int? ?? 0,
      durationSeconds: durationSeconds,
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


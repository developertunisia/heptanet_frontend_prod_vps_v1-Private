import 'package:hive/hive.dart';

part 'voice_message_cache.g.dart';

@HiveType(typeId: 2)
class VoiceMessageCache extends HiveObject {
  @HiveField(0)
  final int messageId;
  
  @HiveField(1)
  final String localFilePath; // Chemin local du fichier audio
  
  @HiveField(2)
  final String? serverUrl; // URL du serveur (pour re-téléchargement si nécessaire)
  
  @HiveField(3)
  final DateTime cachedAt;
  
  @HiveField(4)
  final int? durationSeconds;

  VoiceMessageCache({
    required this.messageId,
    required this.localFilePath,
    this.serverUrl,
    required this.cachedAt,
    this.durationSeconds,
  });
}


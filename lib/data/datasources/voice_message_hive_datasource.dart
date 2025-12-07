import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../domain/models/voice_message_cache.dart';
import 'package:dio/dio.dart';
import '../../../core/constants.dart';

class VoiceMessageHiveDataSource {
  static const String _boxName = 'voice_messages';
  Box<VoiceMessageCache>? _box;

  Future<void> init() async {
    try {
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(VoiceMessageCacheAdapter());
      }
      _box = await Hive.openBox<VoiceMessageCache>(_boxName);
      print('✅ VoiceMessageHiveDataSource initialized');
    } catch (e) {
      print('❌ Error initializing VoiceMessageHiveDataSource: $e');
    }
  }

  /// Sauvegarder un message vocal en cache local
  Future<void> cacheVoiceMessage({
    required int messageId,
    required String localFilePath,
    String? serverUrl,
    int? durationSeconds,
  }) async {
    if (_box == null) await init();

    final cache = VoiceMessageCache(
      messageId: messageId,
      localFilePath: localFilePath,
      serverUrl: serverUrl,
      cachedAt: DateTime.now(),
      durationSeconds: durationSeconds,
    );

    await _box!.put(messageId, cache);
    print('✅ Voice message cached: $messageId');
  }

  /// Récupérer le cache d'un message vocal
  VoiceMessageCache? getCachedVoiceMessage(int messageId) {
    return _box?.get(messageId);
  }

  /// Vérifier si un message vocal est en cache
  bool hasCachedVoiceMessage(int messageId) {
    return _box?.containsKey(messageId) ?? false;
  }

  /// Obtenir le chemin local d'un message vocal
  String? getLocalFilePath(int messageId) {
    final cache = getCachedVoiceMessage(messageId);
    if (cache != null && File(cache.localFilePath).existsSync()) {
      return cache.localFilePath;
    }
    return null;
  }

  /// Télécharger et mettre en cache un message vocal depuis le serveur via l'endpoint API
  Future<String?> downloadAndCacheVoiceMessageFromApi({
    required int messageId,
    required Map<String, String> headers,
    int? durationSeconds,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final voiceDir = Directory('${directory.path}/voice_messages');
      if (!voiceDir.existsSync()) {
        await voiceDir.create(recursive: true);
      }

      final fileName = 'voice_${messageId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final localPath = '${voiceDir.path}/$fileName';

      // Utiliser l'endpoint API pour télécharger avec authentification
      final baseUrl = AppConfig.baseUrl;
      final apiUrl = '$baseUrl/messages/$messageId/voice';

      final dio = Dio();
      await dio.download(
        apiUrl,
        localPath,
        options: Options(headers: headers),
      );

      await cacheVoiceMessage(
        messageId: messageId,
        localFilePath: localPath,
        serverUrl: apiUrl,
        durationSeconds: durationSeconds,
      );

      return localPath;
    } catch (e) {
      print('❌ Erreur lors du téléchargement via API: $e');
      return null;
    }
  }

  /// Télécharger et mettre en cache un message vocal depuis le serveur (URL directe)
  Future<String?> downloadAndCacheVoiceMessage({
    required int messageId,
    required String serverUrl,
    int? durationSeconds,
    Map<String, String>? headers,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final voiceDir = Directory('${directory.path}/voice_messages');
      if (!voiceDir.existsSync()) {
        await voiceDir.create(recursive: true);
      }

      final fileName = 'voice_${messageId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final localPath = '${voiceDir.path}/$fileName';

      final dio = Dio();
      await dio.download(
        serverUrl,
        localPath,
        options: headers != null ? Options(headers: headers) : null,
      );

      await cacheVoiceMessage(
        messageId: messageId,
        localFilePath: localPath,
        serverUrl: serverUrl,
        durationSeconds: durationSeconds,
      );

      return localPath;
    } catch (e) {
      print('❌ Erreur lors du téléchargement: $e');
      return null;
    }
  }

  /// Supprimer un message vocal du cache
  Future<void> removeCachedVoiceMessage(int messageId) async {
    final cache = getCachedVoiceMessage(messageId);
    if (cache != null) {
      final file = File(cache.localFilePath);
      if (file.existsSync()) {
        await file.delete();
      }
      await _box?.delete(messageId);
    }
  }

  /// Nettoyer les anciens fichiers (optionnel)
  Future<void> cleanupOldCache({int daysOld = 30}) async {
    if (_box == null) return;

    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final keysToDelete = <int>[];

    for (var key in _box!.keys) {
      final cache = _box!.get(key);
      if (cache != null && cache.cachedAt.isBefore(cutoffDate)) {
        keysToDelete.add(key);
      }
    }

    for (var key in keysToDelete) {
      await removeCachedVoiceMessage(key);
    }
  }
}


import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:io';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentPlayingUrl;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  
  // Protection contre les appels simultanés pour getLocalDuration
  bool _isCalculatingDuration = false;

  // Streams pour notifier l'UI
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _stateController = StreamController<PlayerState>.broadcast();

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<PlayerState> get stateStream => _stateController.stream;

  String? get currentPlayingUrl => _currentPlayingUrl;
  bool get isPlaying => _player.state == PlayerState.playing;

  AudioPlayerService() {
    _positionSubscription = _player.onPositionChanged.listen(_positionController.add);
    _durationSubscription = _player.onDurationChanged.listen(_durationController.add);
    _stateSubscription = _player.onPlayerStateChanged.listen(_stateController.add);
  }

  /// Jouer un fichier audio depuis une URL
  Future<void> play(String url) async {
    try {
      if (_currentPlayingUrl == url && isPlaying) {
        await pause();
        return;
      }

      if (_currentPlayingUrl != url) {
        await _player.stop();
        await _player.play(UrlSource(url));
        _currentPlayingUrl = url;
      } else {
        await _player.resume();
      }
    } catch (e) {
      print('❌ Erreur lors de la lecture: $e');
      throw Exception('Impossible de lire le fichier audio');
    }
  }

  /// Jouer un fichier audio local
  Future<void> playLocal(String filePath) async {
    try {
      if (_currentPlayingUrl == filePath && isPlaying) {
        await pause();
        return;
      }

      if (_currentPlayingUrl != filePath) {
        await _player.stop();
        await _player.play(DeviceFileSource(filePath));
        _currentPlayingUrl = filePath;
      } else {
        await _player.resume();
      }
    } catch (e) {
      print('❌ Erreur lors de la lecture locale: $e');
      throw Exception('Impossible de lire le fichier audio local');
    }
  }

  /// Mettre en pause
  Future<void> pause() async {
    await _player.pause();
  }

  /// Arrêter
  Future<void> stop() async {
    await _player.stop();
    _currentPlayingUrl = null;
  }

  /// Obtenir la durée d'un fichier audio depuis une URL
  Future<Duration?> getDuration(String url) async {
    try {
      await _player.setSource(UrlSource(url));
      return await _player.getDuration();
    } catch (e) {
      print('❌ Erreur lors de la récupération de la durée: $e');
      return null;
    }
  }

  /// Obtenir la durée d'un fichier audio local
  /// Utilise le stream onDurationChanged pour une méthode plus fiable
  Future<Duration?> getLocalDuration(String filePath) async {
    // Protection contre les appels simultanés
    if (_isCalculatingDuration) {
      print('⚠️ [DURÉE] Un calcul de durée est déjà en cours, attente...');
      // Attendre un peu et réessayer une seule fois
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isCalculatingDuration) {
        print('⚠️ [DURÉE] Le calcul précédent est toujours en cours, abandon');
        return null;
      }
    }
    
    _isCalculatingDuration = true;
    AudioPlayer? tempPlayer;
    StreamSubscription<Duration>? durationSubscription;
    
    try {
      // Vérifier que le fichier existe
      final file = File(filePath);
      if (!await file.exists()) {
        print('⚠️ [DURÉE] Fichier n\'existe pas: $filePath');
        _isCalculatingDuration = false;
        return null;
      }

      // Créer un player temporaire pour éviter les conflits avec le player principal
      tempPlayer = AudioPlayer();
      
      // Utiliser un Completer pour attendre la durée depuis le stream
      final completer = Completer<Duration?>();
      Duration? finalDuration;
      
      // Écouter le stream onDurationChanged qui est plus fiable
      durationSubscription = tempPlayer.onDurationChanged.listen((duration) {
        if (duration != null && duration.inSeconds > 0 && !completer.isCompleted) {
          finalDuration = duration;
          completer.complete(duration);
        }
      });
      
      // Charger le fichier
      await tempPlayer.setSource(DeviceFileSource(filePath));
      
      // Attendre la durée depuis le stream avec un timeout
      try {
        finalDuration = await completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('⚠️ [DURÉE] Timeout en attendant la durée depuis le stream');
            return null;
          },
        );
      } catch (e) {
        print('⚠️ [DURÉE] Erreur en attendant le stream: $e');
      }
      
      // Si le stream n'a pas fonctionné, essayer getDuration() en fallback
      if (finalDuration == null || finalDuration!.inSeconds == 0) {
        print('⚠️ [DURÉE] Stream n\'a pas fourni de durée, tentative avec getDuration()...');
        await Future.delayed(const Duration(milliseconds: 500));
        
        for (int i = 0; i < 3; i++) {
          finalDuration = await tempPlayer.getDuration();
          if (finalDuration != null && finalDuration!.inSeconds > 0) {
            break;
          }
          if (i < 2) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }
      }
      
      // Nettoyer
      await durationSubscription?.cancel();
      if (tempPlayer != null) {
        try {
          await tempPlayer.dispose();
        } catch (e) {
          print('⚠️ [DURÉE] Erreur lors du dispose du player: $e');
        }
      }
      tempPlayer = null;
      _isCalculatingDuration = false;
      
      if (finalDuration != null && finalDuration!.inSeconds > 0) {
        print('✅ [DURÉE] Durée récupérée: ${finalDuration!.inSeconds} secondes pour $filePath');
        return finalDuration;
      } else {
        print('⚠️ [DURÉE] Durée est null ou 0 après toutes les tentatives');
        return null;
      }
    } catch (e) {
      print('❌ [DURÉE] Erreur lors de la récupération de la durée locale: $e');
      await durationSubscription?.cancel();
      if (tempPlayer != null) {
        try {
          await tempPlayer.dispose();
        } catch (_) {}
      }
      _isCalculatingDuration = false;
      return null;
    }
  }

  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _positionController.close();
    _durationController.close();
    _stateController.close();
    _player.dispose();
  }
}

